// On-device check (spec 1.5 #3, M5): a receipt survives
// attach → backup → "new phone" → restore → view, byte for byte, using the
// real image compressor, real SQLite and the real files on the device.
//
//   flutter test integration_test/backup_restore_test.dart -d <device-id>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/accounts/domain/account_type.dart';
import 'package:khaata_digital/features/backup/data/backup_service.dart';
import 'package:khaata_digital/features/backup/domain/backup.dart';
import 'package:khaata_digital/features/transactions/data/receipt_store.dart';
import 'package:khaata_digital/features/transactions/data/transactions_repository_impl.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:path_provider/path_provider.dart';

/// A real phone-sized PNG with some detail in it.
Future<File> photo(Directory dir) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var i = 0; i < 40; i++) {
    canvas.drawRect(
      Rect.fromLTWH(i * 30.0, i * 50.0, 900, 60),
      Paint()..color = Color(0xFF000000 + i * 0x061F0B),
    );
  }
  final image = await recorder.endRecording().toImage(1200, 2000);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return File('${dir.path}/receipt.png')
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

class Phone {
  Phone(Directory root)
    : db = AppDatabase(NativeDatabase(File('${root.path}/kharcha.db'))),
      receipts = ReceiptStore(
        root: () async => root,
        compress: compressReceiptImage,
      );

  final AppDatabase db;
  final ReceiptStore receipts;
  late final backups = BackupService(db, receipts)
    ..appVersion = (() async => 'integration');

  Future<Map<String, int>> balances() async => {
    for (final b in await db.accountsDao.balances())
      b.account.name: b.balanceMinor,
  };
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('receipt: attach → backup → restore → view', (tester) async {
    final base = await getTemporaryDirectory();
    final oldRoot = await Directory('${base.path}/old_phone').create();
    final newRoot = await Directory('${base.path}/new_phone').create();
    addTearDown(() async {
      await oldRoot.delete(recursive: true);
      await newRoot.delete(recursive: true);
    });

    // Old phone: an account and an entry with a real, compressed receipt.
    final old = Phone(oldRoot);
    final bank = await old.db.accountsDao.create(
      name: 'Meezan Bank',
      type: AccountType.bank,
      currencyCode: 'PKR',
      openingBalanceMinor: 1066100,
    );
    await TransactionsRepositoryImpl(old.db, old.receipts).save(
      EntryDraft(
        type: TransactionType.expense,
        amount: Money.parse('2520.50', Currency.pkr)!,
        accountId: bank,
        occurredAt: DateTime.now().toUtc(),
        note: 'Groceries',
        newReceiptPaths: [(await photo(oldRoot)).path],
      ),
    );
    final attachment = (await old.db.select(old.db.attachments).get()).single;
    final original = await File(
      await old.receipts.pathOf(attachment.fileName),
    ).readAsBytes();
    expect(sha256.convert(original).toString(), attachment.sha256);

    // Encrypted backup with the real 120,000-round key derivation.
    final backup = await old.backups.create(passphrase: 'chai-paratha');
    await old.db.close();

    // New phone: restore.
    final fresh = Phone(newRoot);
    final result = await fresh.backups.restore(
      backup.bytes,
      mode: RestoreMode.replace,
      passphrase: 'chai-paratha',
    );
    expect(result.receipts, 1);
    expect((await fresh.balances())['Meezan Bank'], 1066100 - 252050);

    final restored = await File(
      await fresh.receipts.pathOf(attachment.fileName),
    ).readAsBytes();
    expect(restored, original, reason: 'byte-identical receipt');

    // View: the restored file decodes and shows as an image.
    await tester.pumpWidget(
      MaterialApp(home: Image.memory(restored, key: const Key('receipt'))),
    );
    await tester.pumpAndSettle();
    final codec = await ui.instantiateImageCodec(restored);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, greaterThan(0));
    expect(find.byKey(const Key('receipt')), findsOneWidget);
    await fresh.db.close();
  });
}

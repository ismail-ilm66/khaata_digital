import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/accounts/data/accounts_dao.dart';
import 'package:khaata_digital/features/backup/data/backup_archive.dart';
import 'package:khaata_digital/features/backup/data/backup_service.dart';
import 'package:khaata_digital/features/backup/domain/backup.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';
import 'package:khaata_digital/features/transactions/data/receipt_store.dart';
import 'package:khaata_digital/features/transactions/data/transactions_repository_impl.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

import '../../helpers/test_db.dart';
import '../../helpers/test_receipts.dart';

/// One "phone": a database, its receipts folder and a backup service.
class Phone {
  Phone() : db = testDb(), receipts = testReceiptStore() {
    backups = BackupService(db, receipts)
      ..now = (() => DateTime(2026, 10, 6, 9, 30))
      ..appVersion = (() async => '1.0.0+1')
      ..iterations = 1000; // fast tests; real backups use 120,000
    transactions = TransactionsRepositoryImpl(db, receipts);
    ledger = TestLedger(db);
  }

  final AppDatabase db;
  final ReceiptStore receipts;
  late final BackupService backups;
  late final TransactionsRepositoryImpl transactions;
  late final TestLedger ledger;

  Future<Map<String, int>> balances() async => {
    for (final b in await db.accountsDao.balances())
      b.account.name: b.balanceMinor,
  };

  Future<Map<String, Map<String, int>>> people() async => {
    for (final p in await db.peopleDao.balances()) p.person.name: p.byCurrency,
  };

  /// Receipt file name → SHA-256 of its bytes on disk.
  Future<Map<String, String>> receiptHashes() async => {
    for (final a in await db.select(db.attachments).get())
      a.fileName: sha256
          .convert(await File(await receipts.pathOf(a.fileName)).readAsBytes())
          .toString(),
  };

  Future<void> close() => db.close();
}

void main() {
  late Phone old;
  late Phone fresh;

  setUp(() {
    old = Phone();
    fresh = Phone();
  });
  tearDown(() async {
    await old.close();
    await fresh.close();
  });

  /// A realistic book on [old]: accounts, transfer, udhaar, receipts,
  /// tags, a budget and settings.
  Future<void> fillOldPhone() async {
    final cash = (await old.db.accountsDao.balances()).single.account.id;
    final bank = await old.ledger.account('Meezan Bank', opening: 1066100);
    await old.ledger.account('Payoneer', currency: 'USD', opening: 50000);
    final ali = await old.db.peopleDao.create(name: 'Mudassir Bhai');
    await old.transactions.save(
      EntryDraft(
        type: TransactionType.expense,
        amount: Money.parse('2520.50', Currency.pkr)!,
        accountId: bank,
        occurredAt: DateTime.utc(2026, 9, 25, 8),
        note: 'Groceries',
        tags: const ['home'],
        newReceiptPaths: [
          fakeImage('a.jpg', List.generate(5000, (i) => i % 251)),
          fakeImage('b.jpg', List.generate(3000, (i) => (i * 7) % 253)),
        ],
      ),
    );
    await old.ledger.transfer(bank, cash, 500000);
    await old.ledger.expense(cash, 450000, personId: ali);
    await old.db.budgetsDao.setBudget(const CycleId(2026, 9), 5000000);
    await old.db.settingsDao.write(SettingKey.monthStartDay, '25');
  }

  group('backup → uninstall → reinstall → restore (M5 acceptance)', () {
    test('reproduces exact balances and byte-identical receipts', () async {
      await fillOldPhone();
      final backup = await old.backups.create();
      expect(backup.name, 'Kharcha-backup-2026-10-06-0930.kharcha');

      // "Reinstall": the new phone has only its seeded Cash and an entry
      // made before restoring, which Replace removes.
      await fresh.ledger.expense(
        (await fresh.db.accountsDao.balances()).single.account.id,
        999,
      );
      final result = await fresh.backups.restore(
        backup.bytes,
        mode: RestoreMode.replace,
      );

      expect(await fresh.balances(), await old.balances());
      expect(await fresh.people(), await old.people());
      expect(await fresh.receiptHashes(), await old.receiptHashes());
      expect(await fresh.receiptHashes(), hasLength(2));
      expect(
        AccountBalance.totalsByCurrency(await fresh.db.accountsDao.balances()),
        AccountBalance.totalsByCurrency(await old.db.accountsDao.balances()),
      );
      expect(await fresh.db.settingsDao.read(SettingKey.monthStartDay), '25');
      expect(await fresh.db.checkIntegrity(), isTrue);
      expect(result.transactions, 3);
      expect(result.receipts, 2);
      expect(result.manifest.appVersion, '1.0.0+1');
    });

    test(
      'an encrypted backup previews without, restores with, the passphrase',
      () async {
        await fillOldPhone();
        final backup = await old.backups.create(passphrase: 'chai-paratha');
        final raw = utf8.decode(backup.bytes, allowMalformed: true);
        expect(raw.contains('Groceries'), isFalse, reason: 'data is sealed');

        final preview = await fresh.backups.inspect(backup.bytes);
        expect(preview.encrypted, isTrue);
        expect(preview.accounts, 3);
        expect(preview.transactions, 3);
        expect(preview.first, DateTime.utc(2026, 9, 1, 12));

        for (final wrong in [null, '', 'chai']) {
          await expectLater(
            fresh.backups.restore(
              backup.bytes,
              mode: RestoreMode.replace,
              passphrase: wrong,
            ),
            throwsA(const BackupFailure(BackupFailureKind.wrongPassphrase)),
          );
        }
        await fresh.backups.restore(
          backup.bytes,
          mode: RestoreMode.replace,
          passphrase: 'chai-paratha',
        );
        expect(await fresh.balances(), await old.balances());
        expect(await fresh.receiptHashes(), await old.receiptHashes());
      },
    );
  });

  group('a failed restore never touches existing data', () {
    Future<void> expectUntouched(
      Future<void> Function() restore,
      BackupFailureKind kind,
    ) async {
      await fresh.ledger.expense(
        (await fresh.db.accountsDao.balances()).single.account.id,
        12345,
      );
      final before = await fresh.balances();
      await expectLater(
        restore(),
        throwsA(isA<BackupFailure>().having((f) => f.kind, 'kind', kind)),
      );
      expect(await fresh.balances(), before);
      expect(await fresh.db.checkIntegrity(), isTrue);
    }

    test('not a backup', () async {
      await expectUntouched(
        () => fresh.backups.restore(
          utf8.encode('hello'),
          mode: RestoreMode.replace,
        ),
        BackupFailureKind.notABackup,
      );
    });

    test('a changed byte fails the manifest hash', () async {
      await fillOldPhone();
      final backup = await old.backups.create();
      final zip = ZipDecoder().decodeBytes(backup.bytes);
      final tampered = Archive();
      for (final f in zip.files) {
        final bytes = List<int>.of(f.content as List<int>);
        if (f.name == BackupArchive.databaseName) bytes[200] ^= 0xFF;
        tampered.addFile(ArchiveFile(f.name, bytes.length, bytes));
      }
      await expectUntouched(
        () => fresh.backups.restore(
          ZipEncoder().encode(tampered)!,
          mode: RestoreMode.replace,
        ),
        BackupFailureKind.damaged,
      );
    });

    test('a database that fails the integrity check', () async {
      final bytes = await BackupArchive.pack(
        manifest: _manifest(2),
        database: utf8.encode('definitely not sqlite'),
        receipts: const {},
      );
      await expectUntouched(
        () => fresh.backups.restore(bytes, mode: RestoreMode.replace),
        BackupFailureKind.integrity,
      );
    });

    test('a backup from a newer app', () async {
      final bytes = await BackupArchive.pack(
        manifest: _manifest(99),
        database: File('test/fixtures/golden/v2/kharcha.db').readAsBytesSync(),
        receipts: const {},
      );
      await expectUntouched(
        () => fresh.backups.restore(bytes, mode: RestoreMode.replace),
        BackupFailureKind.newerApp,
      );
    });
  });

  test('a backup from schema v1 migrates while restoring', () async {
    final expected =
        jsonDecode(
              File('test/fixtures/golden/v1/expected.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final bytes = await BackupArchive.pack(
      manifest: _manifest(1),
      database: File('test/fixtures/golden/v1/kharcha.db').readAsBytesSync(),
      receipts: const {},
    );
    await fresh.backups.restore(bytes, mode: RestoreMode.replace);
    expect(await fresh.balances(), expected['accounts']);
    final hashes = await fresh.db.select(fresh.db.importHashes).get();
    expect(hashes, isEmpty, reason: 'the v2 table exists and is empty');
  });

  group('merge', () {
    test('adds what is missing, matches by name, newer edit wins', () async {
      await fillOldPhone();
      final backup = await old.backups.create();

      // This phone already has its own Meezan Bank (another id), a new
      // entry, and a newer copy of one of the backup's entries.
      final mine = await fresh.ledger.account('meezan bank', opening: 100);
      await fresh.ledger.expense(mine, 1000);
      await fresh.backups.restore(backup.bytes, mode: RestoreMode.merge);

      final names = (await fresh.balances()).keys;
      expect(names, unorderedEquals(['Cash', 'meezan bank', 'Payoneer']));
      // Meezan: this phone's opening 100 − its 1000, plus the backup's
      // entries re-pointed at it (opening stays this phone's own).
      expect(
        (await fresh.balances())['meezan bank'],
        100 - 1000 - 252050 - 500000,
      );
      expect(await fresh.people(), await old.people());
      expect(await fresh.receiptHashes(), await old.receiptHashes());
      final categories = await fresh.db.categoriesDao.active();
      expect(
        categories.map((c) => '${c.kind.name}/${c.name}').toSet(),
        hasLength(categories.length),
        reason: 'seeded categories were matched, not duplicated',
      );

      // Restoring the same backup again changes nothing.
      final before = await fresh.balances();
      await fresh.backups.restore(backup.bytes, mode: RestoreMode.merge);
      expect(await fresh.balances(), before);

      // An entry edited later on the backup's phone wins on merge.
      final edited = (await old.db.select(old.db.transactions).get()).first;
      await (old.db.update(
        old.db.transactions,
      )..where((t) => t.id.equals(edited.id))).write(
        TransactionsCompanion(
          note: const Value('edited later'),
          updatedAt: Value(
            DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
        ),
      );
      await fresh.backups.restore(
        (await old.backups.create()).bytes,
        mode: RestoreMode.merge,
      );
      final merged = await (fresh.db.select(
        fresh.db.transactions,
      )..where((t) => t.id.equals(edited.id))).getSingle();
      expect(merged.note, 'edited later');
    });
  });

  group('history', () {
    test('on-device copies keep the newest 8; status ignores them', () async {
      final status = <BackupRecord?>[];
      final sub = old.backups.watchLast(offDevice: true).listen(status.add);
      for (var i = 0; i < 10; i++) {
        old.backups.now = () => DateTime(2026, 10, 1 + i, 9);
        await old.backups.saveOnDevice(await old.backups.create());
      }
      final kept = await old.backups.deviceBackups();
      expect(kept, hasLength(BackupService.keepOnDevice));
      expect(
        kept.first.path,
        endsWith('Kharcha-backup-2026-10-10-0900.kharcha'),
      );

      final file = await old.backups.create();
      await old.backups.record(file, BackupDestination.drive);
      await pumpEventQueue();
      expect(status.last?.destination, BackupDestination.drive);
      expect(status.whereType<BackupRecord>(), hasLength(1));
      await sub.cancel();
    });
  });
}

BackupManifest _manifest(int schema) => BackupManifest(
  schemaVersion: schema,
  appVersion: 'test',
  createdAt: DateTime.utc(2026),
  rowCounts: const {},
  accounts: 0,
  transactions: 0,
);

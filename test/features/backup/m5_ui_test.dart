import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/files/file_gateway.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/backup/data/backup_archive.dart';
import 'package:khaata_digital/features/backup/data/backup_service.dart';
import 'package:khaata_digital/features/backup/presentation/backup_screen.dart';
import 'package:khaata_digital/features/import_export/presentation/import_screen.dart';

import '../../helpers/fake_files.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';
import '../../helpers/test_receipts.dart';
import '../../helpers/ui.dart';

void main() {
  late AppDatabase db;
  late FakeFileGateway files;

  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  setUp(() async {
    db = await setUpTestApp();
    files = getIt<FileGateway>() as FakeFileGateway;
  });

  Future<void> start(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  Future<void> openMore(WidgetTester t, String tile) async {
    await t.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('More'),
      ),
    );
    await t.pumpAndSettle();
    await revealAndTap(t, find.byKey(Key(tile)));
  }

  Future<String> cashId() async =>
      (await db.accountsDao.balances()).single.account.id;

  testWidgets('Home asks for a backup until one leaves the phone', (t) async {
    await t.runAsync(() async => TestLedger(db).expense(await cashId(), 5000));
    await start(t);
    await waitFor(t, find.byKey(const Key('backupNudge')));
    expect(find.text("You haven't made a backup yet."), findsOneWidget);

    await t.tap(find.byKey(const Key('backupNudge')));
    await t.pumpAndSettle();
    expect(find.byType(BackupScreen), findsOneWidget);
    expect(find.text('No backup yet'), findsOneWidget);

    await t.tap(find.byKey(const Key('backupToFile')));
    await waitFor(t, find.text('Backup saved'));
    expect(files.saved.single.name, endsWith('.kharcha'));
    expect(find.text('Last backup'), findsOneWidget);

    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('backupNudge')), findsNothing);
  });

  testWidgets('hiding balances does not flash the Home screen', (t) async {
    await t.runAsync(() async => TestLedger(db).expense(await cashId(), 5000));
    await start(t);
    await waitFor(t, find.byKey(const Key('backupNudge')));
    for (var i = 0; i < 2; i++) {
      await t.tap(find.byKey(const Key('hideBalance')));
      // The very next frame: nothing may disappear and pop back in.
      await t.pump();
      expect(find.byKey(const Key('backupNudge')), findsOneWidget);
      await t.pump(const Duration(milliseconds: 16));
      expect(find.byKey(const Key('backupNudge')), findsOneWidget);
    }
  });

  testWidgets('an encrypted backup asks for a passphrase', (t) async {
    await start(t);
    await openMore(t, 'backupTile');
    await t.tap(find.byKey(const Key('encryptSwitch')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('backupToFile')));
    await t.pumpAndSettle();

    await t.enterText(find.byKey(const Key('sheetTextField')), 'short');
    await t.pump();
    final done = find.byKey(const Key('sheetDone'));
    expect(t.widget<FilledButton>(done).onPressed, isNull, reason: '< 6');
    await t.enterText(find.byKey(const Key('sheetTextField')), 'chai-paratha');
    await t.pump();
    await t.tap(done);
    await waitFor(t, find.text('Backup saved'));
    final manifest = BackupArchive.manifestOf(files.saved.single.bytes);
    expect(manifest.encrypted, isTrue);
  });

  testWidgets('restore from a file: preview, replace, verified result', (
    t,
  ) async {
    // A backup from "another phone" with one account and one entry.
    final other = testDb();
    final otherBackups = BackupService(other, testReceiptStore())
      ..appVersion = (() async => '1.0.0+1')
      ..iterations = 1000;
    final bytes = (await t.runAsync(() async {
      final ledger = TestLedger(other);
      final bank = await ledger.account('Meezan Bank', opening: 1000000);
      await ledger.expense(bank, 25000);
      final file = await otherBackups.create();
      await other.close();
      return file.bytes;
    }))!;

    await start(t);
    await openMore(t, 'backupTile');
    files.next = (name: 'old-phone.kharcha', bytes: bytes);
    await reveal(t, find.byKey(const Key('restoreFromFile')));
    await t.tap(find.byKey(const Key('restoreFromFile')));
    await waitFor(t, find.byKey(const Key('restoreConfirm')));
    expect(find.text('Replace my data'), findsOneWidget);
    expect(find.text('v1.0.0+1'), findsOneWidget);

    await t.tap(find.byKey(const Key('restoreConfirm')));
    await waitFor(t, find.byKey(const Key('restoreDone')));
    expect(find.textContaining('integrity check'), findsOneWidget);

    final balances = (await t.runAsync(() => db.accountsDao.balances()))!;
    expect(
      {for (final b in balances) b.account.name: b.balanceMinor},
      {'Cash': 0, 'Meezan Bank': 975000},
    );
    // The safety copy of the old data was kept on this phone.
    final kept = (await t.runAsync(
      () => getIt<BackupService>().deviceBackups(),
    ))!;
    expect(kept, hasLength(1));
  });

  testWidgets('a file that is not a backup is refused with a reason', (
    t,
  ) async {
    await start(t);
    await openMore(t, 'backupTile');
    files.next = (name: 'notes.txt', bytes: 'hello'.codeUnits);
    await reveal(t, find.byKey(const Key('restoreFromFile')));
    await t.tap(find.byKey(const Key('restoreFromFile')));
    await waitFor(t, find.byKey(const Key('restoreFailed')));
    expect(find.text("This isn't a Kharcha backup file."), findsOneWidget);
  });

  testWidgets('Hysab Kytab import: preview, roles, report', (t) async {
    await start(t);
    await openMore(t, 'importTile');
    expect(find.byType(ImportScreen), findsOneWidget);
    files.next = (
      name: 'Hysab Kytab_ExportAll.xls',
      bytes: File('test/fixtures/import/hk_sample.xls').readAsBytesSync(),
    );
    await t.tap(find.byKey(const Key('importChoose')));
    await waitFor(t, find.byKey(const Key('importConfirm')));
    expect(find.text('11 new entries'), findsOneWidget);
    expect(find.text('2 rows need a look'), findsOneWidget);

    // Sami is suggested as a person; make Sami an account instead.
    await reveal(t, find.byKey(const Key('role-Sami')));
    await t.tap(
      find.descendant(
        of: find.byKey(const Key('role-Sami')),
        matching: find.text('Account'),
      ),
    );
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('importConfirm')));
    await waitFor(t, find.byKey(const Key('importDone')));
    final names = (await t.runAsync(
      () => db.accountsDao.balances(),
    ))!.map((b) => b.account.name).toSet();
    expect(names, {'Cash', 'Meezan Bank', 'Nayapay', 'Sami'});
    final people = (await t.runAsync(() => db.peopleDao.balances()))!;
    expect(people.map((p) => p.person.name), ['Mudassir Bhai']);
  });

  testWidgets('a generic CSV goes through the column mapper', (t) async {
    await start(t);
    await openMore(t, 'importTile');
    files.next = (
      name: 'bank.csv',
      bytes:
          'Date,Description,Amount\n2026-09-01,Groceries,-1250.50\n'
                  '2026-09-02,Refund,300\n'
              .codeUnits,
    );
    await t.tap(find.byKey(const Key('importChoose')));
    await waitFor(t, find.byKey(const Key('mappingContinue')));
    expect(find.text('Match the columns'), findsOneWidget);
    await t.tap(find.byKey(const Key('mappingContinue')));
    await waitFor(t, find.byKey(const Key('importConfirm')));
    expect(find.text('2 new entries'), findsOneWidget);
    await t.tap(find.byKey(const Key('importConfirm')));
    await waitFor(t, find.byKey(const Key('importDone')));
    final cash = (await t.runAsync(() => db.accountsDao.balances()))!.single;
    expect(cash.balanceMinor, -125050 + 30000);
  });
}

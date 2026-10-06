import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/features/accounts/domain/account_type.dart';
import 'package:khaata_digital/features/import_export/data/csv_mapper.dart';
import 'package:khaata_digital/features/import_export/data/export_service.dart';
import 'package:khaata_digital/features/import_export/data/import_service.dart';
import 'package:khaata_digital/features/import_export/data/spreadsheet_codec.dart';
import 'package:khaata_digital/features/import_export/domain/exchange_record.dart';
import 'package:khaata_digital/features/import_export/domain/exporter.dart';
import 'package:khaata_digital/features/import_export/domain/import_plan.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';

import '../../helpers/test_db.dart';
import '../../helpers/test_repos.dart';

List<int> fixture(String name) =>
    File('test/fixtures/import/$name').readAsBytesSync();

/// Account name → balance in minor units.
Future<Map<String, int>> accountBalances(AppDatabase db) async => {
  for (final b in await db.accountsDao.balances())
    b.account.name: b.balanceMinor,
};

/// Person name → udhaar per currency.
Future<Map<String, Map<String, int>>> peopleBalances(AppDatabase db) async => {
  for (final p in await db.peopleDao.balances()) p.person.name: p.byCurrency,
};

Future<int> entryCount(AppDatabase db) async =>
    (await db
            .customSelect('SELECT COUNT(*) AS n FROM transactions')
            .getSingle())
        .read<int>('n');

void main() {
  late AppDatabase db;
  late ImportService importer;

  setUp(() {
    db = testDb();
    importer = ImportService(db);
  });
  tearDown(() => db.close());

  Future<ImportDraft> draft(List<int> bytes) async =>
      importer.draftFile(await importer.decode(bytes), currency: Currency.pkr);

  group('Hysab Kytab sample (synthetic, same layout as the real export)', () {
    test('preview: counts, warnings, dates and suggested roles', () async {
      final d = await draft(fixture('hk_sample.xls'));
      expect(d.format, ImportFormat.hysabKytab);
      expect(d.records, hasLength(11));
      expect(d.duplicates, isEmpty);
      expect(d.warnings.map((w) => (w.row, w.kind)), [
        (17, ExchangeWarningKind.unreadableRow),
        (11, ExchangeWarningKind.unpairedTransfer),
      ]);
      expect(d.first, DateTime(2026, 9, 1, 12));
      expect(d.last, DateTime(2026, 9, 10, 12));
      final roles = {for (final n in d.names) n.name: n.role};
      expect(roles, {
        'Cash': ImportRole.account,
        'Meezan Bank': ImportRole.account,
        'Nayapay': ImportRole.account, // a wallet name, though transfer-only
        'Mudassir Bhai': ImportRole.person,
        'Sami': ImportRole.person,
      });
      final cash = d.names.firstWhere((n) => n.name == 'Cash');
      expect(cash.existing, isTrue, reason: 'the seeded Cash account');
      expect(cash.canBePerson, isFalse, reason: 'it has its own expenses');
    });

    test('imports with correct balances, types, dates and labels', () async {
      final report = await importer.run(await draft(fixture('hk_sample.xls')));
      expect(report.imported, 11);
      expect(report.duplicates, 0);
      expect(report.skipped, isEmpty);
      expect(report.accountsCreated, 2, reason: 'Meezan Bank, Nayapay');
      expect(report.peopleCreated, 2);
      expect(report.categoriesCreated, 0, reason: 'all are seeded names');

      // Every figure matches the file's own ACCOUNT sheet closing balance.
      expect(await accountBalances(db), {
        'Cash': 1215000,
        'Meezan Bank': 11423000,
        'Nayapay': 100000,
      });
      expect(await peopleBalances(db), {
        'Mudassir Bhai': {'PKR': 600000},
        'Sami': <String, int>{}, // settled: opening 3,000 then paid back
      });

      final accounts = {
        for (final b in await db.accountsDao.balances()) b.account.name: b,
      };
      expect(accounts['Meezan Bank']!.account.type, AccountType.bank);
      expect(accounts['Nayapay']!.account.type, AccountType.wallet);
      expect(accounts['Cash']!.account.openingBalanceMinor, 50000);

      final rows = await db.select(db.transactions).get();
      final lunch = rows.singleWhere((r) => r.note == 'Lunch');
      expect(lunch.occurredAt, DateTime(2026, 9, 1, 12).toUtc());
      final lunchTags = (await db.labelsDao.tagNamesFor([lunch.id]))[lunch.id];
      expect(lunchTags, unorderedEquals(['Office', 'Lunch']));

      final hotel = rows.singleWhere((r) => r.note.startsWith('Hotel'));
      expect(
        hotel.note,
        'Hotel · Travel: 100.0 \$, @ 282.5, Dubai, 06/09/2026',
      );
      expect(hotel.place, 'Mall of the Emirates');
      expect((await db.labelsDao.eventNamesFor([hotel.id]))[hotel.id], [
        'Dubai Trip',
      ]);

      expect(rows.where((r) => r.note == 'Chai'), hasLength(2));
      expect(rows.where((r) => r.note == 'چائے'), hasLength(1));
    });

    test('re-importing the same file creates 0 duplicates', () async {
      await importer.run(await draft(fixture('hk_sample.xls')));
      final count = await entryCount(db);
      final balances = await accountBalances(db);

      final again = await draft(fixture('hk_sample.xls'));
      expect(again.newCount, 0);
      expect(again.duplicates, hasLength(11));
      final report = await importer.run(again);
      expect(report.imported, 0);
      expect(report.duplicates, 11);
      expect(await entryCount(db), count);
      expect(await accountBalances(db), balances);
    });

    test('a name marked as an account keeps its transfers', () async {
      final d = await draft(fixture('hk_sample.xls'));
      await importer.run(d.withRoles({'Sami': ImportRole.account}));
      final balances = await accountBalances(db);
      expect(balances['Sami'], 0, reason: 'opening 3000 − 3000 sent to Cash');
      expect((await peopleBalances(db)).keys, ['Mudassir Bhai']);
    });

    test('a role cannot make an account with expenses into a person', () {
      return draft(fixture('hk_sample.xls')).then((d) {
        final forced = d.withRoles({'Cash': ImportRole.person});
        expect(
          forced.names.firstWhere((n) => n.name == 'Cash').role,
          ImportRole.account,
        );
      });
    });
  });

  test(
    'Kharcha export → fresh install import reproduces every balance',
    () async {
      final source = TestRepos();
      addTearDown(source.close);
      final cash = await source.cashId();
      final bank = await source.ledger.account('Meezan Bank', opening: 1066100);
      final usd = await source.ledger.account(
        'Payoneer',
        currency: 'USD',
        opening: 50000,
      );
      final ali = await source.people.create('Mudassir Bhai');
      await source.ledger.expense(bank, 252050);
      await source.ledger.transfer(bank, cash, 500000);
      await source.ledger.transfer(
        usd,
        bank,
        10000,
        currency: 'USD',
        toAmount: 2825000,
        rateMicros: 282500000,
      );
      await source.ledger.expense(cash, 450000, personId: ali);
      await source.ledger.income(cash, 200000, personId: ali);
      await source.ledger.adjustment(cash, -5000);

      final file = await ExportService(
        source.transactions,
        source.accounts,
      ).export(const EntryQuery(), ExportFormat.xlsx);
      final d = await draft(file.bytes);
      expect(d.warnings, isEmpty);
      final report = await importer.run(d);
      expect(report.imported, 6);

      expect(await accountBalances(db), await accountBalances(source.db));
      expect(await peopleBalances(db), await peopleBalances(source.db));

      // Same ids, so importing it again (or into the source) adds nothing.
      expect((await draft(file.bytes)).newCount, 0);
      final intoSource = ImportService(source.db);
      final back = await intoSource.draftFile(
        SpreadsheetCodec.decode(file.bytes),
        currency: Currency.pkr,
      );
      expect(back.newCount, 0);
    },
  );

  group('generic CSV with a column mapping', () {
    final csv = SpreadsheetCodec.encodeCsv([
      ['Date', 'Details', 'Amount', 'Category', 'Wallet'],
      ['2026-09-01', 'Groceries', '-1,250.50', 'Groceries', ''],
      ['2026-09-02', 'Refund', '300', 'Other income', 'JazzCash'],
      ['31/02/2026', 'Impossible date', '-1', '', ''],
    ]);

    test('guesses the mapping from the header', () {
      final rows = SpreadsheetCodec.decode(csv).single.rows;
      expect(ImportService.isHysabKytab(rows), isFalse);
      expect(
        CsvMapper.guess(rows.first),
        const CsvMapping(date: 0, amount: 2, account: 4, category: 3, note: 1),
      );
    });

    test('imports signed amounts into the default account', () async {
      final rows = SpreadsheetCodec.decode(csv).single.rows;
      final mapping = CsvMapper.guess(
        rows.first,
      )!.copyWith(defaultAccount: 'Cash');
      final d = await importer.draftMapped(
        rows,
        mapping,
        currency: Currency.pkr,
      );
      expect(d.records, hasLength(2));
      expect(d.warnings.single.row, 4);
      final report = await importer.run(d);
      expect(report.imported, 2);
      expect(report.categoriesCreated, 1, reason: '"Other income" is new');
      expect(await accountBalances(db), {'Cash': -125050, 'JazzCash': 30000});

      final again = await importer.draftMapped(
        rows,
        mapping,
        currency: Currency.pkr,
      );
      expect(again.newCount, 0);
    });
  });

  test('10,000 rows import well under 2 minutes (M5 acceptance)', () async {
    final rows = <List<String>>[
      [
        'Voucher Type',
        'Voucher Date',
        'Voucher Amount',
        'Description',
        'Category Name',
        'Account Name',
        'Tags',
      ],
      for (var i = 0; i < 10000; i++)
        switch (i % 4) {
          0 => [
            'Income',
            _day(i),
            '${1000 + i}.0',
            'Pay $i',
            'Salary',
            'Meezan Bank',
            '',
          ],
          1 => [
            'Transfer',
            _day(i),
            '${200 + i}.0',
            '',
            'No Category',
            'Cash',
            '',
          ],
          2 => [
            'Transfer',
            _day(i),
            '-${200 + i - 1}.0',
            '',
            'No Category',
            'Meezan Bank',
            '',
          ],
          _ => [
            'Expense',
            _day(i),
            '-${50 + i}.0',
            'Item $i',
            'Food & Drink',
            'Cash',
            'bulk',
          ],
        },
    ];
    // Transfer rows pair up by day; keep each pair on one day.
    final watch = Stopwatch()..start();
    final d = await importer.draftFile([
      (name: 'ACTIVITIES', rows: rows),
    ], currency: Currency.pkr);
    final report = await importer.run(d);
    watch.stop();
    expect(report.imported, 7500);
    expect(d.warnings, isEmpty);
    expect(watch.elapsed, lessThan(const Duration(minutes: 2)));
    // ignore: avoid_print
    print('10k rows imported in ${watch.elapsedMilliseconds} ms');
  });

  group('real Hysab Kytab export (local only, never committed)', () {
    final real = File('specs/Hysab Kytab_ExportAll 2026-10-06 18-12-26.xls');

    test(
      'every account and person matches the file\'s closing balance',
      () async {
        final sheets = SpreadsheetCodec.decode(real.readAsBytesSync());
        final d = await importer.draftFile(sheets, currency: Currency.pkr);
        final report = await importer.run(d);
        expect(report.imported, d.records.length - report.skipped.length);

        final roles = {for (final n in d.names) n.name: n.role};
        final accounts = await accountBalances(db);
        final people = await peopleBalances(db);
        final closing = SpreadsheetCodec.named(sheets, 'ACCOUNT')!.rows;
        for (final row in closing.skip(1)) {
          final name = row[0];
          final expected = (double.parse(row[3]) * 100).round();
          final actual = roles[name] == ImportRole.person
              ? (people[name]?['PKR'] ?? 0)
              : accounts[name];
          expect(actual, expected, reason: '$name (${roles[name]})');
        }
        // ignore: avoid_print
        print(
          'imported ${report.imported}, skipped ${report.skipped.length}, '
          'warnings ${report.warnings.length}, '
          'people ${report.peopleCreated}, accounts ${report.accountsCreated}',
        );
      },
      skip: real.existsSync() ? false : 'personal file not present',
    );
  });
}

String _day(int i) {
  final d = DateTime(2020).add(Duration(days: i ~/ 4));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

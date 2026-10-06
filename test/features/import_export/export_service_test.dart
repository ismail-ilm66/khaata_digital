import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/import_export/data/export_service.dart';
import 'package:khaata_digital/features/import_export/data/hk_sheet.dart';
import 'package:khaata_digital/features/import_export/data/spreadsheet_codec.dart';
import 'package:khaata_digital/features/import_export/domain/exporter.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

import '../../helpers/test_repos.dart';

void main() {
  late TestRepos r;
  late ExportService exporter;

  setUp(() async {
    r = TestRepos();
    exporter = ExportService(r.transactions, r.accounts)
      ..now = () => DateTime(2026, 10, 6);
    final cash = await r.cashId();
    final bank = await r.ledger.account('Meezan Bank', opening: 1066100);
    final usd = await r.ledger.account(
      'Payoneer',
      currency: 'USD',
      opening: 50000,
    );
    final food = await r.categoryId('Food & Drink');
    final salary = await r.categoryId('Salary');
    final ali = await r.people.create('Mudassir Bhai');
    Future<void> save(EntryDraft d) => r.transactions.save(d);
    DateTime at(int day, [int h = 12, int m = 0]) =>
        DateTime(2026, 9, day, h, m).toUtc();
    await save(
      EntryDraft(
        type: TransactionType.expense,
        amount: Money.parse('2520.50', Currency.pkr)!,
        accountId: bank,
        categoryId: food,
        occurredAt: at(25, 13, 45),
        note: 'Lunch, "team"',
        tags: const ['office'],
        events: const ['Eid'],
      ),
    );
    await save(
      EntryDraft(
        type: TransactionType.income,
        amount: Money.major(150000, Currency.pkr),
        accountId: bank,
        categoryId: salary,
        occurredAt: at(25, 9),
      ),
    );
    await save(
      EntryDraft(
        type: TransactionType.transfer,
        amount: Money.major(5000, Currency.pkr),
        accountId: bank,
        toAccountId: cash,
        occurredAt: at(26),
      ),
    );
    await save(
      EntryDraft(
        type: TransactionType.transfer,
        amount: Money.major(100, Currency.usd),
        accountId: usd,
        toAccountId: bank,
        toAmount: Money.major(28250, Currency.pkr),
        fxRateMicros: 282500000,
        occurredAt: at(27),
      ),
    );
    await save(
      EntryDraft(
        type: TransactionType.expense,
        amount: Money.major(4500, Currency.pkr),
        accountId: cash,
        personId: ali,
        occurredAt: at(28),
        note: 'Bike',
      ),
    );
    await save(
      EntryDraft(
        type: TransactionType.income,
        amount: Money.major(2000, Currency.pkr),
        accountId: cash,
        personId: ali,
        occurredAt: at(29),
      ),
    );
    await r.ledger.adjustment(cash, -5000);
  });
  tearDown(() => r.close());

  Future<List<Object>> expected([
    EntryQuery q = const EntryQuery(limit: 1000),
  ]) async => (await r.transactions.watch(q).first).items.reversed
      .map(recordOf)
      .toList();

  for (final format in ExportFormat.values) {
    test(
      'full book ${format.name} re-reads with zero diff (M4 acceptance)',
      () async {
        final file = await exporter.export(const EntryQuery(), format);
        final rows = SpreadsheetCodec.activities(
          file.bytes,
          csv: format == ExportFormat.csv,
        );
        final back = HkSheet.read(rows);
        expect(back.warnings, isEmpty);
        expect(back.records, await expected());
        expect(back.records, hasLength(7));
      },
    );
  }

  test('a filtered view exports only what is shown', () async {
    const q = EntryQuery(types: {TransactionType.income});
    final file = await exporter.export(
      q,
      ExportFormat.csv,
      label: 'Income · Sep',
    );
    final back = HkSheet.read(
      SpreadsheetCodec.activities(file.bytes, csv: true),
    );
    expect(back.records, await expected(q.copyWith(limit: 1000)));
    expect(back.records.every((x) => x.type == TransactionType.income), isTrue);
    expect(file.name, 'Kharcha_Income__Sep_2026-10-06.csv');
  });

  test('xlsx carries Hysab Kytab ACCOUNT and CATEGORY sheets', () async {
    final file = await exporter.export(const EntryQuery(), ExportFormat.xlsx);
    final sheets = {
      for (final s in SpreadsheetCodec.decodeXlsx(file.bytes)) s.name: s.rows,
    };
    expect(sheets.keys, containsAll(['ACTIVITIES', 'ACCOUNT', 'CATEGORY']));
    final meezan = sheets['ACCOUNT']!.firstWhere(
      (row) => row.first == 'Meezan Bank',
    );
    // 10,661 + 150,000 − 2,520.50 − 5,000 + 28,250
    expect(meezan, [
      'Meezan Bank',
      '10661.00',
      '170729.50',
      '181390.50',
      'PKR',
    ]);
    final food = sheets['CATEGORY']!.firstWhere(
      (row) => row.first == 'Food & Drink',
    );
    expect(food, ['Food & Drink', '2520.50', 'Expense', 'PKR']);
    expect(
      sheets['CATEGORY']!.map((row) => row.first),
      isNot(contains('Mudassir Bhai')),
    );
  });
}

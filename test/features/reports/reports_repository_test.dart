import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/dates/report_period.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/reports/data/reports_repository_impl.dart';
import 'package:khaata_digital/features/reports/domain/report.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

import '../../helpers/test_repos.dart';

const pkr = Currency.pkr;
const salary25 = BudgetCycle(25);

/// M4 acceptance: report numbers reconcile with DAO sums to the paisa.
void main() {
  late TestRepos r;
  late ReportsRepositoryImpl repo;
  late List<String> accounts;
  late List<String> categories;
  late String person;

  setUp(() async {
    r = TestRepos();
    repo = ReportsRepositoryImpl(r.db);
    accounts = [
      await r.cashId(),
      await r.ledger.account('Meezan Bank', opening: 1066100),
      await r.ledger.account(
        'Savings',
        opening: 900000,
        excludeFromTotal: true,
      ),
    ];
    categories = [for (final c in await r.db.categoriesDao.active()) c.id];
    person = await r.people.create('Ali');

    // 2,000 entries over ~7 months, every type, udhaar and transfers mixed in.
    final rnd = Random(4);
    final start = DateTime(2026, 4, 1);
    for (var i = 0; i < 2000; i++) {
      final at = start.add(Duration(hours: rnd.nextInt(24 * 210))).toUtc();
      final amount = Money(1 + rnd.nextInt(2000000), pkr);
      final acc = accounts[rnd.nextInt(accounts.length)];
      final roll = rnd.nextInt(10);
      final draft = switch (roll) {
        < 5 => EntryDraft(
          type: TransactionType.expense,
          amount: amount,
          accountId: acc,
          categoryId: categories[rnd.nextInt(categories.length)],
          occurredAt: at,
        ),
        < 7 => EntryDraft(
          type: TransactionType.income,
          amount: amount,
          accountId: acc,
          categoryId: rnd.nextBool() ? categories[rnd.nextInt(16)] : null,
          occurredAt: at,
        ),
        < 8 => EntryDraft(
          type: TransactionType.expense,
          amount: amount,
          accountId: acc,
          personId: person,
          occurredAt: at,
        ),
        _ => EntryDraft(
          type: TransactionType.transfer,
          amount: amount,
          accountId: acc,
          toAccountId: accounts[(accounts.indexOf(acc) + 1) % accounts.length],
          occurredAt: at,
        ),
      };
      await r.transactions.save(draft);
    }
  });
  tearDown(() => r.close());

  Future<ReportData> report(
    ReportPeriod p, {
    EntryQuery filters = const EntryQuery(),
  }) => repo
      .watch(
        ReportQuery(
          period: p,
          cycle: salary25,
          currency: pkr,
          filters: filters,
        ),
      )
      .first;

  /// Independent tally straight from the entries, udhaar excluded.
  Future<(int, int)> tally(EntryQuery q) async {
    final items =
        (await r.transactions.watch(q.copyWith(limit: 1 << 20)).first).items;
    var income = 0, expense = 0;
    for (final v in items) {
      if (v.entry.personId != null) continue;
      if (v.entry.type == TransactionType.income) {
        income += v.entry.amount.minor;
      }
      if (v.entry.type == TransactionType.expense) {
        expense += v.entry.amount.minor;
      }
    }
    return (income, expense);
  }

  final periods = {
    'day': ReportPeriod.day(DateTime(2026, 6, 15)),
    'week': ReportPeriod.week(DateTime(2026, 6, 15)),
    'month (25th start)': ReportPeriod.month(DateTime(2026, 6, 15)),
    'year': ReportPeriod.year(DateTime(2026, 6, 15)),
    'custom 1–15 Jul': ReportPeriod.custom(
      DateTime(2026, 7, 1),
      DateTime(2026, 7, 15),
    ),
    'all time': const ReportPeriod.all(),
  };

  periods.forEach((name, period) {
    test('$name: totals, slices and bars reconcile to the paisa', () async {
      final data = await report(period);
      final range = period.range(salary25);

      // Against the DAO's own sum…
      if (range != null) {
        final dao = await r.transactions.watchTotals(range).first;
        expect(data.income, dao.incomeIn(pkr));
        expect(data.expense, dao.expenseIn(pkr));
      }
      // …and against an independent tally of the entries.
      final (income, expense) = await tally(EntryQuery(range: range));
      expect(data.income.minor, income);
      expect(data.expense.minor, expense);

      expect(data.spending.fold(0, (s, x) => s + x.total.minor), expense);
      expect(data.earning.fold(0, (s, x) => s + x.total.minor), income);
      expect(data.flow.fold(0, (s, x) => s + x.income.minor), income);
      expect(data.flow.fold(0, (s, x) => s + x.expense.minor), expense);
    });
  });

  test('all-time balance trend ends on current net worth', () async {
    final data = await report(const ReportPeriod.all());
    final overview = await r.accounts.watchOverview().first;
    expect(data.balance.last.balance, overview.netWorth[pkr]);
  });

  test('filters reconcile too (account + type)', () async {
    final filters = EntryQuery(
      accountIds: {accounts[1]},
      types: const {TransactionType.expense},
    );
    final period = ReportPeriod.year(DateTime(2026, 6, 15));
    final data = await report(period, filters: filters);
    final (_, expense) = await tally(
      EntryQuery(
        accountIds: filters.accountIds,
        types: filters.types,
        range: period.range(salary25),
      ),
    );
    expect(data.expense.minor, expense);
    expect(data.income.isZero, isTrue);
  });

  test('slices are largest first; chart buckets match the period', () async {
    final data = await report(ReportPeriod.year(DateTime(2025, 6, 15)));
    for (var i = 1; i < data.spending.length; i++) {
      expect(data.spending[i - 1].total >= data.spending[i].total, isTrue);
    }
    expect(data.bucketSize, BucketSize.cycle);
    expect(data.flow, hasLength(12));
  });

  test('a period in progress is charted up to today only', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cycle = salary25.rangeFor(now);

    // The shared data has entries dated later this cycle: the chart reaches
    // them, but never runs past the cycle.
    final data = await report(ReportPeriod.month(now));
    expect(data.span!.lastDay.isBefore(today), isFalse);
    expect(data.span!.end.isAfter(cycle.end), isFalse);
    expect(data.flow.last.bucket.end, data.span!.end);

    // A book with nothing in the future stops exactly at today.
    final fresh = TestRepos();
    addTearDown(fresh.close);
    await fresh.ledger.expense(await fresh.cashId(), 5000, at: now.toUtc());
    final mine = await ReportsRepositoryImpl(fresh.db)
        .watch(
          ReportQuery(
            period: ReportPeriod.month(now),
            cycle: salary25,
            currency: pkr,
          ),
        )
        .first;
    expect(mine.span!.lastDay, today);
    expect(mine.flow.last.bucket.start, today);
    expect(mine.balance.last.bucket.start, today);
  });
}

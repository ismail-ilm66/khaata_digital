import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/dates/date_range.dart';
import 'package:khaata_digital/core/dates/report_period.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/people/data/people_repository_impl.dart';
import 'package:khaata_digital/features/reports/data/reports_repository_impl.dart';
import 'package:khaata_digital/features/reports/domain/report.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';

import '../../helpers/test_repos.dart';

Money rs(int r) => Money.major(r, Currency.pkr);

/// Bad debts: a write-off closes what a person owes (or what I owe them)
/// without touching any account, income or spending.
void main() {
  late TestRepos r;
  late PeopleRepositoryImpl repo;
  late String cash;
  late String ali;

  DateTime sep(int day) => DateTime(2026, 9, day, 12).toUtc();
  final september = DateRange(DateTime(2026, 9), DateTime(2026, 10));

  setUp(() async {
    r = TestRepos();
    repo = PeopleRepositoryImpl(r.db, r.transactions);
    cash = await r.cashId();
    ali = await repo.create('Ali');
    await r.ledger.expense(cash, 500000, personId: ali, at: sep(1));
  });
  tearDown(() => r.close());

  Future<Money?> balance(String person) async =>
      (await repo.watchOverview().first).people
          .firstWhere((p) => p.person.id == person)
          .balance[Currency.pkr];

  test('writing off closes the balance and touches no account', () async {
    final before = await r.ledger.balanceOf(cash);
    final totals = await r.transactions.watchTotals(september).first;

    await repo.writeOff(ali, rs(5000), occurredAt: sep(10), note: 'Moved');

    final o = await repo.watchOverview().first;
    expect(o.people.single.isSettled, isTrue);
    expect(o.receivable, isEmpty);
    expect(await r.ledger.balanceOf(cash), before);
    expect(await r.transactions.watchTotals(september).first, totals);
  });

  test('part of it, then the rest is still owed', () async {
    await repo.writeOff(ali, rs(2000), occurredAt: sep(10));
    expect(await balance(ali), rs(3000));
  });

  test('forgiven: what I owe them goes, also with no account', () async {
    final sara = await repo.create('Sara');
    await r.ledger.income(cash, 120000, personId: sara, at: sep(2));
    final before = await r.ledger.balanceOf(cash);

    await repo.writeOff(sara, -rs(1200), occurredAt: sep(10));

    final o = await repo.watchOverview().first;
    expect(o.payable, isEmpty);
    expect(await r.ledger.balanceOf(cash), before);
    final ledger = await repo.watchLedger(sara).first;
    expect(ledger.first.writeOff!.isForgiven, isTrue);
    expect(ledger.first.runningBalance, rs(0));
  });

  test('the ledger merges write-offs in date order with the balance after '
      'each line', () async {
    await r.ledger.income(cash, 100000, personId: ali, at: sep(5));
    final id = await repo.writeOff(ali, rs(1500), occurredAt: sep(3));

    final ledger = await repo.watchLedger(ali).first;
    expect(ledger.map((l) => l.writeOff?.id), [null, id, null]);
    expect(ledger.map((l) => l.runningBalance), [rs(2500), rs(3500), rs(5000)]);
    expect(ledger.fold(rs(0), (s, l) => s + l.delta), await balance(ali));
  });

  test('edit, delete and undo', () async {
    final id = await repo.writeOff(ali, rs(5000), occurredAt: sep(10));
    await repo.editWriteOff(id, rs(4000), occurredAt: sep(11), note: 'Half');
    expect(await balance(ali), rs(1000));
    final w = (await repo.watchLedger(ali).first).first.writeOff!;
    expect((w.amount, w.note, w.occurredAt), (rs(4000), 'Half', sep(11)));

    await repo.removeWriteOff(id);
    expect(await balance(ali), rs(5000));
    expect((await repo.watchLedger(ali).first).length, 1);

    await repo.restoreWriteOff(id);
    expect(await balance(ali), rs(1000));
  });

  group('Reports', () {
    late ReportsRepositoryImpl reports;
    final query = ReportQuery(
      period: ReportPeriod.month(DateTime(2026, 9, 15)),
      cycle: const BudgetCycle.calendar(),
      currency: Currency.pkr,
    );

    setUp(() => reports = ReportsRepositoryImpl(r.db));

    test('lists the period\'s write-offs apart from spending', () async {
      final before = await reports.watch(query).first;
      await repo.writeOff(ali, rs(5000), occurredAt: sep(10));
      // Another month's isn't in this one.
      await repo.writeOff(
        ali,
        rs(1),
        occurredAt: sep(1).add(const Duration(days: 40)),
      );

      final data = await reports.watch(query).first;
      expect(data.writeOffs.map((w) => (w.personName, w.amount)), [
        ('Ali', rs(5000)),
      ]);
      expect((data.expense, data.income), (before.expense, before.income));
    });

    test('a filter leaves them out (no account, category or tag)', () async {
      await repo.writeOff(ali, rs(5000), occurredAt: sep(10));
      final filtered = query.copyWith(filters: EntryQuery(accountIds: {cash}));
      expect((await reports.watch(filtered).first).writeOffs, isEmpty);
    });
  });
}

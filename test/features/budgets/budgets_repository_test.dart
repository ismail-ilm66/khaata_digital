import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/budgets/data/budgets_repository_impl.dart';
import 'package:khaata_digital/features/budgets/domain/budget.dart';

import '../../helpers/test_repos.dart';

Money rs(int r) => Money.major(r, Currency.pkr);

void main() {
  late TestRepos r;
  late BudgetsRepositoryImpl repo;
  late String cash;
  late String food;
  late String fuel;

  const salary25 = BudgetCycle(25);
  const sep = CycleId(2026, 9); // 25 Sep – 24 Oct

  setUp(() async {
    r = TestRepos();
    repo = BudgetsRepositoryImpl(r.db);
    cash = await r.cashId();
    food = await r.categoryId('Food & Drink');
    fuel = await r.categoryId('Fuel & Maintenance');
  });
  tearDown(() => r.close());

  Future<void> spend(
    int rupees,
    String? category,
    DateTime local, {
    String? person,
  }) => r.ledger.expense(
    cash,
    rupees * 100,
    categoryId: category,
    at: local.toUtc(),
    personId: person,
  );

  Future<BudgetOverview> overview() =>
      repo.watch(sep, salary25, Currency.pkr).first;

  test('progress respects a custom month start (M3 acceptance)', () async {
    await repo.set(sep, rs(10000), categoryId: food);
    await spend(3000, food, DateTime(2026, 9, 24, 23)); // before the cycle
    await spend(4000, food, DateTime(2026, 9, 25, 9)); // first day
    await spend(4500, food, DateTime(2026, 10, 24, 22)); // last day
    await spend(9999, food, DateTime(2026, 10, 25, 1)); // next cycle

    final line = (await overview()).lines.single;
    expect(line.spent, rs(8500));
    expect(line.left, rs(1500));
    expect(line.permille, 850);
    expect(line.status, BudgetStatus.nearLimit);
  });

  test('status: green under 80 %, amber 80–100 %, red over 100 %', () async {
    BudgetLine line(int spent) => BudgetLine(limit: rs(100), spent: rs(spent));
    expect(line(79).status, BudgetStatus.onTrack);
    expect(line(80).status, BudgetStatus.nearLimit);
    expect(line(100).status, BudgetStatus.nearLimit);
    expect(line(101).status, BudgetStatus.over);
  });

  test('overall budget counts all spending, budgeted or not', () async {
    await repo.set(sep, rs(50000));
    await repo.set(sep, rs(10000), categoryId: food);
    await spend(2000, food, DateTime(2026, 10, 1));
    await spend(3000, fuel, DateTime(2026, 10, 2));
    await spend(500, null, DateTime(2026, 10, 3));

    final o = await overview();
    expect(o.overall!.spent, rs(5500));
    expect(o.totalSpent, rs(5500));
    expect(o.lines.single.spent, rs(2000));
  });

  test('udhaar is not spending', () async {
    final ali = await r.db.peopleDao.create(name: 'Ali');
    await repo.set(sep, rs(10000));
    await spend(5000, null, DateTime(2026, 10, 1), person: ali);
    expect((await overview()).overall!.spent, rs(0));
  });

  test('lines are ordered fullest first', () async {
    await repo.set(sep, rs(10000), categoryId: food);
    await repo.set(sep, rs(1000), categoryId: fuel);
    await spend(500, food, DateTime(2026, 10, 1));
    await spend(900, fuel, DateTime(2026, 10, 1));
    expect((await overview()).lines.map((l) => l.category!.name), [
      'Fuel & Maintenance',
      'Food & Drink',
    ]);
  });

  test('copy from previous cycle', () async {
    await repo.set(sep.previous, rs(40000));
    await repo.set(sep.previous, rs(8000), categoryId: food);
    await repo.set(sep, rs(1), categoryId: food); // replaced by the copy

    expect(await repo.copyFromPrevious(sep), 2);
    final o = await overview();
    expect(o.overall!.limit, rs(40000));
    expect(o.lines.single.limit, rs(8000));
  });

  test('clear removes a budget', () async {
    await repo.set(sep, rs(100), categoryId: food);
    await repo.clear(sep, categoryId: food);
    expect((await overview()).isEmpty, isTrue);
  });

  test('updates live when spending changes', () async {
    await repo.set(sep, rs(1000));
    final stream = repo
        .watch(sep, salary25, Currency.pkr)
        .map((o) => o.overall!.spent);
    expect(stream, emitsInOrder([rs(0), rs(250)]));
    await Future<void>.delayed(Duration.zero);
    await spend(250, food, DateTime(2026, 10, 1));
  });
}

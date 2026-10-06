import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

import '../../helpers/test_repos.dart';

void main() {
  late TestRepos r;
  late BudgetCycleCubit cycle;
  late String cash;

  setUp(() async {
    r = TestRepos();
    cycle = BudgetCycleCubit(r.settings);
    cash = await r.cashId();
  });
  tearDown(() async {
    await cycle.close();
    await r.close();
  });

  Future<void> save(TransactionType type, int rupees, DateTime local) =>
      r.transactions.save(
        EntryDraft(
          type: type,
          amount: Money.major(rupees, Currency.pkr),
          accountId: cash,
          occurredAt: local.toUtc(),
        ),
      );

  test(
    'this-cycle totals follow the month-start setting (salary on the 25th)',
    () async {
      await save(
        TransactionType.income,
        150000,
        DateTime(2026, 9, 25, 10),
      ); // salary
      await save(TransactionType.expense, 2000, DateTime(2026, 10, 3, 12));
      await save(
        TransactionType.expense,
        999,
        DateTime(2026, 9, 24, 12),
      ); // previous cycle
      await cycle.set(const BudgetCycle(25));

      final home = r.homeCubit(cycle)..start(now: () => DateTime(2026, 10, 6));
      await pumpEventQueue();

      final s = home.state;
      expect(s.cycle, const CycleId(2026, 9));
      expect(
        s.totals!.incomeIn(Currency.pkr),
        Money.major(150000, Currency.pkr),
      );
      expect(
        s.totals!.expenseIn(Currency.pkr),
        Money.major(2000, Currency.pkr),
      );
      expect(s.recent!, hasLength(3));
      expect(
        s.overview!.netWorth[Currency.pkr],
        Money.major(150000 - 2000 - 999, Currency.pkr),
      );
      await home.close();
    },
  );

  test('changing the month start re-buckets live', () async {
    await save(TransactionType.expense, 500, DateTime(2026, 10, 2, 12));
    final home = r.homeCubit(cycle)..start(now: () => DateTime(2026, 10, 6));
    await pumpEventQueue();
    expect(
      home.state.totals!.expenseIn(Currency.pkr),
      Money.major(500, Currency.pkr),
    );

    await cycle.set(const BudgetCycle(5)); // cycle now starts 5 Oct
    await pumpEventQueue();
    expect(home.state.cycle, const CycleId(2026, 10));
    expect(
      home.state.totals!.expenseIn(Currency.pkr),
      const Money.zero(Currency.pkr),
    );
    await home.close();
  });
}

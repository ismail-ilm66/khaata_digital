import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/db/app_database.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../categories/data/categories_repository_impl.dart';
import '../domain/budget.dart';

@LazySingleton(as: BudgetsRepository)
class BudgetsRepositoryImpl implements BudgetsRepository {
  BudgetsRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<BudgetOverview> watch(
    CycleId cycle,
    BudgetCycle budgetCycle,
    Currency currency,
  ) {
    final range = budgetCycle.rangeOf(cycle);
    final spending = _db.transactionsDao
        .spendingByCategory(range.startMillis, range.endMillis, currency.code)
        .watch();
    final categories = _db.categoriesDao.watchActive();
    return _db.budgetsDao
        .watchCycle(cycle)
        .combineLatest(spending, (b, s) => (b, s))
        .combineLatest(categories, (bs, cats) {
          final (budgets, spent) = bs;
          final byCategory = {for (final r in spent) r.categoryId: r.total};
          final total = spent.fold<int>(0, (sum, r) => sum + r.total);
          final catById = {for (final c in cats) c.id: c.toDomain()};

          BudgetLine? overall;
          final lines = <BudgetLine>[];
          for (final b in budgets) {
            final limit = Money(b.amountMinor, currency);
            if (b.categoryId == null) {
              overall = BudgetLine(limit: limit, spent: Money(total, currency));
            } else if (catById[b.categoryId] case final cat?) {
              lines.add(
                BudgetLine(
                  category: cat,
                  limit: limit,
                  spent: Money(byCategory[b.categoryId] ?? 0, currency),
                ),
              );
            }
          }
          lines.sort((a, b) => b.permille.compareTo(a.permille));
          return BudgetOverview(
            cycle: cycle,
            currency: currency,
            overall: overall,
            lines: lines,
            totalSpent: Money(total, currency),
          );
        });
  }

  @override
  Future<void> set(CycleId cycle, Money limit, {String? categoryId}) =>
      _db.budgetsDao.setBudget(cycle, limit.minor, categoryId: categoryId);

  @override
  Future<void> clear(CycleId cycle, {String? categoryId}) =>
      _db.budgetsDao.clearBudget(cycle, categoryId: categoryId);

  @override
  Future<int> copyFromPrevious(CycleId cycle) {
    return _db.transaction(() async {
      final previous = await _db.budgetsDao.forCycle(cycle.previous);
      for (final b in previous) {
        await _db.budgetsDao.setBudget(
          cycle,
          b.amountMinor,
          categoryId: b.categoryId,
        );
      }
      return previous.length;
    });
  }
}

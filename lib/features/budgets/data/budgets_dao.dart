import 'package:drift/drift.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/tables.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.attachedDatabase);

  Expression<bool> _matches(
    $BudgetsTable b,
    CycleId cycle,
    String? categoryId,
  ) {
    final inCycle =
        b.cycleYear.equals(cycle.year) & b.cycleMonth.equals(cycle.month);
    return inCycle &
        (categoryId == null
            ? b.categoryId.isNull()
            : b.categoryId.equals(categoryId));
  }

  /// Sets the budget for [categoryId] (null = overall) in [cycle].
  Future<void> setBudget(CycleId cycle, int amountMinor, {String? categoryId}) {
    return transaction(() async {
      final updated =
          await (update(
            budgets,
          )..where((b) => _matches(b, cycle, categoryId))).write(
            BudgetsCompanion(
              amountMinor: Value(amountMinor),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
      if (updated == 0) {
        await into(budgets).insert(
          BudgetsCompanion.insert(
            categoryId: Value(categoryId),
            amountMinor: amountMinor,
            cycleYear: cycle.year,
            cycleMonth: cycle.month,
          ),
        );
      }
    });
  }

  Future<void> clearBudget(CycleId cycle, {String? categoryId}) =>
      (delete(budgets)..where((b) => _matches(b, cycle, categoryId))).go();

  Future<List<BudgetRow>> forCycle(CycleId cycle) => _cycle(cycle).get();

  Stream<List<BudgetRow>> watchCycle(CycleId cycle) => _cycle(cycle).watch();

  SimpleSelectStatement<$BudgetsTable, BudgetRow> _cycle(CycleId cycle) =>
      (select(budgets)..where(
        (b) =>
            b.cycleYear.equals(cycle.year) & b.cycleMonth.equals(cycle.month),
      ));
}

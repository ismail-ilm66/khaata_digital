import 'package:equatable/equatable.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../categories/domain/category.dart';

/// Green under 80 %, amber 80–100 %, red over 100 % (spec 3.2 #6).
enum BudgetStatus { onTrack, nearLimit, over }

/// One budget and what has been spent against it this cycle.
class BudgetLine extends Equatable {
  const BudgetLine({required this.limit, required this.spent, this.category});

  /// Null for the overall (whole-cycle) budget.
  final Category? category;
  final Money limit;
  final Money spent;

  bool get isOverall => category == null;
  Money get left => limit - spent;

  /// Spent as thousandths of the limit, unclamped (1250 = 25 % over).
  /// Integer, like all money maths; the UI scales it for drawing.
  int get permille => limit.isPositive ? spent.minor * 1000 ~/ limit.minor : 0;

  BudgetStatus get status => permille > 1000
      ? BudgetStatus.over
      : permille >= 800
      ? BudgetStatus.nearLimit
      : BudgetStatus.onTrack;

  @override
  List<Object?> get props => [category, limit, spent];
}

class BudgetOverview extends Equatable {
  const BudgetOverview({
    required this.cycle,
    required this.currency,
    required this.lines,
    required this.totalSpent,
    this.overall,
  });

  final CycleId cycle;
  final Currency currency;

  /// The whole-cycle budget, if set.
  final BudgetLine? overall;

  /// Per-category budgets, fullest (highest permille) first.
  final List<BudgetLine> lines;

  /// All spending in the cycle, budgeted or not.
  final Money totalSpent;

  bool get isEmpty => overall == null && lines.isEmpty;

  @override
  List<Object?> get props => [cycle, currency, overall, lines, totalSpent];
}

abstract interface class BudgetsRepository {
  /// Budgets for [cycle] with live spending, in [currency].
  Stream<BudgetOverview> watch(
    CycleId cycle,
    BudgetCycle budgetCycle,
    Currency currency,
  );

  /// [categoryId] null sets the overall budget.
  Future<void> set(CycleId cycle, Money limit, {String? categoryId});
  Future<void> clear(CycleId cycle, {String? categoryId});

  /// Copies the previous cycle's budgets into [cycle], replacing any with
  /// the same category. Returns how many were copied.
  Future<int> copyFromPrevious(CycleId cycle);
}

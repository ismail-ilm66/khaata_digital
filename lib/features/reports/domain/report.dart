import 'package:equatable/equatable.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/dates/date_range.dart';
import '../../../core/dates/report_period.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/entry_query.dart';

/// What to report on: a period, the same filters as the list, and the
/// currency to total in (no automatic FX in v1).
class ReportQuery extends Equatable {
  const ReportQuery({
    required this.period,
    required this.cycle,
    required this.currency,
    this.filters = const EntryQuery(),
  });

  final ReportPeriod period;
  final BudgetCycle cycle;
  final Currency currency;

  /// Types, accounts, categories and tags (search and paging ignored).
  final EntryQuery filters;

  ReportQuery copyWith({ReportPeriod? period, EntryQuery? filters}) =>
      ReportQuery(
        period: period ?? this.period,
        cycle: cycle,
        currency: currency,
        filters: filters ?? this.filters,
      );

  /// The same filters as a list query over this period (drill-downs).
  EntryQuery entriesQuery({Set<String>? categoryIds}) => EntryQuery(
    types: filters.types,
    accountIds: filters.accountIds,
    categoryIds: categoryIds ?? filters.categoryIds,
    tags: filters.tags,
    range: period.range(cycle),
  );

  @override
  List<Object?> get props => [period, cycle, currency, filters];
}

/// A category's share of income or spending. [category] null = none.
class CategorySlice extends Equatable {
  const CategorySlice(this.category, this.total);

  final Category? category;
  final Money total;

  @override
  List<Object?> get props => [category, total];
}

/// Income and expense within one chart bucket.
class FlowPoint extends Equatable {
  const FlowPoint(this.bucket, this.income, this.expense);

  final DateRange bucket;
  final Money income;
  final Money expense;

  @override
  List<Object?> get props => [bucket, income, expense];
}

/// Balance at the end of a bucket.
class BalancePoint extends Equatable {
  const BalancePoint(this.bucket, this.balance);

  final DateRange bucket;
  final Money balance;

  @override
  List<Object?> get props => [bucket, balance];
}

class ReportData extends Equatable {
  const ReportData({
    required this.span,
    required this.bucketSize,
    required this.income,
    required this.expense,
    required this.spending,
    required this.earning,
    required this.flow,
    required this.balance,
  });

  /// The period's range, or for all time the extent of the data.
  final DateRange? span;
  final BucketSize bucketSize;
  final Money income;
  final Money expense;
  Money get net => income - expense;

  /// Expense by category, largest first.
  final List<CategorySlice> spending;

  /// Income by category, largest first.
  final List<CategorySlice> earning;
  final List<FlowPoint> flow;
  final List<BalancePoint> balance;

  bool get isEmpty => income.isZero && expense.isZero;

  @override
  List<Object?> get props => [
    span,
    bucketSize,
    income,
    expense,
    spending,
    earning,
    flow,
    balance,
  ];
}

abstract interface class ReportsRepository {
  Stream<ReportData> watch(ReportQuery query);
}

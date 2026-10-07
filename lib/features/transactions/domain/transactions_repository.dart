import 'package:equatable/equatable.dart';

import '../../../core/dates/date_range.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import 'entry_query.dart';
import 'ledger_entry.dart';

/// One page of results; [hasMore] when the query's limit cut it short.
/// Pages always end on a whole day so daily totals are never partial.
class EntryPage extends Equatable {
  const EntryPage(this.items, {required this.hasMore});

  static const empty = EntryPage([], hasMore: false);

  final List<EntryView> items;
  final bool hasMore;

  @override
  List<Object?> get props => [items, hasMore];
}

/// Income and expense per currency over a range.
class PeriodTotals extends Equatable {
  const PeriodTotals({required this.income, required this.expense});

  static const empty = PeriodTotals(income: {}, expense: {});

  final Map<Currency, Money> income;
  final Map<Currency, Money> expense;

  Money incomeIn(Currency c) => income[c] ?? Money.zero(c);
  Money expenseIn(Currency c) => expense[c] ?? Money.zero(c);

  @override
  List<Object?> get props => [income, expense];
}

abstract interface class TransactionsRepository {
  Stream<EntryPage> watch(EntryQuery query);
  Stream<EntryView?> watchOne(String id);
  Future<LedgerEntry?> byId(String id);

  /// Creates (no [id]) or replaces the entry. Throws [ValidationFailure]
  /// or [StorageFailure]. Returns the entry id.
  Future<String> save(EntryDraft draft, {String? id});

  /// Soft delete; reversible with [restore].
  Future<void> delete(String id);
  Future<void> restore(String id);

  Stream<PeriodTotals> watchTotals(DateRange range);

  /// Every tag name in use, alphabetical.
  Future<List<String>> tagNames();

  /// Category ids by how often live entries use them, most used first.
  Future<List<String>> frequentCategoryIds({int limit = 8});

  /// Account ids by how often live entries use them, most used first.
  Future<List<String>> frequentAccountIds();

  /// Absolute path of a stored receipt image.
  Future<String> receiptPath(Attachment attachment);
}

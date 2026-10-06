import 'package:equatable/equatable.dart';

import '../../../core/dates/date_range.dart';
import 'transaction_type.dart';

/// Filters for listing entries. Empty sets mean "any".
class EntryQuery extends Equatable {
  const EntryQuery({
    this.types = const {},
    this.accountIds = const {},
    this.categoryIds = const {},
    this.tags = const {},
    this.search = '',
    this.range,
    this.limit = pageSize,
  });

  static const int pageSize = 60;

  final Set<TransactionType> types;

  /// Matches entries from *or to* these accounts.
  final Set<String> accountIds;
  final Set<String> categoryIds;

  /// Tag names.
  final Set<String> tags;

  /// Free text over note, place, category, account, tags and amount.
  final String search;
  final DateRange? range;
  final int limit;

  bool get hasFilters =>
      types.isNotEmpty ||
      accountIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      tags.isNotEmpty;

  EntryQuery copyWith({
    Set<TransactionType>? types,
    Set<String>? accountIds,
    Set<String>? categoryIds,
    Set<String>? tags,
    String? search,
    int? limit,
  }) => EntryQuery(
    types: types ?? this.types,
    accountIds: accountIds ?? this.accountIds,
    categoryIds: categoryIds ?? this.categoryIds,
    tags: tags ?? this.tags,
    search: search ?? this.search,
    range: range,
    limit: limit ?? this.limit,
  );

  /// Same filters, first page.
  EntryQuery cleared() => EntryQuery(search: search, range: range);

  @override
  List<Object?> get props => [
    types,
    accountIds,
    categoryIds,
    tags,
    search,
    range,
    limit,
  ];
}

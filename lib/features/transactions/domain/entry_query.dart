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
    this.personIds = const {},
    this.search = '',
    this.range,
    this.limit = pageSize,
    this.excludeUdhaar = false,
    this.onlyUdhaar = false,
  }) : assert(
         !(excludeUdhaar && onlyUdhaar),
         'udhaar is either left out or the only thing shown',
       );

  static const int pageSize = 60;

  final Set<TransactionType> types;

  /// Matches entries from *or to* these accounts.
  final Set<String> accountIds;
  final Set<String> categoryIds;

  /// Tag names.
  final Set<String> tags;

  /// Udhaar entries with these people.
  final Set<String> personIds;

  /// Free text over note, place, category, account, tags and amount.
  final String search;
  final DateRange? range;
  final int limit;

  /// Leaves out udhaar (person-linked) entries, so a list matches the
  /// income / spent totals, which don't count them.
  final bool excludeUdhaar;

  /// Only udhaar (person-linked) entries.
  final bool onlyUdhaar;

  bool get hasFilters =>
      types.isNotEmpty ||
      accountIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      tags.isNotEmpty ||
      personIds.isNotEmpty ||
      onlyUdhaar;

  EntryQuery copyWith({
    Set<TransactionType>? types,
    Set<String>? accountIds,
    Set<String>? categoryIds,
    Set<String>? tags,
    Set<String>? personIds,
    String? search,
    DateRange? range,
    int? limit,
    bool? excludeUdhaar,
    bool? onlyUdhaar,
  }) => EntryQuery(
    types: types ?? this.types,
    accountIds: accountIds ?? this.accountIds,
    categoryIds: categoryIds ?? this.categoryIds,
    tags: tags ?? this.tags,
    personIds: personIds ?? this.personIds,
    search: search ?? this.search,
    range: range ?? this.range,
    limit: limit ?? this.limit,
    excludeUdhaar: excludeUdhaar ?? this.excludeUdhaar,
    onlyUdhaar: onlyUdhaar ?? this.onlyUdhaar,
  );

  /// Same filters, first page.
  EntryQuery cleared() =>
      EntryQuery(search: search, range: range, excludeUdhaar: excludeUdhaar);

  @override
  List<Object?> get props => [
    types,
    accountIds,
    categoryIds,
    tags,
    personIds,
    search,
    range,
    limit,
    excludeUdhaar,
    onlyUdhaar,
  ];
}

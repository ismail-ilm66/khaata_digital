import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../transactions/domain/transaction_type.dart';

/// One transaction in file-exchange form: names instead of ids, local
/// date-time to the minute. What exports write and imports read.
class ExchangeRecord extends Equatable {
  const ExchangeRecord({
    required this.type,
    required this.at,
    required this.amount,
    required this.account,
    this.id,
    this.toAccount,
    this.toAmount,
    this.fxRateMicros,
    this.category,
    this.person,
    this.note = '',
    this.place,
    this.tags = const [],
    this.events = const [],
  });

  /// Kharcha entry id, when the file came from Kharcha.
  final String? id;
  final TransactionType type;

  /// Local, minute precision.
  final DateTime at;

  /// Positive, except adjustments (signed).
  final Money amount;
  final String account;
  final String? toAccount;

  /// Transfers: what the destination received (its currency).
  final Money? toAmount;
  final int? fxRateMicros;
  final String? category;

  /// Udhaar: the person (expense = I gave, income = I received).
  final String? person;
  final String note;
  final String? place;
  final List<String> tags;
  final List<String> events;

  @override
  List<Object?> get props => [
    id,
    type,
    at,
    amount,
    account,
    toAccount,
    toAmount,
    fxRateMicros,
    category,
    person,
    note,
    place,
    tags,
    events,
  ];

  @override
  String toString() =>
      'ExchangeRecord($type $at $amount $account→$toAccount '
      'cat=$category person=$person note=$note)';
}

/// A non-fatal problem found while reading a file, by 1-based row number.
class ExchangeWarning extends Equatable {
  const ExchangeWarning(this.row, this.kind, [this.detail = '']);

  final int row;
  final ExchangeWarningKind kind;
  final String detail;

  @override
  List<Object?> get props => [row, kind, detail];
}

enum ExchangeWarningKind {
  /// A transfer row with no partner; kept as an adjustment.
  unpairedTransfer,

  /// A row that couldn't be read (bad date or amount); skipped.
  unreadableRow,
}

class ExchangeResult extends Equatable {
  const ExchangeResult(this.records, this.warnings);

  final List<ExchangeRecord> records;
  final List<ExchangeWarning> warnings;

  @override
  List<Object?> get props => [records, warnings];
}

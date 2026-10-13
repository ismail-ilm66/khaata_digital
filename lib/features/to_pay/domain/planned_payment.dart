import 'package:equatable/equatable.dart';

import '../../../core/dates/calendar_day.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';

/// Where something on the To-pay list stands against today.
enum DueStatus { noDate, overdue, today, upcoming }

/// Something still to be paid: a promise, a bill, charity. Not an entry
/// until it's paid; paying it records one and links it via
/// [transactionId].
class PlannedPayment extends Equatable {
  const PlannedPayment({
    required this.id,
    required this.title,
    required this.amount,
    this.categoryId,
    this.dueOn,
    this.note = '',
    this.paidAt,
    this.transactionId,
  });

  final String id;
  final String title;
  final Money amount;

  /// The expense category the payment will be recorded under, if chosen.
  final String? categoryId;
  final CalendarDay? dueOn;
  final String note;
  final DateTime? paidAt;
  final String? transactionId;

  bool get isPaid => paidAt != null;

  DueStatus statusOn(CalendarDay today) {
    final due = dueOn;
    if (due == null) return DueStatus.noDate;
    if (due.isBefore(today)) return DueStatus.overdue;
    return due == today ? DueStatus.today : DueStatus.upcoming;
  }

  PlannedPaymentDraft toDraft() => PlannedPaymentDraft(
    title: title,
    amount: amount,
    categoryId: categoryId,
    dueOn: dueOn,
    note: note,
  );

  /// Totals per currency.
  static Map<Currency, Money> totals(Iterable<PlannedPayment> items) {
    final out = <Currency, Money>{};
    for (final p in items) {
      final c = p.amount.currency;
      out[c] = (out[c] ?? Money.zero(c)) + p.amount;
    }
    return out;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    categoryId,
    dueOn,
    note,
    paidAt,
    transactionId,
  ];
}

/// What the add / edit sheet produces.
class PlannedPaymentDraft extends Equatable {
  const PlannedPaymentDraft({
    required this.title,
    required this.amount,
    this.categoryId,
    this.dueOn,
    this.note = '',
  });

  final String title;
  final Money amount;
  final String? categoryId;
  final CalendarDay? dueOn;
  final String note;

  @override
  List<Object?> get props => [title, amount, categoryId, dueOn, note];
}

abstract class ToPayRepository {
  /// Not yet paid: dated ones by due date first, then the rest by when
  /// they were added.
  Stream<List<PlannedPayment>> watchOpen();

  /// Paid ones, most recent first.
  Stream<List<PlannedPayment>> watchPaid();

  Future<String> add(PlannedPaymentDraft draft);
  Future<void> update(String id, PlannedPaymentDraft draft);
  Future<void> remove(String id);

  /// Paid, by the entry [transactionId] when it was recorded in Kharcha.
  Future<void> markPaid(String id, {String? transactionId, DateTime? at});
  Future<void> markUnpaid(String id);
}

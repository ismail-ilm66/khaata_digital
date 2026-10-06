import 'package:equatable/equatable.dart';

import '../../../core/dates/recurrence.dart';
import '../../../core/money/money.dart';
import '../../transactions/domain/ledger_entry.dart';
import '../../transactions/domain/transaction_type.dart';
import 'recurrence.dart';

/// The fields a repeating entry copies onto every occurrence.
class EntryTemplate extends Equatable {
  const EntryTemplate({
    required this.type,
    required this.amount,
    required this.accountId,
    this.toAccountId,
    this.toAmount,
    this.fxRateMicros,
    this.categoryId,
    this.personId,
    this.note = '',
    this.tags = const [],
  });

  factory EntryTemplate.fromDraft(EntryDraft d) => EntryTemplate(
    type: d.type,
    amount: d.amount,
    accountId: d.accountId!,
    toAccountId: d.toAccountId,
    toAmount: d.toAmount,
    fxRateMicros: d.fxRateMicros,
    categoryId: d.categoryId,
    personId: d.personId,
    note: d.note,
    tags: d.tags,
  );

  final TransactionType type;
  final Money amount;
  final String accountId;
  final String? toAccountId;
  final Money? toAmount;
  final int? fxRateMicros;
  final String? categoryId;
  final String? personId;
  final String note;
  final List<String> tags;

  /// The occurrence due at [local] as a saveable draft.
  EntryDraft draftAt(DateTime local) => EntryDraft(
    type: type,
    amount: amount,
    accountId: accountId,
    toAccountId: toAccountId,
    toAmount: toAmount,
    fxRateMicros: fxRateMicros,
    categoryId: categoryId,
    personId: personId,
    occurredAt: local.toUtc(),
    note: note,
    tags: tags,
  );

  @override
  List<Object?> get props => [
    type,
    amount,
    accountId,
    toAccountId,
    toAmount,
    fxRateMicros,
    categoryId,
    personId,
    note,
    tags,
  ];
}

/// A repeating entry: what to create ([template]) and when ([schedule]).
class RecurringRule extends Equatable {
  const RecurringRule({
    required this.id,
    required this.template,
    required this.schedule,
    required this.nextRunAt,
    this.remind = false,
  });

  final String id;
  final EntryTemplate template;
  final RecurrenceSchedule schedule;

  /// Local time of the next occurrence still to be created, or null when
  /// the rule has ended.
  final DateTime? nextRunAt;

  /// Send a bill reminder when an occurrence falls due.
  final bool remind;

  RecurrenceFrequency get frequency => schedule.frequency;

  @override
  List<Object?> get props => [
    id,
    template,
    schedule.start,
    frequency,
    nextRunAt,
    remind,
  ];
}

/// A rule with the names needed to list it.
class RecurringRuleView extends Equatable {
  const RecurringRuleView({
    required this.rule,
    required this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  final RecurringRule rule;
  final String accountName;
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;

  @override
  List<Object?> get props => [
    rule,
    accountName,
    categoryName,
    categoryIcon,
    categoryColor,
  ];
}

abstract interface class RecurringRepository {
  Stream<List<RecurringRuleView>> watchAll();
  Future<List<RecurringRule>> active();

  /// Starts repeating [first] (already saved as its first occurrence).
  Future<String> create(
    EntryDraft first,
    RecurrenceFrequency frequency, {
    bool remind,
  });

  Future<void> setRemind(String id, bool remind);

  /// Stops the rule; entries already created stay.
  Future<void> delete(String id);

  /// Creates every occurrence due up to [now] and advances each rule, in
  /// one transaction per rule so nothing is created twice. Returns the
  /// number of entries created.
  Future<int> materializeDue(DateTime now);
}

/// Schedules the bill-reminder notifications for rules with [remind].
abstract interface class ReminderScheduler {
  /// Replaces all scheduled reminders with one per reminding rule, at its
  /// next occurrence.
  Future<void> sync(List<RecurringRule> rules);

  /// Asks the OS for permission to notify. True if granted.
  Future<bool> requestPermission();
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../core/dates/recurrence.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/entity_ops.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../transactions/domain/ledger_entry.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../transactions/domain/transactions_repository.dart';
import '../domain/recurrence.dart';
import '../domain/recurring_rule.dart';

/// `recurring_rules.template` JSON. `start` anchors the schedule so month
/// ends clamp without drifting; `remind` turns on bill reminders.
abstract final class TemplateCodec {
  static String encode(
    EntryTemplate t,
    DateTime startLocal, {
    required bool remind,
  }) => jsonEncode({
    'type': t.type.name,
    'amountMinor': t.amount.minor,
    'currency': t.amount.currency.code,
    'accountId': t.accountId,
    'toAccountId': t.toAccountId,
    'toAmountMinor': t.toAmount?.minor,
    'toCurrency': t.toAmount?.currency.code,
    'fxRateMicros': t.fxRateMicros,
    'categoryId': t.categoryId,
    'personId': t.personId,
    'note': t.note,
    'tags': t.tags,
    'startAt': startLocal.toUtc().millisecondsSinceEpoch,
    'remind': remind,
  });

  static ({EntryTemplate template, DateTime start, bool remind}) decode(
    String json,
  ) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    final currency = Currency.of(m['currency'] as String);
    final toMinor = m['toAmountMinor'] as int?;
    return (
      template: EntryTemplate(
        type: TransactionType.values.byName(m['type'] as String),
        amount: Money(m['amountMinor'] as int, currency),
        accountId: m['accountId'] as String,
        toAccountId: m['toAccountId'] as String?,
        toAmount: toMinor == null
            ? null
            : Money(toMinor, Currency.of(m['toCurrency'] as String)),
        fxRateMicros: m['fxRateMicros'] as int?,
        categoryId: m['categoryId'] as String?,
        personId: m['personId'] as String?,
        note: m['note'] as String? ?? '',
        tags: [for (final t in (m['tags'] as List? ?? const [])) t as String],
      ),
      start: DateTime.fromMillisecondsSinceEpoch(m['startAt'] as int).toLocal(),
      remind: m['remind'] as bool? ?? false,
    );
  }
}

@LazySingleton(as: RecurringRepository)
class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl(this._db, this._transactions);

  final AppDatabase _db;
  final TransactionsRepository _transactions;

  $RecurringRulesTable get _rules => _db.recurringRules;

  RecurringRule _toDomain(RecurringRuleRow row) {
    final d = TemplateCodec.decode(row.template);
    return RecurringRule(
      id: row.id,
      template: d.template,
      schedule: RecurrenceSchedule(
        start: d.start,
        frequency: row.freq,
        interval: row.interval,
        end: row.endAt?.toLocal(),
      ),
      nextRunAt: row.nextRunAt.toLocal(),
      remind: d.remind,
    );
  }

  SimpleSelectStatement<$RecurringRulesTable, RecurringRuleRow> _live() =>
      _db.select(_rules)
        ..where((r) => r.deletedAt.isNull())
        ..orderBy([(r) => OrderingTerm.asc(r.nextRunAt)]);

  @override
  Stream<List<RecurringRuleView>> watchAll() {
    return _live().watch().asyncMap((rows) async {
      final accounts = {
        for (final a in await _db.select(_db.accounts).get()) a.id: a,
      };
      final cats = {
        for (final c in await _db.select(_db.categories).get()) c.id: c,
      };
      return [
        for (final row in rows)
          () {
            final rule = _toDomain(row);
            final cat = cats[rule.template.categoryId];
            return RecurringRuleView(
              rule: rule,
              accountName: accounts[rule.template.accountId]?.name ?? '—',
              categoryName: cat?.name,
              categoryIcon: cat?.icon,
              categoryColor: cat?.color,
            );
          }(),
      ];
    });
  }

  @override
  Future<List<RecurringRule>> active() async => [
    for (final r in await _live().get()) _toDomain(r),
  ];

  @override
  Future<String> create(
    EntryDraft first,
    RecurrenceFrequency frequency, {
    bool remind = false,
  }) async {
    final start = first.occurredAt.toLocal();
    final schedule = RecurrenceSchedule(start: start, frequency: frequency);
    final row = await _db
        .into(_rules)
        .insertReturning(
          RecurringRulesCompanion.insert(
            template: TemplateCodec.encode(
              EntryTemplate.fromDraft(first),
              start,
              remind: remind,
            ),
            freq: frequency,
            nextRunAt: schedule.nextAfter(start)!.toUtc(),
          ),
        );
    return row.id;
  }

  @override
  Future<void> setRemind(String id, bool remind) async {
    final row = await (_db.select(
      _rules,
    )..where((r) => r.id.equals(id))).getSingle();
    final d = TemplateCodec.decode(row.template);
    await (_db.update(_rules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        template: Value(
          TemplateCodec.encode(d.template, d.start, remind: remind),
        ),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> delete(String id) => _db.softDelete(_rules, id);

  @override
  Future<int> materializeDue(DateTime now) async {
    var created = 0;
    for (final rule in await active()) {
      final next = rule.nextRunAt;
      if (next == null || next.isAfter(now)) continue;
      final due = [next, ...rule.schedule.dueBetween(next, now)];
      try {
        await _materialize(rule, due);
        created += due.length;
      } on ValidationFailure {
        // e.g. its account was removed: skip this rule, keep the others.
      }
    }
    return created;
  }

  Future<void> _materialize(RecurringRule rule, List<DateTime> due) {
    return _db.transaction(() async {
      for (final at in due) {
        await _transactions.save(rule.template.draftAt(at));
      }
      final following = rule.schedule.nextAfter(due.last);
      await (_db.update(_rules)..where((r) => r.id.equals(rule.id))).write(
        following == null
            ? RecurringRulesCompanion(deletedAt: Value(DateTime.now().toUtc()))
            : RecurringRulesCompanion(nextRunAt: Value(following.toUtc())),
      );
    });
  }
}

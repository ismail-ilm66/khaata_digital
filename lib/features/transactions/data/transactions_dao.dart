import 'package:drift/drift.dart';

import '../../../core/dates/date_range.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/entity_ops.dart';
import '../../../core/db/tables.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.attachedDatabase);

  /// Inserts a transaction with its labels atomically; returns its id.
  Future<String> add(
    TransactionsCompanion entry, {
    Iterable<String> tags = const [],
    Iterable<String> events = const [],
  }) {
    return transaction(() async {
      final row = await into(transactions).insertReturning(entry);
      await _writeLabels(row.id, tags, events);
      return row.id;
    });
  }

  /// Applies [changes] and, when given, replaces the labels. Fields absent
  /// from [changes] — including `occurredAt` — keep their stored values.
  Future<void> edit(
    String id,
    TransactionsCompanion changes, {
    Iterable<String>? tags,
    Iterable<String>? events,
  }) {
    return transaction(() async {
      await (update(transactions)..where((t) => t.id.equals(id))).write(
        changes.copyWith(updatedAt: Value(DateTime.now().toUtc())),
      );
      final labels = db.labelsDao;
      if (tags != null) await labels.setTags(id, await labels.tagIds(tags));
      if (events != null) {
        await labels.setEvents(id, await labels.eventIds(events));
      }
    });
  }

  Future<void> remove(String id) => softDelete(transactions, id);
  Future<void> restore(String id) => undelete(transactions, id);

  Future<TransactionRow?> byId(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Live transactions in [range], newest first.
  Stream<List<TransactionRow>> watchInRange(DateRange range) {
    return (select(transactions)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.occurredAt.isBiggerOrEqualValue(range.startMillis) &
                t.occurredAt.isSmallerThanValue(range.endMillis),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.occurredAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Future<void> _writeLabels(
    String id,
    Iterable<String> tags,
    Iterable<String> events,
  ) async {
    final labels = db.labelsDao;
    if (tags.isNotEmpty) await labels.setTags(id, await labels.tagIds(tags));
    if (events.isNotEmpty) {
      await labels.setEvents(id, await labels.eventIds(events));
    }
  }
}

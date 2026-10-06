import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/entity_ops.dart';
import '../../../core/db/tables.dart';

part 'labels_dao.g.dart';

/// Tags and events: both are free-text labels attached to transactions.
@DriftAccessor(tables: [Tags, TransactionTags, Events, TransactionEvents])
class LabelsDao extends DatabaseAccessor<AppDatabase> with _$LabelsDaoMixin {
  LabelsDao(super.attachedDatabase);

  Future<List<String>> tagIds(Iterable<String> names) =>
      findOrCreateNamed(tags, names);

  Future<List<String>> eventIds(Iterable<String> names) =>
      findOrCreateNamed(events, names);

  /// Replaces the tags on [transactionId].
  Future<void> setTags(String transactionId, List<String> tagIds) {
    return transaction(() async {
      await (delete(
        transactionTags,
      )..where((t) => t.transactionId.equals(transactionId))).go();
      await batch(
        (b) => b.insertAll(transactionTags, [
          for (final id in tagIds)
            TransactionTagsCompanion.insert(
              transactionId: transactionId,
              tagId: id,
            ),
        ]),
      );
    });
  }

  /// Replaces the events on [transactionId].
  Future<void> setEvents(String transactionId, List<String> eventIds) {
    return transaction(() async {
      await (delete(
        transactionEvents,
      )..where((t) => t.transactionId.equals(transactionId))).go();
      await batch(
        (b) => b.insertAll(transactionEvents, [
          for (final id in eventIds)
            TransactionEventsCompanion.insert(
              transactionId: transactionId,
              eventId: id,
            ),
        ]),
      );
    });
  }

  /// Tag names for each of [transactionIds], alphabetical.
  Future<Map<String, List<String>>> tagNamesFor(
    Iterable<String> transactionIds,
  ) async {
    final ids = transactionIds.toSet();
    if (ids.isEmpty) return const {};
    final q =
        select(
            transactionTags,
          ).join([innerJoin(tags, tags.id.equalsExp(transactionTags.tagId))])
          ..where(transactionTags.transactionId.isIn(ids))
          ..orderBy([OrderingTerm.asc(tags.name)]);
    final out = <String, List<String>>{};
    for (final r in await q.get()) {
      out
          .putIfAbsent(r.readTable(transactionTags).transactionId, () => [])
          .add(r.readTable(tags).name);
    }
    return out;
  }

  /// Event names for each of [transactionIds], alphabetical.
  Future<Map<String, List<String>>> eventNamesFor(
    Iterable<String> transactionIds,
  ) async {
    final ids = transactionIds.toSet();
    if (ids.isEmpty) return const {};
    final q =
        select(transactionEvents).join([
            innerJoin(events, events.id.equalsExp(transactionEvents.eventId)),
          ])
          ..where(transactionEvents.transactionId.isIn(ids))
          ..orderBy([OrderingTerm.asc(events.name)]);
    final out = <String, List<String>>{};
    for (final r in await q.get()) {
      out
          .putIfAbsent(r.readTable(transactionEvents).transactionId, () => [])
          .add(r.readTable(events).name);
    }
    return out;
  }

  /// Names of tags attached to at least one live transaction.
  Future<List<String>> usedTagNames() async {
    final rows = await customSelect(
      'SELECT DISTINCT g.name AS name FROM tags g '
      'JOIN transaction_tags tt ON tt.tag_id = g.id '
      'JOIN transactions t ON t.id = tt.transaction_id '
      'WHERE t.deleted_at IS NULL ORDER BY g.name COLLATE NOCASE',
      readsFrom: {tags, transactionTags},
    ).get();
    return [for (final r in rows) r.read<String>('name')];
  }

  Future<List<TagRow>> tagsFor(String transactionId) {
    final q =
        select(tags).join([
            innerJoin(
              transactionTags,
              transactionTags.tagId.equalsExp(tags.id),
            ),
          ])
          ..where(transactionTags.transactionId.equals(transactionId))
          ..orderBy([OrderingTerm.asc(tags.name)]);
    return q.map((r) => r.readTable(tags)).get();
  }
}

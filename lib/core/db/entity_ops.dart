import 'package:drift/drift.dart';

import 'columns.dart';

/// Generic row operations shared by every table built from the column
/// mixins, so soft-delete, reorder and find-or-create live in one place.
extension EntityOps on DatabaseConnectionUser {
  /// Marks a row deleted (archived). Its name becomes reusable immediately.
  Future<void> softDelete<T extends SoftDelete, D>(
    TableInfo<T, D> table,
    String id,
  ) {
    final now = nowMillis();
    return (update(table)..where((t) => t.id.equals(id))).write(
      RawValuesInsertable<D>({
        'deleted_at': Variable<int>(now),
        'updated_at': Variable<int>(now),
      }),
    );
  }

  /// Undoes [softDelete] (undo snackbar, unarchive).
  Future<void> undelete<T extends SoftDelete, D>(
    TableInfo<T, D> table,
    String id,
  ) {
    return (update(table)..where((t) => t.id.equals(id))).write(
      RawValuesInsertable<D>({
        'deleted_at': const Variable<int>(null),
        'updated_at': Variable<int>(nowMillis()),
      }),
    );
  }

  /// Persists a user-chosen order: [orderedIds][i] gets `sort_order = i`.
  Future<void> reorder<T extends Sortable, D>(
    TableInfo<T, D> table,
    List<String> orderedIds,
  ) {
    return transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(table)..where((t) => t.id.equals(orderedIds[i]))).write(
          RawValuesInsertable<D>({'sort_order': Variable<int>(i)}),
        );
      }
    });
  }

  /// The `sort_order` a newly added row should take to land last.
  Future<int> nextSortOrder<T extends Sortable, D>(
    TableInfo<T, D> table,
  ) async {
    final max = table.asDslTable.sortOrder.max();
    final row = await (selectOnly(table)..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  /// Ids for [names] in a name-only table (tags, events), creating missing
  /// rows. Names are trimmed and de-duplicated case-insensitively; the
  /// result follows the order of first appearance.
  Future<List<String>> findOrCreateNamed<T extends Named, D>(
    TableInfo<T, D> table,
    Iterable<String> names,
  ) {
    return transaction(() async {
      final ids = <String>[];
      final seen = <String>{};
      for (final raw in names) {
        final name = raw.trim();
        if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
        final existing =
            await (selectOnly(table)
                  ..addColumns([table.asDslTable.id])
                  ..where(
                    table.asDslTable.name.collate(Collate.noCase).equals(name),
                  ))
                .getSingleOrNull();
        if (existing != null) {
          ids.add(existing.read(table.asDslTable.id)!);
          continue;
        }
        final id = newId();
        await into(table).insert(
          RawValuesInsertable<D>({
            'id': Variable<String>(id),
            'name': Variable<String>(name),
          }),
        );
        ids.add(id);
      }
      return ids;
    });
  }
}

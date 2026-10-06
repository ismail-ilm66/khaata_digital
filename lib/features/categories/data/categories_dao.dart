import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/entity_ops.dart';
import '../../../core/db/tables.dart';
import '../domain/category_kind.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  SimpleSelectStatement<$CategoriesTable, CategoryRow> _active(
    CategoryKind? kind,
  ) {
    return select(categories)
      ..where(
        (c) =>
            c.deletedAt.isNull() &
            (kind == null ? const Constant(true) : c.kind.equalsValue(kind)),
      )
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
  }

  Future<List<CategoryRow>> active({CategoryKind? kind}) => _active(kind).get();
  Stream<List<CategoryRow>> watchActive({CategoryKind? kind}) =>
      _active(kind).watch();

  /// Case-insensitive lookup among active categories of [kind].
  Future<CategoryRow?> findActiveByName(CategoryKind kind, String name) {
    return (select(categories)..where(
          (c) =>
              c.deletedAt.isNull() &
              c.kind.equalsValue(kind) &
              c.name.collate(Collate.noCase).equals(name.trim()),
        ))
        .getSingleOrNull();
  }

  Future<String> create({
    required String name,
    required CategoryKind kind,
    String? icon,
    int? color,
  }) async {
    final row = await into(categories).insertReturning(
      CategoriesCompanion.insert(
        name: name.trim(),
        kind: kind,
        icon: Value(icon),
        color: Value(color),
        sortOrder: Value(await nextSortOrder(categories)),
      ),
    );
    return row.id;
  }

  Future<void> edit(String id, CategoriesCompanion changes) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      changes.copyWith(updatedAt: Value(DateTime.now().toUtc())),
    );
  }

  Future<void> archive(String id) => softDelete(categories, id);
  Future<void> unarchive(String id) => undelete(categories, id);
  Future<void> reorderCategories(List<String> ids) => reorder(categories, ids);
}

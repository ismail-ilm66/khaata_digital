import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/unique_guard.dart';
import '../domain/category.dart';
import '../domain/category_kind.dart';

extension CategoryRowMapping on CategoryRow {
  Category toDomain() =>
      Category(id: id, name: name, kind: kind, iconKey: icon, color: color);
}

@LazySingleton(as: CategoriesRepository)
class CategoriesRepositoryImpl implements CategoriesRepository {
  CategoriesRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Category>> watch(CategoryKind kind) => _db.categoriesDao
      .watchActive(kind: kind)
      .map((rows) => [for (final r in rows) r.toDomain()]);

  @override
  Future<List<Category>> all() async => [
    for (final r in await _db.categoriesDao.active()) r.toDomain(),
  ];

  @override
  Stream<List<Category>> watchArchived(CategoryKind kind) => _db.categoriesDao
      .watchArchived(kind)
      .map((rows) => [for (final r in rows) r.toDomain()]);

  @override
  Future<String> create({
    required String name,
    required CategoryKind kind,
    String? iconKey,
  }) => guardUniqueName(
    name,
    () => _db.categoriesDao.create(name: name, kind: kind, icon: iconKey),
  );

  @override
  Future<void> update(String id, {required String name, String? iconKey}) =>
      guardUniqueName(
        name,
        () => _db.categoriesDao.edit(
          id,
          CategoriesCompanion(name: Value(name.trim()), icon: Value(iconKey)),
        ),
      );

  @override
  Future<void> archive(String id) => _db.categoriesDao.archive(id);

  @override
  Future<void> unarchive(String id) async {
    final row = await _db.categoriesDao.byId(id);
    await guardUniqueName(
      row?.name ?? '',
      () => _db.categoriesDao.unarchive(id),
    );
  }

  @override
  Future<void> reorder(List<String> orderedIds) =>
      _db.categoriesDao.reorderCategories(orderedIds);
}

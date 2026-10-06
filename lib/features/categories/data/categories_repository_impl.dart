import 'package:injectable/injectable.dart';

import '../../../core/db/app_database.dart';
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
}

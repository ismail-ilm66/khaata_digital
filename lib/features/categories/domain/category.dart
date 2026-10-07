import 'package:equatable/equatable.dart';

import '../../../core/error/app_failure.dart';
import 'category_kind.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    this.iconKey,
    this.color,
  });

  final String id;
  final String name;
  final CategoryKind kind;

  /// Key into the icon registry.
  final String? iconKey;

  /// ARGB tint.
  final int? color;

  @override
  List<Object?> get props => [id, name, kind, iconKey, color];
}

abstract interface class CategoriesRepository {
  /// Active categories of [kind] in user order.
  Stream<List<Category>> watch(CategoryKind kind);

  /// Every active category, both kinds (for filters).
  Future<List<Category>> all();

  Stream<List<Category>> watchArchived(CategoryKind kind);

  /// Adds at the end of its list. Throws [DuplicateNameFailure] when an
  /// active category of that kind already has the name (any case).
  Future<String> create({
    required String name,
    required CategoryKind kind,
    String? iconKey,
  });

  Future<void> update(String id, {required String name, String? iconKey});

  /// Hidden from pickers; past entries keep it. Reversible.
  Future<void> archive(String id);
  Future<void> unarchive(String id);
  Future<void> reorder(List<String> orderedIds);
}

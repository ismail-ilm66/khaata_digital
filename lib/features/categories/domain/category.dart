import 'package:equatable/equatable.dart';

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
}

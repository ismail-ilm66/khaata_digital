import 'package:flutter/material.dart';

import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../domain/category.dart';

/// A category's icon in its colour; a neutral tag when uncategorised.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge(this.category, {super.key, this.size = 40});

  final Category? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = category;
    return TintedBadge(
      icon: c == null
          ? AppIcons.fallback.filled
          : AppIcons.of(c.iconKey).filled,
      color: c?.color == null ? context.colors.inkMuted : Color(c!.color!),
      size: size,
    );
  }
}

extension CategoryLabel on BuildContext {
  String categoryName(Category? c) => c?.name ?? l10n.noCategory;
}

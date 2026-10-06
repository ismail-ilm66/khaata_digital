import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_sheet.dart';
import '../domain/category.dart';
import 'category_badge.dart';

/// A category as a tappable badge with its name underneath; a brand ring
/// marks the selected one.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    this.badgeSize = 44,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        key: Key('category-${category.name}'),
        onTap: onTap,
        radius: badgeSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(badgeSize * 0.42),
                border: Border.all(
                  color: selected ? c.brand : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CategoryBadge(category, size: badgeSize),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.labelSmall!.copyWith(
                color: selected ? c.ink : null,
                fontWeight: selected ? FontWeight.w800 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Every category in a 4-column grid.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onTap,
    this.shrinkWrap = false,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category> onTap;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.xl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 92,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) => CategoryTile(
        category: categories[i],
        selected: categories[i].id == selectedId,
        onTap: () => onTap(categories[i]),
      ),
    );
  }
}

/// A sheet with the full category grid; returns the tapped category.
Future<Category?> pickCategory(
  BuildContext context, {
  required List<Category> categories,
  String? selectedId,
}) {
  return showAppSheet<Category>(
    context,
    title: context.l10n.chooseCategory,
    builder: (sheet) => CategoryGrid(
      shrinkWrap: true,
      categories: categories,
      selectedId: selectedId,
      onTap: (c) => Navigator.pop(sheet, c),
    ),
  );
}

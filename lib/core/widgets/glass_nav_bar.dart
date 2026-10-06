import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';
import 'glass_surface.dart';
import 'app_icons.dart';
import '../feedback/haptics.dart';

@immutable
class GlassNavItem {
  const GlassNavItem({required this.icon, required this.label});

  /// Regular weight at rest, filled when selected.
  final AppIcon icon;
  final String label;
}

/// A floating frosted-glass tab bar with a raised primary action in the
/// middle. [items] are the tabs; the action sits between the first and
/// second halves of the list.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.actionLabel,
    required this.onAction,
  }) : assert(
         items.length % 2 == 0,
         'tabs must split evenly around the action',
       );

  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Accessible label for the centre action.
  final String actionLabel;
  final VoidCallback onAction;

  static const double _barHeight = 68;
  static const double _bottomGap = AppSpacing.s;

  /// Space scrollable content must leave at the bottom so its last item
  /// can scroll clear of the floating bar. Pages outside the tab shell
  /// (pushed full-screen) only need the safe-area inset.
  static double clearance(BuildContext context) =>
      GlassNavBarScope.isPresent(context)
      ? _shellClearance(context)
      : AppSpacing.xl + MediaQuery.paddingOf(context).bottom;

  static double _shellClearance(BuildContext context) =>
      _barHeight +
      _bottomGap +
      AppSpacing.l +
      MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final half = items.length ~/ 2;
    Widget tab(int i) => Expanded(
      child: _NavTab(
        item: items[i],
        selected: i == selectedIndex,
        onTap: () {
          Haptics.selection();
          onSelected(i);
        },
      ),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: _bottomGap),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: GlassSurface(
          child: SizedBox(
            height: _barHeight,
            child: Row(
              children: [
                for (var i = 0; i < half; i++) tab(i),
                _ActionButton(label: actionLabel, onTap: onAction),
                for (var i = half; i < items.length; i++) tab(i),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Marks the subtree that sits under the floating [GlassNavBar] (the tab
/// pages), so they reserve room for it while full-screen pages don't.
class GlassNavBarScope extends InheritedWidget {
  const GlassNavBarScope({super.key, required super.child});

  static bool isPresent(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GlassNavBarScope>() != null;

  @override
  bool updateShouldNotify(GlassNavBarScope oldWidget) => false;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightShape: BoxShape.circle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOutCubic,
              width: selected ? 52 : 36,
              height: 30,
              decoration: BoxDecoration(
                color: selected
                    ? c.brand.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                selected ? item.icon.filled : item.icon.regular,
                size: 22,
                color: selected ? c.brand : c.inkMuted,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _duration,
              style: context.text.labelSmall!.copyWith(
                color: selected ? c.ink : c.inkMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The raised green "+" — the only solid brand colour in the bar.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final onBrand = Theme.of(context).colorScheme.onPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            Haptics.tap();
            onTap();
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(c.brand, Colors.white, 0.18)!, c.brand],
              ),
              boxShadow: [
                BoxShadow(
                  color: c.brand.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(AppIcons.add, size: 26, color: onBrand),
          ),
        ),
      ),
    );
  }
}

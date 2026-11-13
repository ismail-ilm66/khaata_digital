import 'package:flutter/material.dart';

import '../theme/context_x.dart';
import 'app_icons.dart';
import '../feedback/haptics.dart';

/// ‹ label › — steps a period back or forward (budgets, reports). Arrows
/// hide when stepping isn't possible (e.g. "All time").
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    this.onPrevious,
    this.onNext,
    this.previousTooltip,
    this.nextTooltip,
    this.dense = false,
    this.trailing,
    this.onLabelTap,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String? previousTooltip;
  final String? nextTooltip;

  /// A card-header version: quiet label at the start, small arrows at the
  /// end (Home's "This month").
  final bool dense;

  /// Dense only: after the arrows (e.g. Home's expand chevron).
  final Widget? trailing;

  /// Not dense: the label opens a choice of period (with a ▾ after it).
  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // With neither arrow there's nothing to keep aligned.
    final noArrows = onPrevious == null && onNext == null;
    Widget arrow(IconData icon, VoidCallback? onTap, String? tip, Key key) =>
        onTap == null && noArrows
        ? const SizedBox.shrink()
        // The other arrow can step: show this one dimmed (not a gap, which
        // left a lone arrow that read as "back").
        : onTap == null
        ? IconButton(
            onPressed: null,
            visualDensity: dense ? VisualDensity.compact : null,
            icon: DirectionalIcon(
              icon,
              size: dense ? 16 : 18,
              color: c.inkMuted.withValues(alpha: 0.4),
            ),
          )
        : IconButton(
            key: key,
            tooltip: tip,
            onPressed: () {
              Haptics.selection();
              onTap();
            },
            visualDensity: dense ? VisualDensity.compact : null,
            icon: DirectionalIcon(icon, size: dense ? 16 : 18, color: c.ink),
          );
    if (dense) {
      return Row(
        children: [
          Expanded(
            child: Text(
              label,
              key: const Key('periodLabel'),
              style: context.text.labelLarge!.copyWith(color: c.inkMuted),
            ),
          ),
          arrow(
            AppIcons.back,
            onPrevious,
            previousTooltip,
            const Key('previousPeriod'),
          ),
          arrow(
            AppIcons.arrowRight,
            onNext,
            nextTooltip,
            const Key('nextPeriod'),
          ),
          ?trailing,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        arrow(
          AppIcons.back,
          onPrevious,
          previousTooltip,
          const Key('previousPeriod'),
        ),
        Flexible(
          child: onLabelTap == null
              ? Text(
                  label,
                  key: const Key('periodLabel'),
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                )
              : InkWell(
                  onTap: () {
                    Haptics.selection();
                    onLabelTap!();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            key: const Key('periodLabel'),
                            textAlign: TextAlign.center,
                            style: context.text.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(AppIcons.chevronDown, size: 16, color: c.inkMuted),
                      ],
                    ),
                  ),
                ),
        ),
        arrow(
          AppIcons.arrowRight,
          onNext,
          nextTooltip,
          const Key('nextPeriod'),
        ),
      ],
    );
  }
}

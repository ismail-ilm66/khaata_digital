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
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String? previousTooltip;
  final String? nextTooltip;

  /// A card-header version: quiet label at the start, small arrows at the
  /// end (Home's "This month").
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget arrow(IconData icon, VoidCallback? onTap, String? tip, Key key) =>
        onTap == null
        ? SizedBox(width: dense ? 36 : 48)
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
          child: Text(
            label,
            key: const Key('periodLabel'),
            textAlign: TextAlign.center,
            style: context.text.titleMedium,
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

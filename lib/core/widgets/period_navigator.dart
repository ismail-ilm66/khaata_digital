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
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String? previousTooltip;
  final String? nextTooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget arrow(IconData icon, VoidCallback? onTap, String? tip, Key key) =>
        onTap == null
        ? const SizedBox(width: 48)
        : IconButton(
            key: key,
            tooltip: tip,
            onPressed: () {
              Haptics.selection();
              onTap();
            },
            icon: DirectionalIcon(icon, size: 18, color: c.ink),
          );
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

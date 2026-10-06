import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';
import 'surface_card.dart';
import 'tinted_badge.dart';

/// A summary at the top of a flow step: tinted icon, a headline with a
/// quiet subtitle, then optional [stats] in a row and a [footer] line.
class HeadlineCard extends StatelessWidget {
  const HeadlineCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    this.stats = const [],
    this.footer,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Badge tint; the brand colour by default.
  final Color? color;

  /// Typically [StatTile]s; laid out in equal columns.
  final List<Widget> stats;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      children: [
        Row(
          children: [
            TintedBadge(icon: icon, color: color, size: 44),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleMedium),
                  if (subtitle != null)
                    Text(subtitle!, style: context.text.bodySmall),
                ],
              ),
            ),
          ],
        ),
        if (stats.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final s in stats) Expanded(child: s)],
          ),
        ?footer,
      ],
    );
  }
}

/// A [StatTile] showing a whole number.
class CountTile extends StatelessWidget {
  const CountTile({super.key, required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => StatTile(
    label: label,
    value: Text('$count', style: context.text.titleMedium),
  );
}

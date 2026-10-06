import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';

/// A rounded surface that groups related content. Children are separated by
/// hairline dividers inset from the leading edge (iOS-style grouped list).
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(AppSpacing.l),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: c.line.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                indent: AppSpacing.l,
                color: c.line.withValues(alpha: 0.7),
              ),
            Padding(padding: padding, child: children[i]),
          ],
        ],
      ),
    );
  }
}

/// A labelled row inside a [SurfaceCard]: leading icon, title, and a
/// control (or value) below or beside it.
class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.control,
  });

  final IconData icon;
  final String title;

  /// Full-width control shown under the title (e.g. a [SegmentedPicker]).
  final Widget? control;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Icon(icon, size: 18, color: c.brand),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(child: Text(title, style: context.text.titleSmall)),
          ],
        ),
        if (control != null) ...[
          const SizedBox(height: AppSpacing.m),
          control!,
        ],
      ],
    );
  }
}

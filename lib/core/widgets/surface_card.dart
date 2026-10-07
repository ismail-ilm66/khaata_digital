import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';
import 'app_icons.dart';
import 'tinted_badge.dart';

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

/// A row inside a [SurfaceCard]: tinted icon badge, title, optional
/// subtitle and trailing widget; with [control], a full-width control sits
/// underneath. Tappable when [onTap] is given (shows a chevron).
class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.control,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Full-width control shown under the title (e.g. a [SegmentedPicker]).
  final Widget? control;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final row = Row(
      children: [
        TintedBadge(icon: icon, size: 32),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleSmall),
              if (subtitle != null)
                Text(subtitle!, style: context.text.bodySmall),
            ],
          ),
        ),
        ?trailing,
        if (onTap != null && trailing == null)
          DirectionalIcon(AppIcons.chevronRight, size: 16, color: c.inkMuted),
      ],
    );
    final content = control == null
        ? row
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row,
              const SizedBox(height: AppSpacing.m),
              control!,
            ],
          );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.s),
      child: content,
    );
  }
}

/// A read-only fact inside a [SurfaceCard]: small muted label over a
/// prominent value (detail screens).
class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TintedBadge(icon: icon, size: 32),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.bodySmall),
              const SizedBox(height: 2),
              DefaultTextStyle.merge(
                style: context.text.bodyLarge,
                child: value,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A labelled figure for summary rows (Income / Spent / Left).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: context.text.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: value,
        ),
      ],
    );
  }
}

/// [StatTile]s side by side in equal shares, with a gap between them so
/// large amounts shrink to fit instead of running into each other.
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.children});

  final List<StatTile> children;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (i, tile) in children.indexed) ...[
        if (i > 0) const SizedBox(width: AppSpacing.l),
        Expanded(child: tile),
      ],
    ],
  );
}

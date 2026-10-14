import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../theme/context_x.dart';

/// The one bold surface on a page: a brand-green gradient card for the
/// headline figure (net worth on Home).
///
/// Everything inside is re-themed for the green: ink and muted text turn
/// white, income turns a pale mint, and inputs/lines become translucent
/// white — so ordinary widgets ([AmountText], [StatTile], icon buttons)
/// work on it unchanged.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    const white = Colors.white;
    final muted = white.withValues(alpha: 0.72);
    final on = c.copyWith(
      ink: white,
      inkMuted: muted,
      income: const Color(0xFFB4F2CF),
      brand: white,
      line: white.withValues(alpha: 0.18),
      surfaceMuted: white.withValues(alpha: 0.12),
      surface: white.withValues(alpha: 0.12),
    );
    final radius = BorderRadius.circular(AppRadii.l);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [c.heroStart, c.heroEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: c.heroEnd.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          // A soft light falling from the top corner, and a hairline edge,
          // so the green has depth rather than reading as a flat block.
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: white.withValues(alpha: 0.10)),
            gradient: RadialGradient(
              center: const Alignment(0.9, -1.2),
              radius: 1.3,
              colors: [
                white.withValues(alpha: 0.16),
                white.withValues(alpha: 0),
              ],
            ),
          ),
          child: Theme(
            data: theme.copyWith(
              extensions: [on],
              textTheme: AppTypography.textTheme(white, muted),
              iconTheme: theme.iconTheme.copyWith(color: white),
              highlightColor: white.withValues(alpha: 0.08),
              colorScheme: theme.colorScheme.copyWith(
                onSurface: white,
                onSurfaceVariant: muted,
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

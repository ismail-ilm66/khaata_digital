import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';

/// A rounded square tinted with [color], holding an icon or a short
/// monogram. The visual anchor for categories, accounts and settings rows.
class TintedBadge extends StatelessWidget {
  const TintedBadge({
    super.key,
    this.icon,
    this.monogram,
    this.color,
    this.size = 40,
  }) : assert(icon != null || monogram != null, 'needs an icon or monogram');

  final IconData? icon;
  final String? monogram;

  /// Defaults to the brand colour.
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.brand;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Color.lerp(tint, Colors.white, 0.25)! : tint;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: dark ? 0.22 : 0.13),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.5, color: fg)
          : Text(
              monogram!,
              maxLines: 1,
              style: context.text.labelMedium!.copyWith(
                color: fg,
                fontSize: size * (monogram!.length > 2 ? 0.26 : 0.32),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
    );
  }
}

/// Square spacing helper so rows built from badges line up.
const double kBadgeGap = AppSpacing.m;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/context_x.dart';

/// Frosted glass: blurs whatever is behind it, tints it with the theme's
/// glass fill, and draws a fine light edge plus a soft floating shadow.
///
/// Use for surfaces that float above content (nav bar, floating actions).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.blur = 24,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: borderRadius,
              border: Border.all(color: c.glassEdge),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

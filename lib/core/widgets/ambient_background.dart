import 'package:flutter/material.dart';

import '../theme/context_x.dart';

/// The app's backdrop: paper with two soft brand glows — one high behind
/// the page titles, one low behind the floating nav — so glass surfaces
/// have colour to refract. Deliberately faint; it is depth, not decoration.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    RadialGradient glow(Alignment at, double radius, double strength) =>
        RadialGradient(
          center: at,
          radius: radius,
          colors: [
            c.glow.withValues(alpha: c.glow.a * strength),
            c.glow.withValues(alpha: 0),
          ],
        );

    return DecoratedBox(
      decoration: BoxDecoration(color: c.paper),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: glow(const Alignment(0.9, -1.1), 1.1, 1),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glow(const Alignment(-0.8, 1.15), 0.9, 0.7),
          ),
          child: child,
        ),
      ),
    );
  }
}

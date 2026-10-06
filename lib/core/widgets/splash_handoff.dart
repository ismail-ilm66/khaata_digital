import 'package:flutter/material.dart';

import '../theme/context_x.dart';

/// Picks up where the native launch screen leaves off — same background,
/// mark and wordmark in the same places — then dissolves into the app: the
/// mark settles back and fades as the background lifts away. About half a
/// second; a plain quick fade when the system asks for reduced motion.
class SplashHandoff extends StatefulWidget {
  const SplashHandoff({super.key, required this.child});

  final Widget child;

  /// Mark size; matches the native splash (560 px images at @4x).
  static const double markSize = 140;

  @override
  State<SplashHandoff> createState() => _SplashHandoffState();
}

class _SplashHandoffState extends State<SplashHandoff>
    with SingleTickerProviderStateMixin {
  late final AnimationController _out = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_out.isAnimating || _out.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _out.duration = const Duration(milliseconds: 160);
    }
    _out.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mark = CurvedAnimation(
      parent: _out,
      curve: const Interval(0, 0.7, curve: Curves.easeInCubic),
    );
    final ground = CurvedAnimation(
      parent: _out,
      curve: const Interval(0.25, 1, curve: Curves.easeOut),
    );
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _out,
            builder: (context, _) => ColoredBox(
              color: context.colors.paper.withValues(alpha: 1 - ground.value),
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: 1 - mark.value,
                      child: Transform.scale(
                        scale: 1 - 0.08 * mark.value,
                        child: Image.asset(
                          'assets/splash/mark.png',
                          width: SplashHandoff.markSize,
                          height: SplashHandoff.markSize,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 32 + MediaQuery.paddingOf(context).bottom,
                    child: Opacity(
                      opacity: (1 - mark.value * 1.4).clamp(0, 1),
                      child: Image.asset(
                        dark
                            ? 'assets/splash/wordmark_dark.png'
                            : 'assets/splash/wordmark.png',
                        height: 50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Shrinks its child slightly while a finger is on it, so every tappable
/// surface answers the touch at once. Purely visual: taps are still handled
/// by the child (an [InkWell], a button…), so it can wrap anything.
///
/// The press ends early if the finger starts to scroll, and the effect is
/// skipped when the system asks for reduced motion.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.enabled = true,
  });

  final Widget child;

  /// Pressed size; 0.95–0.98. Smaller surfaces can go a little further.
  final double scale;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  Offset? _origin;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _origin = e.position;
        _set(true);
      },
      onPointerMove: (e) {
        // A drag is a scroll, not a press.
        if (_origin != null && (e.position - _origin!).distance > kTouchSlop) {
          _set(false);
        }
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        // Pressing in is quick; letting go settles a touch slower.
        duration: _down ? AppMotion.fast : AppMotion.base,
        curve: AppMotion.out,
        child: widget.child,
      ),
    );
  }
}

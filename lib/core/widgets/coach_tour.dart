import 'package:flutter/material.dart';

import '../feedback/haptics.dart';
import '../theme/app_tokens.dart';
import '../theme/context_x.dart';

/// One stop on a [showCoachTour]: the widget under [target] is spotlit and
/// [title] / [body] explain it.
@immutable
class CoachStep {
  const CoachStep({
    required this.target,
    required this.title,
    required this.body,
  });

  final GlobalKey target;
  final String title;
  final String body;
}

/// Labels for the tour's controls (translated by the caller).
@immutable
class CoachLabels {
  const CoachLabels({
    required this.next,
    required this.done,
    required this.skip,
    required this.progress,
  });

  final String next;
  final String done;
  final String skip;

  /// "2 of 7".
  final String Function(int step, int total) progress;
}

/// Dims the app and walks through [steps], one spotlight at a time, each
/// scrolled into view first. Steps whose target isn't on screen are
/// skipped. Completes when finished or skipped (back button = skip);
/// true if the user went through to the end.
Future<bool> showCoachTour(
  BuildContext context, {
  required List<CoachStep> steps,
  required CoachLabels labels,
}) async {
  final finished = await Navigator.of(context, rootNavigator: true).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => _CoachTour(steps: steps, labels: labels),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
  return finished ?? false;
}

class _CoachTour extends StatefulWidget {
  const _CoachTour({required this.steps, required this.labels});

  final List<CoachStep> steps;
  final CoachLabels labels;

  @override
  State<_CoachTour> createState() => _CoachTourState();
}

class _CoachTourState extends State<_CoachTour> {
  /// Steps whose target exists, decided as the tour goes.
  int _index = -1;
  Rect? _hole;

  static const _pad = 6.0;
  static const _scrim = Color(0x9E000000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(0));
  }

  Future<void> _goTo(int from) async {
    for (var i = from; i < widget.steps.length; i++) {
      final target = widget.steps[i].target.currentContext;
      if (target == null || !target.mounted) continue;
      await Scrollable.ensureVisible(
        target,
        alignment: 0.3,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      if (!mounted || !target.mounted) return;
      final box = target.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final origin = box.localToGlobal(Offset.zero);
      setState(() {
        _index = i;
        _hole = (origin & box.size).inflate(_pad);
      });
      return;
    }
    _close(finished: true);
  }

  void _next() {
    Haptics.tap();
    _goTo(_index + 1);
  }

  void _close({required bool finished}) {
    if (mounted) Navigator.of(context).pop(finished);
  }

  @override
  Widget build(BuildContext context) {
    final hole = _hole;
    final size = MediaQuery.sizeOf(context);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            // Plain dim until the first spot is measured, then the window
            // glides from one spot to the next.
            child: hole == null
                ? const ColoredBox(color: _scrim)
                : TweenAnimationBuilder<Rect?>(
                    tween: RectTween(end: hole),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    builder: (context, rect, _) => CustomPaint(
                      painter: _ScrimPainter(hole: rect, color: _scrim),
                    ),
                  ),
          ),
          if (hole != null && _index >= 0)
            _Callout(
              key: ValueKey(_index),
              step: widget.steps[_index],
              hole: hole,
              screen: size,
              progress: widget.labels.progress(_index + 1, widget.steps.length),
              nextLabel: _index == widget.steps.length - 1
                  ? widget.labels.done
                  : widget.labels.next,
              skipLabel: widget.labels.skip,
              onNext: _next,
              onSkip: () => _close(finished: false),
            ),
        ],
      ),
    );
  }
}

/// The dim layer with a rounded window over the target.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.hole, required this.color});

  final Rect? hole;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Path()..addRect(Offset.zero & size);
    final h = hole;
    final path = h == null
        ? all
        : Path.combine(
            PathOperation.difference,
            all,
            Path()..addRRect(
              RRect.fromRectAndRadius(h, const Radius.circular(AppRadii.l)),
            ),
          );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.color != color;
}

/// The explanation card: under the spotlight when it's in the top half,
/// above it otherwise.
class _Callout extends StatelessWidget {
  const _Callout({
    super.key,
    required this.step,
    required this.hole,
    required this.screen,
    required this.progress,
    required this.nextLabel,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
  });

  final CoachStep step;
  final Rect hole;
  final Size screen;
  final String progress;
  final String nextLabel;
  final String skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final below = hole.center.dy < screen.height / 2;
    final card = Material(
      color: c.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadii.l),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.l,
          AppSpacing.l,
          AppSpacing.s,
        ),
        child: Column(
          key: const Key('coachCallout'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step.title, style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(step.body, style: context.text.bodyMedium),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress,
                    style: context.text.bodySmall!.copyWith(color: c.inkMuted),
                  ),
                ),
                TextButton(
                  key: const Key('coachSkip'),
                  onPressed: onSkip,
                  child: Text(skipLabel),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilledButton(
                  key: const Key('coachNext'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                    ),
                  ),
                  onPressed: onNext,
                  child: Text(nextLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final safe = MediaQuery.paddingOf(context);
    return Positioned(
      left: AppSpacing.l,
      right: AppSpacing.l,
      top: below ? hole.bottom + AppSpacing.m : null,
      bottom: below
          ? null
          : (screen.height - hole.top + AppSpacing.m).clamp(
              safe.bottom,
              double.infinity,
            ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (below ? -8 : 8) * (1 - t)),
            child: child,
          ),
        ),
        child: card,
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

/// Calls [onNearEnd] when a vertical scrollable below gets close to its
/// end — the trigger for loading the next page.
class PagedScrollListener extends StatelessWidget {
  const PagedScrollListener({
    super.key,
    required this.onNearEnd,
    required this.child,
    this.threshold = 600,
  });

  final VoidCallback onNearEnd;
  final Widget child;

  /// Pixels from the end at which to load more.
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical &&
            n.metrics.extentAfter < threshold) {
          onNearEnd();
        }
        return false;
      },
      child: child,
    );
  }
}

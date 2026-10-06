import 'package:flutter/widgets.dart';

/// Rebuilds with the latest value of a stream that is created **once**.
///
/// A `StreamBuilder` given `stream: repo.watchX()` in `build` subscribes
/// afresh on every rebuild (theme change, keyboard, a parent's setState)
/// and briefly shows nothing — a visible flash. [Watch] keeps one
/// subscription for its lifetime, re-creating it only when [sourceKey]
/// changes, and always hands [builder] the last value it has.
/// For a future, pass `() => Stream.fromFuture(...)`.
class Watch<T> extends StatefulWidget {
  const Watch(this.source, {super.key, required this.builder, this.sourceKey});

  final Stream<T> Function() source;

  /// Re-subscribe when this changes (e.g. the id being watched).
  final Object? sourceKey;

  /// [data] is null until the first value arrives.
  final Widget Function(BuildContext context, T? data) builder;

  @override
  State<Watch<T>> createState() => _WatchState<T>();
}

class _WatchState<T> extends State<Watch<T>> {
  late Stream<T> _stream = widget.source();

  @override
  void didUpdateWidget(Watch<T> old) {
    super.didUpdateWidget(old);
    if (old.sourceKey != widget.sourceKey) _stream = widget.source();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
    stream: _stream,
    builder: (context, snap) => widget.builder(context, snap.data),
  );
}

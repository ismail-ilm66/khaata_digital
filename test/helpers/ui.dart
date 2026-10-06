import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls the page until [f] is built, then brings it to mid-screen —
/// clear of the floating nav bar — the way a person would before tapping.
Future<void> reveal(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await Scrollable.ensureVisible(t.element(f), alignment: 0.5);
  await t.pumpAndSettle();
}

Future<void> revealAndTap(WidgetTester t, Finder f) async {
  await reveal(t, f);
  await t.tap(f);
  await t.pumpAndSettle();
}

/// Waits for real async work (isolates, file I/O) that fake time can't
/// advance, pumping frames until [f] appears.
Future<void> waitFor(
  WidgetTester t,
  Finder f, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (f.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for $f');
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await t.pump();
  }
  await t.pump(const Duration(milliseconds: 400));
}

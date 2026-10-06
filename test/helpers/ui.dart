import 'package:flutter/material.dart';
import 'package:khaata_digital/core/l10n/gen/app_localizations.dart';
import 'package:khaata_digital/core/theme/app_theme.dart';
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
  // Let short follow-ups finish (animations, the success double tick).
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await t.pump(const Duration(milliseconds: 400));
}

/// A single widget inside the app's theme and localizations.
Widget testApp(Widget child) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

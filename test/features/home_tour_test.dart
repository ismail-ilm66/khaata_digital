import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/locale_cubit.dart';

import '../helpers/test_app.dart';
import '../helpers/ui.dart';

/// The how-to tour: shown once on the first visit to Home (even after a
/// skipped welcome), and again from More → How to use Kharcha.
void main() {
  late AppDatabase db;

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  Finder callout() => find.byKey(const Key('coachCallout'));
  Future<String> done() async =>
      (await db.settingsDao.read(SettingKey.tourDone));

  testWidgets('first visit: the tour walks through, then never again', (
    t,
  ) async {
    db = await setUpTestApp();
    await db.settingsDao.write(SettingKey.tourDone, 'false');
    await pump(t);
    expect(callout(), findsOneWidget);
    expect(find.text('Add an entry'), findsOneWidget);

    var steps = 1;
    while (find.text('Got it').evaluate().isEmpty) {
      await t.tap(find.byKey(const Key('coachNext')));
      await t.pumpAndSettle();
      steps++;
    }
    expect(steps, 8);
    expect(find.text('More'), findsWidgets);
    await t.tap(find.byKey(const Key('coachNext')));
    await t.pumpAndSettle();
    expect(callout(), findsNothing);
    expect(await t.runAsync(done), 'true');

    // A cold start: no tour.
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() => setUpTestApp(reuse: db));
    await pump(t);
    expect(callout(), findsNothing);
  });

  testWidgets('skipping the welcome still shows it; Skip ends it for good', (
    t,
  ) async {
    db = await setUpTestApp(welcome: true);
    await pump(t);
    await t.tap(find.byKey(const Key('onboardingSkip')));
    await t.pumpAndSettle();
    expect(callout(), findsOneWidget);
    await t.tap(find.byKey(const Key('coachSkip')));
    await t.pumpAndSettle();
    expect(callout(), findsNothing);
    expect(await t.runAsync(done), 'true');
  });

  testWidgets('More → How to use Kharcha replays it on Home', (t) async {
    db = await setUpTestApp();
    await pump(t);
    expect(callout(), findsNothing);
    await t.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('More'),
      ),
    );
    await t.pumpAndSettle();
    await revealAndTap(t, find.byKey(const Key('tourTile')));
    await t.pumpAndSettle();
    expect(callout(), findsOneWidget);
    expect(find.text('Add an entry'), findsOneWidget);
    expect(find.byKey(const Key('netWorth')), findsOneWidget, reason: 'Home');
    await t.tap(find.byKey(const Key('coachSkip')));
    await t.pumpAndSettle();
  });

  testWidgets('every step fits in Urdu with large text on a small phone', (
    t,
  ) async {
    db = await setUpTestApp();
    await db.settingsDao.write(SettingKey.tourDone, 'false');
    await getIt<LocaleCubit>().set(LocaleCubit.urdu);
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
    for (var i = 0; i < 8; i++) {
      expect(callout(), findsOneWidget, reason: 'step ${i + 1}');
      expect(t.takeException(), isNull, reason: 'step ${i + 1}');
      await t.tap(find.byKey(const Key('coachNext')));
      await t.pumpAndSettle();
    }
    expect(callout(), findsNothing);
  });
}

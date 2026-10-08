import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/security/presentation/lock_cubit.dart';

import '../helpers/test_app.dart';
import '../helpers/ui.dart';

/// Android back: a tab goes to Home first; Home leaves the app, locked.
void main() {
  late List<String> calls;

  /// The last thing Flutter told Android: does it handle back itself?
  bool? frameworkHandlesBack;

  Future<void> start(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    calls = [];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          frameworkHandlesBack = call.arguments as bool;
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    // Android is only told about back handling while the app is running.
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  Finder tab(String label) =>
      find.descendant(of: find.byType(GlassNavBar), matching: find.text(label));

  Future<void> back(WidgetTester t) async {
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
  }

  bool onHome() => find.byKey(const Key('netWorth')).evaluate().isNotEmpty;

  testWidgets('back on another tab goes Home and keeps the app open', (
    t,
  ) async {
    await setUpTestApp();
    await start(t);
    for (final name in ['Transactions', 'Reports', 'More']) {
      await t.tap(tab(name));
      await t.pumpAndSettle();
      expect(onHome(), isFalse, reason: name);
      await back(t);
      expect(onHome(), isTrue, reason: 'back from $name');
      expect(calls, isNot(contains('SystemNavigator.pop')));
    }
  });

  testWidgets('a page opened from a tab goes back to that tab first', (
    t,
  ) async {
    await setUpTestApp();
    await start(t);
    await t.tap(tab('More'));
    await t.pumpAndSettle();
    await revealAndTap(t, find.byKey(const Key('accountsTile')));
    expect(find.byKey(const Key('addAccount')), findsOneWidget);
    await back(t);
    expect(find.byKey(const Key('accountsTile')), findsOneWidget);
    expect(onHome(), isFalse);
  });

  testWidgets('back on Home leaves the app and locks it at once', (t) async {
    await setUpTestApp();
    final lock = getIt<LockCubit>();
    await t.runAsync(() => lock.setPin('2580'));
    expect(lock.state.locked, isFalse);
    expect(lock.state.lockAfter, const Duration(seconds: 30));
    await start(t);
    await back(t);
    expect(calls, contains('SystemNavigator.pop'));
    expect(lock.state.locked, isTrue, reason: 'no 30-second grace');
  });

  testWidgets('Android hands every back press to the app on every tab', (
    t,
  ) async {
    // Without this, a tab's navigator says "nothing to go back to" and
    // Android closes the app itself, never asking Flutter.
    await setUpTestApp();
    await start(t);
    for (final name in ['More', 'Reports', 'Transactions', 'Home']) {
      await t.tap(tab(name));
      await t.pumpAndSettle();
      expect(frameworkHandlesBack, isTrue, reason: name);
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/security/domain/device_auth.dart';
import 'package:khaata_digital/features/security/presentation/lock_cubit.dart';

import '../../helpers/fake_device_auth.dart';
import '../../helpers/test_app.dart';
import '../../helpers/ui.dart';

void main() {
  late AppDatabase db;
  setUp(() async => db = await setUpTestApp());

  Future<void> start(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  Future<void> typePin(WidgetTester t, String pin) async {
    for (final d in pin.split('')) {
      await t.tap(find.byKey(Key('key-d$d')).last);
      await t.pump();
    }
    // PIN hashing runs in an isolate: give it real time.
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await t.pumpAndSettle();
  }

  /// Simulates a cold start against the same database.
  Future<void> restart(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() => setUpTestApp(reuse: db));
    await start(t);
  }

  Finder lockScreen() => find.byKey(const Key('lockScreen'));

  testWidgets('turn on in More; cold start asks for the PIN', (t) async {
    await start(t);
    await t.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('More'),
      ),
    );
    await t.pumpAndSettle();
    await revealAndTap(t, find.byKey(const Key('appLockTile')));
    await t.tap(find.byKey(const Key('turnOnLock')));
    await t.pumpAndSettle();

    await typePin(t, '1234');
    expect(find.text('Enter it again'), findsOneWidget);
    await typePin(t, '9999');
    expect(find.text("Those didn't match. Try again."), findsOneWidget);
    await typePin(t, '1234');
    await typePin(t, '1234');
    expect(find.text('App lock is on'), findsOneWidget);
    expect(lockScreen(), findsNothing, reason: 'not locked right after');

    await restart(t);
    expect(lockScreen(), findsOneWidget);
    await typePin(t, '1111');
    expect(find.text('Wrong PIN'), findsOneWidget);
    expect(lockScreen(), findsOneWidget);
    await typePin(t, '1234');
    expect(lockScreen(), findsNothing);
    expect(find.text('Kharcha'), findsWidgets, reason: 'back on Home');
  });

  testWidgets('locks again after time away; fingerprint unlocks', (t) async {
    await t.runAsync(() async {
      final lock = getIt<LockCubit>();
      await lock.setPin('2580');
      await lock.setBiometric(true, reason: 'Turn on');
      await lock.setLockAfter(Duration.zero);
    });
    await start(t);
    expect(lockScreen(), findsNothing);

    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    expect(find.byKey(const Key('privacyCover')), findsOneWidget);
    t.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pumpAndSettle();
    // Fingerprint was offered straight away and the fake phone approved.
    final device = getIt<DeviceAuth>() as FakeDeviceAuth;
    expect(device.asked, hasLength(2), reason: 'turning on, then unlocking');
    expect(device.asked.last.biometricOnly, isTrue);
    expect(lockScreen(), findsNothing);
    expect(find.byKey(const Key('privacyCover')), findsNothing);
  });

  testWidgets('forgot PIN: the phone\'s screen lock turns it off', (t) async {
    await t.runAsync(() => getIt<LockCubit>().setPin('2580'));
    await restart(t);
    expect(lockScreen(), findsOneWidget);
    await t.tap(find.byKey(const Key('forgotPin')));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pumpAndSettle();
    expect(lockScreen(), findsNothing);
    expect(getIt<LockCubit>().state.enabled, isFalse);
  });

  testWidgets('after setting a PIN, Kharcha offers fingerprint / face', (
    t,
  ) async {
    (getIt<DeviceAuth>() as FakeDeviceAuth).kind = BiometricKind.face;
    await t.runAsync(() => getIt<LockCubit>().load());
    await start(t);
    await t.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('More'),
      ),
    );
    await t.pumpAndSettle();
    await revealAndTap(t, find.byKey(const Key('appLockTile')));
    await t.tap(find.byKey(const Key('turnOnLock')));
    await t.pumpAndSettle();
    await typePin(t, '1234');
    await typePin(t, '1234');
    expect(find.byKey(const Key('useBiometric')), findsOneWidget);
    await t.tap(find.byKey(const Key('useBiometric')));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pumpAndSettle();
    expect(getIt<LockCubit>().state.biometric, isTrue);
    // The settings now name it the way the phone does.
    expect(find.byKey(const Key('biometricSwitch')), findsOneWidget);
  });
}

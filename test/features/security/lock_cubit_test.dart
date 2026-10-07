import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/lifecycle/system_screens.dart';
import 'package:khaata_digital/features/security/data/pin_hasher.dart';
import 'package:khaata_digital/features/security/presentation/lock_cubit.dart';
import 'package:khaata_digital/features/settings/data/settings_repository_impl.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';

import '../../helpers/fake_device_auth.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  late FakeDeviceAuth device;

  setUp(() {
    db = testDb();
    settings = SettingsRepositoryImpl(db);
    device = FakeDeviceAuth();
  });
  tearDown(() => db.close());

  Future<LockCubit> cubit() async {
    final c = LockCubit(settings, device);
    await c.load();
    return c;
  }

  Future<LockCubit> withPin([String pin = '2580']) async {
    final c = await cubit();
    await c.setPin(pin);
    return c;
  }

  test('the PIN is stored only as a salted hash', () async {
    await withPin();
    final stored = await settings.read(SettingKey.lockPin);
    expect(stored, isNot(contains('2580')));
    expect(await PinHasher.verify('2580', stored), isTrue);
    expect(await PinHasher.verify('2581', stored), isFalse);
    expect(await PinHasher.hash('2580'), isNot(stored), reason: 'salted');
  });

  test('a cold start with the lock on starts locked', () async {
    await withPin();
    final fresh = LockCubit(settings, device);
    await fresh.load();
    expect(fresh.state.enabled, isTrue);
    expect(fresh.state.locked, isTrue);
    expect(await fresh.enterPin('2580'), PinResult.unlocked);
    expect(fresh.state.locked, isFalse);
  });

  test('locks on return after the chosen time away', () async {
    final c = await withPin();
    await c.setLockAfter(const Duration(seconds: 30));
    final t0 = DateTime(2026, 10, 6, 9);

    c
      ..backgrounded(t0)
      ..foregrounded(t0.add(const Duration(seconds: 29)));
    expect(c.state.locked, isFalse, reason: 'a quick glance away');

    c
      ..backgrounded(t0)
      ..foregrounded(t0.add(const Duration(seconds: 30)));
    expect(c.state.locked, isTrue);

    await c.enterPin('2580');
    await c.setLockAfter(Duration.zero);
    c
      ..backgrounded(t0)
      ..foregrounded(t0);
    expect(c.state.locked, isTrue, reason: '"Immediately"');
  });

  test('coming back from a picker Kharcha opened does not lock', () async {
    final c = await withPin();
    await c.setLockAfter(Duration.zero);
    await SystemScreens.show(() async {
      c.backgrounded();
      c.foregrounded(DateTime.now().add(const Duration(minutes: 10)));
    });
    expect(c.state.locked, isFalse);
  });

  test(
    'five misses pause entry; the pause doubles and survives restarts',
    () async {
      final c = await withPin();
      final t = DateTime(2026, 10, 6, 9);
      for (var i = 1; i < LockCubit.freeTries; i++) {
        expect(await c.enterPin('0000', t), PinResult.wrong);
      }
      expect(await c.enterPin('0000', t), PinResult.pausedForNow);
      expect(c.state.pausedUntil, t.add(const Duration(seconds: 30)));
      expect(
        await c.enterPin('2580', t.add(const Duration(seconds: 10))),
        PinResult.pausedForNow,
        reason: 'even the right PIN waits',
      );

      final restarted = LockCubit(settings, device);
      await restarted.load();
      expect(restarted.state.pausedUntil, t.add(const Duration(seconds: 30)));

      final later = t.add(const Duration(seconds: 31));
      expect(await restarted.enterPin('1111', later), PinResult.pausedForNow);
      expect(
        restarted.state.pausedUntil,
        later.add(const Duration(minutes: 1)),
      );
      expect(
        await restarted.enterPin('2580', later.add(const Duration(minutes: 2))),
        PinResult.unlocked,
      );
      expect(restarted.state.failures, 0);
    },
  );

  test('fingerprint / face unlocks only when turned on', () async {
    final c = await withPin();
    c.foregrounded();
    await c.setLockAfter(Duration.zero);
    c
      ..backgrounded()
      ..foregrounded();
    expect(await c.unlockWithBiometrics('Unlock'), isFalse, reason: 'off');

    // Turning it on takes one successful scan.
    device.approve = false;
    expect(await c.setBiometric(true, reason: 'Turn on'), isFalse);
    expect(c.state.biometric, isFalse);
    device.approve = true;
    expect(await c.setBiometric(true, reason: 'Turn on'), isTrue);
    expect(c.state.biometric, isTrue);

    expect(await c.unlockWithBiometrics('Unlock'), isTrue);
    expect(c.state.locked, isFalse);
    expect(device.asked.last.biometricOnly, isTrue);

    device.kind = null;
    final noSensor = LockCubit(settings, device);
    await noSensor.load();
    expect(noSensor.state.biometric, isFalse, reason: 'sensor gone');
    expect(await noSensor.setBiometric(true, reason: 'x'), isFalse);
  });

  test('forgot PIN: the phone\'s own lock turns the app lock off', () async {
    final c = await withPin();
    device.approve = false;
    expect(await c.resetWithPhoneLock('Reset'), isFalse);
    expect(c.state.enabled, isTrue);

    device.approve = true;
    expect(await c.resetWithPhoneLock('Reset'), isTrue);
    expect(device.asked.last.biometricOnly, isFalse);
    expect(c.state.enabled, isFalse);
    expect(c.state.locked, isFalse);
    expect(await settings.read(SettingKey.lockPin), isEmpty);
  });

  test('reports what the phone has: face or fingerprint', () async {
    device.kind = BiometricKind.face;
    final c = await cubit();
    expect(c.state.biometricKind, BiometricKind.face);
    expect(c.state.biometricAvailable, isTrue);
  });
}

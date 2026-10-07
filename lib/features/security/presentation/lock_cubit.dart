import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/lifecycle/system_screens.dart';
import '../../settings/domain/setting_key.dart';
import '../../settings/domain/settings_repository.dart';
import '../data/pin_hasher.dart';
import '../domain/device_auth.dart';

export '../domain/device_auth.dart' show BiometricKind;

/// What happened to a PIN attempt.
enum PinResult { unlocked, wrong, pausedForNow }

class AppLockState extends Equatable {
  const AppLockState({
    this.enabled = false,
    this.locked = false,
    this.biometric = false,
    this.biometricKind,
    this.lockAfter = const Duration(seconds: 30),
    this.failures = 0,
    this.pausedUntil,
  });

  final bool enabled;

  /// The lock screen is up.
  final bool locked;

  /// Fingerprint / face unlock turned on (and possible on this phone).
  final bool biometric;

  /// What this phone offers; null when it has no biometrics set up.
  final BiometricKind? biometricKind;

  bool get biometricAvailable => biometricKind != null;
  final Duration lockAfter;

  /// Wrong PINs in a row.
  final int failures;

  /// No PIN entry until then (after repeated misses).
  final DateTime? pausedUntil;

  AppLockState copyWith({
    bool? enabled,
    bool? locked,
    bool? biometric,
    Duration? lockAfter,
    int? failures,
    DateTime? Function()? pausedUntil,
  }) => AppLockState(
    enabled: enabled ?? this.enabled,
    locked: locked ?? this.locked,
    biometric: biometric ?? this.biometric,
    biometricKind: biometricKind,
    lockAfter: lockAfter ?? this.lockAfter,
    failures: failures ?? this.failures,
    pausedUntil: pausedUntil == null ? this.pausedUntil : pausedUntil(),
  );

  @override
  List<Object?> get props => [
    enabled,
    locked,
    biometric,
    biometricKind,
    lockAfter,
    failures,
    pausedUntil,
  ];
}

/// The optional app lock (spec 3.1 #12): a 4-digit PIN, plus fingerprint /
/// face when the phone has it. Locks on cold start and when the user comes
/// back after [AppLockState.lockAfter] away — but not from system screens
/// Kharcha opened itself (pickers, share sheet, camera).
@lazySingleton
class LockCubit extends Cubit<AppLockState> {
  LockCubit(this._settings, this._device) : super(const AppLockState());

  final SettingsRepository _settings;
  final DeviceAuth _device;
  DateTime? _leftAt;

  static const int pinLength = 4;

  /// Wrong PINs allowed before entry pauses (30 s, doubling to 15 min).
  static const int freeTries = 5;
  static const Duration maxPause = Duration(minutes: 15);

  static const List<Duration> lockAfterChoices = [
    Duration.zero,
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  /// Reads the settings; a cold start with the lock on starts locked.
  Future<void> load() async {
    final enabled =
        await _settings.read(SettingKey.lockEnabled) == 'true' &&
        (await _settings.read(SettingKey.lockPin)).isNotEmpty;
    final kind = await _device.biometrics();
    final until = int.tryParse(await _settings.read(SettingKey.lockUntil)) ?? 0;
    emit(
      AppLockState(
        enabled: enabled,
        locked: enabled,
        biometricKind: kind,
        biometric:
            kind != null &&
            await _settings.read(SettingKey.lockBiometric) == 'true',
        lockAfter: Duration(
          seconds:
              int.tryParse(await _settings.read(SettingKey.lockAfter)) ?? 30,
        ),
        failures:
            int.tryParse(await _settings.read(SettingKey.lockFailures)) ?? 0,
        pausedUntil: until == 0
            ? null
            : DateTime.fromMillisecondsSinceEpoch(until),
      ),
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  /// The app went to the background.
  void backgrounded([DateTime? now]) {
    if (!state.enabled || state.locked) return;
    if (SystemScreens.isOwnTrip(now)) return;
    _leftAt = now ?? DateTime.now();
  }

  /// The app is back. Locks when the user was away long enough.
  void foregrounded([DateTime? now]) {
    final left = _leftAt;
    _leftAt = null;
    if (!state.enabled || state.locked || left == null) return;
    if (SystemScreens.isOwnTrip(now)) return;
    if ((now ?? DateTime.now()).difference(left) >= state.lockAfter) {
      emit(state.copyWith(locked: true));
    }
  }

  // ── Unlocking ─────────────────────────────────────────────────────────

  Future<PinResult> enterPin(String pin, [DateTime? now]) async {
    final at = now ?? DateTime.now();
    final paused = state.pausedUntil;
    if (paused != null && at.isBefore(paused)) return PinResult.pausedForNow;
    if (await PinHasher.verify(pin, await _settings.read(SettingKey.lockPin))) {
      await _setFailures(0, null);
      emit(state.copyWith(locked: false));
      return PinResult.unlocked;
    }
    final failures = state.failures + 1;
    DateTime? until;
    if (failures >= freeTries) {
      final pause = Duration(
        seconds: 30 * pow(2, failures - freeTries).toInt(),
      );
      until = at.add(pause > maxPause ? maxPause : pause);
    }
    await _setFailures(failures, until);
    return until == null ? PinResult.wrong : PinResult.pausedForNow;
  }

  Future<bool> unlockWithBiometrics(String reason) async {
    if (!state.biometric) return false;
    final ok = await _device.authenticate(reason, biometricOnly: true);
    if (ok) {
      await _setFailures(0, null);
      emit(state.copyWith(locked: false));
    }
    return ok;
  }

  /// "Forgot PIN": proving it's the phone's owner (its own screen lock or
  /// biometrics) turns the app lock off; a new PIN can be set afterwards.
  Future<bool> resetWithPhoneLock(String reason) async {
    final ok = await _device.authenticate(reason, biometricOnly: false);
    if (ok) await disable();
    return ok;
  }

  Future<void> _setFailures(int failures, DateTime? until) async {
    await _settings.write(SettingKey.lockFailures, '$failures');
    await _settings.write(
      SettingKey.lockUntil,
      '${until?.millisecondsSinceEpoch ?? 0}',
    );
    emit(state.copyWith(failures: failures, pausedUntil: () => until));
  }

  // ── Settings ──────────────────────────────────────────────────────────

  /// Turns the lock on (or changes the PIN). Doesn't lock right away.
  Future<void> setPin(String pin) async {
    assert(pin.length == pinLength);
    await _settings.write(SettingKey.lockPin, await PinHasher.hash(pin));
    await _settings.write(SettingKey.lockEnabled, 'true');
    await _setFailures(0, null);
    emit(state.copyWith(enabled: true, locked: false));
  }

  Future<void> disable() async {
    await _settings.write(SettingKey.lockEnabled, 'false');
    await _settings.write(SettingKey.lockPin, '');
    await _settings.write(SettingKey.lockBiometric, 'false');
    await _setFailures(0, null);
    emit(state.copyWith(enabled: false, locked: false, biometric: false));
  }

  /// Turning it on takes one successful scan, so it's never on without a
  /// finger or face that works. Returns whether it ended up on.
  Future<bool> setBiometric(bool on, {required String reason}) async {
    if (on) {
      if (!state.biometricAvailable) return false;
      if (!await _device.authenticate(reason, biometricOnly: true)) {
        return false;
      }
    }
    await _settings.write(SettingKey.lockBiometric, '$on');
    emit(state.copyWith(biometric: on));
    return on;
  }

  Future<void> setLockAfter(Duration after) async {
    await _settings.write(SettingKey.lockAfter, '${after.inSeconds}');
    emit(state.copyWith(lockAfter: after));
  }

  /// Checks a PIN without changing the lock (e.g. before turning it off).
  Future<bool> checkPin(String pin) async =>
      PinHasher.verify(pin, await _settings.read(SettingKey.lockPin));
}

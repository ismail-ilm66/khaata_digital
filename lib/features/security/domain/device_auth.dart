/// What the phone can unlock with, for naming it ("Face ID", "Fingerprint").
enum BiometricKind {
  face,
  fingerprint,

  /// The phone has biometrics but doesn't say which (common on Android).
  any,
}

/// The phone's own authentication: fingerprint / face, and its screen
/// lock (PIN, pattern, passcode) as a fallback.
abstract interface class DeviceAuth {
  /// The biometrics set up and usable on this phone; null when none.
  Future<BiometricKind?> biometrics();

  /// Asks for fingerprint / face only ([biometricOnly]) or allows the
  /// phone's screen lock too. False when cancelled or failed.
  Future<bool> authenticate(String reason, {required bool biometricOnly});
}

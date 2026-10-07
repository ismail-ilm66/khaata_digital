import 'package:khaata_digital/features/security/domain/device_auth.dart';

/// A phone whose fingerprint / screen lock answer as told.
class FakeDeviceAuth implements DeviceAuth {
  BiometricKind? kind = BiometricKind.fingerprint;
  bool approve = true;
  final asked = <({String reason, bool biometricOnly})>[];

  @override
  Future<BiometricKind?> biometrics() async => kind;

  @override
  Future<bool> authenticate(
    String reason, {
    required bool biometricOnly,
  }) async {
    asked.add((reason: reason, biometricOnly: biometricOnly));
    return approve && (!biometricOnly || kind != null);
  }
}

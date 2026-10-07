import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/lifecycle/system_screens.dart';
import '../domain/device_auth.dart';

@prod
@LazySingleton(as: DeviceAuth)
class LocalDeviceAuth implements DeviceAuth {
  final _auth = LocalAuthentication();

  @override
  Future<BiometricKind?> biometrics() async {
    try {
      if (!await _auth.canCheckBiometrics) return null;
      final types = await _auth.getAvailableBiometrics();
      if (types.isEmpty) return null;
      if (types.contains(BiometricType.face)) return BiometricKind.face;
      if (types.contains(BiometricType.fingerprint)) {
        return BiometricKind.fingerprint;
      }
      return BiometricKind.any;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> authenticate(
    String reason, {
    required bool biometricOnly,
  }) async {
    try {
      // The system prompt backgrounds the app on Android; not a real exit.
      return await SystemScreens.show(
        () => _auth.authenticate(
          localizedReason: reason,
          biometricOnly: biometricOnly,
          persistAcrossBackgrounding: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

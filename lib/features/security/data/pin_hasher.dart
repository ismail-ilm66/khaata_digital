import 'dart:convert';
import 'dart:isolate';

import 'package:cryptography/cryptography.dart';

/// Stores a PIN only as PBKDF2-HMAC-SHA256 with a random salt, so the
/// settings table (and backups) never hold the PIN itself.
abstract final class PinHasher {
  static const int iterations = 20000;

  /// "iterations:salt:hash", base64.
  static Future<String> hash(String pin, {int rounds = iterations}) async {
    final salt = SecretKeyData.random(length: 16).bytes;
    final digest = await _derive(pin, salt, rounds);
    return '$rounds:${base64Encode(salt)}:${base64Encode(digest)}';
  }

  static Future<bool> verify(String pin, String stored) async {
    final parts = stored.split(':');
    if (parts.length != 3) return false;
    final rounds = int.tryParse(parts[0]);
    if (rounds == null) return false;
    final digest = await _derive(pin, base64Decode(parts[1]), rounds);
    return _same(digest, base64Decode(parts[2]));
  }

  static Future<List<int>> _derive(String pin, List<int> salt, int rounds) =>
      Isolate.run(() async {
        final key = await Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: rounds,
          bits: 256,
        ).deriveKeyFromPassword(password: pin, nonce: salt);
        return key.extractBytes();
      });

  /// Constant-time comparison.
  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

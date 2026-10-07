import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Build settings from the `.env` file bundled with the app (see
/// `.env.example`). Only non-secret values belong there: the file ships
/// inside the app. A missing file or key reads as empty, which turns the
/// matching feature off (e.g. no Google Drive backup).
abstract final class AppConfig {
  /// Call once per isolate (app start, background jobs) before use.
  static Future<void> load() => dotenv.load(isOptional: true);

  static String _get(String key) =>
      dotenv.isInitialized ? (dotenv.maybeGet(key) ?? '').trim() : '';

  /// Google Cloud OAuth client of type "Web application" (Android sign-in).
  static String get googleServerClientId => _get('GOOGLE_SERVER_CLIENT_ID');

  /// Google Cloud OAuth client of type "iOS".
  static String get googleIosClientId => _get('GOOGLE_IOS_CLIENT_ID');

  /// Where "Contact us" sends email.
  static String get supportEmail => _get('SUPPORT_EMAIL');
}

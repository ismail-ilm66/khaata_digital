import 'setting_key.dart';

/// Typed-key access to persisted settings. Values are strings; each caller
/// owns parsing its own key.
abstract interface class SettingsRepository {
  /// The stored value, or [SettingKey.defaultValue] if never set.
  Future<String> read(SettingKey key);

  Future<void> write(SettingKey key, String value);

  Stream<String> watch(SettingKey key);
}

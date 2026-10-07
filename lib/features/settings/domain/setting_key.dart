/// Every key stored in the `settings` table, with its default value.
enum SettingKey {
  currencyCode('PKR'),
  monthStartDay('1'),
  themeMode('system'),
  locale('en'),
  hideBalance('false'),
  lockEnabled('false'),

  /// PBKDF2 of the 4-digit PIN: "iterations:salt:hash" (base64). Device-only.
  lockPin(''),
  lockBiometric('false'),

  /// Seconds away before the app locks again (0 = immediately).
  lockAfter('30'),
  lockFailures('0'),

  /// Epoch millis until which PIN entry is paused after repeated misses.
  lockUntil('0'),
  urduDigits('false'),
  haptics('true'),

  /// First-run welcome finished (or skipped).
  onboardingDone('false'),
  lastAccountId(''),

  /// Weekly automatic backup (spec 3.4).
  autoBackup('false'),
  autoBackupWifiOnly('true'),

  /// The Google account backups go to; empty when Drive isn't connected.
  driveAccount('');

  const SettingKey(this.defaultValue);

  final String defaultValue;

  /// Column value in the `settings` table.
  String get storageKey => switch (this) {
    currencyCode => 'currency_code',
    monthStartDay => 'month_start_day',
    themeMode => 'theme',
    locale => 'locale',
    hideBalance => 'hide_balance',
    lockEnabled => 'lock_enabled',
    lockPin => 'lock_pin',
    lockBiometric => 'lock_biometric',
    lockAfter => 'lock_after',
    lockFailures => 'lock_failures',
    lockUntil => 'lock_until',
    urduDigits => 'urdu_digits',
    haptics => 'haptics',
    onboardingDone => 'onboarding_done',
    lastAccountId => 'last_account_id',
    autoBackup => 'auto_backup',
    autoBackupWifiOnly => 'auto_backup_wifi_only',
    driveAccount => 'drive_account',
  };

  /// Settings that describe this phone, not the user's data: a restore
  /// never brings another phone's values over (no surprise PIN, no
  /// someone else's Google account).
  static const Set<SettingKey> deviceOnly = {
    lockEnabled,
    lockPin,
    lockBiometric,
    lockAfter,
    lockFailures,
    lockUntil,
    driveAccount,
  };
}

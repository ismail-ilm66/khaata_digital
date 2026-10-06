/// Every key stored in the `settings` table, with its default value.
enum SettingKey {
  currencyCode('PKR'),
  monthStartDay('1'),
  themeMode('system'),
  locale('en'),
  hideBalance('false'),
  lockEnabled('false'),
  urduDigits('false'),
  haptics('true'),
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
    urduDigits => 'urdu_digits',
    haptics => 'haptics',
    lastAccountId => 'last_account_id',
    autoBackup => 'auto_backup',
    autoBackupWifiOnly => 'auto_backup_wifi_only',
    driveAccount => 'drive_account',
  };
}

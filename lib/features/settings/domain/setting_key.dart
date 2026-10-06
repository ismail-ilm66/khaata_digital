/// Every key stored in the `settings` table, with its default value.
enum SettingKey {
  currencyCode('PKR'),
  monthStartDay('1'),
  themeMode('system'),
  locale('en'),
  hideBalance('false'),
  lockEnabled('false'),
  urduDigits('false');

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
  };
}

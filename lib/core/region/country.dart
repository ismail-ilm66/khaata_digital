import 'package:meta/meta.dart';

/// Where the user banks: picks the banks and wallets offered when adding an
/// account, and suggests a home currency during onboarding.
@immutable
class Country {
  const Country(this.code, this.name, this.currencyCode);

  /// ISO 3166-1 alpha-2, or [Countries.other]'s "ZZ" / the euro area's "EU".
  final String code;

  /// English name (shown as-is in every language, like the bank names).
  final String name;

  /// Suggested home currency.
  final String currencyCode;

  /// The flag emoji from the two regional-indicator letters; a globe for
  /// "Other".
  String get flag => code == Countries.other.code
      ? '🌍'
      : String.fromCharCodes(code.codeUnits.map((c) => 0x1F1E6 + c - 0x41));

  @override
  bool operator ==(Object other) => other is Country && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Country($code)';
}

abstract final class Countries {
  static const pakistan = Country('PK', 'Pakistan', 'PKR');
  static const other = Country('ZZ', 'Other', 'USD');

  /// Countries with their own bank list, Pakistan first, then by name.
  static const List<Country> all = [
    pakistan,
    Country('AU', 'Australia', 'AUD'),
    Country('BH', 'Bahrain', 'BHD'),
    Country('CA', 'Canada', 'CAD'),
    Country('CN', 'China', 'CNY'),
    Country('EU', 'Europe (euro)', 'EUR'),
    Country('IN', 'India', 'INR'),
    Country('KW', 'Kuwait', 'KWD'),
    Country('MY', 'Malaysia', 'MYR'),
    Country('OM', 'Oman', 'OMR'),
    Country('QA', 'Qatar', 'QAR'),
    Country('SA', 'Saudi Arabia', 'SAR'),
    Country('TR', 'Turkey', 'TRY'),
    Country('AE', 'United Arab Emirates', 'AED'),
    Country('GB', 'United Kingdom', 'GBP'),
    Country('US', 'United States', 'USD'),
    other,
  ];

  /// Euro countries share one list.
  static const Set<String> _euro = {
    'AT', 'BE', 'CY', 'DE', 'EE', 'ES', 'FI', 'FR', 'GR', 'HR', 'IE', 'IT', //
    'LT', 'LU', 'LV', 'MT', 'NL', 'PT', 'SI', 'SK',
  };

  static Country? byCode(String code) {
    final upper = code.toUpperCase();
    final key = _euro.contains(upper) ? 'EU' : upper;
    for (final c in all) {
      if (c.code == key) return c;
    }
    return null;
  }

  /// UTC offsets (minutes, daylight saving included) each country uses.
  static const Map<String, Set<int>> _offsets = {
    'PK': {300},
    'IN': {330},
    'AE': {240},
    'OM': {240},
    'SA': {180},
    'QA': {180},
    'KW': {180},
    'BH': {180},
    'TR': {180},
    'CN': {480},
    'MY': {480},
    'GB': {0, 60},
    'EU': {0, 60, 120, 180},
    'US': {-600, -540, -480, -420, -360, -300, -240},
    'CA': {-480, -420, -360, -300, -240, -210, -180, -150},
    'AU': {480, 525, 570, 600, 630, 660},
  };

  /// Where an offset most likely is, for this app's users.
  static const Map<int, String> _byOffset = {
    300: 'PK',
    330: 'IN',
    240: 'AE',
    180: 'SA',
    480: 'MY',
    0: 'GB',
    60: 'GB',
    120: 'EU',
    570: 'AU',
    600: 'AU',
    630: 'AU',
    660: 'AU',
  };

  /// First run. The phone's region is trusted only when its time zone fits
  /// (many phones in Pakistan say "United States" from an en_US default);
  /// otherwise the time zone decides, then the home currency, then
  /// Pakistan.
  static Country detect({
    String? deviceCountry,
    int? utcOffsetMinutes,
    String? currencyCode,
  }) {
    final region = deviceCountry == null || deviceCountry.isEmpty
        ? null
        : byCode(deviceCountry);
    if (region != null &&
        (utcOffsetMinutes == null ||
            (_offsets[region.code]?.contains(utcOffsetMinutes) ?? true))) {
      return region;
    }
    if (_byOffset[utcOffsetMinutes] case final code?) return byCode(code)!;
    if (utcOffsetMinutes != null && utcOffsetMinutes <= -180) {
      return byCode('US')!;
    }
    if (region != null) return region;
    for (final c in all) {
      if (c != other && c.currencyCode == currencyCode) return c;
    }
    return pakistan;
  }
}

import 'package:meta/meta.dart';

/// An ISO 4217 currency with its display symbol and minor-unit exponent.
@immutable
class Currency {
  const Currency(this.code, this.symbol, this.decimals);

  final String code;
  final String symbol;

  /// Number of minor-unit digits (2 for PKR paisa, 3 for KWD fils).
  final int decimals;

  static const pkr = Currency('PKR', 'Rs', 2);
  static const usd = Currency('USD', r'$', 2);

  /// Currencies Pakistani users most often hold or earn in.
  static const List<Currency> known = [
    pkr,
    usd,
    Currency('EUR', '€', 2),
    Currency('GBP', '£', 2),
    Currency('AED', 'AED', 2),
    Currency('SAR', 'SAR', 2),
    Currency('QAR', 'QAR', 2),
    Currency('OMR', 'OMR', 3),
    Currency('KWD', 'KWD', 3),
    Currency('BHD', 'BHD', 3),
    Currency('CNY', '¥', 2),
    Currency('CAD', r'C$', 2),
    Currency('AUD', r'A$', 2),
    Currency('INR', '₹', 2),
    Currency('TRY', '₺', 2),
    Currency('MYR', 'RM', 2),
  ];

  static final Map<String, Currency> _byCode = {
    for (final c in known) c.code: c,
  };

  /// Informal symbols seen in user data and Hysab Kytab exports.
  static const Map<String, String> _symbolAliases = {
    'rs': 'PKR',
    'rs.': 'PKR',
    'pkr': 'PKR',
    '₨': 'PKR',
    r'$': 'USD',
    'us\$': 'USD',
    'rmb': 'CNY',
    '¥': 'CNY',
    '€': 'EUR',
    '£': 'GBP',
    '₹': 'INR',
    'dhs': 'AED',
    'د.إ': 'AED',
  };

  /// The currency for [code]; unknown codes get the code as their symbol
  /// and 2 decimals so they still format sensibly.
  static Currency of(String code) {
    final upper = code.toUpperCase();
    return _byCode[upper] ?? Currency(upper, upper, 2);
  }

  /// Resolves a free-text symbol or code ("Rs", "$", "AED") to a known
  /// currency, or null if it is not recognised.
  static Currency? fromSymbol(String symbol) {
    final key = symbol.trim().toLowerCase();
    if (key.isEmpty) return null;
    final code = _symbolAliases[key] ?? key.toUpperCase();
    return _byCode[code];
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}

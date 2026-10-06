import 'package:meta/meta.dart';

import 'fixed_point.dart';
import 'money.dart';

/// The pieces of a formatted amount, so UI can style each one separately.
@immutable
class MoneyParts {
  const MoneyParts(this.sign, this.symbol, this.number);

  /// '', '+' or '−' (U+2212).
  final String sign;
  final String symbol;

  /// Grouped digits, e.g. "2,520" or "1,250.50".
  final String number;

  @override
  String toString() => '$sign$symbol $number';
}

/// Display formatting for [Money]: western 3-digit grouping, fraction shown
/// only when non-zero, optional Urdu digits.
@immutable
class MoneyFormat {
  const MoneyFormat({this.urduDigits = false});

  final bool urduDigits;

  static const String minusSign = '−';

  /// Splits [money] into sign, symbol and number. With [signed], positive
  /// amounts get a '+'.
  MoneyParts parts(Money money, {bool signed = false}) {
    final decimals = money.currency.decimals;
    final abs = money.minor.abs();
    final unit = FixedPoint.pow10(decimals);
    final whole = _group((abs ~/ unit).toString());
    final frac = abs % unit;
    var number = frac == 0
        ? whole
        : '$whole.${frac.toString().padLeft(decimals, '0')}';
    if (urduDigits) number = _toUrduDigits(number);

    final sign = money.isNegative
        ? minusSign
        : (signed && money.isPositive ? '+' : '');
    return MoneyParts(sign, money.currency.symbol, number);
  }

  /// "−₨ 2,520" style single string.
  String format(Money money, {bool signed = false}) =>
      parts(money, signed: signed).toString();

  static String _group(String digits) {
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  static String _toUrduDigits(String s) => String.fromCharCodes(
    s.codeUnits.map((c) => c >= 0x30 && c <= 0x39 ? 0x06F0 + c - 0x30 : c),
  );
}

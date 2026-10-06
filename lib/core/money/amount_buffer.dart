import 'package:meta/meta.dart';

import 'currency.dart';
import 'fixed_point.dart';
import 'money.dart';

/// Keys on the in-app amount keypad.
enum KeypadKey {
  d0,
  d1,
  d2,
  d3,
  d4,
  d5,
  d6,
  d7,
  d8,
  d9,
  decimal,
  backspace,
  clear;

  static KeypadKey digit(int d) => KeypadKey.values[d];

  /// The digit this key types, or null for non-digit keys.
  int? get digitValue => index <= 9 ? index : null;
}

/// The text being typed on the amount keypad, as an immutable value.
///
/// Guards that a typed amount is always a valid [Money]: no leading zeros,
/// one decimal point, at most the currency's decimals, and a sane length.
@immutable
class AmountBuffer {
  const AmountBuffer([this.text = '']);

  /// Pre-fills from a stored amount (editing), e.g. 252050 paisa → "2520.5".
  factory AmountBuffer.fromMoney(Money money) {
    final plain = FixedPoint.format(money.minor.abs(), money.currency.decimals);
    if (!plain.contains('.')) return AmountBuffer(plain);
    final trimmed = plain.replaceFirst(RegExp(r'0+$'), '');
    return AmountBuffer(
      trimmed.endsWith('.')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed,
    );
  }

  final String text;

  static const int maxIntegerDigits = 12;

  bool get isEmpty => text.isEmpty;

  AmountBuffer apply(KeypadKey key, Currency currency) {
    switch (key) {
      case KeypadKey.clear:
        return const AmountBuffer();
      case KeypadKey.backspace:
        return text.isEmpty
            ? this
            : AmountBuffer(text.substring(0, text.length - 1));
      case KeypadKey.decimal:
        if (currency.decimals == 0 || text.contains('.')) return this;
        return AmountBuffer(text.isEmpty ? '0.' : '$text.');
      default:
        final digit = key.digitValue!;
        final dot = text.indexOf('.');
        if (dot >= 0) {
          if (text.length - dot - 1 >= currency.decimals) return this;
        } else {
          if (text == '0') return AmountBuffer('$digit');
          if (text.length >= maxIntegerDigits) return this;
        }
        if (text.isEmpty && digit == 0) return const AmountBuffer('0');
        return AmountBuffer('$text$digit');
    }
  }

  /// The typed amount, or zero while empty.
  Money toMoney(Currency currency) =>
      Money.parse(text.isEmpty ? '0' : text, currency) ?? Money.zero(currency);

  @override
  bool operator ==(Object other) => other is AmountBuffer && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'AmountBuffer($text)';
}

import 'package:meta/meta.dart';

import 'currency.dart';
import 'fixed_point.dart';

/// An exact amount of money in integer minor units (paisa for PKR).
///
/// Never construct money from a `double`: parse strings with [Money.parse]
/// or work in [minor] units directly.
@immutable
class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);

  const Money.zero(this.currency) : minor = 0;

  /// Builds money from whole major units (e.g. rupees).
  Money.major(int major, this.currency)
    : minor = major * FixedPoint.pow10(currency.decimals);

  final int minor;
  final Currency currency;

  /// Parses user or file input ("1,250.5", "۱۲۵۰", "-2520.0").
  /// See [FixedPoint.parse] for accepted formats and [round].
  static Money? parse(String input, Currency currency, {bool round = false}) {
    final minor = FixedPoint.parse(input, currency.decimals, round: round);
    return minor == null ? null : Money(minor, currency);
  }

  /// FX rates are stored as micros: 1 USD = 282.5 PKR → 282500000.
  static const int rateScale = 6;

  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;
  bool get isPositive => minor > 0;

  Money operator +(Money other) => Money(minor + _same(other).minor, currency);
  Money operator -(Money other) => Money(minor - _same(other).minor, currency);
  Money operator -() => Money(-minor, currency);
  Money abs() => isNegative ? -this : this;

  bool operator <(Money other) => minor < _same(other).minor;
  bool operator >(Money other) => minor > _same(other).minor;
  bool operator <=(Money other) => minor <= _same(other).minor;
  bool operator >=(Money other) => minor >= _same(other).minor;

  /// Converts to [target] at [rateMicros] (target units per one unit of this
  /// currency, scaled by 10^6), rounding half away from zero.
  Money convert(int rateMicros, Currency target) {
    final numerator =
        BigInt.from(minor) *
        BigInt.from(rateMicros) *
        BigInt.from(FixedPoint.pow10(target.decimals));
    final denominator =
        BigInt.from(FixedPoint.pow10(currency.decimals)) *
        BigInt.from(FixedPoint.pow10(rateScale));
    return Money(_divRound(numerator, denominator), target);
  }

  static Money sum(Iterable<Money> values, Currency currency) =>
      values.fold(Money.zero(currency), (a, b) => a + b);

  Money _same(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Currency mismatch: ${currency.code} vs ${other.currency.code}',
      );
    }
    return other;
  }

  static int _divRound(BigInt n, BigInt d) {
    final q = n ~/ d;
    final r = (n.remainder(d) * BigInt.two).abs();
    if (r < d.abs()) return q.toInt();
    return (n.isNegative != d.isNegative ? q - BigInt.one : q + BigInt.one)
        .toInt();
  }

  @override
  int compareTo(Money other) => minor.compareTo(_same(other).minor);

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() =>
      '${FixedPoint.format(minor, currency.decimals)} $currency';
}

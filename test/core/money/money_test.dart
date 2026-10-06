import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/fixed_point.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/money/money_format.dart';

const pkr = Currency.pkr;
const usd = Currency.usd;
final kwd = Currency.of('KWD');

void main() {
  group('Money arithmetic', () {
    test('adds and subtracts exactly (no float drift)', () {
      // 0.1 + 0.2 in floating point is 0.30000000000000004.
      final a = Money.parse('0.1', pkr)!;
      final b = Money.parse('0.2', pkr)!;
      expect((a + b).minor, 30);
      expect((a - b).minor, -10);
    });

    test('summing 10,000 × Rs0.01 is exactly Rs100', () {
      final sum = Money.sum(List.filled(10000, const Money(1, pkr)), pkr);
      expect(sum, Money.major(100, pkr));
    });

    test('rejects mixing currencies', () {
      expect(
        () => const Money(1, pkr) + const Money(1, usd),
        throwsArgumentError,
      );
      expect(
        () => const Money(1, pkr).compareTo(const Money(1, usd)),
        throwsArgumentError,
      );
    });

    test('sign helpers and comparisons', () {
      const m = Money(-500, pkr);
      expect(m.isNegative, isTrue);
      expect(m.abs(), const Money(500, pkr));
      expect(-m, const Money(500, pkr));
      expect(const Money(1, pkr) > const Money(0, pkr), isTrue);
      expect(const Money.zero(pkr).isZero, isTrue);
    });
  });

  group('Money.convert', () {
    test('USD → PKR at 282.5', () {
      final rate = FixedPoint.parse('282.5', Money.rateScale)!;
      expect(Money.major(100, usd).convert(rate, pkr), Money.major(28250, pkr));
    });

    test('rounds half away from zero, both signs', () {
      // Rs0.01 × 0.5 = 0.005 → rounds to 0.01
      expect(const Money(1, pkr).convert(500000, pkr).minor, 1);
      expect(const Money(-1, pkr).convert(500000, pkr).minor, -1);
      expect(const Money(1, pkr).convert(499999, pkr).minor, 0);
    });

    test('handles differing decimal places (2 → 3)', () {
      // 1000 PKR → KWD at 0.0011 = 1.100 KWD = 1100 fils
      expect(Money.major(1000, pkr).convert(1100, kwd), Money(1100, kwd));
    });

    test('does not overflow on very large amounts', () {
      final huge = Money.major(9000000000000, pkr); // 9 trillion rupees
      expect(huge.convert(1000000, pkr), huge);
    });
  });

  group('MoneyFormat', () {
    const f = MoneyFormat();

    test('groups thousands and hides a zero fraction', () {
      expect(f.format(Money.major(2520, pkr)), 'Rs 2,520');
      expect(f.format(Money.major(1234567, pkr)), 'Rs 1,234,567');
      expect(f.format(const Money(5, pkr)), 'Rs 0.05');
      expect(f.format(const Money(125050, pkr)), 'Rs 1,250.50');
    });

    test('negative uses a true minus; signed adds plus', () {
      expect(f.parts(const Money(-252000, pkr)).sign, MoneyFormat.minusSign);
      expect(f.parts(const Money(100, pkr), signed: true).sign, '+');
      expect(f.parts(const Money.zero(pkr), signed: true).sign, '');
    });

    test('Urdu digits', () {
      const urdu = MoneyFormat(urduDigits: true);
      expect(urdu.parts(const Money(125050, pkr)).number, '۱,۲۵۰.۵۰');
    });

    test('3-decimal currencies', () {
      expect(f.parts(Money(1100, kwd)).number, '1.100');
    });
  });

  group('Currency', () {
    test('lookup by code is case-insensitive with a sensible fallback', () {
      expect(Currency.of('usd'), usd);
      final unknown = Currency.of('xyz');
      expect(unknown.symbol, 'XYZ');
      expect(unknown.decimals, 2);
    });

    test('resolves informal symbols', () {
      expect(Currency.fromSymbol('Rs'), pkr);
      expect(Currency.fromSymbol(r'$'), usd);
      expect(Currency.fromSymbol('RMB')!.code, 'CNY');
      expect(Currency.fromSymbol('AED')!.code, 'AED');
      expect(Currency.fromSymbol('???'), isNull);
      expect(Currency.fromSymbol(''), isNull);
    });
  });
}

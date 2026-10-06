import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/fixed_point.dart';

void main() {
  group('FixedPoint.parse', () {
    final cases = <String, int?>{
      '0': 0,
      '12': 1200,
      '12.5': 1250,
      '12.05': 1205,
      '.5': 50,
      '1,234,567.89': 123456789,
      '-2520.0': -252000,
      '−2,520': -252000,
      '+15': 1500,
      ' 42 ': 4200,
      '۱۲۳۴٫۵۰': 123450, // Urdu digits + Arabic decimal point
      '١٢': 1200, // Arabic-Indic digits
      '1.5E3': 150000,
      '2.5e-1': 25,
      '': null,
      '-': null,
      '.': null,
      'abc': null,
      '12a': null,
      '1.2.3': null,
      '12.345': null, // too many decimals without rounding
      '1234567890123456': null, // over 15 integer digits
    };
    cases.forEach((input, expected) {
      test('"$input" → $expected', () {
        expect(FixedPoint.parse(input, 2), expected);
      });
    });

    test('trailing zeros beyond scale are not "extra precision"', () {
      expect(FixedPoint.parse('12.3400', 2), 1234);
    });

    test('rounds half away from zero when allowed', () {
      expect(FixedPoint.parse('2519.995', 2, round: true), 252000);
      expect(FixedPoint.parse('2519.994', 2, round: true), 251999);
      expect(FixedPoint.parse('-2519.995', 2, round: true), -252000);
      expect(FixedPoint.parse('0.004999', 2, round: true), 0);
    });

    test('supports scale 0 and 6', () {
      expect(FixedPoint.parse('7', 0), 7);
      expect(FixedPoint.parse('282.5', 6), 282500000);
    });
  });

  group('FixedPoint.format', () {
    test('round-trips with parse', () {
      for (final v in [0, 1, -1, 5, 100, 123456789, -252000]) {
        expect(FixedPoint.parse(FixedPoint.format(v, 2), 2), v);
      }
    });

    test('pads the fraction', () {
      expect(FixedPoint.format(5, 2), '0.05');
      expect(FixedPoint.format(-1205, 2), '-12.05');
      expect(FixedPoint.format(7, 0), '7');
    });
  });
}

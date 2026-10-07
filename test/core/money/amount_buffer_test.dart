import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/amount_buffer.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';

const pkr = Currency.pkr;

AmountBuffer type(
  String keys, {
  Currency currency = pkr,
  AmountBuffer start = const AmountBuffer(),
}) {
  var b = start;
  for (final ch in keys.split('')) {
    final key = switch (ch) {
      '.' => KeypadKey.decimal,
      '<' => KeypadKey.backspace,
      'C' => KeypadKey.clear,
      _ => KeypadKey.digit(int.parse(ch)),
    };
    b = b.apply(key, currency);
  }
  return b;
}

void main() {
  test('types digits and a decimal point', () {
    expect(type('2520.5').text, '2520.5');
    expect(type('2520.5').toMoney(pkr), const Money(252050, pkr));
  });

  test('no leading zeros; a leading point becomes 0.', () {
    expect(type('0007').text, '7');
    expect(type('.5').text, '0.5');
    expect(type('0').text, '0');
  });

  test('one decimal point, at most the currency decimals', () {
    expect(type('1.2.3').text, '1.23');
    expect(type('1.234').text, '1.23');
    expect(type('1.5', currency: Currency.of('KWD')).text, '1.5');
    expect(type('1.2345', currency: Currency.of('KWD')).text, '1.234');
  });

  test('backspace and clear', () {
    expect(type('123<').text, '12');
    expect(type('<').text, '');
    expect(type('123C').text, '');
  });

  test('caps the integer part', () {
    expect(type('9' * 20).text, '9' * AmountBuffer.maxIntegerDigits);
  });

  test('empty is zero', () {
    expect(const AmountBuffer().toMoney(pkr), const Money.zero(pkr));
  });

  test('fromMoney round-trips stored amounts for editing', () {
    for (final minor in [252000, 252050, 252005, 5, 100]) {
      final m = Money(minor, pkr);
      expect(AmountBuffer.fromMoney(m).toMoney(pkr), m, reason: '$minor');
    }
    expect(AmountBuffer.fromMoney(const Money(252000, pkr)).text, '2520');
    expect(AmountBuffer.fromMoney(const Money(252050, pkr)).text, '2520.5');
  });

  group('typed (system keyboard)', () {
    String? read(String raw, [Currency c = pkr]) =>
        AmountBuffer.typed(raw, c)?.text;

    test('reads plain, grouped and Urdu digits', () {
      expect(read('2520.5'), '2520.5');
      expect(read('12,500'), '12500');
      expect(read('۱۲۵۰۰٫۵'), '12500.5');
      expect(read(''), '');
    });

    test('same rules as the keypad', () {
      expect(read('0007'), '7');
      expect(read('.5'), '0.5');
      expect(read('1.'), '1.');
      expect(read('1.2.3'), isNull);
      expect(read('1.234'), isNull);
      expect(read('12a'), isNull);
      expect(read('-5'), isNull);
      expect(read('1' * 13), isNull);
      expect(read('1.5', const Currency('JPY', '¥', 0)), isNull);
    });
  });
}

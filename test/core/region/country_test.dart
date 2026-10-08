import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/region/country.dart';
import 'package:khaata_digital/features/accounts/domain/account_presets.dart';

void main() {
  group('detect', () {
    String code({String? region, int? offset, String? currency}) =>
        Countries.detect(
          deviceCountry: region,
          utcOffsetMinutes: offset,
          currencyCode: currency,
        ).code;

    test('trusts the phone region when its time zone fits', () {
      expect(code(region: 'GB', offset: 60), 'GB');
      expect(code(region: 'AE', offset: 240), 'AE');
      expect(code(region: 'PK', offset: 300), 'PK');
      expect(code(region: 'DE', offset: 120), 'EU', reason: 'euro area');
    });

    test('an en_US default in Pakistan time is Pakistan', () {
      expect(code(region: 'US', offset: 300), 'PK');
    });

    test('no usable region: time zone, then currency, then Pakistan', () {
      expect(code(offset: 330), 'IN');
      expect(code(region: 'BR', offset: -180), 'US');
      expect(code(currency: 'SAR'), 'SA');
      expect(code(), 'PK');
    });
  });

  test('flags come from the code', () {
    expect(Countries.pakistan.flag, '🇵🇰');
    expect(Countries.byCode('gb')!.flag, '🇬🇧');
    expect(Countries.other.flag, '🌍');
  });

  group('presets per country', () {
    List<String> names(String c) =>
        AccountPresets.forCountry(c).map((p) => p.name).toList();

    test('Cash first, the country\'s own, then international', () {
      final gb = names('GB');
      expect(gb.first, 'Cash');
      expect(gb, containsAll(['Barclays', 'Monzo']));
      expect(gb, isNot(contains('HBL')));
      expect(gb.sublist(gb.length - 3), ['PayPal', 'Wise', 'Payoneer']);
      expect(names('PK'), containsAll(['HBL', 'Easypaisa']));
      expect(names('ZZ'), ['Cash', 'PayPal', 'Wise', 'Payoneer']);
    });

    test('every country in the list has its own banks', () {
      for (final c in Countries.all) {
        if (c == Countries.other) continue;
        expect(
          AccountPresets.forCountry(c.code).length,
          greaterThan(4),
          reason: c.name,
        );
      }
    });

    test('keys are unique, and old accounts still find their badge', () {
      final keys = AccountPresets.all.map((p) => p.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      expect(AccountPresets.byKey('hbl')!.name, 'HBL');
      expect(AccountPresets.match('Al Rajhi')!.key, 'alrajhi');
    });
  });
}

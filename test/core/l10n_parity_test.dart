import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/l10n/gen/app_localizations.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/locale_cubit.dart';

Set<String> _messageKeys(String path) {
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  test('Urdu ARB has exactly the same message keys as English', () {
    final en = _messageKeys('lib/core/l10n/arb/app_en.arb');
    final ur = _messageKeys('lib/core/l10n/arb/app_ur.arb');
    expect(ur.difference(en), isEmpty, reason: 'extra keys in ur');
    expect(en.difference(ur), isEmpty, reason: 'missing keys in ur');
  });

  test('app supports exactly the locales LocaleCubit offers', () {
    expect(
      AppLocalizations.supportedLocales.toSet(),
      LocaleCubit.supported.toSet(),
    );
  });
}

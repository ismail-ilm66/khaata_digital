import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../domain/setting_key.dart';
import '../../domain/settings_repository.dart';
import 'setting_cubit.dart';

@lazySingleton
class LocaleCubit extends SettingCubit<Locale> {
  LocaleCubit(SettingsRepository repository)
    : super(repository, SettingKey.locale, english);

  static const Locale english = Locale('en');
  static const Locale urdu = Locale('ur');
  static const List<Locale> supported = [english, urdu];

  @override
  Locale decode(String stored) => supported.firstWhere(
    (l) => l.languageCode == stored,
    orElse: () => english,
  );

  @override
  String encode(Locale value) => value.languageCode;
}

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../domain/setting_key.dart';
import '../../domain/settings_repository.dart';
import 'setting_cubit.dart';

@lazySingleton
class ThemeCubit extends SettingCubit<ThemeMode> {
  ThemeCubit(SettingsRepository repository)
    : super(repository, SettingKey.themeMode, ThemeMode.system);

  @override
  ThemeMode decode(String stored) =>
      ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;

  @override
  String encode(ThemeMode value) => value.name;
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/features/settings/data/settings_repository_impl.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/theme_cubit.dart';

import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl repo;

  setUp(() {
    db = testDb();
    repo = SettingsRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('unset keys read their defaults', () async {
    for (final key in SettingKey.values) {
      expect(await repo.read(key), key.defaultValue);
    }
  });

  group('ThemeCubit', () {
    blocTest<ThemeCubit, ThemeMode>(
      'starts at system and emits the chosen mode',
      build: () => ThemeCubit(repo),
      act: (c) async {
        await c.set(ThemeMode.dark);
        await c.set(ThemeMode.light);
      },
      expect: () => [ThemeMode.dark, ThemeMode.light],
    );

    test('persists across instances', () async {
      await ThemeCubit(repo).set(ThemeMode.dark);
      final reloaded = ThemeCubit(repo);
      await reloaded.load();
      expect(reloaded.state, ThemeMode.dark);
    });

    test('falls back to system on an unknown stored value', () async {
      await repo.write(SettingKey.themeMode, 'neon');
      final c = ThemeCubit(repo);
      await c.load();
      expect(c.state, ThemeMode.system);
    });
  });

  group('LocaleCubit', () {
    blocTest<LocaleCubit, Locale>(
      'emits Urdu then English',
      build: () => LocaleCubit(repo),
      act: (c) async {
        await c.set(LocaleCubit.urdu);
        await c.set(LocaleCubit.english);
      },
      expect: () => [LocaleCubit.urdu, LocaleCubit.english],
    );

    test('persists across instances', () async {
      await LocaleCubit(repo).set(LocaleCubit.urdu);
      final reloaded = LocaleCubit(repo);
      await reloaded.load();
      expect(reloaded.state, LocaleCubit.urdu);
    });
  });
}

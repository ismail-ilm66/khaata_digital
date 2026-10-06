import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/theme_cubit.dart';

void main() {
  group('ThemeCubit', () {
    test('defaults to system', () {
      expect(ThemeCubit().state, ThemeMode.system);
    });

    blocTest<ThemeCubit, ThemeMode>(
      'emits the chosen mode',
      build: ThemeCubit.new,
      act: (c) => c
        ..setMode(ThemeMode.dark)
        ..setMode(ThemeMode.light),
      expect: () => [ThemeMode.dark, ThemeMode.light],
    );
  });

  group('LocaleCubit', () {
    test('defaults to English', () {
      expect(LocaleCubit().state, LocaleCubit.english);
    });

    blocTest<LocaleCubit, Locale>(
      'emits Urdu then English',
      build: LocaleCubit.new,
      act: (c) => c
        ..setLocale(LocaleCubit.urdu)
        ..setLocale(LocaleCubit.english),
      expect: () => [LocaleCubit.urdu, LocaleCubit.english],
    );
  });
}

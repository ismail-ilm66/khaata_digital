import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import 'cubit/locale_cubit.dart';
import 'cubit/theme_cubit.dart';

/// More/Settings tab (spec 3.2 #10). M0 ships only theme + language so both
/// themes and both locales can be verified on device; the rest lands in M6.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.settingsTheme, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) => SegmentedButton<ThemeMode>(
              key: const Key('themeSelector'),
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) =>
                  context.read<ThemeCubit>().setMode(s.single),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsLanguage, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) => SegmentedButton<Locale>(
              key: const Key('languageSelector'),
              segments: [
                ButtonSegment(
                  value: LocaleCubit.english,
                  label: Text(l10n.languageEnglish),
                ),
                ButtonSegment(
                  value: LocaleCubit.urdu,
                  label: Text(l10n.languageUrdu),
                ),
              ],
              selected: {locale},
              onSelectionChanged: (s) =>
                  context.read<LocaleCubit>().setLocale(s.single),
            ),
          ),
        ],
      ),
    );
  }
}

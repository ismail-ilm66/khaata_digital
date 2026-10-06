import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/segmented_picker.dart';
import '../../../core/widgets/surface_card.dart';
import 'cubit/locale_cubit.dart';
import 'cubit/theme_cubit.dart';
import '../../../core/widgets/app_icons.dart';

/// More/Settings tab (spec 3.2 #10). Appearance for now; the rest of the
/// settings land in M6.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageScaffold(
      title: l10n.navMore,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          sliver: SliverList.list(
            children: [
              Section(
                title: l10n.settingsAppearance,
                child: SurfaceCard(
                  children: [
                    SettingTile(
                      icon: AppIcons.theme.filled,
                      title: l10n.settingsTheme,
                      control: BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, mode) => SegmentedPicker<ThemeMode>(
                          key: const Key('themeSelector'),
                          value: mode,
                          onChanged: context.read<ThemeCubit>().set,
                          options: [
                            PickerOption(ThemeMode.system, l10n.themeSystem),
                            PickerOption(ThemeMode.light, l10n.themeLight),
                            PickerOption(ThemeMode.dark, l10n.themeDark),
                          ],
                        ),
                      ),
                    ),
                    SettingTile(
                      icon: AppIcons.language.filled,
                      title: l10n.settingsLanguage,
                      control: BlocBuilder<LocaleCubit, Locale>(
                        builder: (context, locale) => SegmentedPicker<Locale>(
                          key: const Key('languageSelector'),
                          value: locale,
                          onChanged: context.read<LocaleCubit>().set,
                          options: [
                            PickerOption(
                              LocaleCubit.english,
                              l10n.languageEnglish,
                            ),
                            PickerOption(LocaleCubit.urdu, l10n.languageUrdu),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

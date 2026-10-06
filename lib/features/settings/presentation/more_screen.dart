import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/segmented_picker.dart';
import '../../../core/widgets/surface_card.dart';
import '../../import_export/presentation/export_sheet.dart';
import 'cubit/locale_cubit.dart';
import 'cubit/preference_cubits.dart';
import 'cubit/theme_cubit.dart';
import 'month_start_label.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/app_switch.dart';

/// More/Settings tab (spec 3.2 #10). Accounts and appearance for now; the
/// rest of the settings land with their milestones.
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
                title: l10n.yourMoney,
                child: SurfaceCard(
                  children: [
                    SettingTile(
                      key: const Key('accountsTile'),
                      icon: AppIcons.accounts.filled,
                      title: l10n.accounts,
                      subtitle: l10n.accountsSubtitle,
                      onTap: () => context.push(Routes.accounts),
                    ),
                    SettingTile(
                      key: const Key('budgetsTile'),
                      icon: AppIcons.budgets.filled,
                      title: l10n.budgets,
                      subtitle: l10n.budgetsSubtitle,
                      onTap: () => context.push(Routes.budgets),
                    ),
                    SettingTile(
                      key: const Key('peopleTile'),
                      icon: AppIcons.people.filled,
                      title: l10n.people,
                      subtitle: l10n.peopleSubtitle,
                      onTap: () => context.push(Routes.people),
                    ),
                    SettingTile(
                      key: const Key('recurringTile'),
                      icon: AppIcons.recurring.filled,
                      title: l10n.recurring,
                      subtitle: l10n.recurringSubtitle,
                      onTap: () => context.push(Routes.recurring),
                    ),
                  ],
                ),
              ),
              Section(
                title: l10n.settingsData,
                child: SurfaceCard(
                  children: [
                    SettingTile(
                      key: const Key('backupTile'),
                      icon: AppIcons.backup.filled,
                      title: l10n.backupTitle,
                      subtitle: l10n.backupTileHint,
                      onTap: () => context.push(Routes.backup),
                    ),
                    SettingTile(
                      key: const Key('importTile'),
                      icon: AppIcons.importFile,
                      title: l10n.importTile,
                      subtitle: l10n.importTileHint,
                      onTap: () => context.push(Routes.importData),
                    ),
                    SettingTile(
                      key: const Key('exportTile'),
                      icon: AppIcons.download,
                      title: l10n.exportEverything,
                      subtitle: l10n.exportAllSubtitle,
                      onTap: () => showExportSheet(context),
                    ),
                  ],
                ),
              ),
              Section(
                title: l10n.settingsGeneral,
                child: SurfaceCard(
                  children: [
                    BlocBuilder<HapticsCubit, bool>(
                      bloc: getIt<HapticsCubit>(),
                      builder: (context, on) => SettingTile(
                        key: const Key('hapticsTile'),
                        icon: AppIcons.haptics,
                        title: l10n.haptics,
                        subtitle: l10n.hapticsHint,
                        trailing: AppSwitch(
                          value: on,
                          onChanged: getIt<HapticsCubit>().set,
                        ),
                      ),
                    ),
                    BlocBuilder<BudgetCycleCubit, BudgetCycle>(
                      builder: (context, cycle) => SettingTile(
                        key: const Key('monthStartTile'),
                        icon: AppIcons.monthStart.filled,
                        title: l10n.monthStart,
                        subtitle: l10n.monthStartHint,
                        trailing: Text(
                          monthStartLabel(context, cycle),
                          style: context.text.titleSmall,
                        ),
                        onTap: () async {
                          final chosen = await pickOne<BudgetCycle>(
                            context,
                            title: l10n.monthStart,
                            selected: cycle,
                            items: [
                              for (final c in BudgetCycle.choices)
                                PickItem(
                                  value: c,
                                  title: monthStartLabel(context, c),
                                ),
                            ],
                          );
                          if (chosen != null && context.mounted) {
                            await context.read<BudgetCycleCubit>().set(chosen);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
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

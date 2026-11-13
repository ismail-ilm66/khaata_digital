import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/di/injection.dart';
import '../../../core/money/currency.dart';
import '../../../core/region/country.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/segmented_picker.dart';
import '../../../core/widgets/surface_card.dart';
import '../../security/presentation/lock_cubit.dart';
import '../../security/presentation/reveal_balances.dart';
import 'country_picker.dart';
import 'cubit/locale_cubit.dart';
import 'cubit/preference_cubits.dart';
import 'cubit/theme_cubit.dart';
import 'month_start_label.dart';

/// More → Settings: what is set once and then left alone. Money (home
/// currency, country, when the month starts), privacy (hidden balances,
/// app lock) and appearance (theme, language, vibration on taps).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageScaffold(
      title: l10n.settingsTitle,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          sliver: SliverList.list(
            children: [
              Section(
                title: l10n.settingsMoney,
                child: SurfaceCard(
                  children: [
                    BlocBuilder<CurrencyCubit, Currency>(
                      builder: (context, currency) => SettingTile(
                        key: const Key('currencyTile'),
                        icon: AppIcons.accounts.filled,
                        title: l10n.homeCurrency,
                        subtitle: l10n.homeCurrencyHint,
                        trailing: Text(
                          currency.code,
                          style: context.text.titleSmall,
                        ),
                        onTap: () async {
                          final c = await pickOne<Currency>(
                            context,
                            title: l10n.homeCurrency,
                            selected: currency,
                            items: [
                              for (final c in Currency.known)
                                PickItem(
                                  value: c,
                                  title: c.code,
                                  subtitle: c.symbol == c.code
                                      ? null
                                      : c.symbol,
                                ),
                            ],
                          );
                          if (c != null && context.mounted) {
                            await context.read<CurrencyCubit>().set(c);
                          }
                        },
                      ),
                    ),
                    BlocBuilder<CountryCubit, Country>(
                      builder: (context, country) => SettingTile(
                        key: const Key('countryTile'),
                        icon: AppIcons.globe,
                        title: l10n.country,
                        subtitle: l10n.countryHint,
                        trailing: CountryFlag(country),
                        onTap: () async {
                          final c = await pickCountry(context, country);
                          if (c != null && context.mounted) {
                            await context.read<CountryCubit>().set(c);
                          }
                        },
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
                            searchable: false,
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
                title: l10n.settingsPrivacy,
                child: SurfaceCard(
                  children: [
                    BlocBuilder<HideBalanceCubit, BalancePrivacy>(
                      builder: (context, privacy) => SettingTile(
                        key: const Key('hideBalanceTile'),
                        icon: AppIcons.hide,
                        title: l10n.hideBalances,
                        subtitle: l10n.hideBalancesHint,
                        trailing: AppSwitch(
                          value: privacy.always,
                          onChanged: (on) => setHideBalances(context, on),
                        ),
                      ),
                    ),
                    BlocBuilder<LockCubit, AppLockState>(
                      bloc: getIt<LockCubit>(),
                      builder: (context, lock) => SettingTile(
                        key: const Key('appLockTile'),
                        icon: AppIcons.lock,
                        title: l10n.appLock,
                        subtitle: l10n.appLockHint,
                        trailing: Text(
                          lock.enabled ? l10n.on : l10n.off,
                          style: context.text.titleSmall,
                        ),
                        onTap: () => context.push(Routes.appLock),
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

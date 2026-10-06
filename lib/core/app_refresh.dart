import 'package:injectable/injectable.dart';

import '../features/recurring/data/recurring_maintenance.dart';
import '../features/recurring/domain/recurring_rule.dart';
import '../features/settings/presentation/cubit/locale_cubit.dart';
import '../features/settings/presentation/cubit/preference_cubits.dart';
import '../features/settings/presentation/cubit/theme_cubit.dart';

/// Re-reads app-wide state from the database: on startup, and after a
/// restore has replaced settings and recurring rules underneath the app.
@lazySingleton
class AppRefresh {
  AppRefresh(
    this._theme,
    this._locale,
    this._hideBalance,
    this._cycle,
    this._currency,
    this._haptics,
    this._recurring,
    this._reminders,
  );

  final ThemeCubit _theme;
  final LocaleCubit _locale;
  final HideBalanceCubit _hideBalance;
  final BudgetCycleCubit _cycle;
  final CurrencyCubit _currency;
  final HapticsCubit _haptics;
  final RecurringRepository _recurring;
  final ReminderScheduler _reminders;

  Future<void> preferences() => Future.wait([
    _theme.load(),
    _locale.load(),
    _hideBalance.load(),
    _cycle.load(),
    _currency.load(),
    _haptics.load(),
  ]);

  /// Creates recurring entries that fell due and refreshes reminders.
  Future<void> recurring() => runRecurringMaintenance(_recurring, _reminders);

  Future<void> all() async {
    await preferences();
    await recurring();
  }
}

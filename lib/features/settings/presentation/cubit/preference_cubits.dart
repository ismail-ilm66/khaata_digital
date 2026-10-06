import 'package:injectable/injectable.dart';

import '../../../../core/dates/budget_cycle.dart';
import '../../../../core/money/currency.dart';
import '../../domain/setting_key.dart';
import '../../domain/settings_repository.dart';
import 'setting_cubit.dart';

/// Hides balances behind dots (the eye toggle on Home).
@lazySingleton
class HideBalanceCubit extends SettingCubit<bool> {
  HideBalanceCubit(SettingsRepository r)
    : super(r, SettingKey.hideBalance, false);

  @override
  bool decode(String stored) => stored == 'true';

  @override
  String encode(bool value) => '$value';

  Future<void> toggle() => set(!state);
}

/// The budget cycle built from the "month starts on day N" setting.
@lazySingleton
class BudgetCycleCubit extends SettingCubit<BudgetCycle> {
  BudgetCycleCubit(SettingsRepository r)
    : super(r, SettingKey.monthStartDay, const BudgetCycle.calendar());

  @override
  BudgetCycle decode(String stored) {
    final day = int.tryParse(stored) ?? 1;
    final valid =
        day >= BudgetCycle.minStartDay && day <= BudgetCycle.maxStartDay;
    return valid ? BudgetCycle(day) : const BudgetCycle.calendar();
  }

  @override
  String encode(BudgetCycle value) => '${value.startDay}';
}

/// The home currency used for summaries.
@lazySingleton
class CurrencyCubit extends SettingCubit<Currency> {
  CurrencyCubit(SettingsRepository r)
    : super(r, SettingKey.currencyCode, Currency.pkr);

  @override
  Currency decode(String stored) => Currency.of(stored);

  @override
  String encode(Currency value) => value.code;
}

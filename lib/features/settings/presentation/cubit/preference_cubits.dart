import 'package:injectable/injectable.dart';

import '../../../../core/dates/budget_cycle.dart';
import '../../../../core/feedback/haptics.dart';
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

/// Haptic feedback on or off; keeps [Haptics.enabled] in step.
@lazySingleton
class HapticsCubit extends SettingCubit<bool> {
  HapticsCubit(SettingsRepository r) : super(r, SettingKey.haptics, true) {
    stream.listen((on) => Haptics.enabled = on);
  }

  @override
  bool decode(String stored) => stored != 'false';

  @override
  String encode(bool value) => '$value';
}

/// The budget cycle built from the "month starts on…" setting.
@lazySingleton
class BudgetCycleCubit extends SettingCubit<BudgetCycle> {
  BudgetCycleCubit(SettingsRepository r)
    : super(r, SettingKey.monthStartDay, const BudgetCycle.calendar());

  @override
  BudgetCycle decode(String stored) => BudgetCycle.fromStorage(stored);

  @override
  String encode(BudgetCycle value) => value.toStorage();
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

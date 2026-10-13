import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/dates/budget_cycle.dart';
import '../../../../core/feedback/haptics.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/region/country.dart';
import '../../domain/setting_key.dart';
import '../../domain/settings_repository.dart';
import 'setting_cubit.dart';

/// Whether balances show as dots right now, and the saved choice.
@immutable
class BalancePrivacy {
  const BalancePrivacy({required this.masked, required this.always});

  /// Hidden on screen at this moment.
  final bool masked;

  /// More → "Hide balances": every start (and every re-lock) begins hidden.
  final bool always;

  @override
  bool operator ==(Object other) =>
      other is BalancePrivacy &&
      other.masked == masked &&
      other.always == always;

  @override
  int get hashCode => Object.hash(masked, always);
}

/// Hides balances behind dots. The setting is saved; the eye on Home only
/// shows or hides them for this session, so a quick peek never turns the
/// setting off.
@lazySingleton
class HideBalanceCubit extends Cubit<BalancePrivacy> {
  HideBalanceCubit(this._settings)
    : super(const BalancePrivacy(masked: false, always: false));

  final SettingsRepository _settings;

  /// Loads the saved choice; call once at startup.
  Future<void> load() async {
    final always = await _settings.read(SettingKey.hideBalance) == 'true';
    emit(BalancePrivacy(masked: always, always: always));
  }

  /// The eye: this session only.
  void show() => emit(BalancePrivacy(masked: false, always: state.always));
  void hide() => emit(BalancePrivacy(masked: true, always: state.always));

  /// The setting: saved, and applied at once.
  Future<void> setAlways(bool on) async {
    emit(BalancePrivacy(masked: on, always: on));
    await _settings.write(SettingKey.hideBalance, '$on');
  }

  /// The app locked again: back to hidden if that's the setting.
  void relocked() {
    if (state.always) hide();
  }
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

/// Which country's banks and wallets the add-account picker offers. Until
/// the user picks one, it follows the phone (see [Countries.detect]).
@lazySingleton
class CountryCubit extends SettingCubit<Country> {
  CountryCubit(SettingsRepository r, this._currency)
    : super(r, SettingKey.country, Countries.pakistan);

  final CurrencyCubit _currency;

  /// The phone's region and time zone; tests replace them.
  @visibleForTesting
  static String? Function() deviceCountry = () =>
      PlatformDispatcher.instance.locale.countryCode;
  @visibleForTesting
  static int Function() utcOffsetMinutes = () =>
      DateTime.now().timeZoneOffset.inMinutes;

  @override
  Country decode(String stored) =>
      Countries.byCode(stored) ??
      Countries.detect(
        deviceCountry: deviceCountry(),
        utcOffsetMinutes: utcOffsetMinutes(),
        currencyCode: _currency.state.code,
      );

  @override
  String encode(Country value) => value.code;
}

/// Accounts on Home and the Accounts screen: most-used first, or the
/// user's own drag order.
@lazySingleton
class AccountsByUseCubit extends SettingCubit<bool> {
  AccountsByUseCubit(SettingsRepository r)
    : super(r, SettingKey.accountsByUse, true);

  @override
  bool decode(String stored) => stored != 'false';

  @override
  String encode(bool value) => '$value';
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/money/currency.dart';
import '../../accounts/domain/account.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../data/app_start.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.page = 0,
    this.currency = Currency.pkr,
    this.cycle = const BudgetCycle.calendar(),
    this.imported = false,
  });

  static const int pages = 3;

  final int page;
  final Currency currency;
  final BudgetCycle cycle;

  /// A Hysab Kytab import finished from the welcome.
  final bool imported;

  OnboardingState copyWith({
    int? page,
    Currency? currency,
    BudgetCycle? cycle,
    bool? imported,
  }) => OnboardingState(
    page: page ?? this.page,
    currency: currency ?? this.currency,
    cycle: cycle ?? this.cycle,
    imported: imported ?? this.imported,
  );

  @override
  List<Object?> get props => [page, currency, cycle, imported];
}

/// First run (spec 3.2 #1): promise → currency and month start → optional
/// import and app lock. Choices apply as they're made; skipping keeps the
/// defaults (PKR, calendar months).
@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._currency, this._cycle, this._accounts, this._start)
    : super(OnboardingState(currency: _currency.state, cycle: _cycle.state));

  final CurrencyCubit _currency;
  final BudgetCycleCubit _cycle;
  final AccountsRepository _accounts;
  final AppStart _start;

  void goTo(int page) =>
      emit(state.copyWith(page: page.clamp(0, OnboardingState.pages - 1)));

  Future<void> setCurrency(Currency c) async {
    emit(state.copyWith(currency: c));
    await _currency.set(c);
    // The seeded Cash account follows while it's still untouched.
    final accounts = (await _accounts.watchOverview().first).accounts;
    for (final s in accounts) {
      final a = s.account;
      if (a.currency != c && s.balance.isZero && a.openingBalance.isZero) {
        await _accounts.update(a.id, a.toDraft().copyWith(currency: c));
      }
    }
  }

  Future<void> setCycle(BudgetCycle c) async {
    emit(state.copyWith(cycle: c));
    await _cycle.set(c);
  }

  void imported() => emit(state.copyWith(imported: true));

  Future<void> finish() => _start.finish();
}

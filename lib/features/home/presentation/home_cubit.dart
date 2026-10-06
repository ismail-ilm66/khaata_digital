import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../accounts/domain/account.dart';
import '../../budgets/domain/budget.dart';
import '../../people/domain/person.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/domain/entry_query.dart';
import '../../transactions/domain/ledger_entry.dart';
import '../../transactions/domain/transactions_repository.dart';

class HomeState extends Equatable {
  const HomeState({
    this.overview,
    this.totals,
    this.recent,
    this.budgets,
    this.people,
    this.cycle,
  });

  final AccountsOverview? overview;

  /// Income and spending in the current budget cycle.
  final PeriodTotals? totals;
  final List<EntryView>? recent;
  final BudgetOverview? budgets;
  final PeopleOverview? people;
  final CycleId? cycle;

  /// Until every card has data, show nothing rather than half a screen.
  bool get loading =>
      overview == null ||
      totals == null ||
      recent == null ||
      budgets == null ||
      people == null;

  HomeState copyWith({
    AccountsOverview? overview,
    PeriodTotals? totals,
    List<EntryView>? recent,
    BudgetOverview? budgets,
    PeopleOverview? people,
    CycleId? cycle,
  }) => HomeState(
    overview: overview ?? this.overview,
    totals: totals ?? this.totals,
    recent: recent ?? this.recent,
    budgets: budgets ?? this.budgets,
    people: people ?? this.people,
    cycle: cycle ?? this.cycle,
  );

  @override
  List<Object?> get props => [overview, totals, recent, budgets, people, cycle];
}

/// Home dashboard (spec 3.2 #2): net worth, this cycle, budgets, accounts,
/// udhaar, recent. Follows the month-start setting via [BudgetCycleCubit].
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._accounts,
    this._transactions,
    this._budgets,
    this._people,
    this._cycle,
    this._currency,
  ) : super(const HomeState());

  final AccountsRepository _accounts;
  final TransactionsRepository _transactions;
  final BudgetsRepository _budgets;
  final PeopleRepository _people;
  final BudgetCycleCubit _cycle;
  final CurrencyCubit _currency;

  static const int recentCount = 5;

  final List<StreamSubscription<void>> _subs = [];
  final List<StreamSubscription<void>> _cycleSubs = [];

  void start({DateTime Function() now = DateTime.now}) {
    _subs
      ..add(
        _accounts.watchOverview().listen(
          (o) => emit(state.copyWith(overview: o)),
        ),
      )
      ..add(
        _transactions
            .watch(const EntryQuery(limit: recentCount))
            .listen(
              (p) => emit(
                state.copyWith(recent: p.items.take(recentCount).toList()),
              ),
            ),
      )
      ..add(
        _people.watchOverview().listen((p) => emit(state.copyWith(people: p))),
      )
      ..add(_cycle.stream.listen((c) => _watchCycle(c, now())));
    _watchCycle(_cycle.state, now());
  }

  /// Totals and budgets depend on which cycle "now" is in.
  void _watchCycle(BudgetCycle cycle, DateTime now) {
    for (final s in _cycleSubs) {
      s.cancel();
    }
    _cycleSubs.clear();
    final id = cycle.idFor(now);
    emit(state.copyWith(cycle: id));
    _cycleSubs
      ..add(
        _transactions
            .watchTotals(cycle.rangeOf(id))
            .listen((t) => emit(state.copyWith(totals: t))),
      )
      ..add(
        _budgets
            .watch(id, cycle, _currency.state)
            .listen((b) => emit(state.copyWith(budgets: b))),
      );
  }

  @override
  Future<void> close() async {
    for (final s in [..._subs, ..._cycleSubs]) {
      await s.cancel();
    }
    return super.close();
  }
}

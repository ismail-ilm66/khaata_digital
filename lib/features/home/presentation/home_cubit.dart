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
    this.current,
  });

  final AccountsOverview? overview;

  /// Income and spending in the current budget cycle.
  final PeriodTotals? totals;
  final List<EntryView>? recent;
  final BudgetOverview? budgets;
  final PeopleOverview? people;

  /// The cycle shown, and the one "now" is in.
  final CycleId? cycle;
  final CycleId? current;

  bool get isCurrent => cycle == current;

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
    CycleId? current,
  }) => HomeState(
    overview: overview ?? this.overview,
    totals: totals ?? this.totals,
    recent: recent ?? this.recent,
    budgets: budgets ?? this.budgets,
    people: people ?? this.people,
    cycle: cycle ?? this.cycle,
    current: current ?? this.current,
  );

  @override
  List<Object?> get props => [
    overview,
    totals,
    recent,
    budgets,
    people,
    cycle,
    current,
  ];
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
      ..add(_cycle.stream.listen((c) => _showCurrent(c, now())));
    _showCurrent(_cycle.state, now());
  }

  void _showCurrent(BudgetCycle cycle, DateTime now) {
    final id = cycle.idFor(now);
    emit(state.copyWith(current: id));
    _watchCycle(cycle, id);
  }

  /// Steps back (−) or forward (+) through cycles, never past the current.
  void step(int steps) {
    var id = state.cycle!;
    for (var i = 0; i < steps.abs(); i++) {
      id = steps > 0 ? id.next : id.previous;
    }
    if (id.compareTo(state.current!) > 0) return;
    _watchCycle(_cycle.state, id);
  }

  /// Totals and budgets for cycle [id].
  void _watchCycle(BudgetCycle cycle, CycleId id) {
    for (final s in _cycleSubs) {
      s.cancel();
    }
    _cycleSubs.clear();
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

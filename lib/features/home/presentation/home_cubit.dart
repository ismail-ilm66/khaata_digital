import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../accounts/domain/account.dart';
import '../../backup/data/backup_service.dart';
import '../../backup/domain/backup.dart';
import '../../budgets/domain/budget.dart';
import '../../people/domain/person.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../to_pay/domain/planned_payment.dart';
import '../../transactions/domain/entry_query.dart';
import '../../transactions/domain/ledger_entry.dart';
import '../../transactions/domain/transactions_repository.dart';

/// The latest off-phone backup. Wrapped so "not loaded yet" (null) and
/// "no backup ever" (`last` null) stay distinct.
typedef BackupStatus = ({BackupRecord? last});

class HomeState extends Equatable {
  const HomeState({
    this.overview,
    this.totals,
    this.recent,
    this.budgets,
    this.people,
    this.toPay,
    this.backup,
    this.cycle,
    this.current,
  });

  final AccountsOverview? overview;

  /// Income and spending in the current budget cycle.
  final PeriodTotals? totals;
  final List<EntryView>? recent;
  final BudgetOverview? budgets;
  final PeopleOverview? people;

  /// What's still to pay, soonest first.
  final List<PlannedPayment>? toPay;
  final BackupStatus? backup;

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
      people == null ||
      toPay == null ||
      backup == null;

  HomeState copyWith({
    AccountsOverview? overview,
    PeriodTotals? totals,
    List<EntryView>? recent,
    BudgetOverview? budgets,
    PeopleOverview? people,
    List<PlannedPayment>? toPay,
    BackupStatus? backup,
    CycleId? cycle,
    CycleId? current,
  }) => HomeState(
    overview: overview ?? this.overview,
    totals: totals ?? this.totals,
    recent: recent ?? this.recent,
    budgets: budgets ?? this.budgets,
    people: people ?? this.people,
    toPay: toPay ?? this.toPay,
    backup: backup ?? this.backup,
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
    toPay,
    backup,
    cycle,
    current,
  ];
}

/// Home dashboard (spec 3.2 #2): this cycle's spending against its budget,
/// net worth, accounts, what needs attention (backup, budgets, to pay,
/// udhaar) and recent entries. Follows the month-start setting via
/// [BudgetCycleCubit].
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._accounts,
    this._transactions,
    this._budgets,
    this._people,
    this._toPay,
    this._backups,
    this._cycle,
    this._currency,
  ) : super(const HomeState());

  final AccountsRepository _accounts;
  final TransactionsRepository _transactions;
  final BudgetsRepository _budgets;
  final PeopleRepository _people;
  final ToPayRepository _toPay;
  final BackupService _backups;
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
      ..add(_toPay.watchOpen().listen((o) => emit(state.copyWith(toPay: o))))
      ..add(
        _backups
            .watchLast(offDevice: true)
            .listen((b) => emit(state.copyWith(backup: (last: b)))),
      )
      ..add(_cycle.stream.listen((c) => _showCurrent(c, now())))
      // Budgets are read in the home currency: follow it when it changes.
      ..add(
        _currency.stream.listen((_) {
          if (state.cycle case final id?) _watchCycle(_cycle.state, id);
        }),
      );
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

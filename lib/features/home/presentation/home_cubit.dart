import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../accounts/domain/account.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/domain/entry_query.dart';
import '../../transactions/domain/ledger_entry.dart';
import '../../transactions/domain/transactions_repository.dart';

class HomeState extends Equatable {
  const HomeState({
    this.overview = AccountsOverview.empty,
    this.totals = PeriodTotals.empty,
    this.recent = const [],
    this.cycle,
    this.loading = true,
  });

  final AccountsOverview overview;

  /// Income and spending in the current budget cycle.
  final PeriodTotals totals;
  final List<EntryView> recent;
  final CycleId? cycle;
  final bool loading;

  @override
  List<Object?> get props => [overview, totals, recent, cycle, loading];
}

/// Home dashboard (spec 3.2 #2): net worth, this cycle, accounts, recent.
/// Follows the month-start setting via [BudgetCycleCubit].
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._accounts, this._transactions, this._cycle)
    : super(const HomeState());

  final AccountsRepository _accounts;
  final TransactionsRepository _transactions;
  final BudgetCycleCubit _cycle;

  static const int recentCount = 5;

  StreamSubscription<HomeState>? _data;
  StreamSubscription<BudgetCycle>? _cycleChanges;

  void start({DateTime Function() now = DateTime.now}) {
    _subscribe(_cycle.state, now());
    _cycleChanges = _cycle.stream.listen((c) => _subscribe(c, now()));
  }

  void _subscribe(BudgetCycle cycle, DateTime now) {
    final id = cycle.idFor(now);
    _data?.cancel();
    _data = _accounts
        .watchOverview()
        .combineLatest(
          _transactions.watchTotals(cycle.rangeOf(id)),
          (a, b) => (a, b),
        )
        .combineLatest(
          _transactions.watch(const EntryQuery(limit: recentCount)),
          (ab, page) => HomeState(
            overview: ab.$1,
            totals: ab.$2,
            recent: page.items.take(recentCount).toList(),
            cycle: id,
            loading: false,
          ),
        )
        .listen(emit);
  }

  @override
  Future<void> close() async {
    await _data?.cancel();
    await _cycleChanges?.cancel();
    return super.close();
  }
}

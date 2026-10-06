import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/money/money.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../domain/budget.dart';

sealed class BudgetsEvent {
  const BudgetsEvent();
}

/// Opens the cycle containing [now] (defaults to today).
final class BudgetsStarted extends BudgetsEvent {
  const BudgetsStarted([this.now]);
  final DateTime? now;
}

final class CycleChanged extends BudgetsEvent {
  const CycleChanged(this.cycle);
  final CycleId cycle;
}

final class BudgetSet extends BudgetsEvent {
  const BudgetSet(this.limit, {this.categoryId});
  final Money limit;
  final String? categoryId;
}

final class BudgetCleared extends BudgetsEvent {
  const BudgetCleared({this.categoryId});
  final String? categoryId;
}

final class CopyLastRequested extends BudgetsEvent {
  const CopyLastRequested();
}

class BudgetsState extends Equatable {
  const BudgetsState({this.cycle, this.overview, this.copied});

  final CycleId? cycle;
  final BudgetOverview? overview;

  /// Set once after "Copy last month" (how many were copied) for a toast.
  final int? copied;

  bool get loading => overview == null;

  @override
  List<Object?> get props => [cycle, overview, copied];
}

/// Budgets screen (spec 3.2 #6). Cycles come from [BudgetCycleCubit], so
/// a salary-date month start applies everywhere.
@injectable
class BudgetsBloc extends Bloc<BudgetsEvent, BudgetsState> {
  BudgetsBloc(this._repo, this._cycle, this._currency)
    : super(const BudgetsState()) {
    on<BudgetsStarted>(
      (e, emit) =>
          add(CycleChanged(_cycle.state.idFor(e.now ?? DateTime.now()))),
    );
    on<CycleChanged>((e, emit) {
      emit(BudgetsState(cycle: e.cycle));
      return emit.forEach<BudgetOverview>(
        _repo.watch(e.cycle, _cycle.state, _currency.state),
        onData: (o) => BudgetsState(cycle: e.cycle, overview: o),
      );
    }, transformer: restartable());
    on<BudgetSet>(
      (e, emit) => _repo.set(state.cycle!, e.limit, categoryId: e.categoryId),
    );
    on<BudgetCleared>(
      (e, emit) => _repo.clear(state.cycle!, categoryId: e.categoryId),
    );
    on<CopyLastRequested>((e, emit) async {
      final n = await _repo.copyFromPrevious(state.cycle!);
      emit(
        BudgetsState(cycle: state.cycle, overview: state.overview, copied: n),
      );
    });
  }

  final BudgetsRepository _repo;
  final BudgetCycleCubit _cycle;
  final CurrencyCubit _currency;
}

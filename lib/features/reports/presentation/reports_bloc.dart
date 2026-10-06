import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/dates/report_period.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/domain/entry_query.dart';
import '../domain/report.dart';

sealed class ReportsEvent {
  const ReportsEvent();
}

final class ReportsStarted extends ReportsEvent {
  const ReportsStarted([this.now]);
  final DateTime? now;
}

/// Switches to Day / Week / Month / Year / All around today (custom has
/// its own event, with dates).
final class PeriodKindChanged extends ReportsEvent {
  const PeriodKindChanged(this.kind);
  final PeriodKind kind;
}

final class CustomPeriodChosen extends ReportsEvent {
  const CustomPeriodChosen(this.firstDay, this.lastDay);
  final DateTime firstDay;
  final DateTime lastDay;
}

final class PeriodStepped extends ReportsEvent {
  const PeriodStepped(this.steps);
  final int steps;
}

final class ReportFiltersChanged extends ReportsEvent {
  const ReportFiltersChanged(this.filters);
  final EntryQuery filters;
}

final class _Load extends ReportsEvent {
  const _Load();
}

class ReportsState extends Equatable {
  const ReportsState({this.query, this.data});

  final ReportQuery? query;
  final ReportData? data;

  bool get loading => data == null;

  @override
  List<Object?> get props => [query, data];
}

/// Reports tab (spec 3.2 #8): one period, the list's filters, live data.
@injectable
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc(this._repo, this._cycle, this._currency)
    : super(const ReportsState()) {
    on<_Load>(
      (e, emit) => emit.forEach<ReportData>(
        _repo.watch(state.query!),
        onData: (d) => ReportsState(query: state.query, data: d),
      ),
      transformer: restartable(),
    );
    on<ReportsStarted>((e, emit) {
      _now = e.now ?? DateTime.now();
      _set(emit, ReportPeriod.month(_now));
    });
    on<PeriodKindChanged>((e, emit) => _set(emit, _periodOf(e.kind)));
    on<CustomPeriodChosen>(
      (e, emit) => _set(emit, ReportPeriod.custom(e.firstDay, e.lastDay)),
    );
    on<PeriodStepped>(
      (e, emit) => _set(emit, state.query!.period.shift(e.steps, _cycle.state)),
    );
    on<ReportFiltersChanged>((e, emit) {
      emit(ReportsState(query: state.query!.copyWith(filters: e.filters)));
      add(const _Load());
    });
  }

  final ReportsRepository _repo;
  final BudgetCycleCubit _cycle;
  final CurrencyCubit _currency;
  DateTime _now = DateTime.now();

  ReportPeriod _periodOf(PeriodKind kind) => switch (kind) {
    PeriodKind.day => ReportPeriod.day(_now),
    PeriodKind.week => ReportPeriod.week(_now),
    PeriodKind.month => ReportPeriod.month(_now),
    PeriodKind.year => ReportPeriod.year(_now),
    PeriodKind.all => const ReportPeriod.all(),
    // Custom starts as this month until dates are chosen.
    PeriodKind.custom => ReportPeriod.month(_now),
  };

  void _set(Emitter<ReportsState> emit, ReportPeriod period) {
    final previous = state.query;
    emit(
      ReportsState(
        query: ReportQuery(
          period: period,
          cycle: _cycle.state,
          currency: _currency.state,
          filters: previous?.filters ?? const EntryQuery(),
        ),
      ),
    );
    add(const _Load());
  }
}

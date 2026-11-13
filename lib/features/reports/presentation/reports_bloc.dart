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

/// Internal: (re)subscribes to the period before, for the comparison.
final class _Compare extends ReportsEvent {
  const _Compare();
}

class ReportsState extends Equatable {
  const ReportsState({this.query, this.data, this.previous, this.before});

  final ReportQuery? query;
  final ReportData? data;

  /// The period the figures are compared with ("vs Oct"); null where
  /// there's none (all time, a custom range).
  final ReportPeriod? previous;

  /// Its figures, over the same number of days while [query]'s period is
  /// still running, with the same filters.
  final ReportData? before;

  bool get loading => data == null;

  ReportsState copyWith({ReportData? data, ReportData? before}) => ReportsState(
    query: query,
    data: data ?? this.data,
    previous: previous,
    before: before ?? this.before,
  );

  @override
  List<Object?> get props => [query, data, previous, before];
}

/// Reports tab (spec 3.2 #8): one period, the list's filters, live data.
@injectable
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc(this._repo, this._cycle, this._currency)
    : super(const ReportsState()) {
    on<_Load>(
      (e, emit) => emit.forEach<ReportData>(
        _repo.watch(state.query!),
        onData: (d) => state.copyWith(data: d),
      ),
      transformer: restartable(),
    );
    on<_Compare>((e, emit) async {
      final period = _comparison(state.query!.period);
      if (period == null) return;
      await emit.forEach<ReportData>(
        _repo.watch(state.query!.copyWith(period: period)),
        onData: (d) => state.copyWith(before: d),
      );
    }, transformer: restartable());
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
      final query = state.query!.copyWith(filters: e.filters);
      emit(ReportsState(query: query, previous: _previousOf(query.period)));
      add(const _Load());
      add(const _Compare());
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
        previous: _previousOf(period),
      ),
    );
    add(const _Load());
    add(const _Compare());
  }

  /// The same kind of period one step back; null for all time and custom
  /// ranges, which have nothing before them to compare with.
  ReportPeriod? _previousOf(ReportPeriod p) =>
      p.canStep ? p.shift(-1, _cycle.state) : null;

  /// What [p] is compared with: the period before, cut to the same number
  /// of days while [p] is still running, so the first 13 days of November
  /// meet the first 13 of October rather than all of it.
  ReportPeriod? _comparison(ReportPeriod p) {
    final before = _previousOf(p);
    if (before == null) return null;
    final cycle = _cycle.state;
    final range = p.range(cycle)!;
    final now = DateTime.now();
    if (!range.contains(now)) return before;
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(range.start).inDays;
    final start = before.range(cycle)!.start;
    final last = DateTime(start.year, start.month, start.day + days);
    return last.isBefore(before.range(cycle)!.lastDay)
        ? ReportPeriod.custom(start, last)
        : before;
  }
}

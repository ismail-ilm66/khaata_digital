import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/day_group.dart';
import '../../domain/entry_query.dart';
import '../../domain/transactions_repository.dart';

sealed class TransactionListEvent {
  const TransactionListEvent();
}

final class ListStarted extends TransactionListEvent {
  const ListStarted([this.query = const EntryQuery()]);
  final EntryQuery query;
}

final class FiltersChanged extends TransactionListEvent {
  const FiltersChanged(this.query);
  final EntryQuery query;
}

final class SearchChanged extends TransactionListEvent {
  const SearchChanged(this.text);
  final String text;
}

final class MoreRequested extends TransactionListEvent {
  const MoreRequested();
}

final class EntryDeleted extends TransactionListEvent {
  const EntryDeleted(this.id);
  final String id;
}

final class DeleteUndone extends TransactionListEvent {
  const DeleteUndone();
}

/// Internal: (re)subscribes to the repository for the current query.
final class _Subscribe extends TransactionListEvent {
  const _Subscribe();
}

class TransactionListState extends Equatable {
  const TransactionListState({
    this.query = const EntryQuery(),
    this.days = const [],
    this.hasMore = false,
    this.loading = true,
    this.lastDeletedId,
  });

  final EntryQuery query;
  final List<DayGroup> days;
  final bool hasMore;
  final bool loading;
  final String? lastDeletedId;

  bool get isEmpty => !loading && days.isEmpty;

  TransactionListState copyWith({
    EntryQuery? query,
    List<DayGroup>? days,
    bool? hasMore,
    bool? loading,
    String? Function()? lastDeletedId,
  }) => TransactionListState(
    query: query ?? this.query,
    days: days ?? this.days,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    lastDeletedId: lastDeletedId != null ? lastDeletedId() : this.lastDeletedId,
  );

  @override
  List<Object?> get props => [query, days, hasMore, loading, lastDeletedId];
}

/// The transactions list and search results (spec 4.1 BLoC map).
@injectable
class TransactionListBloc
    extends Bloc<TransactionListEvent, TransactionListState> {
  TransactionListBloc(this._repo) : super(const TransactionListState()) {
    on<_Subscribe>(_onSubscribe, transformer: restartable());
    on<ListStarted>((e, emit) {
      emit(state.copyWith(query: e.query, loading: true));
      add(const _Subscribe());
    });
    on<FiltersChanged>((e, emit) {
      emit(
        state.copyWith(
          query: e.query.copyWith(limit: EntryQuery.pageSize),
          loading: true,
        ),
      );
      add(const _Subscribe());
    });
    on<SearchChanged>((e, emit) {
      if (e.text == state.query.search) return;
      emit(
        state.copyWith(
          query: state.query.copyWith(
            search: e.text,
            limit: EntryQuery.pageSize,
          ),
          loading: true,
        ),
      );
      add(const _Subscribe());
    });
    on<MoreRequested>((e, emit) {
      if (!state.hasMore) return;
      emit(
        state.copyWith(
          query: state.query.copyWith(
            limit: state.query.limit + EntryQuery.pageSize,
          ),
        ),
      );
      add(const _Subscribe());
    });
    on<EntryDeleted>((e, emit) async {
      // Gone from the list at once: a swiped-away row must leave the tree
      // on the next frame, before the database stream catches up.
      emit(
        state.copyWith(
          days: DayGroup.group([
            for (final d in state.days)
              for (final v in d.entries)
                if (v.entry.id != e.id) v,
          ]),
          lastDeletedId: () => e.id,
        ),
      );
      await _repo.delete(e.id);
    });
    on<DeleteUndone>((e, emit) async {
      final id = state.lastDeletedId;
      if (id == null) return;
      await _repo.restore(id);
      emit(state.copyWith(lastDeletedId: () => null));
    });
  }

  final TransactionsRepository _repo;

  Future<void> _onSubscribe(_Subscribe e, Emitter<TransactionListState> emit) =>
      emit.forEach<EntryPage>(
        _repo.watch(state.query),
        onData: (page) => state.copyWith(
          days: DayGroup.group(page.items),
          hasMore: page.hasMore,
          loading: false,
        ),
      );
}

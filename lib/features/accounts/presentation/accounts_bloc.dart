import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../core/error/app_failure.dart';
import '../domain/account.dart';

sealed class AccountsEvent {
  const AccountsEvent();
}

final class AccountsStarted extends AccountsEvent {
  const AccountsStarted();
}

final class AccountsReordered extends AccountsEvent {
  const AccountsReordered(this.oldIndex, this.newIndex);
  final int oldIndex;
  final int newIndex;
}

final class AccountArchived extends AccountsEvent {
  const AccountArchived(this.id);
  final String id;
}

final class AccountUnarchived extends AccountsEvent {
  const AccountUnarchived(this.id);
  final String id;
}

class AccountsState extends Equatable {
  const AccountsState({
    this.overview = AccountsOverview.empty,
    this.archived = const [],
    this.loading = true,
    this.duplicateName,
  });

  final AccountsOverview overview;
  final List<Account> archived;
  final bool loading;

  /// Set when an unarchive failed because the name is taken.
  final String? duplicateName;

  AccountsState copyWith({
    AccountsOverview? overview,
    List<Account>? archived,
    bool? loading,
    String? Function()? duplicateName,
  }) => AccountsState(
    overview: overview ?? this.overview,
    archived: archived ?? this.archived,
    loading: loading ?? this.loading,
    duplicateName: duplicateName != null ? duplicateName() : this.duplicateName,
  );

  @override
  List<Object?> get props => [overview, archived, loading, duplicateName];
}

/// The Accounts screen: list, reorder, archive (spec 3.2 #5).
@injectable
class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  AccountsBloc(this._repo) : super(const AccountsState()) {
    on<AccountsStarted>(
      (e, emit) => emit.forEach<(AccountsOverview, List<Account>)>(
        _repo.watchOverview().combineLatest(
          _repo.watchArchived(),
          (a, b) => (a, b),
        ),
        onData: (d) =>
            state.copyWith(overview: d.$1, archived: d.$2, loading: false),
      ),
    );
    on<AccountsReordered>(_onReorder);
    on<AccountArchived>((e, emit) => _repo.archive(e.id));
    on<AccountUnarchived>((e, emit) async {
      try {
        await _repo.unarchive(e.id);
      } on DuplicateNameFailure catch (f) {
        emit(state.copyWith(duplicateName: () => f.name));
        emit(state.copyWith(duplicateName: () => null));
      }
    });
  }

  final AccountsRepository _repo;

  /// Moves the row immediately (so the drag feels instant), then persists.
  Future<void> _onReorder(
    AccountsReordered e,
    Emitter<AccountsState> emit,
  ) async {
    final list = [...state.overview.accounts];
    final moved = list.removeAt(e.oldIndex);
    list.insert(e.newIndex > e.oldIndex ? e.newIndex - 1 : e.newIndex, moved);
    emit(
      state.copyWith(
        overview: AccountsOverview(
          accounts: list,
          netWorth: state.overview.netWorth,
        ),
      ),
    );
    await _repo.reorder([for (final s in list) s.account.id]);
  }
}

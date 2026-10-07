import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/category.dart';
import '../domain/category_kind.dart';

class CategoriesState extends Equatable {
  const CategoriesState({
    this.kind = CategoryKind.expense,
    this.active = const [],
    this.archived = const [],
    this.duplicate,
    this.duplicateId = 0,
  });

  final CategoryKind kind;
  final List<Category> active;
  final List<Category> archived;

  /// A name that clashed (one-shot, bumped by [duplicateId]).
  final String? duplicate;
  final int duplicateId;

  CategoriesState copyWith({
    CategoryKind? kind,
    List<Category>? active,
    List<Category>? archived,
    String? duplicate,
  }) => CategoriesState(
    kind: kind ?? this.kind,
    active: active ?? this.active,
    archived: archived ?? this.archived,
    duplicate: duplicate ?? this.duplicate,
    duplicateId: duplicate == null ? duplicateId : duplicateId + 1,
  );

  @override
  List<Object?> get props => [kind, active, archived, duplicate, duplicateId];
}

/// More → Categories (spec 3.2 #10): add, rename, re-icon, reorder,
/// archive and restore, per kind.
@injectable
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repo) : super(const CategoriesState()) {
    _watch(CategoryKind.expense);
  }

  final CategoriesRepository _repo;
  final _subs = <StreamSubscription<Object?>>[];

  void _watch(CategoryKind kind) {
    for (final s in _subs) {
      s.cancel();
    }
    _subs
      ..clear()
      ..add(_repo.watch(kind).listen((c) => emit(state.copyWith(active: c))))
      ..add(
        _repo
            .watchArchived(kind)
            .listen((c) => emit(state.copyWith(archived: c))),
      );
  }

  void showKind(CategoryKind kind) {
    if (kind == state.kind) return;
    emit(state.copyWith(kind: kind, active: const [], archived: const []));
    _watch(kind);
  }

  /// False when the name is taken.
  Future<bool> add(String name, String? iconKey) => _named(
    name,
    () => _repo.create(name: name, kind: state.kind, iconKey: iconKey),
  );

  Future<bool> edit(Category c, String name, String? iconKey) =>
      _named(name, () => _repo.update(c.id, name: name, iconKey: iconKey));

  Future<void> archive(Category c) => _repo.archive(c.id);

  Future<bool> restore(Category c) =>
      _named(c.name, () => _repo.unarchive(c.id));

  Future<void> reorder(int from, int to) async {
    final list = [...state.active];
    final moved = list.removeAt(from);
    list.insert(to > from ? to - 1 : to, moved);
    emit(state.copyWith(active: list)); // instant, before the DB echoes
    await _repo.reorder([for (final c in list) c.id]);
  }

  Future<bool> _named(String name, Future<Object?> Function() op) async {
    try {
      await op();
      return true;
    } on DuplicateNameFailure catch (e) {
      emit(state.copyWith(duplicate: e.name));
      return false;
    }
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}

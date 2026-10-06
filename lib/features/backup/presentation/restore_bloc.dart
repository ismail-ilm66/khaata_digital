import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/app_refresh.dart';
import '../../../core/files/file_gateway.dart';
import '../data/backup_service.dart';
import '../domain/backup.dart';
import 'backup_health.dart';

sealed class RestoreEvent {
  const RestoreEvent();
}

/// A backup file was chosen (from a file, Drive or this phone).
class RestoreOpened extends RestoreEvent {
  const RestoreOpened(this.file);
  final PickedFile file;
}

class RestoreModeChanged extends RestoreEvent {
  const RestoreModeChanged(this.mode);
  final RestoreMode mode;
}

class RestoreConfirmed extends RestoreEvent {
  const RestoreConfirmed({this.passphrase});
  final String? passphrase;
}

enum RestoreStatus { inspecting, ready, restoring, done, failed }

class RestoreState extends Equatable {
  const RestoreState({
    this.status = RestoreStatus.inspecting,
    this.manifest,
    this.mode = RestoreMode.replace,
    this.result,
    this.failure,
  });

  final RestoreStatus status;
  final BackupManifest? manifest;
  final RestoreMode mode;
  final RestoreResult? result;

  /// Why the last attempt failed. With a wrong passphrase the wizard stays
  /// [RestoreStatus.ready] so the user can try again.
  final BackupFailureKind? failure;

  RestoreState copyWith({
    RestoreStatus? status,
    BackupManifest? manifest,
    RestoreMode? mode,
    RestoreResult? result,
    BackupFailureKind? Function()? failure,
  }) => RestoreState(
    status: status ?? this.status,
    manifest: manifest ?? this.manifest,
    mode: mode ?? this.mode,
    result: result ?? this.result,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [status, manifest, mode, result, failure];
}

/// Restore wizard (spec 3.2 #9): preview from the cleartext manifest →
/// passphrase if needed → replace or merge → result with the integrity
/// confirmation. A safety copy of the current data is kept first.
@injectable
class RestoreBloc extends Bloc<RestoreEvent, RestoreState> {
  RestoreBloc(this._backups, this._refresh, this._health)
    : super(const RestoreState()) {
    on<RestoreOpened>(_onOpened);
    on<RestoreModeChanged>((e, emit) => emit(state.copyWith(mode: e.mode)));
    on<RestoreConfirmed>(_onConfirmed);
  }

  final BackupService _backups;
  final AppRefresh _refresh;
  final BackupHealth _health;
  List<int> _bytes = const [];

  Future<void> _onOpened(RestoreOpened e, Emitter<RestoreState> emit) async {
    _bytes = e.file.bytes;
    try {
      final manifest = await _backups.inspect(_bytes);
      emit(
        state.copyWith(
          status: manifest.schemaVersion > _backups.schemaVersion
              ? RestoreStatus.failed
              : RestoreStatus.ready,
          manifest: manifest,
          failure: () => manifest.schemaVersion > _backups.schemaVersion
              ? BackupFailureKind.newerApp
              : null,
        ),
      );
    } on BackupFailure catch (f) {
      emit(state.copyWith(status: RestoreStatus.failed, failure: () => f.kind));
    }
  }

  Future<void> _onConfirmed(
    RestoreConfirmed e,
    Emitter<RestoreState> emit,
  ) async {
    if (state.status != RestoreStatus.ready) return;
    emit(state.copyWith(status: RestoreStatus.restoring, failure: () => null));
    try {
      // Safety net: what's on this phone now, kept on this phone.
      await _backups.saveOnDevice(await _backups.create());
      final result = await _backups.restore(
        _bytes,
        mode: state.mode,
        passphrase: e.passphrase,
      );
      _health.databaseOk = true;
      await _refresh.all();
      emit(state.copyWith(status: RestoreStatus.done, result: result));
    } on BackupFailure catch (f) {
      emit(
        state.copyWith(
          status: f.kind == BackupFailureKind.wrongPassphrase
              ? RestoreStatus.ready
              : RestoreStatus.failed,
          failure: () => f.kind,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RestoreStatus.failed,
          failure: () => BackupFailureKind.damaged,
        ),
      );
    }
  }
}

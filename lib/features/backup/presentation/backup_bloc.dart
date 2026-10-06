import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/background/background_jobs.dart';
import '../../../core/files/file_gateway.dart';
import '../../settings/domain/setting_key.dart';
import '../../settings/domain/settings_repository.dart';
import '../data/auto_backup.dart';
import '../data/backup_service.dart';
import '../domain/backup.dart';
import '../domain/cloud_backup_store.dart';

sealed class BackupEvent {
  const BackupEvent();
}

class BackupStarted extends BackupEvent {
  const BackupStarted();
}

/// Back up now to a file or Google Drive, optionally encrypted.
class BackupNow extends BackupEvent {
  const BackupNow(this.destination, {this.passphrase});
  final BackupDestination destination;
  final String? passphrase;
}

class AutoBackupToggled extends BackupEvent {
  const AutoBackupToggled(this.on);
  final bool on;
}

class WifiOnlyToggled extends BackupEvent {
  const WifiOnlyToggled(this.on);
  final bool on;
}

class DriveConnectRequested extends BackupEvent {
  const DriveConnectRequested();
}

class DriveDisconnectRequested extends BackupEvent {
  const DriveDisconnectRequested();
}

class _LastChanged extends BackupEvent {
  const _LastChanged(this.last);
  final BackupRecord? last;
}

/// One-shot messages for a snackbar.
enum BackupNotice { saved, uploaded, failed, driveFailed }

class BackupState extends Equatable {
  const BackupState({
    this.last,
    this.auto = false,
    this.wifiOnly = true,
    this.driveAvailable = false,
    this.driveAccount,
    this.busy,
    this.notice,
    this.noticeId = 0,
  });

  final BackupRecord? last;
  final bool auto;
  final bool wifiOnly;
  final bool driveAvailable;
  final String? driveAccount;

  /// The backup in progress, if any.
  final BackupDestination? busy;
  final BackupNotice? notice;

  /// Bumped with every notice so the same notice shows again.
  final int noticeId;

  BackupState copyWith({
    BackupRecord? Function()? last,
    bool? auto,
    bool? wifiOnly,
    bool? driveAvailable,
    String? Function()? driveAccount,
    BackupDestination? Function()? busy,
    BackupNotice? notice,
  }) => BackupState(
    last: last == null ? this.last : last(),
    auto: auto ?? this.auto,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    driveAvailable: driveAvailable ?? this.driveAvailable,
    driveAccount: driveAccount == null ? this.driveAccount : driveAccount(),
    busy: busy == null ? this.busy : busy(),
    notice: notice ?? this.notice,
    noticeId: notice == null ? noticeId : noticeId + 1,
  );

  @override
  List<Object?> get props => [
    last,
    auto,
    wifiOnly,
    driveAvailable,
    driveAccount,
    busy,
    notice,
    noticeId,
  ];
}

/// The Backup & restore screen (spec 3.2 #9): status, back up now,
/// automatic weekly backups and the Drive connection.
@injectable
class BackupBloc extends Bloc<BackupEvent, BackupState> {
  BackupBloc(this._backups, this._cloud, this._settings, this._files)
    : super(const BackupState()) {
    on<BackupStarted>(_onStarted);
    on<_LastChanged>((e, emit) => emit(state.copyWith(last: () => e.last)));
    on<BackupNow>(_onBackupNow);
    on<AutoBackupToggled>(_onAuto);
    on<WifiOnlyToggled>(_onWifi);
    on<DriveConnectRequested>(_onConnect);
    on<DriveDisconnectRequested>(_onDisconnect);
  }

  final BackupService _backups;
  final CloudBackupStore _cloud;
  final SettingsRepository _settings;
  final FileGateway _files;
  StreamSubscription<BackupRecord?>? _sub;

  Future<void> _onStarted(BackupStarted e, Emitter<BackupState> emit) async {
    _sub ??= _backups.watchLast().listen((r) => add(_LastChanged(r)));
    // Read everything first: `state` must be read after the awaits, or a
    // backup record arriving meanwhile would be overwritten.
    final account = await _settings.read(SettingKey.driveAccount);
    final auto = await _settings.read(SettingKey.autoBackup) == 'true';
    final wifiOnly =
        await _settings.read(SettingKey.autoBackupWifiOnly) == 'true';
    emit(
      state.copyWith(
        auto: auto,
        wifiOnly: wifiOnly,
        driveAvailable: _cloud.available,
        driveAccount: () =>
            _cloud.available && account.isNotEmpty ? account : null,
      ),
    );
  }

  Future<void> _onBackupNow(BackupNow e, Emitter<BackupState> emit) async {
    if (state.busy != null) return;
    emit(state.copyWith(busy: () => e.destination));
    try {
      final file = await _backups.create(passphrase: e.passphrase);
      switch (e.destination) {
        case BackupDestination.file:
          final saved = await _files.save(
            name: file.name,
            bytes: file.bytes,
            mime: 'application/octet-stream',
          );
          if (!saved) {
            emit(state.copyWith(busy: () => null));
            return;
          }
          await _backups.record(file, BackupDestination.file);
          emit(state.copyWith(busy: () => null, notice: BackupNotice.saved));
        case BackupDestination.drive:
          if (state.driveAccount == null) await _connect(emit);
          await _cloud.upload(file);
          await _backups.record(file, BackupDestination.drive);
          await _cloud.prune(AutoBackup.keepInDrive);
          emit(state.copyWith(busy: () => null, notice: BackupNotice.uploaded));
        case BackupDestination.device:
          await _backups.saveOnDevice(file);
          emit(state.copyWith(busy: () => null, notice: BackupNotice.saved));
      }
    } catch (_) {
      emit(
        state.copyWith(
          busy: () => null,
          notice: e.destination == BackupDestination.drive
              ? BackupNotice.driveFailed
              : BackupNotice.failed,
        ),
      );
    }
  }

  Future<void> _connect(Emitter<BackupState> emit) async {
    final email = await _cloud.connect();
    await _settings.write(SettingKey.driveAccount, email);
    emit(state.copyWith(driveAccount: () => email));
  }

  Future<void> _onConnect(
    DriveConnectRequested e,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _connect(emit);
    } catch (_) {
      emit(state.copyWith(notice: BackupNotice.driveFailed));
    }
  }

  Future<void> _onDisconnect(
    DriveDisconnectRequested e,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _cloud.disconnect();
    } catch (_) {
      // Forget it locally even if Google can't be reached.
    }
    await _settings.write(SettingKey.driveAccount, '');
    emit(state.copyWith(driveAccount: () => null));
  }

  Future<void> _onAuto(AutoBackupToggled e, Emitter<BackupState> emit) async {
    emit(state.copyWith(auto: e.on));
    await _settings.write(SettingKey.autoBackup, '${e.on}');
  }

  Future<void> _onWifi(WifiOnlyToggled e, Emitter<BackupState> emit) async {
    emit(state.copyWith(wifiOnly: e.on));
    await _settings.write(SettingKey.autoBackupWifiOnly, '${e.on}');
    await BackgroundJobs.register(wifiOnly: e.on, replaceBackup: true);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../settings/domain/setting_key.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/backup.dart';
import '../domain/cloud_backup_store.dart';
import 'backup_service.dart';

/// What a weekly auto-backup check did.
enum AutoBackupOutcome {
  /// Turned off, or a recent enough backup exists.
  notDue,

  /// Backed up to the device and to Google Drive.
  drive,

  /// Backed up to the device only (Drive not connected, or the upload
  /// failed; it's retried on the next check).
  device,
}

/// The weekly automatic backup (spec 3.4). Run by the Android background
/// job and on every app start / resume, so it also works on iOS and when
/// the background job can't reach Drive. Safe to call any number of times.
@lazySingleton
class AutoBackup {
  AutoBackup(this._backups, this._cloud, this._settings);

  final BackupService _backups;
  final CloudBackupStore _cloud;
  final SettingsRepository _settings;

  static const Duration interval = Duration(days: 7);

  /// Copies kept in Drive.
  static const int keepInDrive = 8;

  /// Replaceable in tests.
  DateTime Function() now = DateTime.now;

  Future<AutoBackupOutcome> runIfDue({bool interactive = false}) async {
    if (await _settings.read(SettingKey.autoBackup) != 'true') {
      return AutoBackupOutcome.notDue;
    }
    final wantsDrive =
        _cloud.available &&
        (await _settings.read(SettingKey.driveAccount)).isNotEmpty;
    final last = await _backups.lastAt(
      wantsDrive ? BackupDestination.drive : null,
    );
    if (last != null && now().toUtc().difference(last) < interval) {
      return AutoBackupOutcome.notDue;
    }

    final file = await _backups.create();
    // A device copy first: still there if the upload fails.
    final lastDevice = await _backups.lastAt(BackupDestination.device);
    if (lastDevice == null ||
        now().toUtc().difference(lastDevice) >= interval) {
      await _backups.saveOnDevice(file);
    }
    if (!wantsDrive) return AutoBackupOutcome.device;
    try {
      await _cloud.upload(file, interactive: interactive);
      await _backups.record(file, BackupDestination.drive);
      await _cloud.prune(keepInDrive, interactive: interactive);
      return AutoBackupOutcome.drive;
    } catch (e) {
      debugPrint('Kharcha: automatic Drive backup failed: $e');
      return AutoBackupOutcome.device;
    }
  }
}

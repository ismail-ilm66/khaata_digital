import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../core/db/app_database.dart';
import '../../backup/data/backup_service.dart';
import '../../backup/presentation/backup_health.dart';
import '../../../core/config/app_config.dart';

/// The short, non-personal report attached to "Contact us" (spec 1.5
/// #12): app version, database health and last backup. No amounts, names
/// or notes.
@lazySingleton
class Diagnostics {
  Diagnostics(this._backups, this._health, this._db);

  final BackupService _backups;
  final BackupHealth _health;
  final AppDatabase _db;

  static String get supportEmail => AppConfig.supportEmail;

  Future<String> appVersion() => _backups.appVersion();

  Future<String> report() async {
    final last = await _backups.lastAt();
    return [
      'Kharcha ${await appVersion()}',
      'Database: ${_health.databaseOk ? 'OK' : 'failed integrity check'} '
          '(schema ${_db.schemaVersion})',
      'Last backup: ${last?.toIso8601String() ?? 'never'}',
      'Device: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    ].join('\n');
  }
}

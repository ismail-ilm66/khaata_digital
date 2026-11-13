import 'package:injectable/injectable.dart';

/// Startup findings the Home screen surfaces: a database that failed its
/// integrity check gets a prompt to restore from a backup.
@lazySingleton
class BackupHealth {
  bool databaseOk = true;
}

/// Days without a backup that left the phone before Kharcha asks for one
/// (Home's Needs attention, More's Backup & data row).
const int backupQuietDays = 14;

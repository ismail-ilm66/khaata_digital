import 'package:injectable/injectable.dart';

/// Startup findings the Home screen surfaces: a database that failed its
/// integrity check gets a prompt to restore from a backup.
@lazySingleton
class BackupHealth {
  bool databaseOk = true;
}

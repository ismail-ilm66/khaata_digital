import 'package:flutter/foundation.dart';

import 'core/app_refresh.dart';
import 'core/db/app_database.dart';
import 'core/di/injection.dart';
import 'features/backup/data/auto_backup.dart';
import 'features/backup/presentation/backup_health.dart';

/// Startup work shared by the app and widget tests: verify the database,
/// load persisted settings and catch up recurring entries before the first
/// frame.
Future<void> bootstrap() async {
  final healthy = await getIt<AppDatabase>().checkIntegrity();
  if (!healthy) {
    // Home shows a restore prompt; never silently keep writing to a
    // damaged file without the user knowing.
    debugPrint('Kharcha: database integrity check failed');
  }
  getIt<BackupHealth>().databaseOk = healthy;
  await getIt<AppRefresh>().all();
}

/// Creates recurring entries that fell due while the app was closed and
/// refreshes reminders. Called on start and whenever the app resumes.
Future<void> catchUpRecurring() => getIt<AppRefresh>().recurring();

/// The weekly automatic backup, if due. Fire-and-forget on launch and
/// resume; never delays the UI, and a failure only leaves it for later.
Future<void> runAutoBackup() async {
  try {
    await getIt<AutoBackup>().runIfDue();
  } catch (e) {
    debugPrint('Kharcha: automatic backup failed: $e');
  }
}

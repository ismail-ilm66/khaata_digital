import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/backup/data/auto_backup.dart';
import '../../features/backup/data/backup_service.dart';
import '../../features/backup/data/google_drive_store.dart';
import '../../features/recurring/data/recurring_maintenance.dart';
import '../../features/recurring/data/recurring_repository_impl.dart';
import '../../features/recurring/data/reminders.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/transactions/data/receipt_store.dart';
import '../../features/transactions/data/transactions_repository_impl.dart';
import '../db/app_database.dart';

/// Android periodic jobs. iOS has no equivalent here: it catches up on
/// launch and resume instead (see `bootstrap.dart`).
abstract final class BackgroundJobs {
  static const recurring = 'kharcha.recurring';
  static const backup = 'kharcha.backup';

  /// Registers both jobs. Re-run with `replaceBackup` after the user
  /// changes the auto-backup Wi-Fi setting, so the new constraint applies.
  static Future<void> register({
    bool wifiOnly = true,
    bool replaceBackup = false,
  }) async {
    if (!Platform.isAndroid) return;
    await Workmanager().initialize(backgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      recurring,
      recurring,
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    // Checks daily; backs up when a week has passed (AutoBackup decides).
    await Workmanager().registerPeriodicTask(
      backup,
      backup,
      frequency: const Duration(days: 1),
      constraints: Constraints(
        networkType: wifiOnly ? NetworkType.unmetered : NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: replaceBackup
          ? ExistingPeriodicWorkPolicy.replace
          : ExistingPeriodicWorkPolicy.keep,
    );
  }
}

/// Background isolate entry point: no DI here, so the graph is built by
/// hand from the same classes the app uses.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase.open();
    try {
      final settings = SettingsRepositoryImpl(db);
      final receipts = ReceiptStore(
        root: getApplicationDocumentsDirectory,
        compress: compressReceiptImage,
      );
      switch (task) {
        case BackgroundJobs.recurring:
          await runRecurringMaintenance(
            RecurringRepositoryImpl(
              db,
              TransactionsRepositoryImpl(db, receipts),
            ),
            LocalReminderScheduler(
              FlutterLocalNotificationsPlugin(),
              () => reminderStrings(settings),
            ),
          );
        case BackgroundJobs.backup:
          await AutoBackup(
            BackupService(db, receipts),
            GoogleDriveStore(),
            settings,
          ).runIfDue();
      }
      return true;
    } catch (e) {
      debugPrint('Kharcha: background job $task failed: $e');
      return false;
    } finally {
      await db.close();
    }
  });
}

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/db/app_database.dart';
import '../../settings/data/settings_repository_impl.dart';
import '../../transactions/data/receipt_store.dart';
import '../../transactions/data/transactions_repository_impl.dart';
import '../domain/recurring_rule.dart';
import 'recurring_repository_impl.dart';
import 'reminders.dart';

/// Creates every due recurring entry, then re-schedules reminders. Runs on
/// app start and from the background job; safe to run any number of
/// times (each occurrence is created exactly once).
Future<int> runRecurringMaintenance(
  RecurringRepository recurring,
  ReminderScheduler reminders, {
  DateTime? now,
}) async {
  final created = await recurring.materializeDue(now ?? DateTime.now());
  try {
    await reminders.sync(await recurring.active());
  } catch (e) {
    // Notifications are best-effort; never block entries on them.
    debugPrint('Kharcha: reminder sync failed: $e');
  }
  return created;
}

const _taskName = 'kharcha.recurring';

/// Android: a periodic background job that keeps recurring entries and
/// reminders current even when the app isn't opened. (iOS catches up on
/// launch and resume.)
Future<void> registerRecurringBackgroundJob() async {
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(recurringCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _taskName,
    _taskName,
    frequency: const Duration(hours: 6),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

/// Background isolate entry point: no DI here, so the graph is built by
/// hand from the same classes the app uses.
@pragma('vm:entry-point')
void recurringCallbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase.open();
    try {
      final settings = SettingsRepositoryImpl(db);
      final transactions = TransactionsRepositoryImpl(
        db,
        ReceiptStore(
          root: getApplicationDocumentsDirectory,
          compress: compressReceiptImage,
        ),
      );
      await runRecurringMaintenance(
        RecurringRepositoryImpl(db, transactions),
        LocalReminderScheduler(
          FlutterLocalNotificationsPlugin(),
          () => reminderStrings(settings),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Kharcha: background recurring job failed: $e');
      return false;
    } finally {
      await db.close();
    }
  });
}

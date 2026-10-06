import 'package:injectable/injectable.dart';
import 'package:khaata_digital/bootstrap.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/features/transactions/data/receipt_store.dart';

import 'package:khaata_digital/features/recurring/domain/recurring_rule.dart';

import 'fake_reminders.dart';
import 'test_db.dart';
import 'test_receipts.dart';

/// Resets DI with an in-memory database and temp receipt storage, then runs
/// the real [bootstrap]. Pass [reuse] to simulate a cold start against the
/// same database.
Future<AppDatabase> setUpTestApp({AppDatabase? reuse}) async {
  await getIt.reset(dispose: reuse == null);
  final db = reuse ?? testDb();
  getIt
    ..registerSingleton<AppDatabase>(db, dispose: (d) => d.close())
    ..registerSingleton<ReceiptStore>(testReceiptStore())
    ..registerSingleton<ReminderScheduler>(FakeReminderScheduler());
  configureDependencies(environment: Environment.test);
  await bootstrap();
  return db;
}

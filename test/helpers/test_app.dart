import 'package:khaata_digital/features/security/domain/device_auth.dart';
import 'package:khaata_digital/features/backup/data/backup_service.dart';
import 'package:khaata_digital/core/files/file_gateway.dart';
import 'package:khaata_digital/features/backup/domain/cloud_backup_store.dart';
import 'package:injectable/injectable.dart';
import 'package:khaata_digital/bootstrap.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/features/transactions/data/receipt_store.dart';

import 'package:khaata_digital/features/recurring/domain/recurring_rule.dart';

import 'fake_cloud.dart';
import 'fake_device_auth.dart';
import 'fake_files.dart';
import 'fake_reminders.dart';
import 'test_db.dart';
import 'test_receipts.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';

/// Resets DI with an in-memory database and temp receipt storage, then runs
/// the real [bootstrap]. Pass [reuse] to simulate a cold start against the
/// same database.
Future<AppDatabase> setUpTestApp({
  AppDatabase? reuse,
  bool welcome = false,
}) async {
  await getIt.reset(dispose: reuse == null);
  final db = reuse ?? testDb();
  getIt
    ..registerSingleton<AppDatabase>(db, dispose: (d) => d.close())
    ..registerSingleton<ReceiptStore>(testReceiptStore())
    ..registerSingleton<ReminderScheduler>(FakeReminderScheduler())
    ..registerSingleton<CloudBackupStore>(FakeCloudStore())
    ..registerSingleton<FileGateway>(FakeFileGateway())
    ..registerSingleton<DeviceAuth>(FakeDeviceAuth());
  if (!welcome && reuse == null) {
    await db.settingsDao.write(SettingKey.onboardingDone, 'true');
  }
  configureDependencies(environment: Environment.test);
  // No platform channels in widget tests; fast passphrase derivation.
  getIt<BackupService>()
    ..appVersion = (() async => 'test')
    ..iterations = 1000;
  await bootstrap();
  return db;
}

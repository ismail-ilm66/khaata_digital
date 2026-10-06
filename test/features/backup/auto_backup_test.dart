import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/features/backup/data/auto_backup.dart';
import 'package:khaata_digital/features/backup/data/backup_service.dart';
import 'package:khaata_digital/features/backup/domain/backup.dart';
import 'package:khaata_digital/features/settings/data/settings_repository_impl.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';

import '../../helpers/fake_cloud.dart';
import '../../helpers/test_db.dart';
import '../../helpers/test_receipts.dart';

void main() {
  late AppDatabase db;
  late BackupService backups;
  late FakeCloudStore cloud;
  late SettingsRepositoryImpl settings;
  late AutoBackup auto;
  var clock = DateTime(2026, 10, 6, 9);

  setUp(() {
    db = testDb();
    clock = DateTime(2026, 10, 6, 9);
    backups = BackupService(db, testReceiptStore())
      ..now = (() => clock)
      ..appVersion = (() async => 'test');
    cloud = FakeCloudStore();
    settings = SettingsRepositoryImpl(db);
    auto = AutoBackup(backups, cloud, settings)..now = (() => clock);
  });
  tearDown(() => db.close());

  Future<void> week() async => clock = clock.add(const Duration(days: 7));

  test('off by default', () async {
    expect(await auto.runIfDue(), AutoBackupOutcome.notDue);
    expect(await backups.lastAt(), isNull);
  });

  test('weekly to the device when Drive is not connected', () async {
    await settings.write(SettingKey.autoBackup, 'true');
    expect(await auto.runIfDue(), AutoBackupOutcome.device);
    expect(await auto.runIfDue(), AutoBackupOutcome.notDue, reason: 'same day');
    clock = clock.add(const Duration(days: 6));
    expect(await auto.runIfDue(), AutoBackupOutcome.notDue);
    clock = clock.add(const Duration(days: 1));
    expect(await auto.runIfDue(), AutoBackupOutcome.device);
    expect(await backups.deviceBackups(), hasLength(2));
  });

  test('weekly to Drive, keeping the newest 8 there', () async {
    await settings.write(SettingKey.autoBackup, 'true');
    await settings.write(SettingKey.driveAccount, 'me@example.com');
    cloud.account = 'me@example.com';
    for (var i = 0; i < 10; i++) {
      expect(await auto.runIfDue(), AutoBackupOutcome.drive);
      await week();
    }
    expect(cloud.files, hasLength(AutoBackup.keepInDrive));
    expect(await backups.lastAt(BackupDestination.drive), isNotNull);
  });

  test('a failed upload keeps a device copy and retries next time', () async {
    await settings.write(SettingKey.autoBackup, 'true');
    await settings.write(SettingKey.driveAccount, 'me@example.com');
    cloud
      ..account = 'me@example.com'
      ..failUploads = true;
    expect(await auto.runIfDue(), AutoBackupOutcome.device);
    expect(await backups.deviceBackups(), hasLength(1));

    cloud.failUploads = false;
    clock = clock.add(const Duration(hours: 2));
    expect(
      await auto.runIfDue(),
      AutoBackupOutcome.drive,
      reason: 'Drive is still a week behind, so it tries again',
    );
    expect(
      await backups.deviceBackups(),
      hasLength(1),
      reason: 'no second device copy within the week',
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/features/backup/data/backup_service.dart';
import 'package:khaata_digital/features/backup/domain/backup.dart';
import 'package:khaata_digital/features/backup/domain/cloud_backup_store.dart';
import 'package:khaata_digital/features/backup/presentation/backup_bloc.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';
import 'package:khaata_digital/features/settings/domain/settings_repository.dart';

import '../../helpers/fake_cloud.dart';
import '../../helpers/test_app.dart';

void main() {
  setUp(setUpTestApp);

  test('shows a backup made before the screen opened', () async {
    final backups = getIt<BackupService>();
    await backups.record(await backups.create(), BackupDestination.drive);
    await getIt<SettingsRepository>().write(SettingKey.autoBackup, 'true');

    final bloc = getIt<BackupBloc>()..add(const BackupStarted());
    await bloc.stream.firstWhere((s) => s.last != null && s.auto);
    expect(bloc.state.last?.destination, BackupDestination.drive);
    expect(bloc.state.auto, isTrue);
    await bloc.close();
  });

  test('connect, back up to Drive, disconnect', () async {
    final cloud = getIt<CloudBackupStore>() as FakeCloudStore;
    final bloc = getIt<BackupBloc>()..add(const BackupStarted());
    await pumpEventQueue();
    bloc.add(const BackupNow(BackupDestination.drive));
    await bloc.stream.firstWhere((s) => s.notice != null);
    expect(bloc.state.notice, BackupNotice.uploaded);
    expect(bloc.state.driveAccount, 'me@example.com');
    expect(cloud.files, hasLength(1));
    expect(
      await getIt<SettingsRepository>().read(SettingKey.driveAccount),
      'me@example.com',
    );

    bloc.add(const DriveDisconnectRequested());
    await pumpEventQueue();
    expect(bloc.state.driveAccount, isNull);
    expect(cloud.account, isNull);
    await bloc.close();
  });

  test('a failed upload says so and keeps nothing half-done', () async {
    final cloud = getIt<CloudBackupStore>() as FakeCloudStore
      ..account = 'me@example.com'
      ..failUploads = true;
    await getIt<SettingsRepository>().write(
      SettingKey.driveAccount,
      'me@example.com',
    );
    final bloc = getIt<BackupBloc>()..add(const BackupStarted());
    await pumpEventQueue();
    bloc.add(const BackupNow(BackupDestination.drive));
    await bloc.stream.firstWhere((s) => s.notice != null);
    expect(bloc.state.notice, BackupNotice.driveFailed);
    expect(bloc.state.busy, isNull);
    expect(await getIt<BackupService>().lastAt(), isNull);
    expect(cloud.files, isEmpty);
    await bloc.close();
  });
}

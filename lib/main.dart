import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/di/injection.dart';
import 'core/background/background_jobs.dart';
import 'features/settings/domain/setting_key.dart';
import 'features/settings/domain/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  await bootstrap();
  await BackgroundJobs.register(
    wifiOnly:
        await getIt<SettingsRepository>().read(SettingKey.autoBackupWifiOnly) ==
        'true',
  );
  runApp(const KharchaApp());
  unawaited(runAutoBackup());
}

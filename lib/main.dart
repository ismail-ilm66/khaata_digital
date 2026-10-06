import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/di/injection.dart';
import 'core/background/background_jobs.dart';
import 'features/settings/domain/setting_key.dart';
import 'features/settings/domain/settings_repository.dart';

Future<void> main() async {
  // Keep the native launch screen up until the app is ready to draw.
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );
  configureDependencies();
  await bootstrap();
  await BackgroundJobs.register(
    wifiOnly:
        await getIt<SettingsRepository>().read(SettingKey.autoBackupWifiOnly) ==
        'true',
  );
  runApp(const KharchaApp());
  // The first frame is SplashHandoff, identical to the native screen.
  FlutterNativeSplash.remove();
  unawaited(runAutoBackup());
}

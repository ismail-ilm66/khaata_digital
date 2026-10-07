import 'package:injectable/injectable.dart';

import '../../../core/db/app_database.dart';
import '../../settings/domain/setting_key.dart';
import '../../settings/domain/settings_repository.dart';

/// Decides once, at launch, whether the first-run welcome shows.
@lazySingleton
class AppStart {
  AppStart(this._settings, this._db);

  final SettingsRepository _settings;
  final AppDatabase _db;

  bool showWelcome = false;

  Future<void> load() async {
    if (await _settings.read(SettingKey.onboardingDone) == 'true') {
      showWelcome = false;
      return;
    }
    // Someone already using the app (installed before onboarding existed,
    // or just restored a backup) never sees the welcome.
    final row = await _db
        .customSelect('SELECT EXISTS (SELECT 1 FROM transactions) AS used')
        .getSingle();
    if (row.read<bool>('used')) {
      await finish();
      return;
    }
    showWelcome = true;
  }

  Future<void> finish() async {
    showWelcome = false;
    await _settings.write(SettingKey.onboardingDone, 'true');
  }
}

import 'package:injectable/injectable.dart';

import '../../../core/db/app_database.dart';
import '../domain/setting_key.dart';
import '../domain/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<String> read(SettingKey key) => _db.settingsDao.read(key);

  @override
  Future<void> write(SettingKey key, String value) =>
      _db.settingsDao.write(key, value);

  @override
  Stream<String> watch(SettingKey key) => _db.settingsDao.watch(key);
}

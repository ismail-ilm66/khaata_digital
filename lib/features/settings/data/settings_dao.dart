import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables.dart';
import '../domain/setting_key.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  SingleOrNullSelectable<SettingRow> _row(SettingKey key) =>
      select(settings)..where((s) => s.key.equals(key.storageKey));

  /// Stored value, or the key's default when never set.
  Future<String> read(SettingKey key) async =>
      (await _row(key).getSingleOrNull())?.value ?? key.defaultValue;

  Stream<String> watch(SettingKey key) =>
      _row(key).watchSingleOrNull().map((r) => r?.value ?? key.defaultValue);

  Future<void> write(SettingKey key, String value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: key.storageKey, value: value),
      );
}

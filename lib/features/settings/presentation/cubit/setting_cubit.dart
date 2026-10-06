import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/setting_key.dart';
import '../../domain/settings_repository.dart';

/// A cubit holding one persisted setting. Subclasses only say how to
/// convert between the stored string and the typed value.
abstract class SettingCubit<T> extends Cubit<T> {
  SettingCubit(this._repository, this.key, T initial) : super(initial);

  final SettingsRepository _repository;
  final SettingKey key;

  T decode(String stored);
  String encode(T value);

  /// Loads the stored value; call once at startup.
  Future<void> load() async => emit(decode(await _repository.read(key)));

  /// Emits [value] immediately and persists it.
  Future<void> set(T value) async {
    emit(value);
    await _repository.write(key, encode(value));
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:khaata_digital/core/db/app_database.dart' as _i577;
import 'package:khaata_digital/core/di/database_module.dart' as _i503;
import 'package:khaata_digital/features/settings/data/settings_repository_impl.dart'
    as _i744;
import 'package:khaata_digital/features/settings/domain/settings_repository.dart'
    as _i109;
import 'package:khaata_digital/features/settings/presentation/cubit/locale_cubit.dart'
    as _i310;
import 'package:khaata_digital/features/settings/presentation/cubit/theme_cubit.dart'
    as _i547;

const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    gh.singleton<_i577.AppDatabase>(
      () => databaseModule.database,
      registerFor: {_prod},
      dispose: _i503.closeDatabase,
    );
    gh.lazySingleton<_i109.SettingsRepository>(
      () => _i744.SettingsRepositoryImpl(gh<_i577.AppDatabase>()),
    );
    gh.lazySingleton<_i310.LocaleCubit>(
      () => _i310.LocaleCubit(gh<_i109.SettingsRepository>()),
    );
    gh.lazySingleton<_i547.ThemeCubit>(
      () => _i547.ThemeCubit(gh<_i109.SettingsRepository>()),
    );
    return this;
  }
}

class _$DatabaseModule extends _i503.DatabaseModule {}

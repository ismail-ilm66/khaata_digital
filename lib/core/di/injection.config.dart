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
import 'package:khaata_digital/features/settings/presentation/cubit/locale_cubit.dart'
    as _i310;
import 'package:khaata_digital/features/settings/presentation/cubit/theme_cubit.dart'
    as _i547;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i310.LocaleCubit>(() => _i310.LocaleCubit());
    gh.lazySingleton<_i547.ThemeCubit>(() => _i547.ThemeCubit());
    return this;
  }
}

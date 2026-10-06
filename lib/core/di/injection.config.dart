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
import 'package:khaata_digital/features/accounts/data/accounts_repository_impl.dart'
    as _i546;
import 'package:khaata_digital/features/accounts/domain/account.dart' as _i720;
import 'package:khaata_digital/features/accounts/presentation/account_form_cubit.dart'
    as _i698;
import 'package:khaata_digital/features/accounts/presentation/accounts_bloc.dart'
    as _i693;
import 'package:khaata_digital/features/categories/data/categories_repository_impl.dart'
    as _i787;
import 'package:khaata_digital/features/categories/domain/category.dart'
    as _i420;
import 'package:khaata_digital/features/home/presentation/home_cubit.dart'
    as _i24;
import 'package:khaata_digital/features/settings/data/settings_repository_impl.dart'
    as _i744;
import 'package:khaata_digital/features/settings/domain/settings_repository.dart'
    as _i109;
import 'package:khaata_digital/features/settings/presentation/cubit/locale_cubit.dart'
    as _i310;
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart'
    as _i795;
import 'package:khaata_digital/features/settings/presentation/cubit/theme_cubit.dart'
    as _i547;
import 'package:khaata_digital/features/transactions/data/receipt_store.dart'
    as _i761;
import 'package:khaata_digital/features/transactions/data/transactions_repository_impl.dart'
    as _i724;
import 'package:khaata_digital/features/transactions/domain/transactions_repository.dart'
    as _i208;
import 'package:khaata_digital/features/transactions/presentation/form/transaction_form_bloc.dart'
    as _i595;
import 'package:khaata_digital/features/transactions/presentation/list/transaction_list_bloc.dart'
    as _i610;

const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    final receiptModule = _$ReceiptModule();
    gh.singleton<_i577.AppDatabase>(
      () => databaseModule.database,
      registerFor: {_prod},
      dispose: _i503.closeDatabase,
    );
    gh.lazySingleton<_i761.ReceiptStore>(
      () => receiptModule.receiptStore,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i720.AccountsRepository>(
      () => _i546.AccountsRepositoryImpl(gh<_i577.AppDatabase>()),
    );
    gh.lazySingleton<_i208.TransactionsRepository>(
      () => _i724.TransactionsRepositoryImpl(
        gh<_i577.AppDatabase>(),
        gh<_i761.ReceiptStore>(),
      ),
    );
    gh.factory<_i610.TransactionListBloc>(
      () => _i610.TransactionListBloc(gh<_i208.TransactionsRepository>()),
    );
    gh.lazySingleton<_i109.SettingsRepository>(
      () => _i744.SettingsRepositoryImpl(gh<_i577.AppDatabase>()),
    );
    gh.factory<_i698.AccountFormCubit>(
      () => _i698.AccountFormCubit(gh<_i720.AccountsRepository>()),
    );
    gh.factory<_i693.AccountsBloc>(
      () => _i693.AccountsBloc(gh<_i720.AccountsRepository>()),
    );
    gh.lazySingleton<_i420.CategoriesRepository>(
      () => _i787.CategoriesRepositoryImpl(gh<_i577.AppDatabase>()),
    );
    gh.lazySingleton<_i795.HideBalanceCubit>(
      () => _i795.HideBalanceCubit(gh<_i109.SettingsRepository>()),
    );
    gh.lazySingleton<_i795.BudgetCycleCubit>(
      () => _i795.BudgetCycleCubit(gh<_i109.SettingsRepository>()),
    );
    gh.lazySingleton<_i795.CurrencyCubit>(
      () => _i795.CurrencyCubit(gh<_i109.SettingsRepository>()),
    );
    gh.lazySingleton<_i310.LocaleCubit>(
      () => _i310.LocaleCubit(gh<_i109.SettingsRepository>()),
    );
    gh.lazySingleton<_i547.ThemeCubit>(
      () => _i547.ThemeCubit(gh<_i109.SettingsRepository>()),
    );
    gh.factory<_i595.TransactionFormBloc>(
      () => _i595.TransactionFormBloc(
        gh<_i208.TransactionsRepository>(),
        gh<_i720.AccountsRepository>(),
        gh<_i420.CategoriesRepository>(),
        gh<_i109.SettingsRepository>(),
      ),
    );
    gh.factory<_i24.HomeCubit>(
      () => _i24.HomeCubit(
        gh<_i720.AccountsRepository>(),
        gh<_i208.TransactionsRepository>(),
        gh<_i795.BudgetCycleCubit>(),
      ),
    );
    return this;
  }
}

class _$DatabaseModule extends _i503.DatabaseModule {}

class _$ReceiptModule extends _i761.ReceiptModule {}

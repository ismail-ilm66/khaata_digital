// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i163;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:khaata_digital/core/app_refresh.dart' as _i825;
import 'package:khaata_digital/core/db/app_database.dart' as _i577;
import 'package:khaata_digital/core/di/database_module.dart' as _i503;
import 'package:khaata_digital/core/files/file_gateway.dart' as _i635;
import 'package:khaata_digital/features/accounts/data/accounts_repository_impl.dart'
    as _i546;
import 'package:khaata_digital/features/accounts/domain/account.dart' as _i720;
import 'package:khaata_digital/features/accounts/presentation/account_form_cubit.dart'
    as _i698;
import 'package:khaata_digital/features/accounts/presentation/accounts_bloc.dart'
    as _i693;
import 'package:khaata_digital/features/backup/data/auto_backup.dart' as _i746;
import 'package:khaata_digital/features/backup/data/backup_service.dart'
    as _i122;
import 'package:khaata_digital/features/backup/data/google_drive_store.dart'
    as _i1066;
import 'package:khaata_digital/features/backup/domain/cloud_backup_store.dart'
    as _i597;
import 'package:khaata_digital/features/backup/presentation/backup_bloc.dart'
    as _i102;
import 'package:khaata_digital/features/backup/presentation/backup_health.dart'
    as _i904;
import 'package:khaata_digital/features/backup/presentation/restore_bloc.dart'
    as _i262;
import 'package:khaata_digital/features/budgets/data/budgets_repository_impl.dart'
    as _i414;
import 'package:khaata_digital/features/budgets/domain/budget.dart' as _i608;
import 'package:khaata_digital/features/budgets/presentation/budgets_bloc.dart'
    as _i589;
import 'package:khaata_digital/features/categories/data/categories_repository_impl.dart'
    as _i787;
import 'package:khaata_digital/features/categories/domain/category.dart'
    as _i420;
import 'package:khaata_digital/features/categories/presentation/categories_cubit.dart'
    as _i276;
import 'package:khaata_digital/features/home/presentation/home_cubit.dart'
    as _i24;
import 'package:khaata_digital/features/import_export/data/export_service.dart'
    as _i644;
import 'package:khaata_digital/features/import_export/data/import_service.dart'
    as _i511;
import 'package:khaata_digital/features/import_export/domain/exporter.dart'
    as _i1;
import 'package:khaata_digital/features/import_export/presentation/import_bloc.dart'
    as _i178;
import 'package:khaata_digital/features/onboarding/data/app_start.dart'
    as _i397;
import 'package:khaata_digital/features/onboarding/presentation/onboarding_cubit.dart'
    as _i109;
import 'package:khaata_digital/features/people/data/people_repository_impl.dart'
    as _i733;
import 'package:khaata_digital/features/people/domain/person.dart' as _i260;
import 'package:khaata_digital/features/recurring/data/recurring_repository_impl.dart'
    as _i1059;
import 'package:khaata_digital/features/recurring/data/reminders.dart' as _i985;
import 'package:khaata_digital/features/recurring/domain/recurring_rule.dart'
    as _i295;
import 'package:khaata_digital/features/reports/data/reports_repository_impl.dart'
    as _i423;
import 'package:khaata_digital/features/reports/domain/report.dart' as _i318;
import 'package:khaata_digital/features/reports/presentation/reports_bloc.dart'
    as _i556;
import 'package:khaata_digital/features/security/data/local_device_auth.dart'
    as _i36;
import 'package:khaata_digital/features/security/domain/device_auth.dart'
    as _i234;
import 'package:khaata_digital/features/security/presentation/lock_cubit.dart'
    as _i246;
import 'package:khaata_digital/features/settings/data/diagnostics.dart'
    as _i756;
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
    final reminderModule = _$ReminderModule();
    final databaseModule = _$DatabaseModule();
    final receiptModule = _$ReceiptModule();
    gh.lazySingleton<_i904.BackupHealth>(() => _i904.BackupHealth());
    gh.lazySingleton<_i163.FlutterLocalNotificationsPlugin>(
      () => reminderModule.notifications,
    );
    gh.lazySingleton<_i597.CloudBackupStore>(
      () => _i1066.GoogleDriveStore(),
      registerFor: {_prod},
    );
    gh.singleton<_i577.AppDatabase>(
      () => databaseModule.database,
      registerFor: {_prod},
      dispose: _i503.closeDatabase,
    );
    gh.lazySingleton<_i761.ReceiptStore>(
      () => receiptModule.receiptStore,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i122.BackupService>(
      () => _i122.BackupService(
        gh<_i577.AppDatabase>(),
        gh<_i761.ReceiptStore>(),
      ),
    );
    gh.lazySingleton<_i511.ImportService>(
      () => _i511.ImportService(gh<_i577.AppDatabase>()),
    );
    gh.lazySingleton<_i234.DeviceAuth>(
      () => _i36.LocalDeviceAuth(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i635.FileGateway>(
      () => _i635.SystemFileGateway(),
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
    gh.lazySingleton<_i608.BudgetsRepository>(
      () => _i414.BudgetsRepositoryImpl(gh<_i577.AppDatabase>()),
    );
    gh.lazySingleton<_i318.ReportsRepository>(
      () => _i423.ReportsRepositoryImpl(gh<_i577.AppDatabase>()),
    );
    gh.factory<_i610.TransactionListBloc>(
      () => _i610.TransactionListBloc(gh<_i208.TransactionsRepository>()),
    );
    gh.lazySingleton<_i756.Diagnostics>(
      () => _i756.Diagnostics(
        gh<_i122.BackupService>(),
        gh<_i904.BackupHealth>(),
        gh<_i577.AppDatabase>(),
      ),
    );
    gh.lazySingleton<_i109.SettingsRepository>(
      () => _i744.SettingsRepositoryImpl(gh<_i577.AppDatabase>()),
    );
    gh.lazySingleton<_i246.LockCubit>(
      () => _i246.LockCubit(
        gh<_i109.SettingsRepository>(),
        gh<_i234.DeviceAuth>(),
      ),
    );
    gh.lazySingleton<_i1.Exporter>(
      () => _i644.ExportService(
        gh<_i208.TransactionsRepository>(),
        gh<_i720.AccountsRepository>(),
      ),
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
    gh.lazySingleton<_i795.HapticsCubit>(
      () => _i795.HapticsCubit(gh<_i109.SettingsRepository>()),
    );
    gh.lazySingleton<_i795.BudgetCycleCubit>(
      () => _i795.BudgetCycleCubit(gh<_i109.SettingsRepository>()),
    );
    gh.lazySingleton<_i795.CurrencyCubit>(
      () => _i795.CurrencyCubit(gh<_i109.SettingsRepository>()),
    );
    gh.lazySingleton<_i260.PeopleRepository>(
      () => _i733.PeopleRepositoryImpl(
        gh<_i577.AppDatabase>(),
        gh<_i208.TransactionsRepository>(),
      ),
    );
    gh.lazySingleton<_i310.LocaleCubit>(
      () => _i310.LocaleCubit(gh<_i109.SettingsRepository>()),
    );
    gh.lazySingleton<_i547.ThemeCubit>(
      () => _i547.ThemeCubit(gh<_i109.SettingsRepository>()),
    );
    gh.lazySingleton<_i295.RecurringRepository>(
      () => _i1059.RecurringRepositoryImpl(
        gh<_i577.AppDatabase>(),
        gh<_i208.TransactionsRepository>(),
      ),
    );
    gh.lazySingleton<_i295.ReminderScheduler>(
      () => reminderModule.reminders(
        gh<_i163.FlutterLocalNotificationsPlugin>(),
        gh<_i109.SettingsRepository>(),
      ),
      registerFor: {_prod},
    );
    gh.factory<_i589.BudgetsBloc>(
      () => _i589.BudgetsBloc(
        gh<_i608.BudgetsRepository>(),
        gh<_i795.BudgetCycleCubit>(),
        gh<_i795.CurrencyCubit>(),
      ),
    );
    gh.factory<_i178.ImportBloc>(
      () => _i178.ImportBloc(
        gh<_i511.ImportService>(),
        gh<_i122.BackupService>(),
        gh<_i795.CurrencyCubit>(),
        gh<_i720.AccountsRepository>(),
      ),
    );
    gh.lazySingleton<_i397.AppStart>(
      () => _i397.AppStart(
        gh<_i109.SettingsRepository>(),
        gh<_i577.AppDatabase>(),
      ),
    );
    gh.lazySingleton<_i746.AutoBackup>(
      () => _i746.AutoBackup(
        gh<_i122.BackupService>(),
        gh<_i597.CloudBackupStore>(),
        gh<_i109.SettingsRepository>(),
      ),
    );
    gh.factory<_i102.BackupBloc>(
      () => _i102.BackupBloc(
        gh<_i122.BackupService>(),
        gh<_i597.CloudBackupStore>(),
        gh<_i109.SettingsRepository>(),
        gh<_i635.FileGateway>(),
      ),
    );
    gh.factory<_i595.TransactionFormBloc>(
      () => _i595.TransactionFormBloc(
        gh<_i208.TransactionsRepository>(),
        gh<_i720.AccountsRepository>(),
        gh<_i420.CategoriesRepository>(),
        gh<_i109.SettingsRepository>(),
        gh<_i260.PeopleRepository>(),
        gh<_i295.RecurringRepository>(),
        gh<_i295.ReminderScheduler>(),
      ),
    );
    gh.factory<_i24.HomeCubit>(
      () => _i24.HomeCubit(
        gh<_i720.AccountsRepository>(),
        gh<_i208.TransactionsRepository>(),
        gh<_i608.BudgetsRepository>(),
        gh<_i260.PeopleRepository>(),
        gh<_i795.BudgetCycleCubit>(),
        gh<_i795.CurrencyCubit>(),
      ),
    );
    gh.factory<_i276.CategoriesCubit>(
      () => _i276.CategoriesCubit(gh<_i420.CategoriesRepository>()),
    );
    gh.factory<_i556.ReportsBloc>(
      () => _i556.ReportsBloc(
        gh<_i318.ReportsRepository>(),
        gh<_i795.BudgetCycleCubit>(),
        gh<_i795.CurrencyCubit>(),
      ),
    );
    gh.factory<_i109.OnboardingCubit>(
      () => _i109.OnboardingCubit(
        gh<_i795.CurrencyCubit>(),
        gh<_i795.BudgetCycleCubit>(),
        gh<_i720.AccountsRepository>(),
        gh<_i397.AppStart>(),
      ),
    );
    gh.lazySingleton<_i825.AppRefresh>(
      () => _i825.AppRefresh(
        gh<_i547.ThemeCubit>(),
        gh<_i310.LocaleCubit>(),
        gh<_i795.HideBalanceCubit>(),
        gh<_i795.BudgetCycleCubit>(),
        gh<_i795.CurrencyCubit>(),
        gh<_i795.HapticsCubit>(),
        gh<_i295.RecurringRepository>(),
        gh<_i295.ReminderScheduler>(),
      ),
    );
    gh.factory<_i262.RestoreBloc>(
      () => _i262.RestoreBloc(
        gh<_i122.BackupService>(),
        gh<_i825.AppRefresh>(),
        gh<_i904.BackupHealth>(),
      ),
    );
    return this;
  }
}

class _$ReminderModule extends _i985.ReminderModule {}

class _$DatabaseModule extends _i503.DatabaseModule {}

class _$ReceiptModule extends _i761.ReceiptModule {}

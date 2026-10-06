import 'package:flutter/foundation.dart';

import 'core/db/app_database.dart';
import 'core/di/injection.dart';
import 'features/settings/presentation/cubit/locale_cubit.dart';
import 'features/settings/presentation/cubit/preference_cubits.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';

/// Startup work shared by the app and widget tests: verify the database
/// and load persisted settings before the first frame.
Future<void> bootstrap() async {
  final healthy = await getIt<AppDatabase>().checkIntegrity();
  if (!healthy) {
    // M5 surfaces this with a restore prompt; never silently continue
    // writing to a corrupt file without the user knowing.
    debugPrint('Kharcha: database integrity check failed');
  }
  await Future.wait([
    getIt<ThemeCubit>().load(),
    getIt<LocaleCubit>().load(),
    getIt<HideBalanceCubit>().load(),
    getIt<BudgetCycleCubit>().load(),
    getIt<CurrencyCubit>().load(),
  ]);
}

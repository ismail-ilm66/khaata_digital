import 'package:injectable/injectable.dart';

import '../db/app_database.dart';

@module
abstract class DatabaseModule {
  /// Tests register an in-memory [AppDatabase] themselves instead.
  @prod
  @Singleton(dispose: closeDatabase)
  AppDatabase get database => AppDatabase.open();
}

Future<void> closeDatabase(AppDatabase db) => db.close();

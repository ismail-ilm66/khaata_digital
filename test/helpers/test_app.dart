import 'package:injectable/injectable.dart';
import 'package:khaata_digital/bootstrap.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/features/transactions/data/receipt_store.dart';

import 'test_db.dart';
import 'test_receipts.dart';

/// Resets DI with an in-memory database and temp receipt storage, then runs
/// the real [bootstrap].
Future<AppDatabase> setUpTestApp() async {
  await getIt.reset();
  final db = testDb();
  getIt
    ..registerSingleton<AppDatabase>(db, dispose: (d) => d.close())
    ..registerSingleton<ReceiptStore>(testReceiptStore());
  configureDependencies(environment: Environment.test);
  await bootstrap();
  return db;
}

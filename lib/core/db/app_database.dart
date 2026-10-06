import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/accounts/data/accounts_dao.dart';
import '../../features/accounts/domain/account_type.dart';
import '../../features/budgets/data/budgets_dao.dart';
import '../../features/categories/data/categories_dao.dart';
import '../../features/categories/domain/category_kind.dart';
import '../../features/people/data/people_dao.dart';
import '../../features/recurring/domain/recurrence.dart';
import '../../features/settings/data/settings_dao.dart';
import '../../features/transactions/data/attachments_dao.dart';
import '../../features/transactions/data/labels_dao.dart';
import '../../features/transactions/data/transactions_dao.dart';
import '../../features/transactions/domain/transaction_type.dart';
import 'app_database.steps.dart';
import 'columns.dart';
import 'seed.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The Kharcha database (SQLite via Drift).
///
/// Schema changes: bump [schemaVersion], run
/// `dart run drift_dev make-migrations`, add the step to [migration], and
/// commit a new golden fixture (see `test/golden/README.md`).
@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    People,
    Transactions,
    Tags,
    TransactionTags,
    Events,
    TransactionEvents,
    Attachments,
    Budgets,
    RecurringRules,
    Settings,
    BackupMeta,
    ImportHashes,
  ],
  daos: [
    AccountsDao,
    CategoriesDao,
    PeopleDao,
    TransactionsDao,
    LabelsDao,
    AttachmentsDao,
    BudgetsDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database file.
  /// Shared across isolates so the background recurring job and the app
  /// never write to the file at the same time.
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'kharcha',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    ),
  );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDatabase(this);
    },
    onUpgrade: stepByStep(
      // v2: import idempotency (spec 3.3).
      from1To2: (m, schema) async {
        await m.createTable(schema.importHashes);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  /// Runs `PRAGMA integrity_check`; true when SQLite reports "ok".
  Future<bool> checkIntegrity() async {
    final rows = await customSelect('PRAGMA integrity_check').get();
    return rows.length == 1 && rows.single.data.values.single == 'ok';
  }
}

import 'package:drift/drift.dart';

import '../../features/accounts/domain/account_type.dart';
import '../../features/categories/domain/category_kind.dart';
import '../../features/recurring/domain/recurrence.dart';
import '../../features/transactions/domain/transaction_type.dart';
import 'columns.dart';

// Schema from spec Phase 3.3. Table names are final. Data classes carry a
// `Row` suffix to keep them distinct from domain entities.
//
// Partial unique indexes scope names to non-deleted rows, so an archived
// name can be reused (spec complaint #8). Names compare case-insensitively.

@DataClassName('AccountRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX accounts_active_name '
  'ON accounts (name COLLATE NOCASE) WHERE deleted_at IS NULL',
)
class Accounts extends Table
    with Entity, Timestamped, SoftDelete, Sortable, Named {
  TextColumn get type => textEnum<AccountType>()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  IntColumn get openingBalanceMinor =>
      integer().withDefault(const Constant(0))();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
  BoolColumn get excludeFromTotal =>
      boolean().withDefault(const Constant(false))();
}

@DataClassName('CategoryRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX categories_active_name '
  'ON categories (kind, name COLLATE NOCASE) WHERE deleted_at IS NULL',
)
class Categories extends Table
    with Entity, Timestamped, SoftDelete, Sortable, Named {
  TextColumn get kind => textEnum<CategoryKind>()();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();

  /// Reserved for v2 subcategories.
  TextColumn get parentId => text().nullable().references(Categories, #id)();
}

@DataClassName('PersonRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX people_active_name '
  'ON people (name COLLATE NOCASE) WHERE deleted_at IS NULL',
)
class People extends Table with Entity, Timestamped, SoftDelete, Named {
  TextColumn get contactHint => text().nullable()();
}

@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_occurred_at', columns: {#occurredAt})
@TableIndex(name: 'transactions_account', columns: {#accountId})
@TableIndex(name: 'transactions_to_account', columns: {#toAccountId})
@TableIndex(name: 'transactions_category', columns: {#categoryId})
@TableIndex(name: 'transactions_person', columns: {#personId})
class Transactions extends Table with Entity, Timestamped, SoftDelete {
  TextColumn get type => textEnum<TransactionType>()();

  /// Positive minor units; sign only for adjustments (see [TransactionType]).
  IntColumn get amountMinor => integer()();

  /// Currency of [amountMinor] — always the source account's currency.
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get accountId => text().references(Accounts, #id)();

  /// Transfers only: one row per transfer, both sides derived in queries.
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();

  /// Cross-currency transfers: amount credited to [toAccountId] …
  IntColumn get toAmountMinor => integer().nullable()();

  /// … and the manual rate used, in micros (target per 1 source unit).
  IntColumn get fxRateMicros => integer().nullable()();

  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get personId => text().nullable().references(People, #id)();
  IntColumn get occurredAt => integer().map(const UtcMillisConverter())();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get place => text().nullable()();

  @override
  List<String> get customConstraints => const [
    "CHECK (amount_minor > 0 OR (type = 'adjustment' AND amount_minor <> 0))",
    "CHECK ((type = 'transfer') = (to_account_id IS NOT NULL))",
    'CHECK (to_account_id IS NULL OR to_account_id <> account_id)',
    'CHECK (to_amount_minor IS NULL OR to_amount_minor > 0)',
    "CHECK (type = 'transfer' OR "
        '(to_amount_minor IS NULL AND fx_rate_micros IS NULL))',
  ];
}

@DataClassName('TagRow')
@TableIndex.sql('CREATE UNIQUE INDEX tags_name ON tags (name COLLATE NOCASE)')
class Tags extends Table with Entity, Named {}

@DataClassName('TransactionTagRow')
class TransactionTags extends Table {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {transactionId, tagId};
}

@DataClassName('EventRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX events_name ON events (name COLLATE NOCASE)',
)
class Events extends Table with Entity, Named {}

@DataClassName('TransactionEventRow')
class TransactionEvents extends Table {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get eventId =>
      text().references(Events, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {transactionId, eventId};
}

/// Receipt metadata; files live under `appdocs/receipts/`.
@DataClassName('AttachmentRow')
class Attachments extends Table with Entity, Timestamped {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  TextColumn get mime => text()();
  IntColumn get byteSize => integer()();
  TextColumn get sha256 => text().withLength(min: 64, max: 64)();
}

/// [categoryId] null = the overall budget for the cycle.
@DataClassName('BudgetRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX budgets_cycle_category ON budgets '
  "(ifnull(category_id, ''), cycle_year, cycle_month)",
)
class Budgets extends Table with Entity, Timestamped {
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get amountMinor => integer()();
  IntColumn get cycleYear => integer()();
  IntColumn get cycleMonth => integer()();

  @override
  List<String> get customConstraints => const [
    'CHECK (amount_minor > 0)',
    'CHECK (cycle_month BETWEEN 1 AND 12)',
  ];
}

@DataClassName('RecurringRuleRow')
class RecurringRules extends Table with Entity, Timestamped, SoftDelete {
  /// JSON of the transaction fields to materialise.
  TextColumn get template => text()();
  TextColumn get freq => textEnum<RecurrenceFrequency>()();
  IntColumn get interval => integer().withDefault(const Constant(1))();
  TextColumn get dayRule =>
      textEnum<DayRule>().withDefault(Constant(DayRule.clampToMonthEnd.name))();
  IntColumn get nextRunAt => integer().map(const UtcMillisConverter())();
  IntColumn get endAt => integer().map(const UtcMillisConverter()).nullable()();

  @override
  List<String> get customConstraints => const ['CHECK (interval >= 1)'];
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('BackupMetaRow')
class BackupMeta extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get createdAt => integer().map(const UtcMillisConverter())();
  TextColumn get destination => text()();
  IntColumn get schemaVersion => integer()();

  /// JSON object of table name → row count.
  TextColumn get rowCounts => text()();
}

/// Schema v2. One row per imported source record (spec 3.3: imports are
/// idempotent). [hash] is the SHA-256 of the record's source cells plus
/// its occurrence number in the file, so re-importing the same file finds
/// every record already here.
@DataClassName('ImportHashRow')
class ImportHashes extends Table {
  TextColumn get hash => text().withLength(min: 64, max: 64)();

  /// The entry created; null once that entry is purged.
  TextColumn get transactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get importedAt => integer().map(const UtcMillisConverter())();

  @override
  Set<Column<Object>> get primaryKey => {hash};
}

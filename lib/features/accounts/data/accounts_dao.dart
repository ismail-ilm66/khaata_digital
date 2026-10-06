import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/entity_ops.dart';
import '../../../core/db/ledger_sql.dart';
import '../../../core/db/tables.dart';
import '../domain/account_type.dart';

part 'accounts_dao.g.dart';

@immutable
class AccountBalance {
  const AccountBalance(this.account, this.balanceMinor);

  final AccountRow account;

  /// In the account's own currency.
  final int balanceMinor;

  /// Net worth per currency, skipping accounts excluded from totals.
  /// Currencies are never mixed: there are no automatic rates in v1.
  static Map<String, int> totalsByCurrency(Iterable<AccountBalance> all) {
    final totals = <String, int>{};
    for (final b in all) {
      if (b.account.excludeFromTotal) continue;
      totals.update(
        b.account.currencyCode,
        (v) => v + b.balanceMinor,
        ifAbsent: () => b.balanceMinor,
      );
    }
    return totals;
  }
}

@DriftAccessor(tables: [Accounts, Transactions])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.attachedDatabase);

  Selectable<AccountBalance> _balances() {
    return customSelect(
      '''
SELECT a.*, a.opening_balance_minor
  + COALESCE((SELECT SUM(${LedgerSql.sourceDelta}) FROM transactions t
              WHERE t.account_id = a.id AND ${LedgerSql.live}), 0)
  + COALESCE((SELECT SUM(${LedgerSql.destinationCredit}) FROM transactions t
              WHERE t.to_account_id = a.id AND ${LedgerSql.live}), 0)
  AS balance_minor
FROM accounts a
WHERE a.deleted_at IS NULL
ORDER BY a.sort_order, a.name
''',
      readsFrom: {accounts, transactions},
    ).map(
      (row) => AccountBalance(
        accounts.map(row.data),
        row.read<int>('balance_minor'),
      ),
    );
  }

  /// Active accounts in user order with their current balances.
  Future<List<AccountBalance>> balances() => _balances().get();
  Stream<List<AccountBalance>> watchBalances() => _balances().watch();

  Future<List<AccountRow>> archived() =>
      (select(accounts)
            ..where((a) => a.deletedAt.isNotNull())
            ..orderBy([(a) => OrderingTerm.asc(a.name)]))
          .get();

  /// Adds an account at the end of the list and returns its id.
  Future<String> create({
    required String name,
    required AccountType type,
    required String currencyCode,
    int openingBalanceMinor = 0,
    String? icon,
    int? color,
    bool excludeFromTotal = false,
  }) async {
    final row = await into(accounts).insertReturning(
      AccountsCompanion.insert(
        name: name.trim(),
        type: type,
        currencyCode: currencyCode,
        openingBalanceMinor: Value(openingBalanceMinor),
        icon: Value(icon),
        color: Value(color),
        excludeFromTotal: Value(excludeFromTotal),
        sortOrder: Value(await nextSortOrder(accounts)),
      ),
    );
    return row.id;
  }

  Future<void> edit(String id, AccountsCompanion changes) {
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      changes.copyWith(updatedAt: Value(DateTime.now().toUtc())),
    );
  }

  Future<void> archive(String id) => softDelete(accounts, id);
  Future<void> unarchive(String id) => undelete(accounts, id);
  Future<void> reorderAccounts(List<String> ids) => reorder(accounts, ids);
}

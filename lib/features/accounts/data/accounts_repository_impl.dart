import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/unique_guard.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../domain/account.dart';
import 'accounts_dao.dart';

extension AccountRowMapping on AccountRow {
  Account toDomain() {
    final currency = Currency.of(currencyCode);
    return Account(
      id: id,
      name: name,
      type: type,
      currency: currency,
      openingBalance: Money(openingBalanceMinor, currency),
      iconKey: icon,
      color: color,
      excludeFromTotal: excludeFromTotal,
      isArchived: deletedAt != null,
    );
  }
}

@LazySingleton(as: AccountsRepository)
class AccountsRepositoryImpl implements AccountsRepository {
  AccountsRepositoryImpl(this._db);

  final AppDatabase _db;
  AccountsDao get _dao => _db.accountsDao;

  @override
  Stream<AccountsOverview> watchOverview() => _dao.watchBalances().map((rows) {
    final totals = AccountBalance.totalsByCurrency(rows);
    return AccountsOverview(
      accounts: [
        for (final r in rows)
          AccountSummary(
            r.account.toDomain(),
            Money(r.balanceMinor, Currency.of(r.account.currencyCode)),
          ),
      ],
      netWorth: {
        for (final e in totals.entries)
          Currency.of(e.key): Money(e.value, Currency.of(e.key)),
      },
    );
  });

  @override
  Stream<List<Account>> watchArchived() =>
      _dao.watchArchived().map((rows) => [for (final r in rows) r.toDomain()]);

  @override
  Future<Account?> byId(String id) async => (await _dao.byId(id))?.toDomain();

  @override
  Future<String> create(AccountDraft d) => guardUniqueName(
    d.name,
    () => _dao.create(
      name: d.name,
      type: d.type,
      currencyCode: d.currency.code,
      openingBalanceMinor: d.openingBalance.minor,
      icon: d.iconKey,
      color: d.color,
      excludeFromTotal: d.excludeFromTotal,
    ),
  );

  @override
  Future<void> update(String id, AccountDraft d) => guardUniqueName(
    d.name,
    () => _dao.edit(
      id,
      AccountsCompanion(
        name: Value(d.name.trim()),
        type: Value(d.type),
        currencyCode: Value(d.currency.code),
        openingBalanceMinor: Value(d.openingBalance.minor),
        icon: Value(d.iconKey),
        color: Value(d.color),
        excludeFromTotal: Value(d.excludeFromTotal),
      ),
    ),
  );

  @override
  Future<void> archive(String id) => _dao.archive(id);

  @override
  Future<void> unarchive(String id) async {
    final row = await _dao.byId(id);
    await guardUniqueName(row?.name ?? '', () => _dao.unarchive(id));
  }

  @override
  Future<void> reorder(List<String> orderedIds) =>
      _dao.reorderAccounts(orderedIds);
}

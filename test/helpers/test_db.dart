import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/features/accounts/domain/account_type.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

/// A fresh, seeded, in-memory database.
AppDatabase testDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Terse builders for ledger rows, shared by DAO, 10k and golden tests.
class TestLedger {
  TestLedger(this.db);

  final AppDatabase db;

  static final DateTime defaultDate = DateTime.utc(2026, 9, 1, 12);

  Future<String> account(
    String name, {
    String currency = 'PKR',
    int opening = 0,
    AccountType type = AccountType.bank,
    bool excludeFromTotal = false,
    String? id,
  }) async {
    if (id == null) {
      return db.accountsDao.create(
        name: name,
        type: type,
        currencyCode: currency,
        openingBalanceMinor: opening,
        excludeFromTotal: excludeFromTotal,
      );
    }
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(id),
            name: name,
            type: type,
            currencyCode: currency,
            openingBalanceMinor: Value(opening),
            excludeFromTotal: Value(excludeFromTotal),
          ),
        );
    return id;
  }

  Future<String> expense(
    String accountId,
    int amount, {
    String currency = 'PKR',
    DateTime? at,
    String? personId,
    String? categoryId,
    String? id,
  }) => _add(
    TransactionType.expense,
    accountId,
    amount,
    currency: currency,
    at: at,
    personId: personId,
    categoryId: categoryId,
    id: id,
  );

  Future<String> income(
    String accountId,
    int amount, {
    String currency = 'PKR',
    DateTime? at,
    String? personId,
    String? id,
  }) => _add(
    TransactionType.income,
    accountId,
    amount,
    currency: currency,
    at: at,
    personId: personId,
    id: id,
  );

  Future<String> adjustment(
    String accountId,
    int signedAmount, {
    String currency = 'PKR',
    String? id,
  }) => _add(
    TransactionType.adjustment,
    accountId,
    signedAmount,
    currency: currency,
    id: id,
  );

  Future<String> transfer(
    String from,
    String to,
    int amount, {
    String currency = 'PKR',
    int? toAmount,
    int? rateMicros,
    String? id,
  }) => _add(
    TransactionType.transfer,
    from,
    amount,
    currency: currency,
    to: to,
    toAmount: toAmount,
    rateMicros: rateMicros,
    id: id,
  );

  Future<String> _add(
    TransactionType type,
    String accountId,
    int amount, {
    required String currency,
    DateTime? at,
    String? to,
    int? toAmount,
    int? rateMicros,
    String? personId,
    String? categoryId,
    String? id,
  }) {
    return db.transactionsDao.add(
      TransactionsCompanion.insert(
        id: id == null ? const Value.absent() : Value(id),
        type: type,
        amountMinor: amount,
        currencyCode: currency,
        accountId: accountId,
        toAccountId: Value(to),
        toAmountMinor: Value(toAmount),
        fxRateMicros: Value(rateMicros),
        personId: Value(personId),
        categoryId: Value(categoryId),
        occurredAt: at ?? defaultDate,
      ),
    );
  }

  Future<int> balanceOf(String accountId) async {
    final all = await db.accountsDao.balances();
    return all.firstWhere((b) => b.account.id == accountId).balanceMinor;
  }
}

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/features/accounts/data/accounts_dao.dart';

import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TestLedger ledger;
  late String cash;

  setUp(() async {
    db = testDb();
    ledger = TestLedger(db);
    cash = (await db.accountsDao.balances()).single.account.id;
  });
  tearDown(() => db.close());

  test('balance = opening + income − expense ± adjustments', () async {
    final bank = await ledger.account('Meezan Bank', opening: 1066100);
    await ledger.income(bank, 500000);
    await ledger.expense(bank, 252000);
    await ledger.adjustment(bank, -100);
    await ledger.adjustment(bank, 50);
    expect(await ledger.balanceOf(bank), 1066100 + 500000 - 252000 - 100 + 50);
  });

  test(
    'a transfer is one row and moves both sides correctly (complaint #7)',
    () async {
      final bank = await ledger.account('Bank', opening: 100000);
      await ledger.transfer(bank, cash, 30000);

      final rows = await db.select(db.transactions).get();
      expect(rows, hasLength(1));
      expect(await ledger.balanceOf(bank), 70000);
      expect(await ledger.balanceOf(cash), 30000);
    },
  );

  test('cross-currency transfer credits the destination amount', () async {
    final usd = await ledger.account(
      'Payoneer',
      currency: 'USD',
      opening: 50000,
    );
    // $100 → ₨28,250 at 282.5
    await ledger.transfer(
      usd,
      cash,
      10000,
      currency: 'USD',
      toAmount: 2825000,
      rateMicros: 282500000,
    );
    expect(await ledger.balanceOf(usd), 40000);
    expect(await ledger.balanceOf(cash), 2825000);
  });

  test(
    'soft-deleted transactions do not count; restore brings them back',
    () async {
      final id = await ledger.expense(cash, 1000);
      expect(await ledger.balanceOf(cash), -1000);
      await db.transactionsDao.remove(id);
      expect(await ledger.balanceOf(cash), 0);
      await db.transactionsDao.restore(id);
      expect(await ledger.balanceOf(cash), -1000);
    },
  );

  test('net worth is per currency and honours exclude-from-total', () async {
    await ledger.income(cash, 100000);
    await ledger.account('Savings', opening: 900000, excludeFromTotal: true);
    await ledger.account('Wise', currency: 'USD', opening: 2500);

    final totals = AccountBalance.totalsByCurrency(
      await db.accountsDao.balances(),
    );
    expect(totals, {'PKR': 100000, 'USD': 2500});
  });

  test('archived accounts drop out of balances and net worth', () async {
    final old = await ledger.account('Old', opening: 5000);
    await db.accountsDao.archive(old);
    final balances = await db.accountsDao.balances();
    expect(balances.map((b) => b.account.id), [cash]);
  });

  test('new accounts go last; reorder persists the given order', () async {
    final a = await ledger.account('A');
    final b = await ledger.account('B');
    expect((await db.accountsDao.balances()).map((x) => x.account.id), [
      cash,
      a,
      b,
    ]);

    await db.accountsDao.reorderAccounts([b, cash, a]);
    expect((await db.accountsDao.balances()).map((x) => x.account.id), [
      b,
      cash,
      a,
    ]);
  });

  test('edit changes only the given fields and bumps updated_at', () async {
    final before = (await db.accountsDao.balances()).single.account;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await db.accountsDao.edit(
      cash,
      const AccountsCompanion(name: Value('Wallet')),
    );
    final after = (await db.accountsDao.balances()).single.account;
    expect(after.name, 'Wallet');
    expect(after.currencyCode, before.currencyCode);
    expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
  });

  test('watchBalances emits when a transaction is added', () async {
    final stream = db.accountsDao.watchBalances().map(
      (l) => l.single.balanceMinor,
    );
    expect(stream, emitsInOrder([0, 700]));
    await Future<void>.delayed(Duration.zero);
    await ledger.income(cash, 700);
  });
}

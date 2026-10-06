import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';

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

  test(
    'udhaar balance: I gave → they owe me; I received → I owe them',
    () async {
      final ali = await db.peopleDao.create(name: 'Ali');
      final sara = await db.peopleDao.create(name: 'Sara');
      await ledger.expense(cash, 500000, personId: ali); // lent 5,000
      await ledger.income(cash, 200000, personId: ali); // got 2,000 back
      await ledger.income(cash, 100000, personId: sara); // borrowed 1,000

      final byName = {
        for (final p in await db.peopleDao.balances())
          p.person.name: p.byCurrency,
      };
      expect(byName['Ali'], {'PKR': 300000});
      expect(byName['Sara'], {'PKR': -100000});
    },
  );

  test(
    'udhaar entries are real transactions, so the account moves too',
    () async {
      final ali = await db.peopleDao.create(name: 'Ali');
      await ledger.expense(cash, 500000, personId: ali);
      expect(await ledger.balanceOf(cash), -500000);
    },
  );

  test('settled people have an empty balance; currencies never mix', () async {
    final ali = await db.peopleDao.create(name: 'Ali');
    final usd = await ledger.account('USD', currency: 'USD');
    await ledger.expense(cash, 1000, personId: ali);
    await ledger.income(cash, 1000, personId: ali);
    await ledger.expense(usd, 50, currency: 'USD', personId: ali);

    final ali$ = (await db.peopleDao.balances()).single;
    expect(ali$.byCurrency, {'USD': 50});
  });

  test('people with no transactions are listed with no balance', () async {
    await db.peopleDao.create(name: 'Zainab');
    final p = (await db.peopleDao.balances()).single;
    expect(p.person.name, 'Zainab');
    expect(p.byCurrency, isEmpty);
  });

  test('deleted transactions are excluded', () async {
    final ali = await db.peopleDao.create(name: 'Ali');
    final id = await ledger.expense(cash, 1000, personId: ali);
    await db.transactionsDao.remove(id);
    expect((await db.peopleDao.balances()).single.byCurrency, isEmpty);
  });
}

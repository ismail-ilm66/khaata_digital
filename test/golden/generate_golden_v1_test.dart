@Tags(['golden-generator'])
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/features/accounts/domain/account_type.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

import '../helpers/test_db.dart';

/// One-shot generator for the schema-v1 golden database. Committed output
/// is frozen forever; never regenerate it after v1 ships.
///
///   KHARCHA_GENERATE_GOLDEN=1 flutter test test/golden/generate_golden_v1_test.dart
///
/// Expected values live in test/fixtures/golden/v1/expected.json and were
/// worked out by hand from the rows below — not computed by app code.
void main() {
  final enabled = Platform.environment['KHARCHA_GENERATE_GOLDEN'] == '1';

  test(
    'generate v1 golden database',
    () async {
      final db = testDb();
      addTearDown(db.close);
      final l = TestLedger(db);

      final cash = (await db.accountsDao.balances()).single.account.id;
      final meezan = await l.account('Meezan Bank', opening: 1066100);
      final payoneer = await l.account(
        'Payoneer',
        currency: 'USD',
        opening: 25000,
      );
      await l.account(
        'Savings',
        opening: 7500000,
        type: AccountType.savings,
        excludeFromTotal: true,
      );
      final old = await l.account('Old Wallet', opening: 50000);
      await db.accountsDao.archive(old);
      final mudassir = await db.peopleDao.create(name: 'Mudassir Bhai');

      final cats = {
        for (final c in await db.categoriesDao.active()) c.name: c.id,
      };
      DateTime d(int month, int day) => DateTime.utc(2026, month, day, 7);

      await db.transactionsDao.add(
        TransactionsCompanion.insert(
          type: TransactionType.expense,
          amountMinor: 252000,
          currencyCode: 'PKR',
          accountId: meezan,
          categoryId: Value(cats['Food & Drink']),
          note: const Value('Abdullah Sibtain Lunch'),
          occurredAt: d(9, 25),
        ),
        tags: ['Office', 'Lunch'],
      );
      await l.expense(
        meezan,
        79700,
        categoryId: cats['Fuel & Maintenance'],
        at: d(9, 26),
      );
      await l.income(meezan, 15000000, at: d(9, 25));
      await l.transfer(meezan, cash, 500000);
      await l.transfer(
        payoneer,
        meezan,
        10000,
        currency: 'USD',
        toAmount: 2825000,
        rateMicros: 282500000,
      );
      await l.expense(cash, 100000, personId: mudassir, at: d(10, 1));
      await l.income(cash, 30000, personId: mudassir, at: d(10, 3));
      await l.adjustment(cash, -5000);
      final deleted = await l.expense(meezan, 99999, at: d(10, 4));
      await db.transactionsDao.remove(deleted);
      await db.transactionsDao.add(
        TransactionsCompanion.insert(
          type: TransactionType.expense,
          amountMinor: 1,
          currencyCode: 'PKR',
          accountId: cash,
          occurredAt: d(10, 5),
        ),
        events: ['Eid'],
      );

      const sep = CycleId(2026, 9);
      await db.budgetsDao.setBudget(sep, 5000000);
      await db.budgetsDao.setBudget(
        sep,
        1500000,
        categoryId: cats['Food & Drink'],
      );
      await db.settingsDao.write(SettingKey.monthStartDay, '25');
      await db.settingsDao.write(SettingKey.themeMode, 'dark');

      final out = File('test/fixtures/golden/v1/kharcha.db');
      if (out.existsSync()) out.deleteSync();
      out.parent.createSync(recursive: true);
      await db.customStatement("VACUUM INTO '${out.absolute.path}'");
      expect(out.existsSync(), isTrue);
    },
    skip: enabled ? false : 'set KHARCHA_GENERATE_GOLDEN=1 to regenerate',
  );
}

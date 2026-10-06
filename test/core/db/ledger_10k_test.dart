import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/features/accounts/data/accounts_dao.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

import '../../helpers/test_db.dart';

/// M1 acceptance: balances aggregate correctly on 10k generated rows.
///
/// Rows are generated with a fixed seed; the expected balance of every
/// account is computed independently in Dart and compared to the paisa.
void main() {
  test(
    'balances and net worth match an independent tally over 10,000 rows',
    () async {
      final db = testDb();
      addTearDown(db.close);
      final ledger = TestLedger(db);
      final rnd = Random(20260925);

      final pkrAccounts = [
        (await db.accountsDao.balances()).single.account.id,
        await ledger.account('Meezan Bank', opening: 1066100),
        await ledger.account('Nayapay', opening: 0),
        await ledger.account(
          'Savings',
          opening: 2500000,
          excludeFromTotal: true,
        ),
      ];
      final usdAccount = await ledger.account(
        'Payoneer',
        currency: 'USD',
        opening: 10000,
      );
      final person = await db.peopleDao.create(name: 'Mudassir Bhai');

      final expected = <String, int>{
        pkrAccounts[0]: 0,
        pkrAccounts[1]: 1066100,
        pkrAccounts[2]: 0,
        pkrAccounts[3]: 2500000,
        usdAccount: 10000,
      };
      var personNet = 0;
      final deletedIds = <String>[];

      final rows = <TransactionsCompanion>[];
      for (var i = 0; i < 10000; i++) {
        final amount = 1 + rnd.nextInt(5000000); // up to ₨50,000.00
        final from = pkrAccounts[rnd.nextInt(pkrAccounts.length)];
        final deleted = rnd.nextInt(50) == 0; // ~2% soft-deleted
        final at = DateTime.utc(
          2020,
        ).add(Duration(hours: rnd.nextInt(24 * 365 * 6)));
        final id = 'tx-$i';
        if (deleted) deletedIds.add(id);
        void apply(String account, int delta) {
          if (!deleted) expected[account] = expected[account]! + delta;
        }

        TransactionsCompanion row(
          TransactionType type,
          String account,
          int amt, {
          String currency = 'PKR',
        }) => TransactionsCompanion.insert(
          id: Value(id),
          type: type,
          amountMinor: amt,
          currencyCode: currency,
          accountId: account,
          occurredAt: at,
        );

        switch (rnd.nextInt(10)) {
          case 0 || 1 || 2 || 3: // expense, some as udhaar
            final lent = rnd.nextInt(10) == 0;
            rows.add(
              row(
                TransactionType.expense,
                from,
                amount,
              ).copyWith(personId: Value(lent ? person : null)),
            );
            apply(from, -amount);
            if (lent && !deleted) personNet += amount;
          case 4 || 5: // income
            rows.add(row(TransactionType.income, from, amount));
            apply(from, amount);
          case 6 || 7: // same-currency transfer
            final to = (pkrAccounts.toList()..remove(from))[rnd.nextInt(3)];
            rows.add(
              row(
                TransactionType.transfer,
                from,
                amount,
              ).copyWith(toAccountId: Value(to)),
            );
            apply(from, -amount);
            apply(to, amount);
          case 8: // USD → PKR with a manual rate
            final usd = 1 + rnd.nextInt(20000);
            const rate = 282500000;
            final pkr = usd * rate ~/ 1000000;
            rows.add(
              row(
                TransactionType.transfer,
                usdAccount,
                usd,
                currency: 'USD',
              ).copyWith(
                toAccountId: Value(from),
                toAmountMinor: Value(pkr),
                fxRateMicros: const Value(rate),
              ),
            );
            apply(usdAccount, -usd);
            apply(from, pkr);
          default: // signed adjustment
            final signed = rnd.nextBool() ? amount : -amount;
            rows.add(row(TransactionType.adjustment, from, signed));
            apply(from, signed);
        }
      }

      final sw = Stopwatch()..start();
      await db.batch((b) => b.insertAll(db.transactions, rows));
      for (final id in deletedIds) {
        await db.transactionsDao.remove(id);
      }
      final insertTime = sw.elapsed;
      sw.reset();

      final balances = await db.accountsDao.balances();
      final queryTime = sw.elapsed;

      for (final b in balances) {
        expect(b.balanceMinor, expected[b.account.id], reason: b.account.name);
      }
      expect(AccountBalance.totalsByCurrency(balances), {
        'PKR':
            expected[pkrAccounts[0]]! +
            expected[pkrAccounts[1]]! +
            expected[pkrAccounts[2]]!,
        'USD': expected[usdAccount]!,
      });
      expect(
        (await db.peopleDao.balances()).single.byCurrency['PKR'] ?? 0,
        personNet,
      );

      expect(queryTime, lessThan(const Duration(seconds: 1)));
      // ignore: avoid_print
      print(
        '10k rows: insert ${insertTime.inMilliseconds} ms, '
        'balances ${queryTime.inMilliseconds} ms',
      );
    },
  );
}

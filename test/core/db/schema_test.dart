import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/features/accounts/domain/account_type.dart';
import 'package:khaata_digital/features/categories/domain/category_kind.dart';
import 'package:khaata_digital/features/categories/domain/category_seeds.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TestLedger ledger;

  setUp(() {
    db = testDb();
    ledger = TestLedger(db);
  });
  tearDown(() => db.close());

  group('seed', () {
    test('creates the 42 Hysab Kytab categories in export order', () async {
      final all = await db.categoriesDao.active();
      expect(all.map((c) => c.name), CategorySeeds.all.map((s) => s.name));
      expect(all.where((c) => c.kind == CategoryKind.income), hasLength(16));
      expect(all.where((c) => c.kind == CategoryKind.expense), hasLength(26));
    });

    test('does not seed a "No Category" row', () async {
      final none = await db.categoriesDao.findActiveByName(
        CategoryKind.expense,
        CategorySeeds.noCategoryLabel,
      );
      expect(none, isNull);
    });

    test('creates one PKR Cash account with zero balance', () async {
      final balances = await db.accountsDao.balances();
      expect(balances, hasLength(1));
      expect(balances.single.account.name, 'Cash');
      expect(balances.single.account.type, AccountType.cash);
      expect(balances.single.account.currencyCode, 'PKR');
      expect(balances.single.balanceMinor, 0);
    });
  });

  test('integrity check passes on a fresh database', () async {
    expect(await db.checkIntegrity(), isTrue);
  });

  test('foreign keys are enforced', () async {
    expect(
      () => ledger.expense('no-such-account', 100),
      throwsA(isA<SqliteException>()),
    );
  });

  group('soft-delete name scoping (complaint #8)', () {
    test('an archived account name can be reused', () async {
      final first = await ledger.account('Meezan Bank');
      await db.accountsDao.archive(first);
      final second = await ledger.account('Meezan Bank');
      expect(second, isNot(first));
      expect((await db.accountsDao.archived()).single.id, first);
    });

    test(
      'two active accounts cannot share a name, case-insensitively',
      () async {
        await ledger.account('Meezan Bank');
        expect(
          () => ledger.account('meezan bank'),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test('unarchiving is blocked while the name is taken', () async {
      final first = await ledger.account('HBL');
      await db.accountsDao.archive(first);
      await ledger.account('HBL');
      expect(
        () => db.accountsDao.unarchive(first),
        throwsA(isA<SqliteException>()),
      );
    });

    test(
      'categories are unique per kind, so Savings can be income and expense',
      () async {
        await db.categoriesDao.create(
          name: 'Savings',
          kind: CategoryKind.expense,
        );
        expect(
          () => db.categoriesDao.create(
            name: 'savings',
            kind: CategoryKind.income,
          ),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test('archived people free their name', () async {
      final ali = await db.peopleDao.create(name: 'Ali');
      await db.peopleDao.archive(ali);
      await db.peopleDao.create(name: 'Ali');
      expect((await db.peopleDao.balances()).single.person.name, 'Ali');
    });
  });

  group('transaction constraints', () {
    late String cash;
    setUp(
      () async => cash = (await db.accountsDao.balances()).single.account.id,
    );

    Future<void> insert(TransactionsCompanion c) =>
        db.into(db.transactions).insert(c);

    TransactionsCompanion base(TransactionType type, int amount) =>
        TransactionsCompanion.insert(
          type: type,
          amountMinor: amount,
          currencyCode: 'PKR',
          accountId: cash,
          occurredAt: DateTime.utc(2026),
        );

    test('amount must be positive for non-adjustments', () async {
      await expectLater(
        insert(base(TransactionType.expense, 0)),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        insert(base(TransactionType.income, -5)),
        throwsA(isA<SqliteException>()),
      );
    });

    test('adjustments may be negative but not zero', () async {
      await insert(base(TransactionType.adjustment, -500));
      await expectLater(
        insert(base(TransactionType.adjustment, 0)),
        throwsA(isA<SqliteException>()),
      );
    });

    test(
      'transfers require a different destination; others forbid one',
      () async {
        await expectLater(
          insert(base(TransactionType.transfer, 100)),
          throwsA(isA<SqliteException>()),
        );
        await expectLater(
          insert(
            base(
              TransactionType.transfer,
              100,
            ).copyWith(toAccountId: Value(cash)),
          ),
          throwsA(isA<SqliteException>()),
        );
        final other = await ledger.account('Bank');
        await expectLater(
          insert(
            base(
              TransactionType.expense,
              100,
            ).copyWith(toAccountId: Value(other)),
          ),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test('fx fields are only allowed on transfers', () async {
      await expectLater(
        insert(
          base(
            TransactionType.expense,
            100,
          ).copyWith(fxRateMicros: const Value(1000000)),
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  test('timestamps round-trip as UTC epoch millis', () async {
    final cash = (await db.accountsDao.balances()).single.account.id;
    final at = DateTime.utc(2026, 9, 25, 7, 30, 15, 123);
    final id = await ledger.expense(cash, 100, at: at);
    final row = await db.transactionsDao.byId(id);
    expect(row!.occurredAt, at);
    expect(row.occurredAt.isUtc, isTrue);

    final raw = await db
        .customSelect(
          'SELECT occurred_at FROM transactions WHERE id = ?',
          variables: [Variable(id)],
        )
        .getSingle();
    expect(raw.read<int>('occurred_at'), at.millisecondsSinceEpoch);
  });
}

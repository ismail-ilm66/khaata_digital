import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/error/app_failure.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/transactions/data/receipt_store.dart';
import 'package:khaata_digital/features/transactions/data/transactions_repository_impl.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

import '../../helpers/test_db.dart';
import '../../helpers/test_receipts.dart';

const pkr = Currency.pkr;
Money rs(int rupees) => Money.major(rupees, pkr);

/// Cycles are local-time, so fixtures are dated at local noon to keep the
/// tests independent of the machine's timezone.
DateTime localNoon(int y, int m, int d) => DateTime(y, m, d, 12).toUtc();

void main() {
  late AppDatabase db;
  late ReceiptStore receipts;
  late TransactionsRepositoryImpl repo;
  late TestLedger ledger;
  late String cash;
  late String food;

  setUp(() async {
    db = testDb();
    receipts = testReceiptStore();
    repo = TransactionsRepositoryImpl(db, receipts);
    ledger = TestLedger(db);
    cash = (await db.accountsDao.balances()).single.account.id;
    food = (await db.categoriesDao.active())
        .firstWhere((c) => c.name == 'Food & Drink')
        .id;
  });
  tearDown(() => db.close());

  EntryDraft expense(
    int rupees, {
    DateTime? at,
    String? note,
    List<String> tags = const [],
  }) => EntryDraft(
    type: TransactionType.expense,
    amount: rs(rupees),
    accountId: cash,
    categoryId: food,
    occurredAt: at ?? localNoon(2026, 9, 26),
    note: note ?? '',
    tags: tags,
  );

  Future<List<EntryView>> list([EntryQuery q = const EntryQuery()]) async =>
      (await repo.watch(q).first).items;

  group('save', () {
    test('creates an expense that lists with its names and tags', () async {
      final id = await repo.save(
        expense(2520, note: 'Lunch', tags: ['Office']),
      );
      final v = (await list()).single;
      expect(v.entry.id, id);
      expect(v.entry.amount, rs(2520));
      expect(v.entry.tags, ['Office']);
      expect(v.accountName, 'Cash');
      expect(v.category!.name, 'Food & Drink');
      expect(v.entry.signedAmount, -rs(2520));
    });

    test(
      'editing keeps the stored date when the draft keeps it (complaint #7)',
      () async {
        final at = DateTime.utc(2025, 8, 25, 7);
        final id = await repo.save(expense(100, at: at));
        final draft = (await repo.byId(id))!.toDraft();
        expect(draft.occurredAt, at);

        await repo.save(
          EntryDraft(
            type: draft.type,
            amount: rs(150),
            accountId: draft.accountId,
            categoryId: draft.categoryId,
            occurredAt: draft.occurredAt,
          ),
          id: id,
        );
        final stored = (await repo.byId(id))!;
        expect(stored.occurredAt, at);
        expect(stored.amount, rs(150));
      },
    );

    test(
      'changing type from transfer back to expense clears transfer fields',
      () async {
        final bank = await ledger.account('Bank');
        final id = await repo.save(
          EntryDraft(
            type: TransactionType.transfer,
            amount: rs(500),
            accountId: cash,
            toAccountId: bank,
            occurredAt: DateTime.utc(2026),
          ),
        );
        await repo.save(expense(500), id: id);
        final e = (await repo.byId(id))!;
        expect(e.type, TransactionType.expense);
        expect(e.toAccountId, isNull);
      },
    );

    test('a transfer is one entry and moves both balances', () async {
      final bank = await ledger.account('Bank', opening: 100000);
      await repo.save(
        EntryDraft(
          type: TransactionType.transfer,
          amount: rs(300),
          accountId: bank,
          toAccountId: cash,
          categoryId: food, // ignored for transfers
          occurredAt: DateTime.utc(2026),
        ),
      );
      final views = await list();
      expect(views, hasLength(1));
      expect(views.single.toAccountName, 'Cash');
      expect(views.single.category, isNull);
      expect(await ledger.balanceOf(bank), 100000 - 30000);
      expect(await ledger.balanceOf(cash), 30000);
    });

    test(
      'cross-currency transfer stores destination amount and rate',
      () async {
        final usd = await ledger.account(
          'Payoneer',
          currency: 'USD',
          opening: 10000,
        );
        await repo.save(
          EntryDraft(
            type: TransactionType.transfer,
            amount: Money.major(10, Currency.usd),
            accountId: usd,
            toAccountId: cash,
            toAmount: rs(2825),
            fxRateMicros: 282500000,
            occurredAt: DateTime.utc(2026),
          ),
        );
        final e = (await list()).single.entry;
        expect(e.toAmount, rs(2825));
        expect(e.fxRateMicros, 282500000);
        expect(await ledger.balanceOf(cash), 282500);
      },
    );

    final invalid =
        <String, (EntryDraft Function(String cash, String bank), EntryProblem)>{
          'zero amount': (
            (c, b) => EntryDraft(
              type: TransactionType.expense,
              amount: rs(0),
              accountId: c,
              occurredAt: DateTime.utc(2026),
            ),
            EntryProblem.amountRequired,
          ),
          'no account': (
            (c, b) => EntryDraft(
              type: TransactionType.expense,
              amount: rs(1),
              occurredAt: DateTime.utc(2026),
            ),
            EntryProblem.accountRequired,
          ),
          'transfer without destination': (
            (c, b) => EntryDraft(
              type: TransactionType.transfer,
              amount: rs(1),
              accountId: c,
              occurredAt: DateTime.utc(2026),
            ),
            EntryProblem.destinationRequired,
          ),
          'transfer to itself': (
            (c, b) => EntryDraft(
              type: TransactionType.transfer,
              amount: rs(1),
              accountId: c,
              toAccountId: c,
              occurredAt: DateTime.utc(2026),
            ),
            EntryProblem.sameAccount,
          ),
          'cross-currency without amount': (
            (c, b) => EntryDraft(
              type: TransactionType.transfer,
              amount: rs(1),
              accountId: c,
              toAccountId: b,
              occurredAt: DateTime.utc(2026),
            ),
            EntryProblem.conversionRequired,
          ),
        };
    invalid.forEach((name, spec) {
      test('rejects $name', () async {
        final usd = await ledger.account('USD', currency: 'USD');
        await expectLater(
          repo.save(spec.$1(cash, usd)),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.problem,
              'problem',
              spec.$2,
            ),
          ),
        );
        expect(await list(), isEmpty);
      });
    });
  });

  group('receipts', () {
    test('are compressed, stored with a sha256, and resolvable', () async {
      final id = await repo.save(
        EntryDraft(
          type: TransactionType.expense,
          amount: rs(10),
          accountId: cash,
          occurredAt: DateTime.utc(2026),
          newReceiptPaths: [
            fakeImage('a.jpg', [1, 2, 3]),
          ],
        ),
      );
      final att = (await repo.byId(id))!.attachments.single;
      expect(att.mime, 'image/jpeg');
      expect(att.byteSize, 3);
      expect(
        att.sha256,
        '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
      );
      expect(File(await repo.receiptPath(att)).readAsBytesSync(), [1, 2, 3]);
    });

    test('edit keeps listed receipts, deletes the rest from disk', () async {
      final id = await repo.save(
        EntryDraft(
          type: TransactionType.expense,
          amount: rs(10),
          accountId: cash,
          occurredAt: DateTime.utc(2026),
          newReceiptPaths: [fakeImage('a.jpg'), fakeImage('b.jpg')],
        ),
      );
      final both = (await repo.byId(id))!.attachments;
      final dropped = await repo.receiptPath(both.last);

      final draft = (await repo.byId(id))!.toDraft();
      await repo.save(
        EntryDraft(
          type: draft.type,
          amount: draft.amount,
          accountId: draft.accountId,
          occurredAt: draft.occurredAt,
          keptAttachments: [both.first],
        ),
        id: id,
      );
      expect((await repo.byId(id))!.attachments, [both.first]);
      expect(File(dropped).existsSync(), isFalse);
    });

    test('an unreadable image fails cleanly and saves nothing', () async {
      await expectLater(
        repo.save(
          EntryDraft(
            type: TransactionType.expense,
            amount: rs(10),
            accountId: cash,
            occurredAt: DateTime.utc(2026),
            newReceiptPaths: [fakeImage('ok.jpg'), fakeImage('broken.jpg')],
          ),
        ),
        throwsA(isA<StorageFailure>()),
      );
      expect(await list(), isEmpty);
      final dir = Directory(
        '${(await receipts.root()).path}/${ReceiptStore.folder}',
      );
      expect(dir.listSync(), isEmpty, reason: 'partial files cleaned up');
    });
  });

  group('query', () {
    late String bank;
    setUp(() async {
      bank = await ledger.account('Meezan Bank');
      await repo.save(expense(2520, note: 'Abdullah lunch', tags: ['Office']));
      await repo.save(
        EntryDraft(
          type: TransactionType.income,
          amount: rs(50000),
          accountId: bank,
          occurredAt: localNoon(2026, 9, 25),
        ),
      );
      await repo.save(expense(797, note: 'Petrol', at: localNoon(2026, 9, 24)));
    });

    test('lists newest first', () async {
      expect((await list()).map((v) => v.entry.amount), [
        rs(2520),
        rs(50000),
        rs(797),
      ]);
    });

    test('filters by type, account, category and tag', () async {
      expect(
        await list(const EntryQuery(types: {TransactionType.income})),
        hasLength(1),
      );
      expect(await list(EntryQuery(accountIds: {bank})), hasLength(1));
      expect(await list(EntryQuery(categoryIds: {food})), hasLength(2));
      expect(await list(const EntryQuery(tags: {'Office'})), hasLength(1));
    });

    final searches = {
      'lunch': 1, // note, case-insensitive
      'meezan': 1, // account name
      'food': 2, // category name
      'office': 1, // tag
      '797': 1, // exact amount
      '2,520': 1, // formatted amount
      'nothing-here': 0,
      '%': 0, // wildcards are literal
    };
    searches.forEach((needle, count) {
      test('search "$needle" → $count', () async {
        expect(await list(EntryQuery(search: needle)), hasLength(count));
      });
    });

    test('range uses BudgetCycle bounds', () async {
      final range = const BudgetCycle(25).rangeOf(const CycleId(2026, 9));
      expect(
        await list(EntryQuery(range: range)),
        hasLength(2),
        reason: 'the 24 Sep entry belongs to the previous cycle',
      );
    });

    test('delete hides an entry; restore brings it back', () async {
      final id = (await list()).first.entry.id;
      await repo.delete(id);
      expect(await list(), hasLength(2));
      await repo.restore(id);
      expect(await list(), hasLength(3));
    });

    test('totals per type and currency over a range', () async {
      final totals = await repo
          .watchTotals(const BudgetCycle(25).rangeOf(const CycleId(2026, 9)))
          .first;
      expect(totals.incomeIn(pkr), rs(50000));
      expect(totals.expenseIn(pkr), rs(2520));
    });

    test('tag names in use', () async {
      expect(await repo.tagNames(), ['Office']);
    });
  });

  test('pages end on a whole day so daily totals are never partial', () async {
    // 3 entries on day 1, 3 on day 2; a page of 4 must not split day 2.
    for (var i = 0; i < 3; i++) {
      await repo.save(expense(1, at: DateTime(2026, 9, 2, 10 + i).toUtc()));
      await repo.save(expense(1, at: DateTime(2026, 9, 1, 10 + i).toUtc()));
    }
    final page = await repo.watch(const EntryQuery(limit: 4)).first;
    expect(page.hasMore, isTrue);
    expect(page.items, hasLength(3));
    final all = await repo.watch(const EntryQuery(limit: 10)).first;
    expect(all.hasMore, isFalse);
    expect(all.items, hasLength(6));
  });
}

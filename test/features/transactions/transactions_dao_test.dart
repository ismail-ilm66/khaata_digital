import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

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

  test('editing keeps the stored date (complaint #7)', () async {
    final at = DateTime.utc(2025, 8, 25, 12);
    final id = await ledger.expense(cash, 252000, at: at);

    await db.transactionsDao.edit(
      id,
      const TransactionsCompanion(
        amountMinor: Value(260000),
        note: Value('Lunch'),
      ),
    );

    final row = (await db.transactionsDao.byId(id))!;
    expect(row.occurredAt, at);
    expect(row.amountMinor, 260000);
    expect(row.note, 'Lunch');
    expect(
      row.updatedAt.isAfter(row.createdAt) || row.updatedAt == row.createdAt,
      isTrue,
    );
  });

  test(
    'tags are trimmed, de-duplicated case-insensitively and reused',
    () async {
      final a = await db.transactionsDao.add(
        _expense(cash),
        tags: [' Office ', 'office', 'Lunch', ''],
      );
      final b = await db.transactionsDao.add(_expense(cash), tags: ['LUNCH']);

      expect((await db.labelsDao.tagsFor(a)).map((t) => t.name), [
        'Lunch',
        'Office',
      ]);
      expect((await db.labelsDao.tagsFor(b)).map((t) => t.name), ['Lunch']);
      expect(await db.select(db.tags).get(), hasLength(2));
    },
  );

  test('editing replaces tags only when given', () async {
    final id = await db.transactionsDao.add(_expense(cash), tags: ['a', 'b']);
    await db.transactionsDao.edit(
      id,
      const TransactionsCompanion(note: Value('x')),
    );
    expect(await db.labelsDao.tagsFor(id), hasLength(2));
    await db.transactionsDao.edit(
      id,
      const TransactionsCompanion(),
      tags: ['c'],
    );
    expect((await db.labelsDao.tagsFor(id)).map((t) => t.name), ['c']);
  });

  test('events are stored like tags', () async {
    final id = await db.transactionsDao.add(
      _expense(cash),
      events: ['Eid 2026'],
    );
    final links = await (db.select(
      db.transactionEvents,
    )..where((e) => e.transactionId.equals(id))).get();
    expect(links, hasLength(1));
  });

  test('watchInRange uses BudgetCycle bounds and skips deleted rows', () async {
    const cycle = BudgetCycle(25);
    final range = cycle.rangeOf(const CycleId(2026, 9)); // 25 Sep – 24 Oct

    final inside = await ledger.expense(
      cash,
      1,
      at: DateTime(2026, 9, 25).toUtc(),
    );
    final lastMoment = await ledger.expense(
      cash,
      2,
      at: DateTime(2026, 10, 24, 23, 59).toUtc(),
    );
    await ledger.expense(cash, 3, at: DateTime(2026, 10, 25).toUtc()); // next
    await ledger.expense(
      cash,
      4,
      at: DateTime(2026, 9, 24, 23, 59).toUtc(),
    ); // prev
    final deleted = await ledger.expense(
      cash,
      5,
      at: DateTime(2026, 10, 1).toUtc(),
    );
    await db.transactionsDao.remove(deleted);

    final rows = await db.transactionsDao.watchInRange(range).first;
    expect(rows.map((r) => r.id), [lastMoment, inside]);
  });
}

TransactionsCompanion _expense(String accountId) =>
    TransactionsCompanion.insert(
      type: TransactionType.expense,
      amountMinor: 100,
      currencyCode: 'PKR',
      accountId: accountId,
      occurredAt: TestLedger.defaultDate,
    );

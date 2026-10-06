import 'package:drift/drift.dart';

import '../../../core/dates/date_range.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/entity_ops.dart';
import '../../../core/db/tables.dart';
import '../../../core/money/fixed_point.dart';
import '../domain/transaction_type.dart';

part 'transactions_dao.g.dart';

/// A transaction joined with what a list row needs to show it.
typedef EntryRows = ({
  TransactionRow tx,
  AccountRow from,
  AccountRow? to,
  CategoryRow? category,
  PersonRow? person,
});

@DriftAccessor(
  tables: [Transactions, Accounts, Categories, People, Tags, TransactionTags],
)
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.attachedDatabase);

  /// Inserts a transaction with its labels atomically; returns its id.
  Future<String> add(
    TransactionsCompanion entry, {
    Iterable<String> tags = const [],
    Iterable<String> events = const [],
  }) {
    return transaction(() async {
      final row = await into(transactions).insertReturning(entry);
      await _writeLabels(row.id, tags, events);
      return row.id;
    });
  }

  /// Applies [changes] and, when given, replaces the labels. Fields absent
  /// from [changes] — including `occurredAt` — keep their stored values.
  Future<void> edit(
    String id,
    TransactionsCompanion changes, {
    Iterable<String>? tags,
    Iterable<String>? events,
  }) {
    return transaction(() async {
      await (update(transactions)..where((t) => t.id.equals(id))).write(
        changes.copyWith(updatedAt: Value(DateTime.now().toUtc())),
      );
      final labels = db.labelsDao;
      if (tags != null) await labels.setTags(id, await labels.tagIds(tags));
      if (events != null) {
        await labels.setEvents(id, await labels.eventIds(events));
      }
    });
  }

  Future<void> remove(String id) => softDelete(transactions, id);
  Future<void> restore(String id) => undelete(transactions, id);

  Future<TransactionRow?> byId(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Live transactions in [range], newest first.
  Stream<List<TransactionRow>> watchInRange(DateRange range) {
    return (select(transactions)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.occurredAt.isBiggerOrEqualValue(range.startMillis) &
                t.occurredAt.isSmallerThanValue(range.endMillis),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.occurredAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  /// Live entries matching the filters, newest first. Empty sets mean
  /// "any". [search] matches note, place, category, either account, tag
  /// names, or the exact amount when it parses as one.
  Selectable<EntryRows> queryEntries({
    Set<TransactionType> types = const {},
    Set<String> accountIds = const {},
    Set<String> categoryIds = const {},
    Set<String> tagNames = const {},
    Set<String> personIds = const {},
    String search = '',
    int? fromMillis,
    int? toMillis,
    String? id,
    int? limit,
  }) {
    final toAcc = alias(accounts, 'to_acc');
    final t = transactions;
    final q = select(t).join([
      innerJoin(accounts, accounts.id.equalsExp(t.accountId)),
      leftOuterJoin(toAcc, toAcc.id.equalsExp(t.toAccountId)),
      leftOuterJoin(categories, categories.id.equalsExp(t.categoryId)),
      leftOuterJoin(people, people.id.equalsExp(t.personId)),
    ]);

    Expression<bool> tagged(Expression<bool> Function() match) => existsQuery(
      selectOnly(
          transactionTags,
        ).join([innerJoin(tags, tags.id.equalsExp(transactionTags.tagId))])
        ..addColumns([transactionTags.tagId])
        ..where(transactionTags.transactionId.equalsExp(t.id) & match()),
    );

    final conditions = <Expression<bool>>[
      t.deletedAt.isNull(),
      if (id != null) t.id.equals(id),
      if (types.isNotEmpty) t.type.isIn(types.map((e) => e.name)),
      if (accountIds.isNotEmpty)
        t.accountId.isIn(accountIds) | t.toAccountId.isIn(accountIds),
      if (categoryIds.isNotEmpty) t.categoryId.isIn(categoryIds),
      if (tagNames.isNotEmpty) tagged(() => tags.name.isIn(tagNames)),
      if (personIds.isNotEmpty) t.personId.isIn(personIds),
      if (fromMillis != null) t.occurredAt.isBiggerOrEqualValue(fromMillis),
      if (toMillis != null) t.occurredAt.isSmallerThanValue(toMillis),
    ];

    final needle = search.trim();
    if (needle.isNotEmpty) {
      final pattern = _containsPattern(needle);
      Expression<bool> like(Expression<String> e) =>
          e.like(pattern, escapeChar: _escape);
      final amount = FixedPoint.parse(needle, 2);
      conditions.add(
        like(t.note) |
            like(t.place) |
            like(accounts.name) |
            like(toAcc.name) |
            like(categories.name) |
            like(people.name) |
            tagged(() => like(tags.name)) |
            (amount == null
                ? const Constant(false)
                : t.amountMinor.equals(amount.abs())),
      );
    }

    q
      ..where(conditions.reduce((a, b) => a & b))
      ..orderBy([
        OrderingTerm.desc(t.occurredAt),
        OrderingTerm.desc(t.createdAt),
      ]);
    if (limit != null) q.limit(limit);

    return q.map(
      (r) => (
        tx: r.readTable(t),
        from: r.readTable(accounts),
        to: r.readTableOrNull(toAcc),
        category: r.readTableOrNull(categories),
        person: r.readTableOrNull(people),
      ),
    );
  }

  /// Income and expense sums per currency in `[fromMillis, toMillis)`.
  Selectable<({TransactionType type, String currency, int total})> totals(
    int fromMillis,
    int toMillis,
  ) {
    return customSelect(
      'SELECT type, currency_code, SUM(amount_minor) AS total '
      'FROM transactions '
      "WHERE deleted_at IS NULL AND type IN ('income', 'expense') "
      // Udhaar (person-linked) moves balances but isn't income or spending.
      'AND person_id IS NULL '
      'AND occurred_at >= ? AND occurred_at < ? '
      'GROUP BY type, currency_code',
      variables: [Variable.withInt(fromMillis), Variable.withInt(toMillis)],
      readsFrom: {transactions},
    ).map(
      (r) => (
        type: TransactionType.values.byName(r.read<String>('type')),
        currency: r.read<String>('currency_code'),
        total: r.read<int>('total'),
      ),
    );
  }

  /// Expense totals per category (null = uncategorised) in one currency
  /// over `[fromMillis, toMillis)`, excluding udhaar.
  Selectable<({String? categoryId, int total})> spendingByCategory(
    int fromMillis,
    int toMillis,
    String currencyCode,
  ) {
    return customSelect(
      'SELECT category_id, SUM(amount_minor) AS total FROM transactions '
      "WHERE deleted_at IS NULL AND type = 'expense' AND person_id IS NULL "
      'AND currency_code = ? AND occurred_at >= ? AND occurred_at < ? '
      'GROUP BY category_id',
      variables: [
        Variable.withString(currencyCode),
        Variable.withInt(fromMillis),
        Variable.withInt(toMillis),
      ],
      readsFrom: {transactions},
    ).map(
      (r) => (
        categoryId: r.readNullable<String>('category_id'),
        total: r.read<int>('total'),
      ),
    );
  }

  /// Category ids ordered by use count across live entries.
  Future<List<String>> frequentCategoryIds(int limit) async {
    final rows = await customSelect(
      'SELECT category_id FROM transactions '
      'WHERE deleted_at IS NULL AND category_id IS NOT NULL '
      'GROUP BY category_id ORDER BY COUNT(*) DESC, MAX(occurred_at) DESC '
      'LIMIT ?',
      variables: [Variable.withInt(limit)],
      readsFrom: {transactions},
    ).get();
    return [for (final r in rows) r.read<String>('category_id')];
  }

  static const _escape = r'\';

  /// `%needle%` with LIKE wildcards in [needle] matched literally.
  static String _containsPattern(String needle) {
    final escaped = needle
        .replaceAll(_escape, '$_escape$_escape')
        .replaceAll('%', '$_escape%')
        .replaceAll('_', '${_escape}_');
    return '%$escaped%';
  }

  Future<void> _writeLabels(
    String id,
    Iterable<String> tags,
    Iterable<String> events,
  ) async {
    final labels = db.labelsDao;
    if (tags.isNotEmpty) await labels.setTags(id, await labels.tagIds(tags));
    if (events.isNotEmpty) {
      await labels.setEvents(id, await labels.eventIds(events));
    }
  }
}

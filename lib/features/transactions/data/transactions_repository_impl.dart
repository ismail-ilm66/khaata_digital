import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../core/dates/date_range.dart';
import '../../../core/db/app_database.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../accounts/data/accounts_repository_impl.dart';
import '../../accounts/domain/account.dart';
import '../../categories/data/categories_repository_impl.dart';
import '../domain/entry_query.dart';
import '../domain/ledger_entry.dart';
import '../domain/transaction_type.dart';
import '../domain/transactions_repository.dart';
import 'receipt_store.dart';
import 'transactions_dao.dart';

@LazySingleton(as: TransactionsRepository)
class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._db, this._receipts);

  final AppDatabase _db;
  final ReceiptStore _receipts;

  TransactionsDao get _dao => _db.transactionsDao;

  @override
  Stream<EntryPage> watch(EntryQuery q) {
    return _dao
        .queryEntries(
          types: q.types,
          accountIds: q.accountIds,
          categoryIds: q.categoryIds,
          tagNames: q.tags,
          personIds: q.personIds,
          search: q.search,
          fromMillis: q.range?.startMillis,
          toMillis: q.range?.endMillis,
          limit: q.limit + 1,
        )
        .watch()
        .asyncMap((rows) async => _page(await _views(rows), q.limit));
  }

  /// Cuts to [limit] and, if more exist, drops the trailing (possibly
  /// partial) day so daily totals on screen are always complete.
  static EntryPage _page(List<EntryView> views, int limit) {
    if (views.length <= limit) return EntryPage(views, hasMore: false);
    final page = views.sublist(0, limit);
    final lastDay = _localDay(views[limit].entry.occurredAt);
    final whole = page
        .where((v) => _localDay(v.entry.occurredAt) != lastDay)
        .toList();
    return EntryPage(whole.isEmpty ? page : whole, hasMore: true);
  }

  static DateTime _localDay(DateTime utc) {
    final l = utc.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  @override
  Stream<EntryView?> watchOne(String id) => _dao
      .queryEntries(id: id)
      .watch()
      .asyncMap((rows) async => (await _views(rows)).firstOrNull);

  @override
  Future<LedgerEntry?> byId(String id) async =>
      (await _views(await _dao.queryEntries(id: id).get())).firstOrNull?.entry;

  Future<List<EntryView>> _views(List<EntryRows> rows) async {
    final ids = [for (final r in rows) r.tx.id];
    final tags = await _db.labelsDao.tagNamesFor(ids);
    final events = await _db.labelsDao.eventNamesFor(ids);
    final files = await _db.attachmentsDao.forTransactions(ids);
    return [
      for (final r in rows)
        EntryView(
          entry: _entry(
            r,
            tags[r.tx.id] ?? const [],
            events[r.tx.id] ?? const [],
            files[r.tx.id] ?? const [],
          ),
          accountName: r.from.name,
          accountCurrency: Currency.of(r.from.currencyCode),
          toAccountName: r.to?.name,
          category: r.category?.toDomain(),
          personName: r.person?.name,
        ),
    ];
  }

  static LedgerEntry _entry(
    EntryRows r,
    List<String> tags,
    List<String> events,
    List<AttachmentRow> files,
  ) {
    final tx = r.tx;
    final currency = Currency.of(tx.currencyCode);
    return LedgerEntry(
      id: tx.id,
      type: tx.type,
      amount: Money(tx.amountMinor, currency),
      accountId: tx.accountId,
      toAccountId: tx.toAccountId,
      toAmount: tx.toAmountMinor == null || r.to == null
          ? null
          : Money(tx.toAmountMinor!, Currency.of(r.to!.currencyCode)),
      fxRateMicros: tx.fxRateMicros,
      categoryId: tx.categoryId,
      personId: tx.personId,
      occurredAt: tx.occurredAt,
      note: tx.note,
      place: tx.place,
      tags: tags,
      events: events,
      attachments: [
        for (final f in files)
          Attachment(
            id: f.id,
            fileName: f.fileName,
            mime: f.mime,
            byteSize: f.byteSize,
            sha256: f.sha256,
          ),
      ],
    );
  }

  @override
  Future<String> save(EntryDraft draft, {String? id}) async {
    final from = await _account(draft.accountId);
    final to = draft.isTransfer ? await _account(draft.toAccountId) : null;
    final problem = validateEntry(draft, from: from, to: to);
    if (problem != null) throw ValidationFailure(problem);

    final source = from!; // validated above
    final crossCurrency = to != null && to.currency != source.currency;
    final row = TransactionsCompanion(
      type: Value(draft.type),
      amountMinor: Value(draft.amount.minor),
      currencyCode: Value(source.currency.code),
      accountId: Value(source.id),
      toAccountId: Value(to?.id),
      toAmountMinor: Value(crossCurrency ? draft.toAmount!.minor : null),
      fxRateMicros: Value(crossCurrency ? draft.fxRateMicros : null),
      categoryId: Value(draft.isTransfer ? null : draft.categoryId),
      personId: Value(draft.personId),
      occurredAt: Value(draft.occurredAt.toUtc()),
      note: Value(draft.note.trim()),
      place: Value(draft.place),
    );

    // Compress and write new receipts before touching the database, so a
    // bad image never leaves a half-saved entry.
    final stored = <StoredReceipt>[];
    try {
      for (final path in draft.newReceiptPaths) {
        stored.add(await _receipts.store(path));
      }
      final removed = <AttachmentRow>[];
      final savedId = await _db.transaction(() async {
        final entryId =
            id ?? await _dao.add(row, tags: draft.tags, events: draft.events);
        if (id != null) {
          await _dao.edit(id, row, tags: draft.tags, events: draft.events);
        }
        removed.addAll(
          await _db.attachmentsDao.removeExcept(entryId, {
            for (final a in draft.keptAttachments) a.id,
          }),
        );
        for (final s in stored) {
          await _db.attachmentsDao.add(
            AttachmentsCompanion.insert(
              transactionId: entryId,
              fileName: s.fileName,
              mime: s.mime,
              byteSize: s.byteSize,
              sha256: s.sha256,
            ),
          );
        }
        return entryId;
      });
      for (final r in removed) {
        await _receipts.delete(r.fileName);
      }
      return savedId;
    } catch (_) {
      for (final s in stored) {
        await _receipts.delete(s.fileName);
      }
      rethrow;
    }
  }

  Future<Account?> _account(String? id) async =>
      id == null ? null : (await _db.accountsDao.byId(id))?.toDomain();

  @override
  Future<void> delete(String id) => _dao.remove(id);

  @override
  Future<void> restore(String id) => _dao.restore(id);

  @override
  Stream<PeriodTotals> watchTotals(DateRange range) =>
      _dao.totals(range.startMillis, range.endMillis).watch().map((rows) {
        final income = <Currency, Money>{};
        final expense = <Currency, Money>{};
        for (final r in rows) {
          final c = Currency.of(r.currency);
          (r.type == TransactionType.income ? income : expense)[c] = Money(
            r.total,
            c,
          );
        }
        return PeriodTotals(income: income, expense: expense);
      });

  @override
  Future<List<String>> tagNames() => _db.labelsDao.usedTagNames();

  @override
  Future<List<String>> frequentCategoryIds({int limit = 8}) =>
      _dao.frequentCategoryIds(limit);

  @override
  Future<List<String>> frequentAccountIds() => _dao.frequentAccountIds();

  @override
  Future<String> receiptPath(Attachment attachment) =>
      _receipts.pathOf(attachment.fileName);
}

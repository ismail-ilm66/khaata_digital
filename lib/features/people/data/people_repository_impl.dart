import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../core/db/app_database.dart';
import '../../../core/dates/date_range.dart';
import '../../../core/db/unique_guard.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../transactions/domain/entry_query.dart';
import '../../transactions/domain/transactions_repository.dart';
import '../domain/person.dart';

extension PersonRowMapping on PersonRow {
  Person toDomain() => Person(id: id, name: name, contactHint: contactHint);
}

extension WriteOffRowMapping on WriteOffRow {
  WriteOff toDomain(String personName) => WriteOff(
    id: id,
    personId: personId,
    personName: personName,
    amount: Money(amountMinor, Currency.of(currencyCode)),
    occurredAt: occurredAt,
    note: note,
  );
}

@LazySingleton(as: PeopleRepository)
class PeopleRepositoryImpl implements PeopleRepository {
  PeopleRepositoryImpl(this._db, this._transactions);

  final AppDatabase _db;
  final TransactionsRepository _transactions;

  /// A ledger is one person's history; it's never paged.
  static const int _ledgerLimit = 1 << 20;

  @override
  Stream<PeopleOverview> watchOverview() => _db.peopleDao.watchBalances().map(
    (rows) => PeopleOverview.of([
      for (final r in rows)
        PersonSummary(r.person.toDomain(), {
          for (final e in r.byCurrency.entries)
            Currency.of(e.key): Money(e.value, Currency.of(e.key)),
        }),
    ]),
  );

  @override
  Stream<Person?> watchPerson(String id) =>
      _db.peopleDao.watchById(id).map((r) => r?.toDomain());

  @override
  Future<String> create(String name, {String? contactHint}) => guardUniqueName(
    name,
    () => _db.peopleDao.create(name: name, contactHint: contactHint),
  );

  @override
  Future<void> rename(String id, String name) =>
      guardUniqueName(name, () => _db.peopleDao.rename(id, name));

  @override
  Future<void> archive(String id) => _db.peopleDao.archive(id);

  @override
  Stream<List<LedgerLine>> watchLedger(String personId) => _transactions
      .watch(EntryQuery(personIds: {personId}, limit: _ledgerLimit))
      .combineLatest(
        _watchWriteOffs(personId: personId),
        (page, writeOffs) => LedgerLine.build(page.items, writeOffs),
      );

  @override
  Future<String> writeOff(
    String personId,
    Money amount, {
    required DateTime occurredAt,
    String note = '',
  }) => _db.writeOffsDao.create(
    WriteOffsCompanion.insert(
      personId: personId,
      amountMinor: amount.minor,
      currencyCode: amount.currency.code,
      occurredAt: occurredAt.toUtc(),
      note: Value(note.trim()),
    ),
  );

  @override
  Future<void> editWriteOff(
    String id,
    Money amount, {
    required DateTime occurredAt,
    String note = '',
  }) => _db.writeOffsDao.change(
    id,
    WriteOffsCompanion(
      amountMinor: Value(amount.minor),
      currencyCode: Value(amount.currency.code),
      occurredAt: Value(occurredAt.toUtc()),
      note: Value(note.trim()),
    ),
  );

  @override
  Future<void> removeWriteOff(String id) => _db.writeOffsDao.remove(id);

  @override
  Future<void> restoreWriteOff(String id) => _db.writeOffsDao.restore(id);

  @override
  Stream<List<WriteOff>> watchWriteOffs({DateRange? range}) =>
      _watchWriteOffs(range: range);

  Stream<List<WriteOff>> _watchWriteOffs({
    String? personId,
    DateRange? range,
  }) => _db.writeOffsDao
      .watch(
        personId: personId,
        fromMillis: range?.startMillis,
        toMillis: range?.endMillis,
      )
      .map((rows) => [for (final r in rows) r.row.toDomain(r.personName)]);
}

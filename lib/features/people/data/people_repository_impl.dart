import 'package:injectable/injectable.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/unique_guard.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../transactions/domain/entry_query.dart';
import '../../transactions/domain/transactions_repository.dart';
import '../domain/person.dart';

extension PersonRowMapping on PersonRow {
  Person toDomain() => Person(id: id, name: name, contactHint: contactHint);
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
      .map((page) => LedgerLine.build(page.items));
}

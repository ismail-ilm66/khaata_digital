import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/entity_ops.dart';
import '../../../core/db/ledger_sql.dart';
import '../../../core/db/tables.dart';

part 'people_dao.g.dart';

@immutable
class PersonBalance {
  const PersonBalance(this.person, this.byCurrency);

  final PersonRow person;

  /// Net udhaar per currency: positive = they owe me, negative = I owe them.
  /// Derived from linked transactions; never stored (spec 3.3).
  final Map<String, int> byCurrency;
}

@DriftAccessor(tables: [People, Transactions])
class PeopleDao extends DatabaseAccessor<AppDatabase> with _$PeopleDaoMixin {
  PeopleDao(super.attachedDatabase);

  Selectable<({QueryRow row, PersonRow person})> _balances() {
    return customSelect(
      '''
SELECT p.*, t.currency_code AS currency, SUM(${LedgerSql.personDelta}) AS net
FROM people p
LEFT JOIN transactions t ON t.person_id = p.id AND ${LedgerSql.live}
WHERE p.deleted_at IS NULL
GROUP BY p.id, t.currency_code
ORDER BY p.name COLLATE NOCASE
''',
      readsFrom: {people, transactions},
    ).map((row) => (row: row, person: people.map(row.data)));
  }

  /// Active people with their net balance per currency.
  Future<List<PersonBalance>> balances() async =>
      _group(await _balances().get());

  Stream<List<PersonBalance>> watchBalances() =>
      _balances().watch().map(_group);

  // The query yields one row per (person, currency); fold them per person.
  static List<PersonBalance> _group(
    List<({QueryRow row, PersonRow person})> rows,
  ) {
    final byId = <String, PersonBalance>{};
    for (final r in rows) {
      final entry = byId.putIfAbsent(
        r.person.id,
        () => PersonBalance(r.person, <String, int>{}),
      );
      final currency = r.row.readNullable<String>('currency');
      final net = r.row.readNullable<int>('net') ?? 0;
      if (currency != null && net != 0) entry.byCurrency[currency] = net;
    }
    return byId.values.toList();
  }

  Future<String> create({required String name, String? contactHint}) async {
    final row = await into(people).insertReturning(
      PeopleCompanion.insert(
        name: name.trim(),
        contactHint: Value(contactHint),
      ),
    );
    return row.id;
  }

  Stream<PersonRow?> watchById(String id) =>
      (select(people)..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<void> rename(String id, String name) =>
      (update(people)..where((p) => p.id.equals(id))).write(
        PeopleCompanion(
          name: Value(name.trim()),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Future<void> archive(String id) => softDelete(people, id);
  Future<void> unarchive(String id) => undelete(people, id);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/db/seed.dart';

import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = testDb());
  tearDown(() => db.close());

  Future<List<Map<String, Object?>>> investments() async => [
    for (final r
        in await db
            .customSelect(
              'SELECT kind, deleted_at, sort_order FROM categories '
              "WHERE name = 'Investment' ORDER BY kind",
            )
            .get())
      r.data,
  ];

  test('a new install has Investment for income and for expenses', () async {
    await addNewDefaultCategories(db);
    final rows = await investments();
    expect(rows.map((r) => r['kind']), ['expense', 'income']);
  });

  test('an install from before gets the expense Investment once', () async {
    // As created by the first release: no expense Investment.
    await db.customStatement(
      "DELETE FROM categories WHERE name = 'Investment' AND kind = 'expense'",
    );
    final maxOrder =
        (await db
                .customSelect('SELECT MAX(sort_order) AS m FROM categories')
                .getSingle())
            .read<int>('m');

    await addNewDefaultCategories(db);
    await addNewDefaultCategories(db); // every start: still once
    final expense = (await investments()).where((r) => r['kind'] == 'expense');
    expect(expense, hasLength(1));
    expect(expense.single['sort_order'], maxOrder + 1, reason: 'at the end');
  });

  test('one the user deleted stays deleted', () async {
    await db.customStatement(
      'UPDATE categories SET deleted_at = 1 '
      "WHERE name = 'Investment' AND kind = 'expense'",
    );
    await addNewDefaultCategories(db);
    final expense = (await investments()).where((r) => r['kind'] == 'expense');
    expect(expense, hasLength(1));
    expect(expense.single['deleted_at'], isNotNull);
  });
}

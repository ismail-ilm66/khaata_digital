import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/db/app_database.dart';

import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = testDb());
  tearDown(() => db.close());

  const sep = CycleId(2026, 9);

  test(
    'setBudget upserts overall and per-category budgets per cycle',
    () async {
      final food = (await db.categoriesDao.active()).firstWhere(
        (c) => c.name == 'Food & Drink',
      );

      await db.budgetsDao.setBudget(sep, 5000000);
      await db.budgetsDao.setBudget(sep, 6000000); // replaces, not duplicates
      await db.budgetsDao.setBudget(sep, 1500000, categoryId: food.id);
      await db.budgetsDao.setBudget(sep.next, 7000000);

      final rows = await db.budgetsDao.watchCycle(sep).first;
      expect(rows, hasLength(2));
      expect(rows.firstWhere((b) => b.categoryId == null).amountMinor, 6000000);
      expect(
        rows.firstWhere((b) => b.categoryId == food.id).amountMinor,
        1500000,
      );
    },
  );

  test('clearBudget removes only the targeted budget', () async {
    await db.budgetsDao.setBudget(sep, 100);
    await db.budgetsDao.setBudget(sep.next, 100);
    await db.budgetsDao.clearBudget(sep);
    expect(await db.budgetsDao.watchCycle(sep).first, isEmpty);
    expect(await db.budgetsDao.watchCycle(sep.next).first, hasLength(1));
  });
}

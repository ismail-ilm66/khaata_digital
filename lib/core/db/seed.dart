import 'package:drift/drift.dart';

import '../../features/accounts/domain/account_presets.dart';
import '../../features/categories/domain/category_seeds.dart';
import '../money/currency.dart';
import 'app_database.dart';

/// First-run data: the Hysab Kytab category set and a Cash account, so the
/// app is usable the moment it opens (spec 3.2 onboarding).
Future<void> seedDatabase(AppDatabase db) async {
  await db.batch((b) {
    b.insertAll(db.categories, [
      for (var i = 0; i < CategorySeeds.all.length; i++)
        CategoriesCompanion.insert(
          name: CategorySeeds.all[i].name,
          kind: CategorySeeds.all[i].kind,
          icon: Value(CategorySeeds.all[i].icon),
          color: Value(CategorySeeds.colorAt(i)),
          sortOrder: Value(i),
        ),
    ]);
    b.insert(
      db.accounts,
      AccountsCompanion.insert(
        name: AccountPresets.cash.name,
        type: AccountPresets.cash.type,
        currencyCode: Currency.pkr.code,
        icon: Value(AccountPresets.cash.key),
        color: Value(AccountPresets.cash.color),
      ),
    );
  });
}

/// Gives an existing install the default categories added after it was
/// created. Skips any it has, or ever had (a deleted one stays deleted).
/// Safe to run on every start and after a restore.
Future<void> addNewDefaultCategories(AppDatabase db) async {
  for (final seed in CategorySeeds.addedLater) {
    final known = await db
        .customSelect(
          'SELECT 1 FROM categories WHERE kind = ? AND name = ? COLLATE NOCASE '
          'LIMIT 1',
          variables: [
            Variable.withString(seed.kind.name),
            Variable.withString(seed.name),
          ],
          readsFrom: {db.categories},
        )
        .getSingleOrNull();
    if (known != null) continue;
    final last = await db
        .customSelect(
          'SELECT COALESCE(MAX(sort_order), -1) AS m FROM categories',
          readsFrom: {db.categories},
        )
        .getSingle();
    final order = last.read<int>('m') + 1;
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: seed.name,
            kind: seed.kind,
            icon: Value(seed.icon),
            color: Value(CategorySeeds.colorAt(order)),
            sortOrder: Value(order),
          ),
        );
  }
}

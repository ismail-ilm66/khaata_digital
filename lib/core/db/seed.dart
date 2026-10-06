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

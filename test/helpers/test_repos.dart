import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/features/accounts/data/accounts_repository_impl.dart';
import 'package:khaata_digital/features/categories/data/categories_repository_impl.dart';
import 'package:khaata_digital/features/settings/data/settings_repository_impl.dart';
import 'package:khaata_digital/features/transactions/data/transactions_repository_impl.dart';

import 'package:khaata_digital/features/budgets/data/budgets_repository_impl.dart';
import 'package:khaata_digital/features/home/presentation/home_cubit.dart';
import 'package:khaata_digital/features/people/data/people_repository_impl.dart';
import 'package:khaata_digital/features/recurring/data/recurring_repository_impl.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';
import 'package:khaata_digital/features/transactions/presentation/form/transaction_form_bloc.dart';

import 'fake_reminders.dart';
import 'test_db.dart';
import 'test_receipts.dart';

/// Real repositories over one in-memory database — blocs are tested
/// against real persistence rather than mocks.
class TestRepos {
  TestRepos() : db = testDb() {
    accounts = AccountsRepositoryImpl(db);
    categories = CategoriesRepositoryImpl(db);
    settings = SettingsRepositoryImpl(db);
    transactions = TransactionsRepositoryImpl(db, testReceiptStore());
    budgets = BudgetsRepositoryImpl(db);
    people = PeopleRepositoryImpl(db, transactions);
    recurring = RecurringRepositoryImpl(db, transactions);
  }

  final AppDatabase db;
  late final AccountsRepositoryImpl accounts;
  late final CategoriesRepositoryImpl categories;
  late final SettingsRepositoryImpl settings;
  late final TransactionsRepositoryImpl transactions;
  late final BudgetsRepositoryImpl budgets;
  late final PeopleRepositoryImpl people;
  late final RecurringRepositoryImpl recurring;
  final reminders = FakeReminderScheduler();

  TransactionFormBloc formBloc() => TransactionFormBloc(
    transactions,
    accounts,
    categories,
    settings,
    people,
    recurring,
    reminders,
  );

  HomeCubit homeCubit(BudgetCycleCubit cycle) => HomeCubit(
    accounts,
    transactions,
    budgets,
    people,
    cycle,
    CurrencyCubit(settings),
  );

  late final ledger = TestLedger(db);

  Future<String> cashId() async =>
      (await db.accountsDao.balances()).first.account.id;

  Future<String> categoryId(String name) async =>
      (await db.categoriesDao.active()).firstWhere((c) => c.name == name).id;

  Future<void> close() => db.close();
}

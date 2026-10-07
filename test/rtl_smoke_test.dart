import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/router/routes.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/backup/data/backup_service.dart';
import 'package:khaata_digital/features/recurring/domain/recurrence.dart';
import 'package:khaata_digital/features/recurring/domain/recurring_rule.dart';
import 'package:khaata_digital/features/security/presentation/lock_cubit.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

import 'helpers/test_app.dart';
import 'helpers/test_db.dart';
import 'helpers/ui.dart';

/// Urdu RTL smoke test (M6 acceptance): every screen opens right-to-left
/// on a small phone — at normal and enlarged text — with real data in it,
/// and lays out without a single overflow or error.
void main() {
  late AppDatabase db;
  late String entryId;
  late String personId;
  late List<int> backupBytes;

  Future<void> seed() async {
    db = await setUpTestApp();
    final l = TestLedger(db);
    final cash = (await db.accountsDao.balances()).single.account.id;
    final bank = await l.account('Meezan Bank', opening: 15000000);
    final food = (await db.categoriesDao.active())
        .firstWhere((c) => c.name == 'Food & Drink')
        .id;
    personId = await db.peopleDao.create(name: 'مدثر بھائی');
    final now = DateTime.now().toUtc();
    await l.income(bank, 25000000, at: now);
    entryId = await l.expense(
      bank,
      1234550,
      categoryId: food,
      at: now.subtract(const Duration(days: 1)),
    );
    await l.transfer(bank, cash, 500000);
    await l.expense(cash, 450000, personId: personId, at: now);
    await db.budgetsDao.setBudget(
      const BudgetCycle.calendar().idFor(DateTime.now()),
      5000000,
    );
    await getIt<RecurringRepository>().create(
      EntryDraft(
        type: TransactionType.expense,
        amount: Money.major(3500, Currency.pkr),
        accountId: bank,
        categoryId: food,
        occurredAt: now.add(const Duration(days: 20)),
        note: 'انٹرنیٹ بل',
      ),
      RecurrenceFrequency.monthly,
    );
    backupBytes = (await getIt<BackupService>().create()).bytes;
    await getIt<LocaleCubit>().set(LocaleCubit.urdu);
  }

  /// Every route, with what it needs.
  Map<String, Object? Function()> screens() => {
    Routes.home: () => null,
    Routes.transactions: () => null,
    Routes.reports: () => null,
    Routes.more: () => null,
    Routes.search: () => null,
    Routes.accounts: () => null,
    Routes.accountForm: () => null,
    Routes.entry(entryId): () => null,
    Routes.budgets: () => null,
    Routes.people: () => null,
    Routes.person(personId): () => null,
    Routes.recurring: () => null,
    Routes.addEntry: () => null,
    Routes.editEntry(entryId): () => null,
    Routes.backup: () => null,
    Routes.restore: () => (name: 'b.kharcha', bytes: backupBytes),
    Routes.importData: () => null,
    Routes.appLock: () => null,
    Routes.categories: () => null,
    Routes.about: () => null,
    Routes.privacy: () => null,
    Routes.welcome: () => null,
  };

  for (final scale in [1.0, 1.3]) {
    testWidgets('every screen in Urdu at text ×$scale', (t) async {
      final errors = <String>[];
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        errors.add(d.exceptionAsString());
        if (Platform.environment['RTL_VERBOSE'] == '1') {
          // ignore: avoid_print
          print('DETAIL ${d.toString().split('\n').take(40).join('\n')}');
        }
      };

      t.view.physicalSize = const Size(1080, 1920); // 360 × 640 dp
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);

      await t.runAsync(seed);
      await t.pumpWidget(const KharchaApp());
      await t.pumpAndSettle();

      final failures = <String>[];
      for (final MapEntry(key: route, value: extra) in screens().entries) {
        errors.clear();
        final context = t.element(find.byType(GlassNavBar));
        if (route == Routes.home ||
            route == Routes.transactions ||
            route == Routes.reports ||
            route == Routes.more) {
          context.go(route);
        } else {
          unawaited(context.push(route, extra: extra()));
        }
        await waitFor(t, find.byType(Scaffold));
        // Real async (isolates, file reads) then frames; never wait on
        // endless spinners.
        for (var i = 0; i < 10; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)),
          );
          await t.pump(const Duration(milliseconds: 100));
        }

        final rtl = Directionality.of(t.element(find.byType(Scaffold).last));
        if (rtl != TextDirection.rtl) failures.add('$route: not RTL');
        if (errors.isNotEmpty) failures.add('$route: ${errors.first}');

        // Back to Home for the next one.
        context.go(Routes.home);
        await t.pump(const Duration(milliseconds: 500));
        await t.pump(const Duration(milliseconds: 500));
      }

      // The lock screen, too.
      await t.runAsync(() => getIt<LockCubit>().setPin('2580'));
      await t.pumpWidget(const SizedBox());
      await t.runAsync(() => setUpTestApp(reuse: db));
      errors.clear();
      await t.pumpWidget(const KharchaApp());
      await t.pumpAndSettle();
      if (find.byKey(const Key('lockScreen')).evaluate().isEmpty) {
        failures.add('lock screen: not shown');
      }
      if (errors.isNotEmpty) failures.add('lock screen: ${errors.first}');

      // Restore Flutter's handler before asserting, so failures report.
      FlutterError.onError = old;
      expect(failures, isEmpty, reason: failures.join('\n'));
      if (Platform.environment['RTL_VERBOSE'] == '1') {
        // ignore: avoid_print
        print('checked ${screens().length + 1} screens at ×$scale');
      }
    });
  }
}

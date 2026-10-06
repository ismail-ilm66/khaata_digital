import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/people/domain/person.dart';
import 'package:khaata_digital/features/recurring/domain/recurrence.dart';
import 'package:khaata_digital/features/recurring/domain/recurring_rule.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';

import '../helpers/test_app.dart';
import '../helpers/test_db.dart';
import '../helpers/ui.dart';

/// M3 acceptance criteria, driven through the real UI.
void main() {
  late AppDatabase db;
  late TestLedger ledger;
  late String cash;

  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  setUp(() async {
    db = await setUpTestApp();
    ledger = TestLedger(db);
    cash = (await db.accountsDao.balances()).single.account.id;
  });

  Future<void> pumpApp(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  Finder tab(String label) =>
      find.descendant(of: find.byType(GlassNavBar), matching: find.text(label));

  Future<void> keys(WidgetTester t, String digits) async {
    for (final d in digits.split('')) {
      await t.tap(find.byKey(Key('key-d$d')));
    }
    await t.pumpAndSettle();
  }

  Future<void> openMoreTile(WidgetTester t, String key) async {
    await t.tap(tab('More'));
    await t.pumpAndSettle();
    await revealAndTap(t, find.byKey(Key(key)));
  }

  testWidgets('budget bars respect a custom month start (25th)', (t) async {
    final food = (await t.runAsync(
      () => db.categoriesDao.active(),
    ))!.firstWhere((c) => c.name == 'Food & Drink').id;
    await t.runAsync(
      () => getIt<BudgetCycleCubit>().set(const BudgetCycle(25)),
    );
    final range = const BudgetCycle(25).rangeFor(DateTime.now());
    await t.runAsync(() async {
      await ledger.expense(
        cash,
        400000,
        categoryId: food,
        at: range.start.add(const Duration(hours: 2)).toUtc(),
      );
      await ledger.expense(
        cash,
        999900,
        categoryId: food,
        at: range.start.subtract(const Duration(hours: 2)).toUtc(),
      );
    });
    await pumpApp(t);

    await openMoreTile(t, 'budgetsTile');
    expect(
      find.text(
        const BudgetCycle(
          25,
        ).label(const BudgetCycle(25).idFor(DateTime.now()), locale: 'en'),
      ),
      findsOneWidget,
    );

    await t.tap(find.byKey(const Key('addBudget')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('category-Food & Drink')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('sheetAmount')), '10000');
    await t.tap(find.byKey(const Key('sheetSave')));
    await t.pumpAndSettle();

    // Only the in-cycle Rs 4,000 counts; the Rs 9,999 the day before doesn't.
    expect(find.text('Rs 6,000 left'), findsOneWidget);
  });

  testWidgets(
    'people: I gave / I received, totals match the ledger, settle up',
    (t) async {
      await pumpApp(t);
      await openMoreTile(t, 'peopleTile');

      await t.tap(find.byKey(const Key('addPerson')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('sheetTextField')), 'Ali');
      await t.tap(find.byKey(const Key('sheetDone')));
      await t.pumpAndSettle(); // lands on Ali's ledger

      await t.tap(find.byKey(const Key('iGave')));
      await t.pumpAndSettle();
      await keys(t, '5000');
      await t.tap(find.byKey(const Key('saveEntry')));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('iReceived')));
      await t.pumpAndSettle();
      await keys(t, '2000');
      await t.tap(find.byKey(const Key('saveEntry')));
      await t.pumpAndSettle();

      final overview = (await t.runAsync(
        () => getIt<PeopleRepository>().watchOverview().first,
      ))!;
      expect(
        overview.receivable[Currency.pkr],
        Money.major(3000, Currency.pkr),
      );
      expect(find.text('I gave'), findsWidgets);
      expect(find.text('I received'), findsWidgets);

      // Settle up pre-fills Rs 3,000 received; saving zeroes the balance.
      await t.tap(find.byKey(const Key('settleUp')));
      await t.pumpAndSettle();
      expect(find.text('3,000'), findsOneWidget);
      await t.tap(find.byKey(const Key('saveEntry')));
      await t.pumpAndSettle();
      expect(find.text('Settled'), findsOneWidget);
      expect(find.byKey(const Key('settleUp')), findsNothing);
    },
  );

  testWidgets('udhaar from the editor, adding the person inline', (t) async {
    await pumpApp(t);
    await t.tap(find.bySemanticsLabel('Add'));
    await t.pumpAndSettle();
    await t.tap(find.text('Udhaar'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('personCard')));
    await t.pumpAndSettle();
    await t.tap(find.text('Add person'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('sheetTextField')), 'Sara');
    await t.tap(find.byKey(const Key('sheetDone')));
    await t.pumpAndSettle();
    await keys(t, '700');
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();

    final o = (await t.runAsync(
      () => getIt<PeopleRepository>().watchOverview().first,
    ))!;
    expect(o.people.single.person.name, 'Sara');
    expect(o.receivable[Currency.pkr], Money.major(700, Currency.pkr));
    // Udhaar isn't spending: this month's Spent stays zero on Home.
    expect(find.byKey(const Key('netWorth')), findsOneWidget);
  });

  testWidgets('Repeat in the editor creates a rule listed under Recurring', (
    t,
  ) async {
    await pumpApp(t);
    await t.tap(find.bySemanticsLabel('Add'));
    await t.pumpAndSettle();
    await keys(t, '45000');
    await t.tap(find.byKey(const Key('noteChip')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('sheetTextField')), 'Rent');
    await t.tap(find.byKey(const Key('sheetDone')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('repeatChip')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('repeat-monthly')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('remindSwitch')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('repeatDone')));
    await t.pumpAndSettle();
    expect(
      find.text('Monthly'),
      findsOneWidget,
      reason: 'the chip shows the choice',
    );
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();

    final rule = (await t.runAsync(
      () => getIt<RecurringRepository>().active(),
    ))!.single;
    expect(rule.frequency, RecurrenceFrequency.monthly);
    expect(rule.remind, isTrue);

    await openMoreTile(t, 'recurringTile');
    expect(find.byKey(const Key('rule-Rent')), findsOneWidget);
    expect(find.textContaining('Monthly'), findsOneWidget);
  });
}

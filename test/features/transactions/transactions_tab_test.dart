import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/widgets/amount_text.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:khaata_digital/features/transactions/domain/transactions_repository.dart';
import 'package:khaata_digital/features/transactions/presentation/widgets/entry_tile.dart';

import '../../helpers/test_app.dart';
import '../../helpers/ui.dart';

/// The Transactions tab shows one budget cycle at a time (DECISIONS #141).
void main() {
  late AppDatabase db;
  late String cash;

  setUp(() async {
    db = await setUpTestApp();
    cash = (await db.accountsDao.balances()).single.account.id;
  });

  Future<void> open(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('Transactions'),
      ),
    );
    await t.pumpAndSettle();
  }

  Finder row(String text) => find.widgetWithText(EntryTile, text);

  Future<void> spend(int rupees, DateTime at, String note, {String? person}) =>
      getIt<TransactionsRepository>().save(
        EntryDraft(
          type: TransactionType.expense,
          amount: Money.major(rupees, Currency.pkr),
          accountId: cash,
          occurredAt: at,
          note: note,
          personId: person,
        ),
      );

  int spent(WidgetTester t) =>
      t.widget<AmountText>(find.byKey(const Key('monthSpent'))).money.minor;

  /// Month totals come from a live query: wait for [minor].
  Future<void> spentIs(WidgetTester t, int minor) => waitFor(
    t,
    find.byWidgetPredicate(
      (w) =>
          w is AmountText &&
          w.key == const Key('monthSpent') &&
          w.money.minor == minor,
    ),
  );

  /// Midday on a day inside the cycle [steps] before the current one.
  DateTime inCycle(int steps) {
    final cycle = getIt<BudgetCycleCubit>().state;
    var id = cycle.idFor(DateTime.now());
    for (var i = 0; i < steps; i++) {
      id = id.previous;
    }
    final start = cycle.rangeOf(id).start;
    return DateTime(start.year, start.month, start.day, 12).toUtc();
  }

  testWidgets('one month at a time; the arrows step months', (t) async {
    await t.runAsync(() async {
      await spend(500, DateTime.now().toUtc(), 'Now');
      await spend(700, inCycle(1), 'Last month');
    });
    await open(t);
    expect(row('Now'), findsOneWidget);
    expect(row('Last month'), findsNothing);
    expect(spent(t), 50000);

    await t.tap(find.byKey(const Key('previousPeriod')));
    await t.pump();
    expect(row('Now'), findsNothing, reason: 'never under the wrong month');
    await waitFor(t, row('Last month'));
    await spentIs(t, 70000);

    await t.tap(find.byKey(const Key('nextPeriod')));
    await waitFor(t, row('Now'));
    expect(row('Last month'), findsNothing);
    expect(
      find.byKey(const Key('nextPeriod')),
      findsNothing,
      reason: 'nothing later than this month',
    );
  });

  testWidgets('chips: Expenses leaves udhaar out; Udhaar shows only it', (
    t,
  ) async {
    await t.runAsync(() async {
      final ali = await db.peopleDao.create(name: 'Ali');
      await spend(300, DateTime.now().toUtc(), 'Lunch');
      await spend(900, DateTime.now().toUtc(), 'Lent', person: ali);
    });
    await open(t);
    expect(row('Lunch'), findsOneWidget);
    expect(row('Ali'), findsOneWidget);

    await t.tap(find.byKey(const Key('kind-expenses')));
    await waitFor(t, row('Lunch'));
    expect(row('Ali'), findsNothing, reason: 'a loan is not spending');
    expect(spent(t), 30000, reason: 'the list adds up to Spent');

    // The chips scroll sideways; Udhaar is past the edge in test fonts.
    await t.drag(find.byKey(const Key('kindChips')), const Offset(-300, 0));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('kind-udhaar')));
    await waitFor(t, row('Ali'));
    expect(row('Lunch'), findsNothing);
  });

  testWidgets('a future-dated entry keeps the next month in reach', (t) async {
    final cycle = getIt<BudgetCycleCubit>().state;
    final next = cycle.rangeOf(cycle.idFor(DateTime.now()).next).start;
    await t.runAsync(
      () => spend(
        100,
        DateTime(next.year, next.month, next.day, 12).toUtc(),
        'Planned',
      ),
    );
    await open(t);
    expect(row('Planned'), findsNothing);
    await t.tap(find.byKey(const Key('nextPeriod')));
    await waitFor(t, row('Planned'));
  });

  testWidgets('the month name opens All time and Pick a month', (t) async {
    await t.runAsync(() async {
      await spend(500, DateTime.now().toUtc(), 'Now');
      await spend(700, inCycle(3), 'Long ago');
    });
    await open(t);
    expect(row('Long ago'), findsNothing);

    // All time: every entry, each cycle named above its card, no arrows.
    await t.tap(find.byKey(const Key('periodLabel')));
    await t.pumpAndSettle();
    await t.tap(find.text('All time'));
    await waitFor(t, row('Long ago'));
    expect(row('Now'), findsOneWidget);
    expect(find.byKey(const Key('previousPeriod')), findsNothing);
    await spentIs(t, 120000);
    final cycle = getIt<BudgetCycleCubit>().state;
    final old = cycle.idFor(inCycle(3).toLocal());
    expect(find.text(cycle.label(old, locale: 'en')), findsOneWidget);

    // Pick a month: straight to it, three months back.
    await t.tap(find.byKey(const Key('periodLabel')));
    await t.pumpAndSettle();
    await t.tap(find.text('Pick a month…'));
    await t.pumpAndSettle();
    await t.tap(find.text(cycle.label(old, locale: 'en')).last);
    await waitFor(t, row('Long ago'));
    expect(row('Now'), findsNothing);
    await spentIs(t, 70000);
    expect(find.byKey(const Key('nextPeriod')), findsOneWidget);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/router/routes.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/people/domain/person.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// Bad debts through the real UI: Settle up → Write it off.
void main() {
  late AppDatabase db;
  late String cash;
  late String ali;

  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  setUp(() async {
    db = await setUpTestApp();
    cash = (await db.accountsDao.balances()).single.account.id;
    ali = await getIt<PeopleRepository>().create('Ali');
    await TestLedger(db).expense(cash, 500000, personId: ali);
  });

  /// Pushes a person's page over whatever is showing.
  Future<void> open(WidgetTester t, String person) async {
    unawaited(
      t.element(find.byType(Navigator).last).push(Routes.person(person)),
    );
    await t.pumpAndSettle();
  }

  Future<void> openAli(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
    await open(t, ali);
  }

  Future<Money?> balance(WidgetTester t) async => (await t.runAsync(
    () => getIt<PeopleRepository>().watchOverview().first,
  ))!.people.single.balance[Currency.pkr];

  testWidgets('write off part, then the rest; delete with undo', (t) async {
    await openAli(t);
    final cashBefore = (await t.runAsync(
      () => TestLedger(db).balanceOf(cash),
    ))!;

    await t.tap(find.byKey(const Key('settleUp')));
    await t.pumpAndSettle();
    expect(find.text('They paid me back'), findsOneWidget);
    await t.tap(find.text('Write it off'));
    await t.pumpAndSettle();

    // Starts at the whole balance and can't go over it.
    expect(find.text('Write off Rs\u00a05,000'), findsOneWidget);
    await t.enterText(find.byKey(const Key('writeOffAmount')), '6000');
    await t.tap(find.byKey(const Key('writeOffSave')));
    await t.pumpAndSettle();
    expect(find.text('Up to Rs\u00a05,000'), findsOneWidget);

    await t.enterText(find.byKey(const Key('writeOffAmount')), '2000');
    await t.enterText(find.byKey(const Key('writeOffNote')), 'Moved away');
    await t.pumpAndSettle();
    expect(find.text('Write off Rs\u00a02,000'), findsOneWidget);
    await t.tap(find.byKey(const Key('writeOffSave')));
    await t.pumpAndSettle();

    expect(await balance(t), Money.major(3000, Currency.pkr));
    expect(find.text('Written off'), findsOneWidget);
    expect(find.textContaining('Moved away'), findsOneWidget);

    // The rest: the sheet now starts at what's left.
    await t.tap(find.byKey(const Key('settleUp')));
    await t.pumpAndSettle();
    await t.tap(find.text('Write it off'));
    await t.pumpAndSettle();
    await t.tap(find.text('Write off Rs\u00a03,000'));
    await t.pumpAndSettle();
    expect(find.text('Settled'), findsOneWidget);
    expect(find.byKey(const Key('settleUp')), findsNothing);
    expect(
      await t.runAsync(() => TestLedger(db).balanceOf(cash)),
      cashBefore,
      reason: 'no account moves',
    );

    // Tapping a write-off edits it; deleting offers undo.
    await t.tap(find.text('Written off').first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('writeOffDelete')));
    await t.pumpAndSettle();
    expect(find.text('Write-off deleted'), findsOneWidget);
    expect(await balance(t), Money.major(3000, Currency.pkr));
    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(await balance(t), isNull, reason: 'settled again');
  });

  testWidgets('what I owe: they let it go', (t) async {
    final sara = await getIt<PeopleRepository>().create('Sara');
    await TestLedger(db).income(cash, 120000, personId: sara);
    await openAli(t);
    await open(t, sara);

    await t.tap(find.byKey(const Key('settleUp')));
    await t.pumpAndSettle();
    expect(find.text('I paid them back'), findsOneWidget);
    await t.tap(find.text('They let it go'));
    await t.pumpAndSettle();
    await t.tap(find.text('Mark Rs\u00a01,200 forgiven'));
    await t.pumpAndSettle();

    expect(find.text('Forgiven'), findsOneWidget);
    expect(find.text('Settled'), findsOneWidget);
  });

  testWidgets('Reports: a quiet line under the totals, opening the person', (
    t,
  ) async {
    await getIt<PeopleRepository>().writeOff(
      ali,
      Money.major(5000, Currency.pkr),
      occurredAt: DateTime.now(),
    );
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('Reports'),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('Written off · 1 person'), findsOneWidget);
    // Not spending: this month's Spent is still nothing.
    expect(find.text('Rs\u00a05,000'), findsOneWidget);
    await t.tap(find.byKey(const Key('reportWrittenOff')));
    await t.pumpAndSettle();
    await t.tap(find.text('Ali'));
    await t.pumpAndSettle();
    expect(find.text('Written off'), findsOneWidget);
    expect(find.text('Settled'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/router/routes.dart';
import 'package:khaata_digital/core/widgets/amount_text.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/categories/presentation/category_grid.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';

import '../helpers/test_app.dart';
import '../helpers/test_db.dart';
import '../helpers/ui.dart';

/// Owner requests: an expense "Investment" category, search in the pick
/// sheets, and the eye on Accounts, People and a person's page.
void main() {
  late AppDatabase db;
  late String cash;

  setUp(() async {
    db = await setUpTestApp();
    cash = (await db.accountsDao.balances()).single.account.id;
  });

  Future<void> start(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  Future<void> go(WidgetTester t, String route) async {
    unawaited(t.element(find.byType(GlassNavBar)).push(route));
    await t.pumpAndSettle();
  }

  Future<void> openAllCategories(WidgetTester t) async {
    await t.tap(find.bySemanticsLabel('Add'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('allCategories')));
    await t.pumpAndSettle();
  }

  testWidgets('expenses have an Investment category, found by search', (
    t,
  ) async {
    await start(t);
    await openAllCategories(t);
    await t.enterText(find.byKey(const Key('sheetSearch')), 'inv');
    await t.pumpAndSettle();
    Finder inSheet(String key) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byKey(Key(key)),
    );
    expect(inSheet('category-Investment'), findsOneWidget);
    expect(inSheet('category-Grocery'), findsNothing);

    await t.enterText(find.byKey(const Key('sheetSearch')), 'zzz');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sheetNoMatches')), findsOneWidget);
  });

  testWidgets('tapping a searched category selects it', (t) async {
    // Owner bug: on a phone, the keyboard closed as the finger landed on a
    // result, the sheet shrank under it and the tap was lost.
    await start(t);
    await openAllCategories(t);
    await t.tap(find.byKey(const Key('sheetSearch')));
    await t.enterText(find.byKey(const Key('sheetSearch')), 'inv');
    await t.pumpAndSettle();
    final search = t.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('sheetSearch')),
        matching: find.byType(EditableText),
      ),
    );
    expect(search.focusNode.hasFocus, isTrue);

    final tile = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byKey(const Key('category-Investment')),
    );
    final finger = await t.startGesture(t.getCenter(tile));
    await t.pump();
    expect(
      search.focusNode.hasFocus,
      isTrue,
      reason: 'the keyboard must not close while the finger is down',
    );
    await finger.up();
    await t.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    final picked = t.widget<CategoryTile>(
      find.ancestor(
        of: find.byKey(const Key('category-Investment')),
        matching: find.byType(CategoryTile),
      ),
    );
    expect(picked.selected, isTrue);
  });

  testWidgets('choosing a person can be searched; Add person stays', (t) async {
    await t.runAsync(() async {
      for (final n in ['Ali', 'Sara', 'Zain Bhai']) {
        await db.peopleDao.create(name: n);
      }
    });
    await start(t);
    await t.tap(find.bySemanticsLabel('Add'));
    await t.pumpAndSettle();
    await t.tap(find.text('Udhaar'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('personCard')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('sheetSearch')), 'SA');
    await t.pumpAndSettle();
    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('Ali'), findsNothing);
    expect(find.text('Add person'), findsOneWidget);
    await t.tap(find.text('Sara'));
    await t.pumpAndSettle();
    expect(find.text('Sara'), findsOneWidget, reason: 'chosen');
  });

  group('the eye beyond Home', () {
    bool allMasked(WidgetTester t) => t
        .widgetList<AmountText>(find.byType(AmountText))
        .every((a) => a.masked);

    testWidgets('Accounts has its own eye', (t) async {
      await start(t);
      await go(t, Routes.accounts);
      expect(allMasked(t), isFalse);
      await t.tap(find.byKey(const Key('accountsEye')));
      await t.pumpAndSettle();
      expect(allMasked(t), isTrue);
      expect(getIt<HideBalanceCubit>().state.masked, isTrue);
      await t.tap(find.byKey(const Key('accountsEye')));
      await t.pumpAndSettle();
      expect(allMasked(t), isFalse);
    });

    testWidgets('hidden on Home stays hidden in People and on a person', (
      t,
    ) async {
      final ali = (await t.runAsync(() => db.peopleDao.create(name: 'Ali')))!;
      await t.runAsync(
        () => TestLedger(db).expense(cash, 500000, personId: ali),
      );
      await start(t);
      await t.tap(find.byKey(const Key('hideBalance')));
      await t.pumpAndSettle();

      await reveal(t, find.byKey(const Key('receivable')));
      await t.tap(find.byKey(const Key('receivable')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('peopleTabTotal')), findsOneWidget);
      expect(allMasked(t), isTrue, reason: 'People');

      await t.tap(find.byKey(const Key('person-Ali')));
      await t.pumpAndSettle();
      expect(
        t.widget<AmountText>(find.byKey(const Key('personBalance'))).masked,
        isTrue,
      );

      // Shown again from the person's own eye.
      await t.tap(find.byKey(const Key('personEye')));
      await t.pumpAndSettle();
      expect(
        t.widget<AmountText>(find.byKey(const Key('personBalance'))).masked,
        isFalse,
      );
      t.element(find.byKey(const Key('personBalance'))).pop();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('peopleEye')), findsOneWidget);
      expect(allMasked(t), isFalse, reason: 'one setting everywhere');
    });
  });
}

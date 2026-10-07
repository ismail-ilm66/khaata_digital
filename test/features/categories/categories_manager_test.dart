import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/router/routes.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/categories/domain/category_kind.dart';

import '../../helpers/test_app.dart';
import '../../helpers/ui.dart';

void main() {
  late AppDatabase db;
  setUp(() async => db = await setUpTestApp());

  Future<void> open(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
    unawaited(t.element(find.byType(GlassNavBar)).push(Routes.categories));
    await t.pumpAndSettle();
  }

  Future<List<String>> names(WidgetTester t, CategoryKind kind) async => [
    for (final c in (await t.runAsync(
      () => db.categoriesDao.active(kind: kind),
    ))!)
      c.name,
  ];

  Future<void> save(WidgetTester t) async {
    await t.tap(find.byKey(const Key('saveCategory')));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await t.pumpAndSettle();
  }

  testWidgets('add, refuse a duplicate, rename and re-icon', (t) async {
    await open(t);
    await t.tap(find.byKey(const Key('addCategory')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('categoryNameField')), 'Committee');
    await t.tap(find.byKey(const Key('icon-savings')));
    await save(t);
    expect(await names(t, CategoryKind.expense), contains('Committee'));

    await t.tap(find.byKey(const Key('addCategory')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('categoryNameField')), 'committee');
    await save(t);
    expect(
      find.text('You already have a category called committee'),
      findsOneWidget,
    );
    expect(
      (await names(
        t,
        CategoryKind.expense,
      )).where((n) => n.toLowerCase() == 'committee'),
      hasLength(1),
    );

    await revealAndTap(t, find.byKey(const Key('category-row-Committee')));
    await t.enterText(
      find.byKey(const Key('categoryNameField')),
      'BC Committee',
    );
    await t.tap(find.byKey(const Key('icon-wallet')));
    await save(t);
    final row = (await t.runAsync(
      () => db.categoriesDao.active(),
    ))!.singleWhere((c) => c.name == 'BC Committee');
    expect(row.icon, 'wallet');
  });

  testWidgets('archive with undo, restore, and the Income tab', (t) async {
    await open(t);
    expect(await names(t, CategoryKind.expense), contains('Food & Drink'));
    await revealAndTap(t, find.byKey(const Key('category-row-Food & Drink')));
    await t.tap(find.byKey(const Key('archiveCategory')));
    await t.pumpAndSettle();
    expect(
      await names(t, CategoryKind.expense),
      isNot(contains('Food & Drink')),
    );
    expect(find.text('Category archived'), findsOneWidget);

    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(await names(t, CategoryKind.expense), contains('Food & Drink'));

    await t.tap(find.text('Income'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('category-row-Salary')), findsOneWidget);
    expect(find.byKey(const Key('category-row-Food & Drink')), findsNothing);
  });
}

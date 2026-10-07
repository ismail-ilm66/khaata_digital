import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/router/routes.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/core/widgets/pill_button.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:khaata_digital/features/transactions/domain/transactions_repository.dart';

import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

/// The add / edit screen: the phone's number pad for the amount, account
/// chips instead of a picker sheet, and the note typed in place.
void main() {
  late AppDatabase db;
  late String cash;
  late String bank;

  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  setUp(() async {
    db = await setUpTestApp();
    cash = (await db.accountsDao.balances()).single.account.id;
    bank = await TestLedger(db).account('Meezan Bank');
  });

  Future<List<EntryView>> entries() async =>
      (await getIt<TransactionsRepository>().watch(const EntryQuery()).first)
          .items;

  Future<void> openAdd(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 1920); // a small 360 × 640 phone
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Add'));
    await t.pumpAndSettle();
  }

  Finder amount() => find.byKey(const Key('amountField'));

  EditableText editable(WidgetTester t, Finder field) => t.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );

  testWidgets('a new entry opens with the number pad up', (t) async {
    await openAdd(t);
    final field = editable(t, amount());
    expect(field.focusNode.hasFocus, isTrue);
    expect(
      field.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(find.byKey(const Key('key-d1')), findsNothing, reason: 'no keypad');

    await t.enterText(amount(), '12500');
    await t.pump();
    expect(find.text('12,500'), findsOneWidget);
  });

  testWidgets('nothing is pre-chosen; Save says what is missing', (t) async {
    await openAdd(t);
    final chips = find.descendant(
      of: find.byKey(const Key('accountStrip')),
      matching: find.byType(PillButton),
    );
    expect(
      t.widgetList<PillButton>(chips).where((p) => p.selected),
      isEmpty,
      reason: 'no account selected by default',
    );
    await t.enterText(amount(), '700');
    await t.pump();
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();
    expect(find.text('Choose an account'), findsOneWidget);

    await t.tap(find.byKey(const Key('account-Cash')));
    await t.pumpAndSettle();
    expect(find.text('Choose an account'), findsNothing);
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();
    expect(find.text('Choose a category'), findsOneWidget);
    expect((await t.runAsync(entries))!, isEmpty);
  });

  testWidgets('Save stays reachable above the keyboard', (t) async {
    await openAdd(t);
    await t.enterText(amount(), '700');
    await t.tap(find.byKey(const Key('account-Cash')));
    await t.tap(find.byKey(const Key('category-Food & Drink')));
    t.view.viewInsets = const FakeViewPadding(bottom: 291 * 3);
    addTearDown(t.view.resetViewInsets);
    await t.pumpAndSettle();
    final save = t.getRect(find.byKey(const Key('saveEntry')));
    expect(save.bottom, lessThanOrEqualTo(640 - 291));
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();
    expect((await t.runAsync(entries))!.single.entry.amount.minor, 70000);
  });

  testWidgets('accounts are one tap away, and the note is typed in place', (
    t,
  ) async {
    await openAdd(t);
    await t.enterText(amount(), '250');
    await t.tap(find.byKey(const Key('account-Meezan Bank')));
    await t.tap(find.byKey(const Key('category-Food & Drink')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('noteField')), '  Chai with Ali ');
    await t.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();

    final saved = (await t.runAsync(entries))!.single.entry;
    expect(saved.accountId, bank);
    expect(saved.amount, Money.major(250, Currency.pkr));
    expect(saved.note, 'Chai with Ali');
  });

  testWidgets('transfers pick From and To from chips; picking To as From '
      'swaps them', (t) async {
    await openAdd(t);
    await t.tap(find.text('Transfer'));
    await t.pumpAndSettle();
    await t.enterText(amount(), '1000');
    Finder chip(String strip, String name) => find.descendant(
      of: find.byKey(Key(strip)),
      matching: find.byKey(Key('account-$name')),
    );
    await t.tap(chip('fromAccount', 'Cash'));
    await t.pumpAndSettle();
    await t.tap(chip('toAccount', 'Meezan Bank'));
    await t.pumpAndSettle();
    // Now choose Meezan Bank as the source: the two swap.
    await t.tap(
      find.descendant(
        of: find.byKey(const Key('fromAccount')),
        matching: find.byKey(const Key('account-Meezan Bank')),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();

    final saved = (await t.runAsync(entries))!.single.entry;
    expect(saved.type, TransactionType.transfer);
    expect(saved.accountId, bank);
    expect(saved.toAccountId, cash);
  });

  testWidgets('editing shows the amount without forcing the keyboard up', (
    t,
  ) async {
    final id = await TestLedger(db).expense(cash, 252000);
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
    unawaited(t.element(find.byType(GlassNavBar)).push(Routes.editEntry(id)));
    await t.pumpAndSettle();
    expect(editable(t, amount()).focusNode.hasFocus, isFalse);
    expect(find.text('2,520'), findsOneWidget);
  });
}

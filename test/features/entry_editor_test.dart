import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import '../helpers/ui.dart';

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

  testWidgets('Save waits under the keyboard; a tap anywhere puts it away', (
    t,
  ) async {
    await openAdd(t);
    bool typing() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>() !=
        null;
    expect(typing(), isTrue, reason: 'a new entry opens typing');

    // A tap on a plain label (nothing to press there) puts it away.
    await t.tap(find.text('Paid from'));
    await t.pumpAndSettle();
    expect(typing(), isFalse);

    await t.enterText(amount(), '700');
    await t.tap(find.byKey(const Key('account-Cash')));
    await t.tap(find.byKey(const Key('category-Food & Drink')));
    t.view.viewInsets = const FakeViewPadding(bottom: 291 * 3);
    addTearDown(t.view.resetViewInsets);
    await t.pumpAndSettle();
    expect(
      find.byKey(const Key('saveEntry')),
      findsNothing,
      reason: 'not riding on top of the keyboard',
    );

    t.view.resetViewInsets();
    await t.pumpAndSettle();
    final save = t.getRect(find.byKey(const Key('saveEntry')));
    expect(save.bottom, greaterThan(640 - 80), reason: 'back at the bottom');
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();
    expect((await t.runAsync(entries))!.single.entry.amount.minor, 70000);
  });

  testWidgets('a bill split with people asks for each share, then saves', (
    t,
  ) async {
    await t.runAsync(() async {
      await db.peopleDao.create(name: 'Ali');
      await db.peopleDao.create(name: 'Sara');
    });
    await openAdd(t);
    await t.enterText(amount(), '3000');
    await t.tap(find.byKey(const Key('account-Cash')));
    await t.tap(find.byKey(const Key('category-Food & Drink')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('splitChip')));
    await t.tap(find.byKey(const Key('splitChip')));
    await t.pumpAndSettle();
    await t.tap(find.text('Ali'));
    await t.tap(find.text('Sara'));
    await t.pump();
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(find.text('Split · 2'), findsOneWidget);
    expect(find.byKey(const Key('repeatChip')), findsNothing);

    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();
    String share(int i) => t
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(Key('share-$i')),
            matching: find.byType(EditableText),
          ),
        )
        .controller
        .text;
    expect([share(0), share(1), share(2)], ['1000', '1000', '1000']);

    FilledButton confirm() =>
        t.widget<FilledButton>(find.byKey(const Key('confirmSplit')));
    await t.enterText(find.byKey(const Key('share-0')), '500');
    await t.pump();
    expect(find.textContaining('still to split'), findsOneWidget);
    expect(confirm().onPressed, isNull);
    await t.enterText(find.byKey(const Key('share-1')), '1500');
    await t.pump();
    expect(find.textContaining('Adds up to'), findsOneWidget);
    await t.tap(find.byKey(const Key('confirmSplit')));
    await t.pumpAndSettle();

    final saved = [for (final v in (await t.runAsync(entries))!) v.entry];
    expect(saved.map((e) => e.amount.minor).toList()..sort(), [
      50000,
      100000,
      150000,
    ]);
    expect(saved.where((e) => e.personId == null).single.categoryId, isNotNull);
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

  testWidgets('Yesterday in one tap keeps the time; Other and the time '
      'open one picker each', (t) async {
    await openAdd(t);
    await t.enterText(amount(), '700');
    await t.tap(find.byKey(const Key('account-Cash')));
    await t.tap(find.byKey(const Key('category-Grocery')));
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    String time() => t
        .widget<Text>(
          find.descendant(
            of: find.byKey(const Key('timeChip')),
            matching: find.byType(Text),
          ),
        )
        .data!;
    final before = time();

    // Other: the calendar only, no clock after it. Cancel keeps the day.
    await revealAndTap(t, find.byKey(const Key('dateChip')));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);

    // The time: the clock only.
    await revealAndTap(t, find.byKey(const Key('timeChip')));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(find.byType(DatePickerDialog), findsNothing);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();

    await revealAndTap(t, find.byKey(const Key('dayYesterday')));
    expect(time(), before, reason: 'the time is kept');
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();

    final at = (await t.runAsync(entries))!.single.entry.occurredAt.toLocal();
    final now = DateTime.now();
    expect(
      DateUtils.dateOnly(at),
      DateUtils.addDaysToDate(DateUtils.dateOnly(now), -1),
    );
    expect(DateFormat.jm('en').format(at), before, reason: 'same time');
  });
}

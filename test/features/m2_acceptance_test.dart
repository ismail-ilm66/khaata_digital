import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:khaata_digital/features/transactions/domain/transactions_repository.dart';
import 'package:khaata_digital/features/transactions/presentation/widgets/entry_tile.dart';

import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

/// M2 acceptance criteria, driven through the real UI.
void main() {
  late AppDatabase db;
  late TestLedger ledger;
  late String cash;

  // A tap that lands on another widget (e.g. a sheet hidden behind the
  // nav bar) must fail the test, not just warn.
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  setUp(() async {
    db = await setUpTestApp();
    ledger = TestLedger(db);
    cash = (await db.accountsDao.balances()).single.account.id;
  });

  TransactionsRepository repo() => getIt<TransactionsRepository>();

  Future<void> pumpApp(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  Finder tab(String label) =>
      find.descendant(of: find.byType(GlassNavBar), matching: find.text(label));

  Future<List<EntryView>> entries() async =>
      (await repo().watch(const EntryQuery()).first).items;

  // Owner decision #117: nothing is pre-chosen, so the account is one more
  // tap than the spec's 4.
  testWidgets('the quick path: + → type 5 → account → category → Save', (
    t,
  ) async {
    await pumpApp(t);
    var taps = 0;
    Future<void> tap(Finder f) async {
      taps++;
      await t.tap(f);
      await t.pumpAndSettle();
    }

    await tap(find.bySemanticsLabel('Add'));
    taps++; // typing the amount on the number pad
    await t.enterText(find.byKey(const Key('amountField')), '5');
    await t.pumpAndSettle();
    await tap(find.byKey(const Key('account-Cash')));
    await tap(find.byKey(const Key('category-Food & Drink')));
    await tap(find.byKey(const Key('saveEntry')));

    expect(taps, lessThanOrEqualTo(5));
    final saved = (await t.runAsync(entries))!.single;
    expect(saved.entry.amount, Money.major(5, Currency.pkr));
    expect(saved.category!.name, 'Food & Drink');
    // Home's recent list shows it straight away (scroll down to it).
    final tile = find.widgetWithText(EntryTile, 'Food & Drink');
    await t.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tile, findsOneWidget);
  });

  testWidgets('edit re-opens with the stored date and saving keeps it', (
    t,
  ) async {
    final at = DateTime(2025, 8, 25, 13, 45);
    final id = (await t.runAsync(
      () => repo().save(
        EntryDraft(
          type: TransactionType.expense,
          amount: Money.major(2520, Currency.pkr),
          accountId: cash,
          occurredAt: at.toUtc(),
          note: 'Lunch',
        ),
      ),
    ))!;
    await pumpApp(t);

    await t.tap(tab('Transactions'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(EntryTile, 'No category'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('editEntry')));
    await t.pumpAndSettle();

    final dateChip = t.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('dateChip')),
        matching: find.byType(Text),
      ),
    );
    expect(dateChip.data, contains('2025'), reason: 'not reset to today');
    expect(find.text('2,520'), findsOneWidget);

    await t.enterText(find.byKey(const Key('amountField')), '25200');
    await t.pumpAndSettle();
    // An expense can't be saved without a category (#118).
    await t.tap(find.byKey(const Key('category-Food & Drink')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();

    final stored = (await t.runAsync(() => repo().byId(id)))!;
    expect(stored.amount, Money.major(25200, Currency.pkr));
    expect(stored.occurredAt.toLocal(), at);
  });

  testWidgets('an archived account name can be reused', (t) async {
    await pumpApp(t);
    await t.tap(tab('More'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('accountsTile')));
    await t.pumpAndSettle();

    // Archive Cash.
    await t.tap(find.text('Cash').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('archiveAccount')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('archivedSection')), findsOneWidget);
    expect(find.text('Account archived'), findsOneWidget);
    await t.pump(const Duration(seconds: 5)); // let the snackbar go
    await t.pumpAndSettle();

    // Create a new account called Cash.
    await t.tap(find.byKey(const Key('addAccount')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('preset-custom')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('preset-custom')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('accountName')), 'Cash');
    await t.tap(find.byKey(const Key('saveAccount')));
    await t.pumpAndSettle();

    final rows = (await t.runAsync(() => db.accountsDao.balances()))!;
    expect(rows.single.account.name, 'Cash');
    expect(rows.single.account.id, isNot(cash));
  });

  testWidgets('a transfer shows once and moves both balances', (t) async {
    final bank = (await t.runAsync(
      () => ledger.account('Meezan Bank', opening: 100000),
    ))!;
    await pumpApp(t);

    await t.tap(find.bySemanticsLabel('Add'));
    await t.pumpAndSettle();
    await t.tap(find.text('Transfer'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('amountField')), '300');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('account-Cash')).first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('account-Meezan Bank')).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();

    await t.tap(tab('Transactions'));
    await t.pumpAndSettle();
    expect(find.byType(EntryTile), findsOneWidget);
    expect(
      find.widgetWithText(EntryTile, 'Cash → Meezan Bank'),
      findsOneWidget,
    );
    expect(await t.runAsync(() => ledger.balanceOf(cash)), -30000);
    expect(await t.runAsync(() => ledger.balanceOf(bank)), 130000);
  });

  testWidgets('swipe left deletes with undo', (t) async {
    await t.runAsync(() => ledger.expense(cash, 100));
    await pumpApp(t);
    await t.tap(tab('Transactions'));
    await t.pumpAndSettle();

    await t.drag(find.byType(EntryTile), const Offset(-600, 0));
    await t.pumpAndSettle();
    expect(
      find.text('Delete this entry?'),
      findsOneWidget,
      reason: 'asks first',
    );
    await t.tap(find.byKey(const Key('confirmAction')));
    await t.pumpAndSettle();
    expect(find.byType(EntryTile), findsNothing);
    expect(find.text('Transaction deleted'), findsOneWidget);

    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(find.byType(EntryTile), findsOneWidget);
  });

  testWidgets('search finds by note', (t) async {
    await t.runAsync(() async {
      await repo().save(
        EntryDraft(
          type: TransactionType.expense,
          amount: Money.major(80, Currency.pkr),
          accountId: cash,
          occurredAt: DateTime.now().toUtc(),
          note: 'Chai at Tapal',
        ),
      );
      await ledger.expense(cash, 999);
    });
    await pumpApp(t);
    await t.tap(tab('Transactions'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('searchButton')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('searchField')), 'chai');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();

    expect(find.byType(EntryTile), findsOneWidget);
    expect(find.textContaining('Chai at Tapal'), findsOneWidget);
  });

  testWidgets('the editor and sheets open above the glass nav bar', (t) async {
    await pumpApp(t);

    // Add is a full-screen task over the shell.
    await t.tap(find.bySemanticsLabel('Add'));
    await t.pumpAndSettle();
    expect(find.byType(GlassNavBar), findsNothing);
    await t.tap(find.byKey(const Key('closeEditor')));
    await t.pumpAndSettle();

    // A sheet opened from a tab covers the bar; its bottom button takes
    // the tap (hit-test warnings are fatal here).
    await t.tap(tab('Transactions'));
    await t.pumpAndSettle();
    await t.tap(find.text('Type'));
    await t.pumpAndSettle();
    final done = find.widgetWithText(FilledButton, 'Done');
    expect(
      t.getRect(done).overlaps(t.getRect(find.byType(GlassNavBar))),
      isTrue,
    );
    await t.tap(done);
    await t.pumpAndSettle();
    expect(done, findsNothing);
  });

  testWidgets(
    'Home → account card opens Accounts full-screen without switching tabs',
    (t) async {
      await pumpApp(t);
      await t.tap(find.text('Cash').first);
      await t.pumpAndSettle();

      expect(find.text('Accounts'), findsWidgets);
      expect(
        find.byType(GlassNavBar),
        findsNothing,
        reason: 'pushed over the shell',
      );

      await t.pageBack();
      await t.pumpAndSettle();
      final nav = t.widget<GlassNavBar>(find.byType(GlassNavBar));
      expect(nav.selectedIndex, 0, reason: 'still on Home');
    },
  );
}

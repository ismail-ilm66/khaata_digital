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
import 'package:khaata_digital/features/to_pay/domain/planned_payment.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/transactions_repository.dart';

import '../../helpers/test_app.dart';
import '../../helpers/ui.dart';

/// "I need to give 2,400 to charity": write it down, see it on Home, then
/// pay it as an expense in one go.
void main() {
  late AppDatabase db;

  setUp(() async => db = await setUpTestApp());

  Future<void> start(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  ToPayRepository repo() => getIt<ToPayRepository>();

  testWidgets('add from More, see it on Home, pay it as an expense', (t) async {
    await start(t);
    expect(find.byKey(const Key('homeToPay')), findsNothing, reason: 'empty');

    await t.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('More'),
      ),
    );
    await t.pumpAndSettle();
    await revealAndTap(t, find.byKey(const Key('toPayTile')));
    expect(find.text('Nothing to pay'), findsOneWidget);

    await t.tap(find.byKey(const Key('addFirstToPay')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('toPayTitle')), 'Charity');
    await t.enterText(
      find.descendant(
        of: find.byKey(const Key('toPayAmount')),
        matching: find.byType(EditableText),
      ),
      '2400',
    );
    await t.tap(find.byKey(const Key('toPaySave')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('toPay-Charity')), findsOneWidget);
    expect(find.byKey(const Key('toPayTotal-PKR')), findsOneWidget);

    // Home lists it too.
    t.element(find.byType(Scaffold).last).pop();
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('Home'),
      ),
    );
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('homeToPay')));
    expect(find.byKey(const Key('toPay-Charity')), findsOneWidget);

    // Pay: the editor opens with the amount and the title as the note.
    await t.tap(find.byKey(const Key('pay-Charity')));
    await t.pumpAndSettle();
    expect(find.text('2,400'), findsOneWidget);
    expect(find.text('Charity'), findsWidgets, reason: 'note');
    await t.tap(find.byKey(const Key('account-Cash')));
    await t.tap(find.byKey(const Key('allCategories')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('sheetSearch')), 'Donations');
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byKey(const Key('category-Donations/Charity')),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('saveEntry')));
    await t.pumpAndSettle();

    final entry = (await t.runAsync(
      () => getIt<TransactionsRepository>().watch(const EntryQuery()).first,
    ))!.items.single.entry;
    expect(entry.amount, Money.major(2400, Currency.pkr));
    expect(entry.note, 'Charity');
    final paid = (await t.runAsync(() => repo().watchPaid().first))!.single;
    expect(paid.transactionId, entry.id, reason: 'linked to its entry');
    expect(await t.runAsync(() => repo().watchOpen().first), isEmpty);
    expect(find.byKey(const Key('homeToPay')), findsNothing, reason: 'paid');
  });

  testWidgets('already paid elsewhere: mark paid without an entry, undo', (
    t,
  ) async {
    await t.runAsync(
      () => repo().add(
        PlannedPaymentDraft(
          title: 'School fee',
          amount: Money.major(15000, Currency.pkr),
        ),
      ),
    );
    await start(t);
    unawaited(t.element(find.byType(GlassNavBar)).push(Routes.toPay));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('toPay-School fee')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('toPayMarkPaid')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('paid-School fee')), findsOneWidget);
    expect(
      (await t.runAsync(
        () => getIt<TransactionsRepository>().watch(const EntryQuery()).first,
      ))!.items,
      isEmpty,
      reason: 'no entry recorded',
    );

    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('toPay-School fee')), findsOneWidget);
  });

  testWidgets('deleting asks first', (t) async {
    await t.runAsync(
      () => repo().add(
        PlannedPaymentDraft(
          title: 'Gift',
          amount: Money.major(3000, Currency.pkr),
        ),
      ),
    );
    await start(t);
    unawaited(t.element(find.byType(GlassNavBar)).push(Routes.toPay));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('toPay-Gift')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('toPayDelete')));
    await t.pumpAndSettle();
    expect(find.text('Delete this?'), findsOneWidget);
    await t.tap(find.byKey(const Key('confirmAction')));
    await t.pumpAndSettle();
    expect(find.text('Nothing to pay'), findsOneWidget);
    expect(db, isNotNull);
  });
}

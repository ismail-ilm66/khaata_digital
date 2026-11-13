import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/dates/calendar_day.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/budgets/domain/budget.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';
import 'package:khaata_digital/features/settings/presentation/settings_screen.dart';
import 'package:khaata_digital/features/to_pay/domain/planned_payment.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';
import '../../helpers/ui.dart';

/// More shows what's worth knowing on each row; settings live one level
/// down (DECISIONS #143).
void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestApp();
  });

  Future<void> openMore(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('More'),
      ),
    );
    await t.pumpAndSettle();
  }

  Finder on(String tile, String text) =>
      find.descendant(of: find.byKey(Key(tile)), matching: find.text(text));

  testWidgets('rows show counts, budget used, overdue and the last backup', (
    t,
  ) async {
    await t.runAsync(() async {
      final ledger = TestLedger(db);
      final cash = (await db.accountsDao.balances()).single.account.id;
      await ledger.account('Meezan Bank');
      await ledger.expense(cash, 550000, at: DateTime.now().toUtc());
      final cycle = getIt<BudgetCycleCubit>().state;
      await getIt<BudgetsRepository>().set(
        cycle.idFor(DateTime.now()),
        Money.major(10000, Currency.pkr),
      );
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await getIt<ToPayRepository>().add(
        PlannedPaymentDraft(
          title: 'Electricity',
          amount: Money.major(4200, Currency.pkr),
          dueOn: CalendarDay.of(yesterday),
        ),
      );
    });
    await openMore(t);
    await waitFor(t, on('accountsTile', '2'));
    await waitFor(t, on('budgetsTile', '55% used'));
    await waitFor(t, on('toPayTile', '1 overdue'));
    expect(on('backupTile', 'No backup yet'), findsOneWidget);
    expect(find.byKey(const Key('hideBalanceTile')), findsNothing);
  });

  testWidgets('Settings holds money, privacy and appearance', (t) async {
    await openMore(t);
    await revealAndTap(t, find.byKey(const Key('settingsTile')));
    expect(find.byType(SettingsScreen), findsOneWidget);
    for (final key in [
      'currencyTile',
      'countryTile',
      'monthStartTile',
      'hideBalanceTile',
      'appLockTile',
      'themeSelector',
      'languageSelector',
      'hapticsTile',
    ]) {
      await reveal(t, find.byKey(Key(key)));
    }
  });

  testWidgets('Backup & data holds import and export', (t) async {
    await openMore(t);
    await revealAndTap(t, find.byKey(const Key('backupTile')));
    await reveal(t, find.byKey(const Key('importTile')));
    await reveal(t, find.byKey(const Key('exportTile')));
  });
}

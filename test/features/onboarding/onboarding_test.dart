import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/features/home/presentation/home_screen.dart';
import 'package:khaata_digital/features/onboarding/presentation/onboarding_screen.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  Future<void> start(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  Future<void> next(WidgetTester t) async {
    await t.tap(find.byKey(const Key('onboardingNext')));
    await t.pumpAndSettle();
  }

  testWidgets('first run: welcome → currency and payday → Home', (t) async {
    db = await setUpTestApp(welcome: true);
    await start(t);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Know where your money goes'), findsOneWidget);

    await next(t);
    await t.tap(find.byKey(const Key('onboardingCurrency')));
    await t.pumpAndSettle();
    await t.tap(find.text('AED'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('onboardingMonthStart')));
    await t.pumpAndSettle();
    // Scroll the sheet until the row exists, then fully into view.
    await t.scrollUntilVisible(
      find.text('Last working day'),
      200,
      scrollable: find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      ),
    );
    await t.ensureVisible(find.text('Last working day'));
    await t.pumpAndSettle();
    await t.tap(find.text('Last working day'));
    await t.pumpAndSettle();

    await next(t);
    expect(find.text('Coming from Hysab Kytab?'), findsOneWidget);
    await next(t); // "Start using Kharcha"
    expect(find.byType(HomeScreen), findsOneWidget);

    expect(getIt<CurrencyCubit>().state.code, 'AED');
    expect(getIt<BudgetCycleCubit>().state, const BudgetCycle.lastWorkingDay());
    final cash = (await t.runAsync(db.accountsDao.balances))!.single;
    expect(cash.account.currencyCode, 'AED', reason: 'untouched Cash follows');
    expect(
      await t.runAsync(() => db.settingsDao.read(SettingKey.onboardingDone)),
      'true',
    );

    // Never again.
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() => setUpTestApp(reuse: db));
    await start(t);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('Skip keeps the defaults and goes Home', (t) async {
    db = await setUpTestApp(welcome: true);
    await start(t);
    await t.tap(find.byKey(const Key('onboardingSkip')));
    await t.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(getIt<CurrencyCubit>().state, Currency.pkr);
  });

  testWidgets('people already using the app never see it', (t) async {
    final existing = testDb();
    await TestLedger(
      existing,
    ).expense((await existing.accountsDao.balances()).single.account.id, 500);
    db = await t.runAsync(() => setUpTestApp(reuse: existing)) as AppDatabase;
    await start(t);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

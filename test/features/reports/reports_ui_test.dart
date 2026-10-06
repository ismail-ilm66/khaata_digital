import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/dates/report_period.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/reports/domain/report.dart';
import 'package:khaata_digital/features/reports/presentation/reports_bloc.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:khaata_digital/features/transactions/presentation/entries_screen.dart';
import 'package:khaata_digital/features/transactions/presentation/widgets/entry_tile.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';
import '../../helpers/ui.dart';

void main() {
  late AppDatabase db;
  late String cash;
  late String food;

  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  setUp(() async {
    db = await setUpTestApp();
    final ledger = TestLedger(db);
    cash = (await db.accountsDao.balances()).single.account.id;
    food = (await db.categoriesDao.active())
        .firstWhere((c) => c.name == 'Food & Drink')
        .id;
    final now = DateTime.now();
    await ledger.income(cash, 5000000, at: now.toUtc());
    await ledger.expense(cash, 120000, categoryId: food, at: now.toUtc());
    await ledger.expense(
      cash,
      30000,
      at: now.subtract(const Duration(days: 400)).toUtc(),
    );
  });

  group('ReportsBloc', () {
    Future<ReportsBloc> started() async {
      final bloc = getIt<ReportsBloc>()
        ..add(ReportsStarted(DateTime(2026, 10, 6)));
      await pumpEventQueue();
      return bloc;
    }

    test('opens on this month and follows the month-start setting', () async {
      await getIt<BudgetCycleCubit>().set(const BudgetCycle(25));
      final bloc = await started();
      expect(bloc.state.query!.period.kind, PeriodKind.month);
      expect(
        bloc.state.query!.period.range(const BudgetCycle(25))!.start,
        DateTime(2026, 9, 25),
      );
      await bloc.close();
    });

    test('switching kind, stepping and filters each reload', () async {
      final bloc = await started();
      bloc.add(const PeriodKindChanged(PeriodKind.year));
      await pumpEventQueue();
      expect(
        bloc.state.query!.period,
        ReportPeriod.year(DateTime(2026, 10, 6)),
      );
      bloc.add(const PeriodStepped(-1));
      await pumpEventQueue();
      expect(
        bloc.state.query!.period.range(const BudgetCycle.calendar())!.start,
        DateTime(2025),
      );
      bloc.add(
        const ReportFiltersChanged(
          EntryQuery(types: {TransactionType.expense}),
        ),
      );
      await pumpEventQueue();
      expect(bloc.state.data!.income.isZero, isTrue);
      await bloc.close();
    });

    test('custom range', () async {
      final bloc = await started();
      bloc.add(CustomPeriodChosen(DateTime(2026, 7, 1), DateTime(2026, 7, 15)));
      await pumpEventQueue();
      expect(bloc.state.query!.period.kind, PeriodKind.custom);
      await bloc.close();
    });
  });

  group('Reports screen', () {
    Future<void> openReports(WidgetTester t) async {
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
    }

    testWidgets('shows this month and reconciles with the database', (t) async {
      await openReports(t);
      final cycle = getIt<BudgetCycleCubit>().state;
      final totals = (await t.runAsync(
        () => db.transactionsDao
            .totals(
              cycle.rangeFor(DateTime.now()).startMillis,
              cycle.rangeFor(DateTime.now()).endMillis,
            )
            .get(),
      ))!;
      final spent = totals
          .where((r) => r.type == TransactionType.expense)
          .fold(0, (s, r) => s + r.total);
      expect(
        spent,
        120000,
        reason: 'last year\'s Rs 300 is outside this month',
      );
      expect(find.text('Spending by category'), findsOneWidget);
      expect(find.byKey(const Key('slice-Food & Drink')), findsOneWidget);
    });

    testWidgets('All shows every period; tapping a category drills down', (
      t,
    ) async {
      await openReports(t);
      await t.tap(find.text('All'));
      await t.pumpAndSettle();
      expect(find.text('All time'), findsOneWidget);
      expect(
        find.byKey(const Key('previousPeriod')),
        findsNothing,
        reason: 'nothing to step',
      );

      await revealAndTap(t, find.byKey(const Key('slice-Food & Drink')));
      expect(find.byType(EntriesScreen), findsOneWidget);
      expect(find.byType(EntryTile), findsOneWidget);
    });

    testWidgets('Export offers this view or everything, Excel or CSV', (
      t,
    ) async {
      await openReports(t);
      await t.tap(find.byKey(const Key('exportButton')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('exportScope')), findsOneWidget);
      expect(find.text('This view'), findsOneWidget);
      expect(find.text('Excel'), findsOneWidget);
      expect(find.byKey(const Key('exportShare')), findsOneWidget);
      expect(find.byKey(const Key('exportSave')), findsOneWidget);
    });
  });

  test('report and export agree: totals equal the exported rows', () async {
    final data = await getIt<ReportsRepository>()
        .watch(
          ReportQuery(
            period: const ReportPeriod.all(),
            cycle: const BudgetCycle.calendar(),
            currency: Currency.pkr,
          ),
        )
        .first;
    expect(data.expense, Money(150000, Currency.pkr));
    expect(data.income, Money(5000000, Currency.pkr));
  });
}

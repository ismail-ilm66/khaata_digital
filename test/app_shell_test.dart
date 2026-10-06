import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/features/home/presentation/home_screen.dart';
import 'package:khaata_digital/features/reports/presentation/reports_screen.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:khaata_digital/features/settings/presentation/more_screen.dart';
import 'package:khaata_digital/features/transactions/presentation/add_transaction_sheet.dart';
import 'package:khaata_digital/features/transactions/presentation/transactions_screen.dart';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const KharchaApp());
    await tester.pumpAndSettle();
  }

  testWidgets('boots to Home with five bottom tabs', (tester) async {
    await pumpApp(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    for (final label in ['Home', 'Transactions', 'Add', 'Reports', 'More']) {
      expect(_navLabel(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('each tab navigates to its screen', (tester) async {
    await pumpApp(tester);

    await tester.tap(_navLabel('Transactions'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionsScreen), findsOneWidget);

    await tester.tap(_navLabel('Reports'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsScreen), findsOneWidget);

    await tester.tap(_navLabel('More'));
    await tester.pumpAndSettle();
    expect(find.byType(MoreScreen), findsOneWidget);

    await tester.tap(_navLabel('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Add tab opens the sheet without leaving the current tab', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(_navLabel('Reports'));
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Add'));
    await tester.pumpAndSettle();
    expect(find.byType(AddTransactionSheet), findsOneWidget);

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, 3, reason: 'Reports stays selected');
  });

  testWidgets('renders in dark and light themes', (tester) async {
    await pumpApp(tester);
    BuildContext ctx() => tester.element(find.byType(HomeScreen));

    getIt<ThemeCubit>().setMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(Theme.of(ctx()).brightness, Brightness.dark);

    getIt<ThemeCubit>().setMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(Theme.of(ctx()).brightness, Brightness.light);
  });

  testWidgets('theme selector on More switches theme', (tester) async {
    await pumpApp(tester);
    await tester.tap(_navLabel('More'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(getIt<ThemeCubit>().state, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(MoreScreen))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('switching to Urdu localizes the shell and goes RTL', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(_navLabel('More'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('اردو'));
    await tester.pumpAndSettle();

    expect(getIt<LocaleCubit>().state, LocaleCubit.urdu);
    expect(
      Directionality.of(tester.element(find.byType(MoreScreen))),
      TextDirection.rtl,
    );
    for (final label in ['ہوم', 'لین دین', 'شامل کریں', 'رپورٹس', 'مزید']) {
      expect(_navLabel(label), findsOneWidget, reason: label);
    }

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(MoreScreen))),
      TextDirection.ltr,
    );
    expect(_navLabel('Home'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/home/presentation/home_screen.dart';
import 'package:khaata_digital/features/reports/presentation/reports_screen.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:khaata_digital/features/settings/presentation/more_screen.dart';
import 'package:khaata_digital/features/transactions/presentation/form/entry_editor_screen.dart';
import 'package:khaata_digital/features/transactions/presentation/transactions_screen.dart';

import 'helpers/test_app.dart';

/// Scrolls [f] to mid-screen, clear of the floating nav bar, like a user.
Future<void> reveal(WidgetTester t, Finder f) async {
  await Scrollable.ensureVisible(t.element(f), alignment: 0.5);
  await t.pumpAndSettle();
}

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(GlassNavBar), matching: find.text(label));

void main() {
  setUp(setUpTestApp);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const KharchaApp());
    await tester.pumpAndSettle();
  }

  testWidgets('boots to Home with five bottom tabs', (tester) async {
    await pumpApp(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    for (final label in ['Home', 'Transactions', 'Reports', 'More']) {
      expect(_navLabel(label), findsOneWidget, reason: label);
    }
    expect(find.bySemanticsLabel('Add'), findsOneWidget);
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

  testWidgets('+ opens the editor; closing returns to the same tab', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(_navLabel('Reports'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Add'));
    await tester.pumpAndSettle();
    expect(find.byType(EntryEditorScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('closeEditor')));
    await tester.pumpAndSettle();
    final nav = tester.widget<GlassNavBar>(find.byType(GlassNavBar));
    expect(nav.selectedIndex, 2, reason: 'Reports stays selected');
  });

  testWidgets('renders in dark and light themes', (tester) async {
    await pumpApp(tester);
    BuildContext ctx() => tester.element(find.byType(HomeScreen));

    await getIt<ThemeCubit>().set(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(Theme.of(ctx()).brightness, Brightness.dark);

    await getIt<ThemeCubit>().set(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(Theme.of(ctx()).brightness, Brightness.light);
  });

  testWidgets('theme selector on More switches theme', (tester) async {
    await pumpApp(tester);
    await tester.tap(_navLabel('More'));
    await tester.pumpAndSettle();

    await reveal(tester, find.text('Dark'));
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

    await reveal(tester, find.text('اردو'));
    await tester.tap(find.text('اردو'));
    await tester.pumpAndSettle();

    expect(getIt<LocaleCubit>().state, LocaleCubit.urdu);
    expect(
      Directionality.of(tester.element(find.byType(MoreScreen))),
      TextDirection.rtl,
    );
    for (final label in ['ہوم', 'لین دین', 'رپورٹس', 'مزید']) {
      expect(_navLabel(label), findsOneWidget, reason: label);
    }
    expect(find.bySemanticsLabel('شامل کریں'), findsOneWidget);

    await reveal(tester, find.text('English'));
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(MoreScreen))),
      TextDirection.ltr,
    );
    expect(_navLabel('Home'), findsOneWidget);
  });

  testWidgets('theme and language survive a restart', (tester) async {
    await pumpApp(tester);
    await tester.tap(_navLabel('More'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Dark'));
    await tester.tap(find.text('Dark'));
    await reveal(tester, find.text('اردو'));
    await tester.tap(find.text('اردو'));
    await tester.pumpAndSettle();

    // Simulate a cold start against the same database.
    final db = getIt<AppDatabase>();
    await tester.runAsync(() => setUpTestApp(reuse: db));

    expect(getIt<ThemeCubit>().state, ThemeMode.dark);
    expect(getIt<LocaleCubit>().state, LocaleCubit.urdu);
  });
}

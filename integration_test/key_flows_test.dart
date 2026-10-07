// Crash-free run of the key flows on a real device (spec M7), against the
// real app: real database file, plugins and startup. Start from a fresh
// install so onboarding shows:
//
//   flutter test integration_test/key_flows_test.dart -d <device-id>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/import_export/data/import_service.dart';
import 'package:khaata_digital/features/security/presentation/lock_cubit.dart';
import 'package:khaata_digital/features/transactions/presentation/widgets/entry_tile.dart';
import 'package:khaata_digital/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester t, [int frames = 40]) async {
    for (var i = 0; i < frames; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> tab(WidgetTester t, String label) async {
    await t.tap(
      find
          .descendant(of: find.byType(GlassNavBar), matching: find.text(label))
          .first,
    );
    await settle(t);
  }

  testWidgets('first run → add, edit, delete → Urdu → lock → 10k import', (
    t,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      errors.add(d);
      previous?.call(d);
    };

    await app.main();
    await settle(t, 60);

    // Onboarding on a fresh install: skip it.
    final skip = find.byKey(const Key('onboardingSkip'));
    if (skip.evaluate().isNotEmpty) {
      await t.tap(skip);
      await settle(t);
    }

    // Add: + → type 500 → Food & Drink → Save.
    await t.tap(find.bySemanticsLabel('Add'));
    await settle(t);
    await t.enterText(find.byKey(const Key('amountField')), '500');
    await t.pump();
    await t.tap(find.byKey(const Key('account-Cash')));
    await t.pump();
    await t.tap(find.byKey(const Key('category-Food & Drink')));
    await settle(t);
    await t.tap(find.byKey(const Key('saveEntry')));
    await settle(t, 60);

    // Edit it from Transactions → detail → Edit → 5000 → Save.
    await tab(t, 'Transactions');
    expect(find.byType(EntryTile), findsOneWidget);
    await t.tap(find.byType(EntryTile));
    await settle(t);
    await t.tap(find.byKey(const Key('editEntry')));
    await settle(t);
    await t.enterText(find.byKey(const Key('amountField')), '5000');
    await t.pump();
    await t.tap(find.byKey(const Key('saveEntry')));
    await settle(t, 60);

    // Delete it, then undo.
    await t.tap(find.byKey(const Key('deleteEntry')));
    await settle(t, 60);
    if (find.text('Undo').evaluate().isNotEmpty) {
      await t.tap(find.text('Undo').first);
      await settle(t);
    }

    // Urdu, right to left, through every tab.
    await tab(t, 'More');
    await t.scrollUntilVisible(
      find.byKey(const Key('languageSelector')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(
      find.descendant(
        of: find.byKey(const Key('languageSelector')),
        matching: find.text('اردو'),
      ),
    );
    await settle(t, 60);
    for (final label in ['ہوم', 'لین دین', 'رپورٹس', 'مزید']) {
      final f = find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text(label),
      );
      if (f.evaluate().isNotEmpty) {
        await t.tap(f.first);
        await settle(t);
      }
    }

    // Lock: a PIN, then a cold-start lock.
    final lock = getIt<LockCubit>();
    await lock.setPin('2580');
    await lock.load();
    await settle(t);
    expect(find.byKey(const Key('lockScreen')), findsOneWidget);
    for (final d in [2, 5, 8, 0]) {
      await t.tap(find.byKey(Key('key-d$d')).last);
      await t.pump();
    }
    await settle(t, 60);
    expect(find.byKey(const Key('lockScreen')), findsNothing);
    await lock.disable();

    // Import 10,000 rows on the device, timed.
    final rows = <List<String>>[
      [
        'Voucher Type',
        'Voucher Date',
        'Voucher Amount',
        'Description',
        'Category Name',
        'Account Name',
      ],
      for (var i = 0; i < 10000; i++)
        [
          i.isEven ? 'Expense' : 'Income',
          '${(i % 28 + 1).toString().padLeft(2, '0')}/0${i % 9 + 1}/2025',
          i.isEven ? '-${100 + i}.0' : '${200 + i}.0',
          'Row $i',
          i.isEven ? 'Food & Drink' : 'Salary',
          'Cash',
        ],
    ];
    final importer = getIt<ImportService>();
    final watch = Stopwatch()..start();
    final draft = await importer.draftFile([
      (name: 'ACTIVITIES', rows: rows),
    ], currency: Currency.pkr);
    final report = await importer.run(draft);
    watch.stop();
    expect(report.imported, 10000);
    expect(watch.elapsed, lessThan(const Duration(minutes: 2)));
    // ignore: avoid_print
    print('10k rows imported on device in ${watch.elapsedMilliseconds} ms');

    FlutterError.onError = previous;
    expect(
      errors.map((e) => e.exceptionAsString()).toList(),
      isEmpty,
      reason: 'no framework errors anywhere in the run',
    );
  });
}

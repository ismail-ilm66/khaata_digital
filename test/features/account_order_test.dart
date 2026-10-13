import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/router/routes.dart';
import 'package:khaata_digital/core/widgets/app_switch.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';

import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

/// Accounts most-used first on Home and the Accounts screen, or in the
/// user's own order with a toggle.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestApp();
    final l = TestLedger(db);
    final cash = (await db.accountsDao.balances()).single.account.id;
    await l.account('Alfalah'); // never used
    final wallet = await l.account('Wallet');
    for (var i = 0; i < 3; i++) {
      await l.expense(wallet, 100);
    }
    await l.expense(cash, 100);
  });

  Future<void> start(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  /// Account names top to bottom (or start to end on Home).
  List<String> order(
    WidgetTester t,
    List<String> names, {
    bool across = false,
  }) {
    final at = {
      for (final n in names)
        n: across
            ? t.getTopLeft(find.text(n).first).dx
            : t.getTopLeft(find.text(n).first).dy,
    };
    return names.toList()..sort((a, b) => at[a]!.compareTo(at[b]!));
  }

  testWidgets('most used first by default, on Home and on Accounts', (t) async {
    expect(SettingKey.accountsByUse.defaultValue, 'true');
    await start(t);
    expect(order(t, ['Wallet', 'Cash'], across: true), [
      'Wallet',
      'Cash',
    ], reason: 'Home carousel');
    unawaited(t.element(find.byType(GlassNavBar)).push(Routes.accounts));
    await t.pumpAndSettle();
    expect(order(t, ['Cash', 'Alfalah', 'Wallet']), [
      'Wallet',
      'Cash',
      'Alfalah',
    ]);
    expect(find.byType(ReorderableDragStartListener), findsNothing);
  });

  testWidgets('the toggle switches to your own order, with drag handles', (
    t,
  ) async {
    await start(t);
    unawaited(t.element(find.byType(GlassNavBar)).push(Routes.accounts));
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byKey(const Key('accountsByUse')),
        matching: find.byType(AppSwitch),
      ),
    );
    await t.pumpAndSettle();
    expect(order(t, ['Cash', 'Alfalah', 'Wallet']), [
      'Cash',
      'Alfalah',
      'Wallet',
    ]);
    expect(find.byType(ReorderableDragStartListener), findsNWidgets(3));
    expect(
      await t.runAsync(() => db.settingsDao.read(SettingKey.accountsByUse)),
      'false',
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';

import '../../helpers/test_app.dart';
import '../../helpers/ui.dart';

void main() {
  late AppDatabase db;
  setUp(() async => db = await setUpTestApp());

  Future<void> tab(WidgetTester t, String label) async {
    await t.tap(
      find.descendant(of: find.byType(GlassNavBar), matching: find.text(label)),
    );
    await t.pumpAndSettle();
  }

  testWidgets('month can start on the last working day; Home follows it', (
    t,
  ) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();

    await tab(t, 'More');
    await revealAndTap(t, find.byKey(const Key('monthStartTile')));
    await revealAndTap(t, find.text('Last working day'));

    const payday = BudgetCycle.lastWorkingDay();
    expect(getIt<BudgetCycleCubit>().state, payday);
    expect(
      await t.runAsync(() => db.settingsDao.read(SettingKey.monthStartDay)),
      'last-working',
    );
    await reveal(t, find.byKey(const Key('monthStartTile')));
    expect(
      find.descendant(
        of: find.byKey(const Key('monthStartTile')),
        matching: find.text('Last working day'),
      ),
      findsOneWidget,
    );

    await tab(t, 'Home');
    final now = DateTime.now();
    expect(find.text(payday.label(payday.idFor(now))), findsOneWidget);
  });
}

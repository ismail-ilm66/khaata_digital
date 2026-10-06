import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/feedback/haptics.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';

import '../../helpers/test_app.dart';
import '../../helpers/ui.dart';

/// Records every haptic the app asks the platform for.
List<String> recordHaptics(WidgetTester t) {
  final calls = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

void main() {
  group('Haptics vocabulary', () {
    tearDown(() => Haptics.enabled = true);

    testWidgets('each level maps to one gentle platform effect', (t) async {
      final calls = recordHaptics(t);
      Haptics.selection();
      Haptics.tap();
      Haptics.warning();
      await t.runAsync(Haptics.success);
      expect(calls, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
      ]);
    });

    testWidgets('nothing at all when turned off', (t) async {
      final calls = recordHaptics(t);
      Haptics.enabled = false;
      Haptics.selection();
      Haptics.tap();
      Haptics.warning();
      await t.runAsync(Haptics.success);
      expect(calls, isEmpty);
    });
  });

  group('in the app', () {
    late AppDatabase db;
    setUp(() async => db = await setUpTestApp());
    tearDown(() => Haptics.enabled = true);

    Future<void> start(WidgetTester t) async {
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(const KharchaApp());
      await t.pumpAndSettle();
    }

    Finder tab(String label) => find.descendant(
      of: find.byType(GlassNavBar),
      matching: find.text(label),
    );

    testWidgets('tabs tick; the setting turns every haptic off', (t) async {
      await start(t);
      final calls = recordHaptics(t);
      await t.tap(tab('More'));
      await t.pumpAndSettle();
      expect(calls, ['HapticFeedbackType.selectionClick']);

      await revealAndTap(t, find.byKey(const Key('hapticsTile')));
      await t.tap(
        find.descendant(
          of: find.byKey(const Key('hapticsTile')),
          matching: find.byType(Switch),
        ),
      );
      await t.pumpAndSettle();
      expect(
        await t.runAsync(() => db.settingsDao.read(SettingKey.haptics)),
        'false',
      );
      calls.clear();
      await t.tap(tab('Home'));
      await t.pumpAndSettle();
      expect(calls, isEmpty, reason: 'haptics are off');
    });

    testWidgets('saving an entry gives the success double tick', (t) async {
      await start(t);
      final calls = recordHaptics(t);
      await t.tap(find.bySemanticsLabel('Add'));
      await t.pumpAndSettle();
      for (final d in [5, 0, 0]) {
        await t.tap(find.byKey(Key('key-d$d')));
      }
      await t.tap(find.byKey(const Key('category-Food & Drink')));
      await t.pumpAndSettle();
      calls.clear();
      await t.tap(find.byKey(const Key('saveEntry')));
      await waitFor(t, find.text('Saved'));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      expect(calls, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
      ]);
    });
  });
}

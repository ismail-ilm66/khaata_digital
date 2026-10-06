import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/theme/app_theme.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/core/widgets/glass_surface.dart';
import 'package:khaata_digital/core/widgets/segmented_picker.dart';
import 'package:khaata_digital/core/widgets/app_icons.dart';

Future<void> _pump(WidgetTester tester, Widget child, {ThemeData? theme}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('SegmentedPicker', () {
    testWidgets('reports taps on other options only', (tester) async {
      final picked = <String>[];
      await _pump(
        tester,
        SegmentedPicker<String>(
          value: 'a',
          onChanged: picked.add,
          options: const [
            PickerOption('a', 'Alpha'),
            PickerOption('b', 'Beta'),
          ],
        ),
      );
      await tester.tap(find.text('Alpha'));
      await tester.tap(find.text('Beta'));
      expect(picked, ['b']);
    });

    testWidgets('marks the selected option for accessibility', (tester) async {
      await _pump(
        tester,
        SegmentedPicker<int>(
          value: 2,
          onChanged: (_) {},
          options: const [PickerOption(1, 'One'), PickerOption(2, 'Two')],
        ),
      );
      expect(
        tester.getSemantics(find.text('Two')),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          label: 'Two',
        ),
      );
    });
  });

  group('GlassNavBar', () {
    Widget bar({required int selected, required List<String> log}) =>
        GlassNavBar(
          selectedIndex: selected,
          onSelected: (i) => log.add('tab$i'),
          actionLabel: 'Add',
          onAction: () => log.add('action'),
          items: [
            for (final l in ['A', 'B', 'C', 'D'])
              GlassNavItem(
                icon: const AppIcon(Icons.circle_outlined, Icons.circle),
                label: l,
              ),
          ],
        );

    testWidgets('is frosted glass', (tester) async {
      await _pump(tester, bar(selected: 0, log: []));
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('places the action in the middle and routes taps', (
      tester,
    ) async {
      final log = <String>[];
      await _pump(tester, bar(selected: 0, log: log));

      final bx = tester.getCenter(find.text('B')).dx;
      final cx = tester.getCenter(find.text('C')).dx;
      final actionX = tester.getCenter(find.bySemanticsLabel('Add')).dx;
      expect(actionX, inExclusiveRange(bx, cx));

      await tester.tap(find.text('C'));
      await tester.tap(find.bySemanticsLabel('Add'));
      expect(log, ['tab2', 'action']);
    });

    testWidgets('shows the filled icon only on the selected tab', (
      tester,
    ) async {
      await _pump(tester, bar(selected: 1, log: []));
      expect(find.byIcon(Icons.circle), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsNWidgets(3));
    });

    testWidgets('renders in dark mode', (tester) async {
      await _pump(tester, bar(selected: 0, log: []), theme: AppTheme.dark);
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/theme/app_theme.dart';
import 'package:khaata_digital/core/widgets/amount_field.dart';

void main() {
  late TextEditingController controller;
  setUp(() => controller = TextEditingController());

  Future<void> pump(WidgetTester t, {bool allowNegative = true}) =>
      t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AmountField(
              controller: controller,
              currency: Currency.pkr,
              label: 'Opening balance',
              invalidMessage: 'Invalid',
              allowNegative: allowNegative,
            ),
          ),
        ),
      );

  TextInputType keyboard(WidgetTester t) =>
      t.widget<EditableText>(find.byType(EditableText)).keyboardType;

  testWidgets(
    'always opens the numeric keypad, even when negatives are allowed',
    (t) async {
      await pump(t);
      // Unsigned on purpose: a signed keypad is the full keyboard on iOS.
      expect(keyboard(t), const TextInputType.numberWithOptions(decimal: true));
    },
  );

  testWidgets('± toggles the sign', (t) async {
    await pump(t);
    await t.enterText(find.byType(TextFormField), '2500');
    await t.tap(find.byKey(const Key('amountSign')));
    await t.pump();
    expect(controller.text, '-2500');
    expect(
      AmountField.read(controller, Currency.pkr),
      Money.major(-2500, Currency.pkr),
    );

    await t.tap(find.byKey(const Key('amountSign')));
    await t.pump();
    expect(controller.text, '2500');
  });

  testWidgets('letters and stray minus signs are rejected', (t) async {
    await pump(t);
    await t.enterText(find.byType(TextFormField), '12a3');
    expect(controller.text, '123');
    await t.enterText(find.byType(TextFormField), '12-3');
    expect(controller.text, '123', reason: 'minus only leads');
  });

  testWidgets('no sign toggle and no minus when negatives are not allowed', (
    t,
  ) async {
    await pump(t, allowNegative: false);
    expect(find.byKey(const Key('amountSign')), findsNothing);
    await t.enterText(find.byType(TextFormField), '-5');
    expect(controller.text, isEmpty);
  });
}

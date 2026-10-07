import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/widgets/hero_amount_field.dart';

import '../../helpers/ui.dart';

void main() {
  final f = GroupedAmountFormatter(Currency.pkr);

  TextEditingValue type(String old, String next, [int? caret]) =>
      f.formatEditUpdate(
        TextEditingValue(text: old),
        TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: caret ?? next.length),
        ),
      );

  test('groups while typing, caret at the end', () {
    final v = type('1,250', '1,2500');
    expect(v.text, '12,500');
    expect(v.selection.baseOffset, 6);
    expect(type('12,500', '12,500.').text, '12,500.');
  });

  test('rejects what is not an amount, keeping the old text', () {
    expect(type('12', '12a').text, '12');
    expect(type('1.25', '1.255').text, '1.25');
    expect(type('1.2', '1.2.').text, '1.2');
  });

  test('the caret stays next to the digit it followed', () {
    // A 9 typed after the "2" of "12,500".
    final v = type('12,500', '129,500', 3);
    expect(v.text, '129,500');
    expect(v.text.substring(0, v.selection.baseOffset), '129');
  });

  testWidgets('the field opens the number pad and reports plain text', (
    t,
  ) async {
    String? typed;
    await t.pumpWidget(
      testApp(
        HeroAmountField(
          fieldKey: const Key('amount'),
          value: '',
          currency: Currency.pkr,
          onChanged: (v) => typed = v,
        ),
      ),
    );
    final field = t.widget<EditableText>(find.byType(EditableText));
    expect(
      field.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    await t.enterText(find.byKey(const Key('amount')), '25000');
    expect(typed, '25000');
    expect(find.text('25,000'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/theme/app_colors.dart';
import 'package:khaata_digital/core/theme/app_theme.dart';
import 'package:khaata_digital/core/widgets/amount_text.dart';

Future<TextSpan> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection dir = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: dir,
        child: Center(child: child),
      ),
    ),
  );
  return tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
}

List<TextSpan> _spans(TextSpan span) => span.children!.cast<TextSpan>();

void main() {
  testWidgets('renders symbol and number as separate spans', (tester) async {
    final rt = await _pump(tester, AmountText(Money.major(2520, Currency.pkr)));
    expect(rt.toPlainText(), 'Rs 2,520');
    final spans = _spans(rt);
    expect(spans.first.style!.fontSize, lessThan(spans.last.style!.fontSize!));
  });

  testWidgets('uses tabular figures', (tester) async {
    final rt = await _pump(tester, const AmountText(Money(100, Currency.pkr)));
    expect(
      _spans(rt).last.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('colored: income green, expenses stay ink', (tester) async {
    var rt = await _pump(
      tester,
      const AmountText(Money(100, Currency.pkr), colored: true, signed: true),
    );
    expect(rt.toPlainText(), startsWith('+'));
    expect(_spans(rt).last.style!.color, AppColors.light.income);

    rt = await _pump(
      tester,
      const AmountText(Money(-100, Currency.pkr), colored: true),
    );
    expect(_spans(rt).last.style!.color, AppColors.light.ink);
  });

  testWidgets('masked hides digits and sign', (tester) async {
    final rt = await _pump(
      tester,
      const AmountText(Money(-999999, Currency.pkr), masked: true),
    );
    expect(rt.toPlainText(), 'Rs ${AmountText.maskedDigits}');
  });

  testWidgets('stays left-to-right inside RTL layouts', (tester) async {
    await _pump(
      tester,
      const AmountText(Money(-100, Currency.pkr)),
      dir: TextDirection.rtl,
    );
    expect(
      tester.widget<Text>(find.byType(Text)).textDirection,
      TextDirection.ltr,
    );
  });
}

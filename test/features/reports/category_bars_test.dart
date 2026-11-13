import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/date_range.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/categories/domain/category.dart';
import 'package:khaata_digital/features/categories/domain/category_kind.dart';
import 'package:khaata_digital/features/reports/domain/report.dart';
import 'package:khaata_digital/features/reports/presentation/report_charts.dart';

import '../../helpers/ui.dart';

void main() {
  Money pkr(int major) => Money.major(major, Currency.pkr);
  Category cat(String id) =>
      Category(id: id, name: id, kind: CategoryKind.expense);

  Future<void> pump(
    WidgetTester t,
    List<CategorySlice> slices,
    List<Category?> tapped,
  ) => t.pumpWidget(
    testApp(
      SingleChildScrollView(
        child: CategoryBars(
          slices: slices,
          total: slices.fold(pkr(0), (a, s) => a + s.total),
          noCategoryLabel: 'No category',
          onCategoryTap: tapped.add,
        ),
      ),
    ),
  );

  testWidgets('largest first, with share; a row opens its category', (t) async {
    final tapped = <Category?>[];
    await pump(t, [
      CategorySlice(cat('Food'), pkr(600)),
      CategorySlice(cat('Fuel'), pkr(300)),
      CategorySlice(null, pkr(100)),
    ], tapped);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(
      t.getTopLeft(find.byKey(const Key('slice-Food'))).dy,
      lessThan(t.getTopLeft(find.byKey(const Key('slice-Fuel'))).dy),
    );
    await t.tap(find.byKey(const Key('slice-Fuel')));
    expect(tapped.single!.id, 'Fuel');
    expect(find.byKey(const Key('slice-No category')), findsOneWidget);
  });

  testWidgets('past five, the rest fold into "N more" until opened', (t) async {
    await pump(t, [
      for (final (i, n) in ['A', 'B', 'C', 'D', 'E', 'F', 'G'].indexed)
        CategorySlice(cat(n), pkr(700 - i * 100)),
    ], []);
    expect(find.byKey(const Key('slice-E')), findsOneWidget);
    expect(find.byKey(const Key('slice-F')), findsNothing);
    expect(find.text('2 more'), findsOneWidget);

    await t.tap(find.byKey(const Key('moreCategories')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('slice-G')), findsOneWidget);
    expect(find.byKey(const Key('moreCategories')), findsNothing);
  });

  test('the bar average is in whole rupees', () {
    final day = DateRange(DateTime(2026, 11, 1), DateTime(2026, 11, 2));
    final points = [
      FlowPoint(day, pkr(0), Money(100000, Currency.pkr)),
      FlowPoint(day, pkr(0), Money(25050, Currency.pkr)),
      FlowPoint(day, pkr(0), Money(0, Currency.pkr)),
    ];
    // 1,250.50 over 3 days = 416.83… → Rs 417.
    expect(
      PeriodBars.average(points, income: false, currency: Currency.pkr),
      pkr(417),
    );
  });
}

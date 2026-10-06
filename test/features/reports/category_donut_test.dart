import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Future<void> pumpDonut(WidgetTester t, List<Category?> tapped) =>
      t.pumpWidget(
        testApp(
          SingleChildScrollView(
            child: CategoryDonut(
              slices: [
                CategorySlice(cat('Food'), pkr(600)),
                CategorySlice(cat('Fuel'), pkr(300)),
                CategorySlice(null, pkr(100)),
              ],
              total: pkr(1000),
              otherLabel: 'Other',
              noCategoryLabel: 'No category',
              onCategoryTap: tapped.add,
            ),
          ),
        ),
      );

  testWidgets('tapping or dragging over the hole in the middle is ignored', (
    t,
  ) async {
    final tapped = <Category?>[];
    await pumpDonut(t, tapped);
    await t.pumpAndSettle();
    final top = t.getTopLeft(find.byType(CategoryDonut));
    final centre = Offset(
      t.getCenter(find.byType(CategoryDonut)).dx,
      top.dy + 100,
    );
    // Touches that miss every slice: inside the hole (above the total
    // text) and in the empty corner beside the ring.
    for (final miss in [
      centre - const Offset(0, 45),
      top + const Offset(8, 8),
    ]) {
      final g = await t.startGesture(miss);
      await t.pump();
      await g.moveBy(const Offset(2, 2));
      await t.pump();
      await g.up();
      await t.pumpAndSettle();
    }

    expect(t.takeException(), isNull);
    expect(tapped, isEmpty, reason: 'the hole is not a category');
  });
}

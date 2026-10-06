import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/features/transactions/presentation/widgets/receipts.dart';

import '../../helpers/test_receipts.dart';
import '../../helpers/ui.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget child) =>
      t.pumpWidget(testApp(child));

  testWidgets('thumbnails open the full-screen viewer', (t) async {
    final path = fakeImage('r.jpg');
    await pump(t, ReceiptStrip(receipts: [ReceiptRef.picked(path)]));
    expect(find.byType(ReceiptImage), findsOneWidget);

    await t.tap(find.byType(ReceiptImage));
    await t.pumpAndSettle();
    expect(find.byType(ReceiptViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('editable strip offers add and remove', (t) async {
    final removed = <ReceiptRef>[];
    final r = ReceiptRef.picked(fakeImage('r.jpg'));
    await pump(
      t,
      ReceiptStrip(receipts: [r], onAdd: (_) {}, onRemove: removed.add),
    );
    expect(find.text('Add receipt'), findsOneWidget);
    await t.tap(find.byType(CircleAvatar));
    expect(removed, [r]);
  });
}

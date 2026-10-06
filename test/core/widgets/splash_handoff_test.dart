import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/widgets/splash_handoff.dart';

import '../../helpers/ui.dart';

void main() {
  Finder mark() => find.byWidgetPredicate(
    (w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == 'assets/splash/mark.png',
  );

  testWidgets('covers the first frame, then dissolves away', (t) async {
    var taps = 0;
    await t.pumpWidget(
      testApp(
        SplashHandoff(
          child: Center(
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Home'),
            ),
          ),
        ),
      ),
    );
    expect(mark(), findsOneWidget, reason: 'same mark as the native splash');

    // Taps go through even while it fades.
    await t.tap(find.text('Home'), warnIfMissed: false);
    expect(taps, 1);

    await t.pump(const Duration(milliseconds: 300));
    expect(mark(), findsOneWidget, reason: 'still dissolving');
    await t.pumpAndSettle();
    expect(mark(), findsNothing, reason: 'gone; the app is all that is left');
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('reduced motion: a quick fade', (t) async {
    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: testApp(const SplashHandoff(child: Text('Home'))),
      ),
    );
    await t.pump(const Duration(milliseconds: 200));
    await t.pump();
    expect(mark(), findsNothing);
  });
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/router/routes.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';

import '../../helpers/test_app.dart';
import '../../helpers/ui.dart';

void main() {
  test('the published policy keeps its promises', () {
    final policy = File('docs/privacy-policy.md').readAsStringSync();
    for (final promise in [
      'no ads, no analytics and no tracking',
      "You don't need an account",
      'only for Google Drive backup',
      'only for access to the files it creates',
    ]) {
      expect(policy, contains(promise));
    }
  });

  testWidgets('About → Privacy policy shows the bundled policy', (t) async {
    await setUpTestApp();
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
    unawaited(t.element(find.byType(GlassNavBar)).push(Routes.about));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('privacyTile')));
    await waitFor(t, find.text('The short version'));
    expect(
      find.textContaining('no ads, no analytics', findRichText: true),
      findsOneWidget,
    );
  });
}

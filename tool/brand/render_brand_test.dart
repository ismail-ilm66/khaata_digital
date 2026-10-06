// Renders the splash / brand images into assets/splash/. Dev tool, run by
// hand after changing the mark:
//
//   flutter test tool/brand/render_brand_test.dart
//
// Drawn with Flutter itself (Manrope, the app's font) so the splash and the
// app share one source of truth.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/theme/app_colors.dart';

Future<void> _font() async {
  final loader = FontLoader('Manrope')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/Manrope-Variable.ttf').readAsBytesSync(),
        ),
      ),
    );
  await loader.load();
}

/// The mark: a softly lit brand-green rounded square with a white "K".
void paintMark(Canvas canvas, Offset origin, double side) {
  final rect = origin & Size.square(side);
  final tile = RRect.fromRectAndRadius(rect, Radius.circular(side * 0.28));
  canvas.drawRRect(
    tile,
    Paint()
      ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, const [
        Color(0xFF16A363),
        AppColors.brandGreen,
      ]),
  );
  final k = TextPainter(
    text: TextSpan(
      text: 'K',
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: side * 0.62,
        fontVariations: const [FontVariation('wght', 800)],
        color: Colors.white,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  // Optical centring: cap height sits a touch above the box centre.
  k.paint(
    canvas,
    rect.center -
        Offset(k.width / 2 - side * 0.01, k.height / 2 + side * 0.005),
  );
}

Future<void> _save(
  String name,
  int w,
  int h,
  void Function(Canvas) draw,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(w, h);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('assets/splash/$name').writeAsBytesSync(png!.buffer.asUint8List());
}

void _wordmark(Canvas canvas, Color color, Size size) {
  final p = TextPainter(
    text: TextSpan(
      text: 'Kharcha',
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: size.height * 0.62,
        fontVariations: const [FontVariation('wght', 700)],
        letterSpacing: -size.height * 0.012,
        color: color,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  p.paint(
    canvas,
    Offset((size.width - p.width) / 2, (size.height - p.height) / 2),
  );
}

void main() {
  test('render brand assets', () async {
    await _font();
    // All images are @4x: 560 px = 140 pt/dp on screen.
    await _save('mark.png', 560, 560, (c) => paintMark(c, Offset.zero, 560));
    // Android 12 splash icon: 288 dp canvas whose inner 192 dp circle is
    // visible; the 140 dp tile's rounded corners stay inside it.
    await _save(
      'mark_android12.png',
      1152,
      1152,
      (c) => paintMark(c, const Offset(296, 296), 560),
    );
    const word = Size(800, 200);
    await _save(
      'wordmark.png',
      800,
      200,
      (c) => _wordmark(c, AppColors.light.inkMuted, word),
    );
    await _save(
      'wordmark_dark.png',
      800,
      200,
      (c) => _wordmark(c, AppColors.dark.inkMuted, word),
    );
  });
}

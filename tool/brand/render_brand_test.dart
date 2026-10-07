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

/// The mark: a brand-green tile with a white monoline "K" whose open
/// arms hold a gold coin — the letter and money in one simple shape that
/// stays clear down to 24 px.
void paintMark(Canvas canvas, Offset origin, double side) {
  final rect = origin & Size.square(side);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(side * 0.27)),
    _ground(rect),
  );
  paintGlyph(canvas, origin, side);
}

Paint _ground(Rect rect) => Paint()
  ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, const [
    Color(0xFF16A363),
    Color(0xFF0B6B40),
  ]);

/// The K and coin, laid out for a tile of [side] at [origin]. [mono] draws
/// everything white (Android themed icons tint it).
void paintGlyph(
  Canvas canvas,
  Offset origin,
  double side, {
  bool mono = false,
}) {
  // Glyph spans 0.265–0.805 of the tile; shifted to sit optically centred.
  const dx = -0.03;
  Offset at(double x, double y) => origin + Offset(side * (x + dx), side * y);
  final ink = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = side * 0.13
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas
    ..drawLine(at(.33, .27), at(.33, .73), ink)
    ..drawPath(
      Path()
        ..moveTo(at(.655, .27).dx, at(.655, .27).dy)
        ..lineTo(at(.44, .50).dx, at(.44, .50).dy)
        ..lineTo(at(.655, .73).dx, at(.655, .73).dy),
      ink,
    )
    ..drawCircle(
      at(.725, .50),
      side * 0.08,
      Paint()..color = mono ? Colors.white : const Color(0xFFF2C14E),
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
    // App icons. iOS: full-bleed square (the system rounds it). Android
    // adaptive: the K and coin sit in the central 66 % safe zone over a
    // gradient background layer.
    await _save('icon_ios.png', 1024, 1024, (c) {
      const r = Rect.fromLTWH(0, 0, 1024, 1024);
      c.drawRect(r, _ground(r));
      paintGlyph(c, const Offset(112, 112), 800);
    });
    await _save('icon_android_bg.png', 1024, 1024, (c) {
      const r = Rect.fromLTWH(0, 0, 1024, 1024);
      c.drawRect(r, _ground(r));
    });
    await _save(
      'icon_android_fg.png',
      1024,
      1024,
      (c) => paintGlyph(c, const Offset(232, 232), 560),
    );
    await _save(
      'icon_android_mono.png',
      1024,
      1024,
      (c) => paintGlyph(c, const Offset(232, 232), 560, mono: true),
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

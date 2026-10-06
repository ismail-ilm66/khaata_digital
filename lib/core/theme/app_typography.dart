import 'package:flutter/material.dart';

/// Type scale for Kharcha, set in Manrope (bundled variable font).
abstract final class AppTypography {
  static const String family = 'Manrope';

  /// Variable fonts need the `wght` axis set explicitly; [FontWeight] alone
  /// is not mapped onto the axis on every renderer.
  static TextStyle weighted(double size, FontWeight weight, {double? height}) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
    );
  }

  /// Figures with equal advance widths, so amounts align in columns.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color ink, Color inkMuted) {
    TextStyle s(double size, FontWeight w, Color c, {double? h}) =>
        weighted(size, w, height: h).copyWith(color: c);
    // Large display/headline sizes are tracked tighter so titles feel set,
    // not typed.
    TextStyle tight(TextStyle t, double tracking) =>
        t.copyWith(letterSpacing: tracking);
    return TextTheme(
      displayLarge: tight(s(44, FontWeight.w800, ink, h: 1.05), -1.2),
      displayMedium: tight(s(36, FontWeight.w800, ink, h: 1.1), -0.9),
      displaySmall: tight(s(30, FontWeight.w800, ink, h: 1.15), -0.6),
      headlineLarge: tight(s(32, FontWeight.w800, ink, h: 1.15), -0.8),
      headlineMedium: tight(s(24, FontWeight.w700, ink, h: 1.25), -0.4),
      headlineSmall: s(20, FontWeight.w700, ink, h: 1.3),
      titleLarge: s(20, FontWeight.w700, ink, h: 1.3),
      titleMedium: s(16, FontWeight.w600, ink, h: 1.4),
      titleSmall: s(14, FontWeight.w600, ink, h: 1.4),
      bodyLarge: s(16, FontWeight.w500, ink, h: 1.5),
      bodyMedium: s(14, FontWeight.w500, ink, h: 1.5),
      bodySmall: s(13, FontWeight.w500, inkMuted, h: 1.45),
      labelLarge: s(14, FontWeight.w600, ink, h: 1.3),
      labelMedium: s(12, FontWeight.w600, ink, h: 1.3),
      labelSmall: s(11, FontWeight.w600, inkMuted, h: 1.3),
    );
  }
}

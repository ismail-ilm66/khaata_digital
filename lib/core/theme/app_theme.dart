import 'package:flutter/material.dart';

/// Kharcha brand palette and Material 3 themes.
abstract final class AppTheme {
  /// Deep "Pakistani" green from the icon direction in spec Phase 2.2.
  static const Color brandGreen = Color(0xFF0E7C4A);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandGreen,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
    );
  }
}

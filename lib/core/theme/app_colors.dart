import 'package:flutter/material.dart';

/// Semantic colours that Material's [ColorScheme] has no slot for.
///
/// Colour carries meaning only: income is [income], expenses stay neutral
/// ink, and [warning]/[danger] are reserved for budget thresholds.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.brand,
    required this.income,
    required this.warning,
    required this.danger,
    required this.glass,
    required this.glassEdge,
    required this.glow,
    required this.shadow,
  });

  static const brandGreen = Color(0xFF0E7C4A);

  static const light = AppColors(
    paper: Color(0xFFF4F6F5),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEBEFED),
    ink: Color(0xFF15201B),
    inkMuted: Color(0xFF5C6963),
    line: Color(0xFFDDE3E0),
    brand: brandGreen,
    income: brandGreen,
    warning: Color(0xFFA86A0B),
    danger: Color(0xFFB83227),
    glass: Color(0xB8FFFFFF),
    glassEdge: Color(0x99FFFFFF),
    glow: Color(0x2E0E7C4A),
    shadow: Color(0x1A0B2A1C),
  );

  static const dark = AppColors(
    paper: Color(0xFF0E1412),
    surface: Color(0xFF161E1B),
    surfaceMuted: Color(0xFF1E2824),
    ink: Color(0xFFE6ECE9),
    inkMuted: Color(0xFF93A29B),
    line: Color(0xFF2A3530),
    brand: Color(0xFF3DBE7E),
    income: Color(0xFF3DBE7E),
    warning: Color(0xFFE0A53A),
    danger: Color(0xFFF0705F),
    glass: Color(0x9E1A2420),
    glassEdge: Color(0x1FFFFFFF),
    glow: Color(0x333DBE7E),
    shadow: Color(0x66000000),
  );

  /// Page background.
  final Color paper;

  /// Cards, sheets, navigation bar.
  final Color surface;

  /// Inputs and pressed/selected fills.
  final Color surfaceMuted;

  /// Primary text, including expense amounts.
  final Color ink;

  /// Secondary text, currency symbols, captions.
  final Color inkMuted;

  /// Hairline dividers and outlines.
  final Color line;

  final Color brand;
  final Color income;
  final Color warning;
  final Color danger;

  /// Translucent fill for frosted-glass surfaces (nav bar, floating bars).
  final Color glass;

  /// The thin light edge that makes glass read as glass.
  final Color glassEdge;

  /// Ambient brand glow behind content, so glass has something to blur.
  final Color glow;

  /// Soft shadow under floating surfaces.
  final Color shadow;

  @override
  AppColors copyWith({
    Color? paper,
    Color? surface,
    Color? surfaceMuted,
    Color? ink,
    Color? inkMuted,
    Color? line,
    Color? brand,
    Color? income,
    Color? warning,
    Color? danger,
    Color? glass,
    Color? glassEdge,
    Color? glow,
    Color? shadow,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      line: line ?? this.line,
      brand: brand ?? this.brand,
      income: income ?? this.income,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      glass: glass ?? this.glass,
      glassEdge: glassEdge ?? this.glassEdge,
      glow: glow ?? this.glow,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      paper: mix(paper, other.paper),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      line: mix(line, other.line),
      brand: mix(brand, other.brand),
      income: mix(income, other.income),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      glass: mix(glass, other.glass),
      glassEdge: mix(glassEdge, other.glassEdge),
      glow: mix(glow, other.glow),
      shadow: mix(shadow, other.shadow),
    );
  }
}

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Light and dark themes composed from [AppColors], [AppTypography] and the
/// spacing/radius tokens. Flat by design: no elevation, no surface tint.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppColors.light);
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brandGreen,
          brightness: brightness,
        ).copyWith(
          primary: c.brand,
          onPrimary: brightness == Brightness.light ? Colors.white : c.paper,
          surface: c.paper,
          onSurface: c.ink,
          onSurfaceVariant: c.inkMuted,
          surfaceContainerLowest: c.surface,
          surfaceContainerLow: c.surface,
          surfaceContainer: c.surface,
          surfaceContainerHigh: c.surfaceMuted,
          surfaceContainerHighest: c.surfaceMuted,
          outline: c.inkMuted,
          outlineVariant: c.line,
          error: c.danger,
          surfaceTint: Colors.transparent,
        );
    final text = AppTypography.textTheme(c.ink, c.inkMuted);
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.m),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.family,
      textTheme: text,
      scaffoldBackgroundColor: c.paper,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.paper,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: rounded,
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
        iconColor: c.inkMuted,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.s),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: rounded,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: c.brand.withValues(alpha: 0.12),
          selectedForegroundColor: c.ink,
          foregroundColor: c.inkMuted,
          side: BorderSide(color: c.line),
          textStyle: text.labelLarge,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.l)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: text.bodyMedium!.copyWith(color: c.paper),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.s),
        ),
      ),
    );
  }
}

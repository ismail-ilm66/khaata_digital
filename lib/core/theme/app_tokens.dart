/// Spacing scale. Use these instead of literal paddings and gaps.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page gutter shared by every screen.
  static const double page = l;
}

/// Corner radii by hierarchy: the larger the surface, the larger the radius.
abstract final class AppRadii {
  /// Inputs, chips, small badges.
  static const double s = 10;

  /// Cards, buttons, list groups.
  static const double m = 16;

  /// Bottom sheets and dialogs.
  static const double l = 24;
}

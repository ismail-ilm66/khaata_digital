import 'package:flutter/widgets.dart';

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

/// Motion scale. Every UI animation takes its duration and curve from here,
/// so the app moves in one rhythm and honours the system's reduce-motion
/// setting in one place ([of]).
abstract final class AppMotion {
  /// Press feedback, small state changes (a chip turning on).
  static const fast = Duration(milliseconds: 150);

  /// The default: pickers, folds, cross-fades.
  static const base = Duration(milliseconds: 220);

  /// Larger surfaces: progress bars filling, page-level reveals.
  static const slow = Duration(milliseconds: 300);

  /// Strong ease-out: starts at once, settles softly. For anything entering
  /// or responding to a touch.
  static const Curve out = Cubic(0.23, 1, 0.32, 1);

  /// Strong ease-in-out: for things already on screen moving to a new spot.
  static const Curve inOut = Cubic(0.77, 0, 0.175, 1);

  /// [d], or zero when the user asked the system to reduce motion.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

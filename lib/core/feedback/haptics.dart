import 'package:flutter/services.dart';

/// The app's haptic vocabulary: few, gentle and consistent, so a touch
/// means the same thing everywhere. Turned off in settings via [enabled].
abstract final class Haptics {
  /// Mirrors the "Haptics" setting (on by default).
  static bool enabled = true;

  /// Moving between options: tabs, segments, pickers, switches, keys.
  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Committing a primary action: the add button, confirm.
  static void tap() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Something finished well: saved, backed up, imported, restored. A soft
  /// double tick, distinct from a tap without being any stronger.
  static Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (enabled) await HapticFeedback.lightImpact();
  }

  /// Something needs care: a deletion (with undo), a failure.
  static void warning() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}

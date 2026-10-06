import 'package:flutter/material.dart';

/// Chart colours, validated with the dataviz palette checker against
/// Kharcha's surfaces (#FFFFFF light, #161E1B dark): lightness band,
/// chroma floor, colour-blind separation (worst adjacent ΔE 9.1 light /
/// 8.4 dark) and normal-vision floor all pass. In light mode three slots
/// are under 3:1 contrast, so every chart pairs colour with a labelled
/// legend — colour is never the only cue.
///
/// Category badges keep their own muted tints; charts need the stronger
/// separation, so they use these slots instead.
abstract final class ChartPalette {
  static const List<Color> _light = [
    Color(0xFF2A78D6), // blue
    Color(0xFFEB6834), // orange
    Color(0xFF1BAF7A), // aqua
    Color(0xFFEDA100), // yellow
    Color(0xFFE87BA4), // magenta
    Color(0xFF008300), // green
    Color(0xFF4A3AA7), // violet
    Color(0xFFE34948), // red
  ];

  static const List<Color> _dark = [
    Color(0xFF3987E5),
    Color(0xFFD95926),
    Color(0xFF199E70),
    Color(0xFFC98500),
    Color(0xFFD55181),
    Color(0xFF008300),
    Color(0xFF9085E9),
    Color(0xFFE66767),
  ];

  static int get length => _light.length;

  static List<Color> of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// "Other" (folded small slices) — neutral, never a ninth hue.
  static Color other(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF6E7A74)
      : const Color(0xFFA9B2AD);

  /// Assigns each entity a slot that follows the entity, not its rank:
  /// its preferred slot (from a stable index) if free, else the next free
  /// one. At most [length] entities; callers fold the rest into "Other".
  static Map<K, int> assign<K>(List<K> entities, int Function(K) stableIndex) {
    final taken = <int>{};
    final out = <K, int>{};
    for (final e in entities.take(length)) {
      var slot = stableIndex(e) % length;
      while (taken.contains(slot)) {
        slot = (slot + 1) % length;
      }
      taken.add(slot);
      out[e] = slot;
    }
    return out;
  }
}

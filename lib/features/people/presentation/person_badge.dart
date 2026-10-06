import 'package:flutter/material.dart';

import '../../../core/widgets/tinted_badge.dart';

/// A person's initials on a tinted tile, coloured stably from their name.
class PersonBadge extends StatelessWidget {
  const PersonBadge(this.name, {super.key, this.size = 40});

  final String name;
  final double size;

  static const List<int> _palette = [
    0xFF3A6EA5,
    0xFF8A5BA8,
    0xFFC0703A,
    0xFF3D8C8C,
    0xFFB5475A,
    0xFF2F7D5B,
  ];

  /// "Mudassir Bhai" → "MB", "Ali" → "A".
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_palette[name.hashCode.abs() % _palette.length]);
    return TintedBadge(monogram: initials(name), color: color, size: size);
  }
}

import 'package:flutter/material.dart';

import '../feedback/haptics.dart';

/// A [Switch] that ticks when flipped, like every other selection.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Switch(
    value: value,
    onChanged: onChanged == null
        ? null
        : (v) {
            Haptics.selection();
            onChanged!(v);
          },
  );
}

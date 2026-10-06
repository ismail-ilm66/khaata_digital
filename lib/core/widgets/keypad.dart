import 'package:flutter/material.dart';

import '../money/amount_buffer.dart';
import '../theme/app_typography.dart';
import '../theme/context_x.dart';
import 'app_icons.dart';
import '../feedback/haptics.dart';

/// The in-app number pad for amounts: always open, no system keyboard.
/// Long-press backspace clears.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.onKey,
    this.allowDecimal = true,
    this.keyHeight = 54,
  });

  final ValueChanged<KeypadKey> onKey;
  final bool allowDecimal;

  /// Row height; smaller on short screens.
  final double keyHeight;

  @override
  Widget build(BuildContext context) {
    Widget row(List<KeypadKey?> keys) => Row(
      children: [
        for (final k in keys)
          Expanded(
            child: k == null ? const SizedBox() : _Key(k, onKey, keyHeight),
          ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([KeypadKey.d1, KeypadKey.d2, KeypadKey.d3]),
        row([KeypadKey.d4, KeypadKey.d5, KeypadKey.d6]),
        row([KeypadKey.d7, KeypadKey.d8, KeypadKey.d9]),
        row([
          allowDecimal ? KeypadKey.decimal : null,
          KeypadKey.d0,
          KeypadKey.backspace,
        ]),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key(this.k, this.onKey, this.height);

  final double height;

  final KeypadKey k;
  final ValueChanged<KeypadKey> onKey;

  void _press(KeypadKey key) {
    Haptics.selection();
    onKey(key);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = switch (k) {
      KeypadKey.decimal => '.',
      KeypadKey.backspace || KeypadKey.clear => null,
      _ => '${k.digitValue}',
    };
    return SizedBox(
      height: height,
      child: InkResponse(
        key: ValueKey('key-${k.name}'),
        radius: 34,
        onTap: () => _press(k),
        onLongPress: k == KeypadKey.backspace
            ? () => _press(KeypadKey.clear)
            : null,
        child: Center(
          child: label == null
              ? Semantics(
                  label: 'Delete',
                  child: Icon(AppIcons.backspace, size: 26, color: c.ink),
                )
              : Text(
                  label,
                  style: context.text.headlineMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
        ),
      ),
    );
  }
}

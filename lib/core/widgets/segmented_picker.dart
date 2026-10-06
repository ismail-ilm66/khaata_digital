import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';

@immutable
class PickerOption<T> {
  const PickerOption(this.value, this.label);

  final T value;
  final String label;
}

/// A pill-shaped segmented control with a sliding thumb. Used for theme and
/// language now, and the Expense / Income / Transfer / Udhaar switch later.
class SegmentedPicker<T> extends StatelessWidget {
  const SegmentedPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<PickerOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  static const double _height = 40;
  static const double _inset = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final index = options.indexWhere((o) => o.value == value);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(_height / 2),
      ),
      child: Stack(
        children: [
          // The sliding thumb.
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional(
              options.length == 1 ? 0 : -1 + 2 * index / (options.length - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / options.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dark ? c.line : c.surface,
                  borderRadius: BorderRadius.circular(_height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final o in options)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: o.value == value,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (o.value == value) return;
                        HapticFeedback.selectionClick();
                        onChanged(o.value);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: context.text.labelLarge!.copyWith(
                            color: o.value == value ? c.ink : c.inkMuted,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                            ),
                            child: Text(o.label, maxLines: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

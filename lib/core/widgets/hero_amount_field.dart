import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../money/amount_buffer.dart';
import '../money/currency.dart';
import '../money/money_format.dart';
import '../theme/app_typography.dart';
import '../theme/context_x.dart';

/// Keeps a typed amount valid for [currency] (the same rules as
/// [AmountBuffer.typed]) and shows it grouped ("12,500.5") while typing,
/// with the caret staying next to the digit it was after.
class GroupedAmountFormatter extends TextInputFormatter {
  GroupedAmountFormatter(this.currency);

  final Currency currency;

  static final _significant = RegExp(r'[0-9.٫۰-۹٠-٩]');

  /// Groups the integer part, keeping what's typed after the point
  /// exactly as entered ("12500." → "12,500.").
  static String group(String raw) {
    final dot = raw.indexOf('.');
    return dot < 0
        ? MoneyFormat.groupDigits(raw)
        : '${MoneyFormat.groupDigits(raw.substring(0, dot))}${raw.substring(dot)}';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final typed = AmountBuffer.typed(newValue.text, currency);
    if (typed == null) return oldValue;
    final caret = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, newValue.text.length)
        : newValue.text.length;
    final after = _significant
        .allMatches(newValue.text.substring(caret))
        .length;
    final text = group(typed.text);
    var offset = text.length;
    for (var seen = 0; seen < after && offset > 0;) {
      offset--;
      if (text[offset] != ',') seen++;
    }
    // Before a comma, not after it ("129|,500").
    while (offset > 0 && text[offset - 1] == ',') {
      offset--;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// The big amount at the top of the entry editor, typed with the phone's
/// own number pad. [value] is the plain typed text ("12500.5");
/// [onChanged] reports it the same way. Tapping outside closes the pad
/// (the iOS number pad has no Done key).
class HeroAmountField extends StatefulWidget {
  const HeroAmountField({
    super.key,
    required this.value,
    required this.currency,
    required this.onChanged,
    this.autofocus = false,
    this.fontSize = 56,
    this.fieldKey,
  });

  final String value;
  final Currency currency;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final double fontSize;

  /// Key for the text field itself (tests type into it).
  final Key? fieldKey;

  @override
  State<HeroAmountField> createState() => _HeroAmountFieldState();
}

class _HeroAmountFieldState extends State<HeroAmountField> {
  late final _controller = TextEditingController(
    text: GroupedAmountFormatter.group(widget.value),
  );

  String get _raw => _controller.text.replaceAll(',', '');

  @override
  void didUpdateWidget(HeroAmountField old) {
    super.didUpdateWidget(old);
    // Changed from outside (another account's currency, a swap).
    if (widget.value != _raw) {
      final text = GroupedAmountFormatter.group(widget.value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        // Long amounts shrink rather than scroll out of sight.
        final length = math.max(value.text.length, 1);
        final size = length <= 8
            ? widget.fontSize
            : math.max(widget.fontSize * 0.55, widget.fontSize * 8 / length);
        final style = context.text.displayLarge!.copyWith(
          fontSize: size,
          fontFeatures: AppTypography.tabular,
          color: c.ink,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          textDirection: TextDirection.ltr,
          children: [
            Text(
              '${widget.currency.symbol} ',
              style: context.text.headlineMedium!.copyWith(
                color: c.inkMuted,
                fontSize: size * 0.5,
              ),
            ),
            Flexible(
              child: IntrinsicWidth(
                child: TextField(
                  key: widget.fieldKey,
                  controller: _controller,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: widget.currency.decimals > 0,
                  ),
                  inputFormatters: [GroupedAmountFormatter(widget.currency)],
                  textDirection: TextDirection.ltr,
                  style: style,
                  cursorColor: c.brand,
                  cursorWidth: 3,
                  cursorRadius: const Radius.circular(2),
                  decoration: InputDecoration.collapsed(
                    hintText: '0',
                    hintStyle: style.copyWith(
                      color: c.inkMuted.withValues(alpha: 0.35),
                    ),
                  ),
                  onChanged: (_) => widget.onChanged(_raw),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

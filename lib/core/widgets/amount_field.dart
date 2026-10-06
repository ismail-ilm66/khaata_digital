import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../money/currency.dart';
import '../money/money.dart';
import '../theme/app_typography.dart';
import '../theme/context_x.dart';

/// A text field for typing an amount with the system keyboard (forms where
/// the in-app keypad would be overkill, e.g. an opening balance).
///
/// Always opens the numeric keypad. iOS has no numeric keypad with a minus
/// key, so when [allowNegative] is set the sign is a ± toggle inside the
/// field instead of a key. Tapping outside closes the keypad (the iOS
/// number pad has no Done key).
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.currency,
    required this.label,
    required this.invalidMessage,
    this.allowNegative = false,
  });

  final TextEditingController controller;
  final Currency currency;
  final String label;
  final String invalidMessage;
  final bool allowNegative;

  static const String _minus = '-';

  /// The parsed value of [controller], or null if invalid. Empty is zero.
  static Money? read(TextEditingController controller, Currency currency) {
    final text = controller.text.trim();
    return text.isEmpty || text == _minus
        ? Money.zero(currency)
        : Money.parse(text, currency);
  }

  void _toggleSign() {
    final text = controller.text;
    final next = text.startsWith(_minus) ? text.substring(1) : '$_minus$text';
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: currency.decimals > 0,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,۰-۹٫]')),
        // A minus may only lead, and only via the ± toggle.
        TextInputFormatter.withFunction(
          (old, next) =>
              next.text.lastIndexOf(_minus) > 0 ||
                  (!allowNegative && next.text.contains(_minus))
              ? old
              : next,
        ),
      ],
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: TextStyle(fontFeatures: AppTypography.tabular),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '${currency.symbol}  ',
        suffixIcon: allowNegative
            ? ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final negative = value.text.startsWith(_minus);
                  return TextButton(
                    key: const Key('amountSign'),
                    onPressed: _toggleSign,
                    child: Text(
                      negative ? '−' : '+',
                      style: context.text.titleMedium!.copyWith(
                        color: negative
                            ? context.colors.danger
                            : context.colors.inkMuted,
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
      validator: (_) {
        final m = read(controller, currency);
        if (m == null || (!allowNegative && m.isNegative)) {
          return invalidMessage;
        }
        return null;
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../money/currency.dart';
import '../money/fixed_point.dart';
import '../money/money.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../theme/context_x.dart';
import 'app_sheet.dart';

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
    this.autofocus = false,
  });

  final TextEditingController controller;
  final bool autofocus;
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
      autofocus: autofocus,
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

/// What [showAmountSheet] returns: a new amount, or a request to remove.
sealed class AmountSheetResult {
  const AmountSheetResult();
}

final class AmountEntered extends AmountSheetResult {
  const AmountEntered(this.amount);
  final Money amount;
}

final class AmountRemoved extends AmountSheetResult {
  const AmountRemoved();
}

/// A small sheet asking for one positive amount (e.g. a budget limit).
/// With [removeLabel] it also offers removal. Null if dismissed.
Future<AmountSheetResult?> showAmountSheet(
  BuildContext context, {
  required String title,
  required String fieldLabel,
  required Currency currency,
  required String saveLabel,
  required String invalidMessage,
  Money? initial,
  String? removeLabel,
}) {
  return showAppSheet<AmountSheetResult>(
    context,
    title: title,
    builder: (_) => _AmountSheet(
      fieldLabel: fieldLabel,
      currency: currency,
      saveLabel: saveLabel,
      invalidMessage: invalidMessage,
      initial: initial,
      removeLabel: removeLabel,
    ),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.fieldLabel,
    required this.currency,
    required this.saveLabel,
    required this.invalidMessage,
    this.initial,
    this.removeLabel,
  });

  final String fieldLabel;
  final Currency currency;
  final String saveLabel;
  final String invalidMessage;
  final Money? initial;
  final String? removeLabel;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.initial == null
        ? ''
        : FixedPoint.format(widget.initial!.minor, widget.currency.decimals),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final amount = AmountField.read(_controller, widget.currency);
    if (!_form.currentState!.validate() ||
        amount == null ||
        !amount.isPositive) {
      return;
    }
    Navigator.pop(context, AmountEntered(amount));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmountField(
              key: const Key('sheetAmount'),
              controller: _controller,
              currency: widget.currency,
              label: widget.fieldLabel,
              invalidMessage: widget.invalidMessage,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.l),
            FilledButton(
              key: const Key('sheetSave'),
              onPressed: _save,
              child: Text(widget.saveLabel),
            ),
            if (widget.removeLabel != null)
              TextButton(
                key: const Key('sheetRemove'),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.danger,
                ),
                onPressed: () => Navigator.pop(context, const AmountRemoved()),
                child: Text(widget.removeLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

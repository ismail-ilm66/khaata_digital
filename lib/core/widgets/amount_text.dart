import 'package:flutter/material.dart';

import '../money/money.dart';
import '../money/money_format.dart';
import '../theme/app_typography.dart';
import '../theme/context_x.dart';

/// The one way amounts are drawn: tabular figures, with the sign and
/// currency symbol set smaller and quieter than the number.
///
/// Always laid out left-to-right so "−Rs 2,520" reads correctly in Urdu.
class AmountText extends StatelessWidget {
  const AmountText(
    this.money, {
    super.key,
    this.style,
    this.signed = false,
    this.colored = false,
    this.masked = false,
    this.format = const MoneyFormat(),
  });

  final Money money;

  /// Base style for the number; defaults to `bodyLarge`.
  final TextStyle? style;

  /// Prefix positive amounts with '+'.
  final bool signed;

  /// Colour positive amounts as income. Negatives stay ink — spending is
  /// not an error.
  final bool colored;

  /// Replace digits with dots (the hide-balance toggle).
  final bool masked;

  final MoneyFormat format;

  static const String maskedDigits = '••••';

  @override
  Widget build(BuildContext context) {
    final base = (style ?? context.text.bodyLarge!).copyWith(
      fontFeatures: AppTypography.tabular,
    );
    final color = colored && money.isPositive
        ? context.colors.income
        : (base.color ?? context.colors.ink);
    final parts = format.parts(money, signed: signed);
    final number = masked ? maskedDigits : parts.number;
    final prefixStyle = base.copyWith(
      fontSize: (base.fontSize ?? 16) * 0.72,
      color: color.withValues(alpha: 0.7),
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${masked ? '' : parts.sign}${parts.symbol} ',
            style: prefixStyle,
          ),
          TextSpan(
            text: number,
            style: base.copyWith(color: color),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      semanticsLabel: masked ? '${parts.symbol} hidden' : parts.toString(),
    );
  }
}

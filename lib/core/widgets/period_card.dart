import 'package:flutter/material.dart';

import '../money/money.dart';
import '../theme/app_tokens.dart';
import '../theme/context_x.dart';
import 'amount_text.dart';
import 'period_navigator.dart';

/// A period's name between ‹ › (the name itself opens a choice of period)
/// over its Spent and Income, each centred in its half on one line — a
/// long figure shrinks rather than wrapping. Transactions and Reports.
class PeriodCard extends StatelessWidget {
  const PeriodCard({
    super.key,
    required this.label,
    required this.spent,
    required this.income,
    this.onLabelTap,
    this.onPrevious,
    this.onNext,
    this.spentNote,
    this.incomeNote,
    this.footer,
    this.masked = false,
  });

  final String label;

  /// Null until the period's figures arrive: the place is kept, empty,
  /// and never shows the previous period's.
  final Money? spent;
  final Money? income;
  final VoidCallback? onLabelTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// Under each figure (Reports' comparison with the period before).
  final Widget? spentNote;
  final Widget? incomeNote;

  /// Under the totals, after a rule (Reports' write-offs).
  final Widget? footer;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    Widget total(
      String name,
      Money? amount,
      Widget? note,
      Key key,
      bool income,
    ) => Column(
      children: [
        Text(name, style: context.text.bodySmall),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: amount == null
              // Holds the line's height until the figure arrives.
              ? Text(' ', style: context.text.titleLarge)
              : AmountText(
                  amount,
                  key: key,
                  signed: income,
                  colored: income,
                  masked: masked,
                  style: context.text.titleLarge,
                ),
        ),
        if (note != null) ...[const SizedBox(height: 2), note],
      ],
    );

    return DecoratedBox(
      key: const Key('monthCard'),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: c.line.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s,
          AppSpacing.xs,
          AppSpacing.s,
          AppSpacing.m,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PeriodNavigator(
              label: label,
              onLabelTap: onLabelTap,
              previousTooltip: l.previousPeriod,
              nextTooltip: l.nextPeriod,
              onPrevious: onPrevious,
              onNext: onNext,
            ),
            Divider(color: c.line.withValues(alpha: 0.7)),
            const SizedBox(height: AppSpacing.s),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: total(
                        l.spent,
                        spent,
                        spentNote,
                        const Key('monthSpent'),
                        false,
                      ),
                    ),
                    VerticalDivider(
                      width: AppSpacing.xl,
                      color: c.line.withValues(alpha: 0.7),
                    ),
                    Expanded(
                      child: total(
                        l.income,
                        income,
                        incomeNote,
                        const Key('monthIncome'),
                        true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.s),
              Divider(color: c.line.withValues(alpha: 0.7)),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

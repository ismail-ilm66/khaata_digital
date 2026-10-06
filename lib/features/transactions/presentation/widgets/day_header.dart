import 'package:flutter/material.dart';

import '../../../../core/l10n/date_labels.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/context_x.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../domain/day_group.dart';

/// "Today" on the left, that day's spending (and income) on the right —
/// the daily totals reviewers asked for.
class DayHeader extends StatelessWidget {
  const DayHeader(this.group, {super.key});

  final DayGroup group;

  @override
  Widget build(BuildContext context) {
    final small = context.text.labelLarge!.copyWith(
      color: context.colors.inkMuted,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        AppSpacing.l,
        AppSpacing.xs,
        AppSpacing.s,
      ),
      child: Row(
        children: [
          Expanded(child: Text(context.dayLabel(group.day), style: small)),
          for (final m in group.earned.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.s),
              child: AmountText(m, signed: true, colored: true, style: small),
            ),
          for (final m in group.spent.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.s),
              child: AmountText(-m, style: small),
            ),
        ],
      ),
    );
  }
}

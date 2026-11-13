import 'package:flutter/material.dart';

import '../../../../core/l10n/date_labels.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/context_x.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../domain/day_group.dart';

/// A day's label inside the list card ("Today", "Wed, 11 Nov") and, when
/// the day has more than one entry, its spending and income on the right
/// (with one entry the row already shows it).
class DayHeader extends StatelessWidget {
  const DayHeader(this.group, {super.key});

  final DayGroup group;

  @override
  Widget build(BuildContext context) {
    final small = context.text.labelMedium!.copyWith(
      color: context.colors.inkMuted,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.l,
        AppSpacing.m,
        AppSpacing.l,
        0,
      ),
      child: Row(
        children: [
          Expanded(child: Text(context.dayLabel(group.day), style: small)),
          if (group.entries.length > 1) ...[
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
        ],
      ),
    );
  }
}

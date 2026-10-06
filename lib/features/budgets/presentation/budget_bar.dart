import 'package:flutter/material.dart';

import '../../../core/money/money_format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../domain/budget.dart';

extension BudgetStatusColor on BudgetStatus {
  Color color(AppColors c) => switch (this) {
    BudgetStatus.onTrack => c.brand,
    BudgetStatus.nearLimit => c.warning,
    BudgetStatus.over => c.danger,
  };
}

/// A rounded progress bar for a budget line: green under 80 %, amber to
/// 100 %, red beyond (the overflow shows as a full red bar).
class BudgetBar extends StatelessWidget {
  const BudgetBar(this.line, {super.key, this.height = 8});

  final BudgetLine line;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fraction = (line.permille / 1000).clamp(0.0, 1.0);
    final color = line.status.color(c);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.surfaceMuted),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: const Duration(milliseconds: 300),
                builder: (_, value, _) => ColoredBox(color: value ?? color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One budget, laid out to fit any width:
///   Name ··················· Rs 4,000
///   [██████████░░░░░░░░░░░░░░░░]
///   Rs 6,000 left ······ of Rs 10,000
class BudgetLineView extends StatelessWidget {
  const BudgetLineView({
    super.key,
    required this.name,
    required this.line,
    this.barHeight = 8,
  });

  final String name;
  final BudgetLine line;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final over = line.left.isNegative;
    final left = const MoneyFormat().format(line.left.abs());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            AmountText(line.spent, style: context.text.titleSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        BudgetBar(line, height: barHeight),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                over ? l.budgetOver(left) : l.budgetLeft(left),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall!.copyWith(
                  color: line.status.color(context.colors),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text('/ ', style: context.text.bodySmall),
            AmountText(line.limit, style: context.text.bodySmall),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/dates/calendar_day.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../../../core/widgets/watch.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/category_kind.dart';
import '../../categories/presentation/category_badge.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/presentation/form/entry_editor_screen.dart';
import '../domain/planned_payment.dart';

/// "Due Fri, 25 Oct", "Due today", "Overdue since Mon, 7 Oct", or nothing.
String dueLabel(BuildContext context, PlannedPayment p, CalendarDay today) {
  final l = context.l10n;
  final due = p.dueOn;
  return switch (p.statusOn(today)) {
    DueStatus.noDate => '',
    DueStatus.today => l.dueToday,
    DueStatus.overdue => l.overdueSince(context.dayLabel(due!.toLocal())),
    DueStatus.upcoming => l.dueOn(context.dayLabel(due!.toLocal())),
  };
}

/// Every expense category by id, for badges (kept up to date).
class ExpenseCategories extends StatelessWidget {
  const ExpenseCategories({super.key, required this.builder});

  final Widget Function(BuildContext context, Map<String, Category> byId)
  builder;

  @override
  Widget build(BuildContext context) => Watch<List<Category>>(
    () => getIt<CategoriesRepository>().watch(CategoryKind.expense),
    builder: (context, all) =>
        builder(context, {for (final c in all ?? const <Category>[]) c.id: c}),
  );
}

/// One thing still to pay: what, when, how much, and a Pay button that
/// records it as an expense.
class ToPayRow extends StatelessWidget {
  const ToPayRow({
    super.key,
    required this.item,
    required this.category,
    required this.onTap,
  });

  final PlannedPayment item;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = CalendarDay.of(DateTime.now());
    final due = dueLabel(context, item, today);
    final late = item.statusOn(today) == DueStatus.overdue;
    final subtitle = [due, item.note].where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      key: Key('toPay-${item.title}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Row(
          children: [
            if (category != null)
              CategoryBadge(category!, size: 40)
            else
              TintedBadge(icon: AppIcons.toPay.filled, size: 40),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall!.copyWith(
                        color: late ? c.danger : null,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(item.amount, style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                FilledButton.tonal(
                  key: Key('pay-${item.title}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                    ),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => EntryEditor.pay(context, item),
                  child: Text(context.l10n.pay),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Still to pay Rs 12,400", hidden like other totals when balances are.
class ToPayTotal extends StatelessWidget {
  const ToPayTotal({super.key, required this.items, this.big = false});

  final List<PlannedPayment> items;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final masked = context.watch<HideBalanceCubit>().state.masked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.stillToPay, style: context.text.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        for (final total in PlannedPayment.totals(items).values)
          AmountText(
            total,
            key: Key('toPayTotal-${total.currency.code}'),
            masked: masked,
            style: big ? context.text.headlineMedium : context.text.titleLarge,
          ),
      ],
    );
  }
}

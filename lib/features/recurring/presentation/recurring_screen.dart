import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/category_kind.dart';
import '../../categories/presentation/category_badge.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/recurrence.dart';
import '../domain/recurring_rule.dart';
import '../../../core/widgets/watch.dart';

/// Recurring bills and payments: what repeats, when it's next, reminders.
class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Watch<List<RecurringRuleView>>(
      getIt<RecurringRepository>().watchAll,
      builder: (context, rules) {
        return PageScaffold(
          title: l.recurring,
          slivers: [
            if (rules != null && rules.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: AppIcons.recurring.filled,
                  title: l.noRecurring,
                  message: l.noRecurringBody,
                ),
              )
            else if (rules != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                sliver: SliverToBoxAdapter(
                  child: SurfaceCard(
                    padding: EdgeInsets.zero,
                    children: [for (final r in rules) _RuleTile(r)],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

String frequencyLabel(BuildContext context, RecurrenceFrequency f) {
  final l = context.l10n;
  return switch (f) {
    RecurrenceFrequency.daily => l.repeatDaily,
    RecurrenceFrequency.weekly => l.repeatWeekly,
    RecurrenceFrequency.monthly => l.repeatMonthly,
    RecurrenceFrequency.yearly => l.repeatYearly,
  };
}

class _RuleTile extends StatelessWidget {
  const _RuleTile(this.view);

  final RecurringRuleView view;

  Future<void> _stop(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final repo = getIt<RecurringRepository>();
    await repo.delete(view.rule.id);
    await getIt<ReminderScheduler>().sync(await repo.active());
    messenger.toast(l.stoppedRepeating);
  }

  Future<void> _toggleRemind(bool on) async {
    final repo = getIt<RecurringRepository>();
    final reminders = getIt<ReminderScheduler>();
    if (on) await reminders.requestPermission();
    await repo.setRemind(view.rule.id, on);
    await reminders.sync(await repo.active());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rule = view.rule;
    final t = rule.template;
    final title = t.note.isNotEmpty
        ? t.note
        : (view.categoryName ?? l.recurringEntry);
    final next = rule.nextRunAt;
    final category = view.categoryName == null
        ? null
        : Category(
            id: t.categoryId!,
            name: view.categoryName!,
            kind: CategoryKind.expense,
            iconKey: view.categoryIcon,
            color: view.categoryColor,
          );
    return Padding(
      key: Key('rule-$title'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.m,
        AppSpacing.xs,
        AppSpacing.m,
      ),
      child: Row(
        children: [
          t.type == TransactionType.transfer
              ? const TintedBadge(icon: AppIcons.transfer, size: 40)
              : CategoryBadge(category),
          const SizedBox(width: kBadgeGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${frequencyLabel(context, rule.frequency)} · '
                  '${view.accountName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
                if (next != null)
                  Text(
                    l.nextOn(context.dayLabel(next)),
                    style: context.text.bodySmall,
                  ),
              ],
            ),
          ),
          AmountText(t.amount, style: context.text.titleSmall),
          PopupMenuButton<void>(
            icon: Icon(
              AppIcons.overflow,
              size: 18,
              color: context.colors.inkMuted,
            ),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                checked: rule.remind,
                onTap: () => _toggleRemind(!rule.remind),
                child: Text(l.remindMe),
              ),
              PopupMenuItem(
                onTap: () => _stop(context),
                child: Text(l.stopRepeating),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/watch.dart';
import '../../categories/domain/category.dart';
import '../domain/planned_payment.dart';
import 'to_pay_sheet.dart';
import 'to_pay_widgets.dart';

/// More → To pay: what you still have to pay (charity, a bill, money you
/// promised), each one tap from being recorded as an expense.
class ToPayScreen extends StatelessWidget {
  const ToPayScreen({super.key});

  /// Adds one from anywhere (the screen, Home).
  static Future<void> add(
    BuildContext context,
    List<Category> categories,
  ) async {
    final result = await showToPaySheet(context, categories: categories);
    if (result is ToPaySaved) {
      await getIt<ToPayRepository>().add(result.draft);
      await Haptics.success();
    }
  }

  /// Edits one: save, mark paid without an entry, or delete.
  static Future<void> edit(
    BuildContext context,
    PlannedPayment item,
    List<Category> categories,
  ) async {
    final repo = getIt<ToPayRepository>();
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await showToPaySheet(
      context,
      categories: categories,
      existing: item,
    );
    switch (result) {
      case null:
        return;
      case ToPaySaved(:final draft):
        await repo.update(item.id, draft);
      case ToPayMarkedPaid():
        await repo.markPaid(item.id);
        messenger.undo(
          message: l.toPayMarkedPaid,
          undoLabel: l.undo,
          onUndo: () => repo.markUnpaid(item.id),
        );
      case ToPayDeleted():
        await repo.remove(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = getIt<ToPayRepository>();
    return ExpenseCategories(
      builder: (context, categories) => Watch<List<PlannedPayment>>(
        repo.watchOpen,
        builder: (context, open) => Watch<List<PlannedPayment>>(
          repo.watchPaid,
          builder: (context, paid) {
            final list = categories.values.toList();
            return PageScaffold(
              title: l.toPay,
              trailing: IconButton.filled(
                key: const Key('addToPay'),
                tooltip: l.addToPay,
                onPressed: () => add(context, list),
                icon: const Icon(AppIcons.plus),
              ),
              slivers: [
                if (open == null || paid == null)
                  const SliverToBoxAdapter(child: SizedBox.shrink())
                else if (open.isEmpty && paid.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyState(
                      icon: AppIcons.toPay.filled,
                      title: l.toPayEmptyTitle,
                      message: l.toPayEmptyBody,
                      action: FilledButton(
                        key: const Key('addFirstToPay'),
                        onPressed: () => add(context, list),
                        child: Text(l.addToPay),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    sliver: SliverList.list(
                      children: [
                        if (open.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.l,
                            ),
                            child: Text(
                              l.toPayAllDone,
                              style: context.text.bodyMedium!.copyWith(
                                color: context.colors.inkMuted,
                              ),
                            ),
                          )
                        else ...[
                          ToPayTotal(items: open, big: true),
                          const SizedBox(height: AppSpacing.l),
                          SurfaceCard(
                            padding: EdgeInsets.zero,
                            children: [
                              for (final item in open)
                                ToPayRow(
                                  item: item,
                                  category: categories[item.categoryId],
                                  onTap: () => edit(context, item, list),
                                ),
                            ],
                          ),
                        ],
                        if (paid.isNotEmpty)
                          Section(
                            title: l.paid,
                            child: SurfaceCard(
                              padding: EdgeInsets.zero,
                              children: [
                                for (final item in paid) _PaidRow(item),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A paid item: when, and a way back onto the list.
class _PaidRow extends StatelessWidget {
  const _PaidRow(this.item);

  final PlannedPayment item;

  Future<void> _actions(BuildContext context) async {
    final l = context.l10n;
    final repo = getIt<ToPayRepository>();
    final choice = await pickOne<bool>(
      context,
      title: item.title,
      items: [
        PickItem(
          value: true,
          title: l.markNotPaid,
          subtitle: item.transactionId == null ? null : l.markNotPaidHint,
          leading: const Icon(AppIcons.undo),
          trailing: const SizedBox.shrink(),
        ),
        PickItem(
          value: false,
          title: l.delete,
          leading: Icon(AppIcons.delete, color: context.colors.danger),
          trailing: const SizedBox.shrink(),
        ),
      ],
    );
    if (choice == true) await repo.markUnpaid(item.id);
    if (choice == false) await repo.remove(item.id);
    if (choice != null && context.mounted) showToast(context, l.saved);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      key: Key('paid-${item.title}'),
      onTap: () => _actions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Row(
          children: [
            Icon(AppIcons.check, color: c.brand, size: 20),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall!.copyWith(color: c.inkMuted),
                  ),
                  Text(
                    context.l10n.paidOn(
                      context.dayLabel(item.paidAt!.toLocal()),
                    ),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            AmountText(
              item.amount,
              style: context.text.titleSmall!.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

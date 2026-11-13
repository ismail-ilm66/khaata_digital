import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/context_x.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/account_badge.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/category_badge.dart';
import '../../domain/entry_query.dart';
import '../../domain/transaction_type.dart';
import '../../domain/transactions_repository.dart';

/// Filter chips for Reports (spec 3.2 #8). Each opens a multi-select
/// sheet; an active filter shows its count.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.query, required this.onChanged});

  final EntryQuery query;
  final ValueChanged<EntryQuery> onChanged;

  @override
  Widget build(BuildContext context) {
    final q = query;
    final l = context.l10n;
    Future<void> apply(Future<EntryQuery?> picked) async {
      final next = await picked;
      if (next != null) onChanged(next);
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        children: [
          PillButton(
            icon: AppIcons.filter,
            label: filterLabel(l.filterType, q.types.length),
            selected: q.types.isNotEmpty,
            showChevron: true,
            onTap: () => apply(pickTypeFilter(context, q)),
          ),
          const SizedBox(width: AppSpacing.s),
          PillButton(
            label: filterLabel(l.filterAccount, q.accountIds.length),
            selected: q.accountIds.isNotEmpty,
            showChevron: true,
            onTap: () => apply(pickAccountFilter(context, q)),
          ),
          const SizedBox(width: AppSpacing.s),
          PillButton(
            label: filterLabel(l.filterCategory, q.categoryIds.length),
            selected: q.categoryIds.isNotEmpty,
            showChevron: true,
            onTap: () => apply(pickCategoryFilter(context, q)),
          ),
          const SizedBox(width: AppSpacing.s),
          PillButton(
            icon: AppIcons.tag,
            label: filterLabel(l.filterTag, q.tags.length),
            selected: q.tags.isNotEmpty,
            showChevron: true,
            onTap: () => apply(pickTagFilter(context, q)),
          ),
          if (q.hasFilters) ...[
            const SizedBox(width: AppSpacing.s),
            PillButton(
              icon: AppIcons.close,
              label: l.clear,
              onTap: () => onChanged(q.cleared()),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Account" or, with two chosen, "Account · 2".
String filterLabel(String name, int count) =>
    count == 0 ? name : '$name · $count';

Future<Set<T>?> _choose<T>(
  BuildContext context,
  String title,
  List<PickItem<T>> items,
  Set<T> selected,
) => pickMany<T>(
  context,
  title: title,
  items: items,
  selected: selected,
  doneLabel: context.l10n.done,
  clearLabel: context.l10n.clear,
);

/// Each picker returns [q] with that filter replaced, or null if dismissed.
Future<EntryQuery?> pickTypeFilter(BuildContext context, EntryQuery q) async {
  final l = context.l10n;
  final picked = await _choose(context, l.filterType, [
    PickItem(value: TransactionType.expense, title: l.typeExpense),
    PickItem(value: TransactionType.income, title: l.typeIncome),
    PickItem(value: TransactionType.transfer, title: l.typeTransfer),
  ], q.types);
  return picked == null ? null : q.copyWith(types: picked);
}

Future<EntryQuery?> pickAccountFilter(
  BuildContext context,
  EntryQuery q,
) async {
  final overview = await getIt<AccountsRepository>().watchOverview().first;
  if (!context.mounted) return null;
  final picked = await _choose(context, context.l10n.filterAccount, [
    for (final s in overview.accounts)
      PickItem(
        value: s.account.id,
        title: s.account.name,
        leading: AccountBadge.of(s.account, size: 32),
      ),
  ], q.accountIds);
  return picked == null ? null : q.copyWith(accountIds: picked);
}

Future<EntryQuery?> pickCategoryFilter(
  BuildContext context,
  EntryQuery q,
) async {
  final all = await getIt<CategoriesRepository>().all();
  if (!context.mounted) return null;
  final picked = await _choose(context, context.l10n.filterCategory, [
    for (final c in all)
      PickItem(value: c.id, title: c.name, leading: CategoryBadge(c, size: 32)),
  ], q.categoryIds);
  return picked == null ? null : q.copyWith(categoryIds: picked);
}

Future<EntryQuery?> pickTagFilter(BuildContext context, EntryQuery q) async {
  final tags = await getIt<TransactionsRepository>().tagNames();
  if (!context.mounted) return null;
  final picked = await _choose(context, context.l10n.filterTag, [
    for (final t in tags) PickItem(value: t, title: t),
  ], q.tags);
  return picked == null ? null : q.copyWith(tags: picked);
}

/// How many account, category and tag filters are on.
int moreFilterCount(EntryQuery q) =>
    q.accountIds.length + q.categoryIds.length + q.tags.length;

enum _More { account, category, tag, clear }

/// Transactions' "Filter" button: which filter to change (or clear them
/// all), then that filter's own picker.
Future<EntryQuery?> pickMoreFilters(BuildContext context, EntryQuery q) async {
  final l = context.l10n;
  final which = await pickOne<_More>(
    context,
    title: l.filter,
    searchable: false,
    items: [
      PickItem(
        value: _More.account,
        title: filterLabel(l.filterAccount, q.accountIds.length),
        leading: Icon(AppIcons.accounts.regular),
      ),
      PickItem(
        value: _More.category,
        title: filterLabel(l.filterCategory, q.categoryIds.length),
        leading: Icon(AppIcons.more.regular),
      ),
      PickItem(
        value: _More.tag,
        title: filterLabel(l.filterTag, q.tags.length),
        leading: const Icon(AppIcons.tag),
      ),
      if (moreFilterCount(q) > 0)
        PickItem(
          value: _More.clear,
          title: l.clearFilters,
          leading: const Icon(AppIcons.close),
        ),
    ],
  );
  if (which == null || !context.mounted) return null;
  return switch (which) {
    _More.account => pickAccountFilter(context, q),
    _More.category => pickCategoryFilter(context, q),
    _More.tag => pickTagFilter(context, q),
    _More.clear => q.copyWith(accountIds: {}, categoryIds: {}, tags: {}),
  };
}

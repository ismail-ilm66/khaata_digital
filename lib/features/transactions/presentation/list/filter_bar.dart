import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import 'transaction_list_bloc.dart';

/// Filter chips for the transactions list (spec 3.2 #4). Each opens a
/// multi-select sheet; an active filter shows its count.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TransactionListBloc>();
    final q = context.select((TransactionListBloc b) => b.state.query);
    final l = context.l10n;

    String label(String name, int count) =>
        count == 0 ? name : '$name · $count';
    void apply(EntryQuery next) => bloc.add(FiltersChanged(next));

    Future<Set<T>?> choose<T>(
      String title,
      List<PickItem<T>> items,
      Set<T> selected,
    ) => pickMany<T>(
      context,
      title: title,
      items: items,
      selected: selected,
      doneLabel: l.done,
      clearLabel: l.clear,
    );

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        children: [
          PillButton(
            icon: AppIcons.filter,
            label: label(l.filterType, q.types.length),
            selected: q.types.isNotEmpty,
            showChevron: true,
            onTap: () async {
              final picked = await choose(l.filterType, [
                PickItem(value: TransactionType.expense, title: l.typeExpense),
                PickItem(value: TransactionType.income, title: l.typeIncome),
                PickItem(
                  value: TransactionType.transfer,
                  title: l.typeTransfer,
                ),
              ], q.types);
              if (picked != null) apply(q.copyWith(types: picked));
            },
          ),
          const SizedBox(width: AppSpacing.s),
          PillButton(
            label: label(l.filterAccount, q.accountIds.length),
            selected: q.accountIds.isNotEmpty,
            showChevron: true,
            onTap: () async {
              final overview = await getIt<AccountsRepository>()
                  .watchOverview()
                  .first;
              if (!context.mounted) return;
              final picked = await choose(l.filterAccount, [
                for (final s in overview.accounts)
                  PickItem(
                    value: s.account.id,
                    title: s.account.name,
                    leading: AccountBadge.of(s.account, size: 32),
                  ),
              ], q.accountIds);
              if (picked != null) apply(q.copyWith(accountIds: picked));
            },
          ),
          const SizedBox(width: AppSpacing.s),
          PillButton(
            label: label(l.filterCategory, q.categoryIds.length),
            selected: q.categoryIds.isNotEmpty,
            showChevron: true,
            onTap: () async {
              final all = await getIt<CategoriesRepository>().all();
              if (!context.mounted) return;
              final picked = await choose(l.filterCategory, [
                for (final c in all)
                  PickItem(
                    value: c.id,
                    title: c.name,
                    leading: CategoryBadge(c, size: 32),
                  ),
              ], q.categoryIds);
              if (picked != null) apply(q.copyWith(categoryIds: picked));
            },
          ),
          const SizedBox(width: AppSpacing.s),
          PillButton(
            icon: AppIcons.tag,
            label: label(l.filterTag, q.tags.length),
            selected: q.tags.isNotEmpty,
            showChevron: true,
            onTap: () async {
              final tags = await getIt<TransactionsRepository>().tagNames();
              if (!context.mounted) return;
              final picked = await choose(l.filterTag, [
                for (final t in tags) PickItem(value: t, title: t),
              ], q.tags);
              if (picked != null) apply(q.copyWith(tags: picked));
            },
          ),
          if (q.hasFilters) ...[
            const SizedBox(width: AppSpacing.s),
            PillButton(
              icon: AppIcons.close,
              label: l.clear,
              onTap: () => apply(q.cleared()),
            ),
          ],
        ],
      ),
    );
  }
}

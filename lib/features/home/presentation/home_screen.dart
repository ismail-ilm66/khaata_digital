import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/money/money.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/account_badge.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/presentation/budget_bar.dart';
import '../../people/presentation/people_screen.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/presentation/form/entry_editor_screen.dart';
import '../../transactions/presentation/widgets/entry_tile.dart';
import 'home_cubit.dart';

/// Home (spec 3.2 #2). Budgets and Udhaar cards join in M3.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..start(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.watch<HomeCubit>().state;
    final masked = context.watch<HideBalanceCubit>().state;
    final cycle = context.watch<BudgetCycleCubit>().state;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return PageScaffold(
      title: l.appTitle,
      subtitle: s.cycle == null ? null : cycle.label(s.cycle!, locale: locale),
      trailing: IconButton.filledTonal(
        key: const Key('hideBalance'),
        tooltip: masked ? l.showBalances : l.hideBalances,
        onPressed: context.read<HideBalanceCubit>().toggle,
        style: IconButton.styleFrom(backgroundColor: context.colors.surface),
        icon: Icon(
          masked ? AppIcons.hide : AppIcons.show,
          color: context.colors.ink,
        ),
      ),
      slivers: [
        if (!s.loading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            sliver: SliverList.list(
              children: [
                _SummaryCard(state: s, masked: masked),
                const SizedBox(height: AppSpacing.xl),
                Section(
                  title: l.budgets,
                  trailing: TextButton(
                    onPressed: () => context.push(Routes.budgets),
                    child: Text(l.manage),
                  ),
                  child: _BudgetsCard(overview: s.budgets!),
                ),
                Section(
                  title: l.accounts,
                  trailing: TextButton(
                    onPressed: () => context.push(Routes.accounts),
                    child: Text(l.manage),
                  ),
                  child: _AccountsCarousel(
                    accounts: s.overview!.accounts,
                    masked: masked,
                  ),
                ),
                Section(
                  title: l.people,
                  trailing: TextButton(
                    onPressed: () => context.push(Routes.people),
                    child: Text(l.manage),
                  ),
                  child: UdhaarTotals(
                    overview: s.people!,
                    onTap: () => context.push(Routes.people),
                  ),
                ),
                Section(
                  title: l.recent,
                  trailing: s.recent!.isEmpty
                      ? null
                      : TextButton(
                          onPressed: () => context.go(Routes.transactions),
                          child: Text(l.seeAll),
                        ),
                  child: s.recent!.isEmpty
                      ? SurfaceCard(
                          children: [
                            EmptyState(
                              icon: AppIcons.quickAdd.filled,
                              title: l.noTransactions,
                              message: l.noTransactionsBody,
                              action: FilledButton(
                                onPressed: () => EntryEditor.open(context),
                                child: Text(l.addTransaction),
                              ),
                            ),
                          ],
                        )
                      : SurfaceCard(
                          padding: EdgeInsets.zero,
                          children: [
                            for (final v in s.recent!)
                              EntryTile(
                                v,
                                onTap: () =>
                                    context.push(Routes.entry(v.entry.id)),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Net worth (the headline) and this cycle's income / spent / left.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state, required this.masked});

  final HomeState state;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final currency = context.watch<CurrencyCubit>().state;
    final income = state.totals!.incomeIn(currency);
    final spent = state.totals!.expenseIn(currency);
    final net = state.overview!.netWorth;
    final others = [
      for (final e in net.entries)
        if (e.key != currency) e.value,
    ];

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.netWorth, style: context.text.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            AmountText(
              net[currency] ?? Money.zero(currency),
              key: const Key('netWorth'),
              masked: masked,
              style: context.text.displaySmall,
            ),
            for (final m in others)
              AmountText(
                m,
                masked: masked,
                style: context.text.titleMedium!.copyWith(color: c.inkMuted),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l.thisCycle,
              style: context.text.labelLarge!.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: l.income,
                    value: AmountText(
                      income,
                      signed: true,
                      colored: true,
                      style: context.text.titleMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: StatTile(
                    label: l.spent,
                    value: AmountText(spent, style: context.text.titleMedium),
                  ),
                ),
                Expanded(
                  child: StatTile(
                    label: l.left,
                    value: AmountText(
                      income - spent,
                      style: context.text.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountsCarousel extends StatelessWidget {
  const _AccountsCarousel({required this.accounts, required this.masked});

  final List<AccountSummary> accounts;
  final bool masked;

  static const double _height = 116;
  static const double _width = 156;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget card({
      required Widget child,
      required VoidCallback onTap,
      Key? key,
    }) => Material(
      key: key,
      color: c.surface,
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.m),
        onTap: onTap,
        child: SizedBox(
          width: _width,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: child,
          ),
        ),
      ),
    );

    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: accounts.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
        itemBuilder: (context, i) {
          if (i == accounts.length) {
            return card(
              key: const Key('homeAddAccount'),
              onTap: () => addAccount(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.plus, color: c.brand),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.addAccount,
                    style: context.text.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final s = accounts[i];
          return card(
            onTap: () => context.push(Routes.accounts),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccountBadge.of(s.account, size: 32),
                const Spacer(),
                Text(
                  s.account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: AmountText(
                    s.balance,
                    masked: masked,
                    style: context.text.titleSmall,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Budgets at a glance: the overall bar plus the three fullest categories.
class _BudgetsCard extends StatelessWidget {
  const _BudgetsCard({required this.overview});

  final BudgetOverview overview;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (overview.isEmpty) {
      return SurfaceCard(
        children: [
          SettingTile(
            key: const Key('homeSetBudget'),
            icon: AppIcons.budgets.filled,
            title: l.addBudget,
            subtitle: l.noBudgetsBody,
            onTap: () => context.push(Routes.budgets),
          ),
        ],
      );
    }
    Widget row(String name, BudgetLine line) =>
        BudgetLineView(name: name, line: line);
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.l),
      child: InkWell(
        key: const Key('homeBudgets'),
        borderRadius: BorderRadius.circular(AppRadii.l),
        onTap: () => context.push(Routes.budgets),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              if (overview.overall case final overall?)
                row(l.overallBudget, overall),
              for (final line in overview.lines.take(3)) ...[
                const SizedBox(height: AppSpacing.l),
                row(line.category!.name, line),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_refresh.dart';
import '../../../core/di/injection.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/money/money.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/hero_card.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/period_navigator.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/account_badge.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../accounts/presentation/ordered_accounts.dart';
import '../../budgets/presentation/budget_bar.dart';
import '../../onboarding/presentation/home_tour.dart';
import '../../security/presentation/reveal_balances.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/domain/entry_query.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../transactions/presentation/entries_screen.dart';
import '../../transactions/presentation/form/entry_editor_screen.dart';
import '../../transactions/presentation/widgets/entry_tile.dart';
import 'home_cubit.dart';
import 'needs_attention.dart';

/// Home (spec 3.2 #2): the month's spending, accounts, what needs
/// attention, recent entries.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..start(),
      // The how-to tour, the first time Home has something to show.
      child: BlocListener<HomeCubit, HomeState>(
        listenWhen: (a, b) => a.loading && !b.loading,
        listener: (context, _) =>
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) maybeStartHomeTour(context);
            }),
        child: const _HomeView(),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.watch<HomeCubit>().state;
    final masked = context.watch<HideBalanceCubit>().state.masked;
    final cycle = context.watch<BudgetCycleCubit>().state;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final hour = DateTime.now().hour;

    return PageScaffold(
      title: hour < 12
          ? l.greetingMorning
          : hour < 17
          ? l.greetingAfternoon
          : l.greetingEvening,
      // The current month's dates (they follow the month-start setting).
      subtitle: s.current == null
          ? null
          : cycle.label(s.current!, locale: locale),
      onRefresh: () async {
        Haptics.selection();
        await getIt<AppRefresh>().recurring();
      },
      trailing: KeyedSubtree(
        key: TourTargets.eye,
        child: const BalanceEyeButton(),
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
                  key: TourTargets.accounts,
                  title: l.accounts,
                  onTap: () => context.push(Routes.accounts),
                  child: OrderedAccounts(
                    accounts: s.overview!.accounts,
                    builder: (context, accounts) =>
                        _AccountsCarousel(accounts: accounts, masked: masked),
                  ),
                ),
                NeedsAttention(state: s, masked: masked),
                Section(
                  title: l.recent,
                  onTap: s.recent!.isEmpty
                      ? null
                      : () => context.go(Routes.transactions),
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

/// The month at a glance. Spent is the headline; under it, the overall
/// budget's bar and what's left of it, or income when there's no budget.
/// Net worth closes the card. Every figure opens what's behind it, and the
/// arrows step through earlier cycles.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state, required this.masked});

  final HomeState state;
  final bool masked;

  /// The cycle's entries of [types], udhaar left out to match the totals.
  void _show(BuildContext context, String title, Set<TransactionType> types) {
    final cycle = context.read<BudgetCycleCubit>().state;
    final id = state.cycle!;
    context.push(
      Routes.entries,
      extra: EntriesArgs(
        title: title,
        subtitle: cycle.label(
          id,
          locale: Localizations.localeOf(context).toLanguageTag(),
        ),
        query: EntryQuery(
          types: types,
          range: cycle.rangeOf(id),
          excludeUdhaar: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final currency = context.watch<CurrencyCubit>().state;
    final cycle = context.watch<BudgetCycleCubit>().state;
    final income = state.totals!.incomeIn(currency);
    final spent = state.totals!.expenseIn(currency);
    final budgets = state.budgets!;
    final overall = budgets.overall;
    final net = state.overview!.netWorth;
    final others = [
      for (final e in net.entries)
        if (e.key != currency) e.value,
    ];

    return HeroCard(
      // Read colours and text styles under the card (white on the green).
      child: Builder(
        builder: (context) {
          final c = context.colors;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The tour's "your month" step: the headline, which fits a
              // small phone where the whole card wouldn't.
              KeyedSubtree(
                key: TourTargets.summary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PeriodNavigator(
                      dense: true,
                      label: state.isCurrent
                          ? l.spentThisMonth
                          : l.spentIn(
                              cycle.label(
                                state.cycle!,
                                locale: Localizations.localeOf(
                                  context,
                                ).toLanguageTag(),
                              ),
                            ),
                      previousTooltip: l.previousPeriod,
                      nextTooltip: l.nextPeriod,
                      onPrevious: () => context.read<HomeCubit>().step(-1),
                      onNext: state.isCurrent
                          ? null
                          : () => context.read<HomeCubit>().step(1),
                    ),
                    _Figure(
                      key: const Key('statSpent'),
                      onTap: () =>
                          _show(context, l.spent, {TransactionType.expense}),
                      child: AmountText(
                        spent,
                        key: const Key('spent'),
                        masked: masked,
                        animated: true,
                        style: context.text.displayMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              if (overall != null)
                _Figure(
                  key: const Key('homeBudgets'),
                  onTap: () => context.push(Routes.budgets),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BudgetBar(overall),
                      const SizedBox(height: AppSpacing.xs),
                      BudgetLeftRow(overall, masked: masked),
                    ],
                  ),
                )
              else
                // One line when it fits; on a narrow phone with large text
                // the budget link drops below.
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.m,
                    children: [
                      _Figure(
                        key: const Key('statIncome'),
                        onTap: () =>
                            _show(context, l.income, {TransactionType.income}),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.income, style: context.text.bodySmall),
                            const SizedBox(width: AppSpacing.s),
                            // A huge figure shrinks rather than overflowing.
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: AmountText(
                                  income,
                                  signed: true,
                                  colored: true,
                                  masked: masked,
                                  style: context.text.titleSmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Only with no budget at all: a category budget is a
                      // budget too.
                      if (budgets.isEmpty)
                        _Figure(
                          key: const Key('homeSetBudget'),
                          onTap: () => context.push(Routes.budgets),
                          child: Text(
                            l.setBudget,
                            style: context.text.labelLarge!.copyWith(
                              color: c.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.l),
              Divider(color: c.line),
              _Figure(
                key: const Key('homeNetWorth'),
                onTap: () => context.push(Routes.accounts),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        l.netWorth,
                        style: context.text.bodyMedium!.copyWith(
                          color: c.inkMuted,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AmountText(
                          net[currency] ?? Money.zero(currency),
                          key: const Key('netWorth'),
                          masked: masked,
                          animated: true,
                          style: context.text.titleMedium,
                        ),
                        for (final m in others)
                          AmountText(
                            m,
                            masked: masked,
                            style: context.text.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A figure on the summary card that opens what's behind it.
class _Figure extends StatelessWidget {
  const _Figure({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadii.s),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: child,
    ),
  );
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
    }) => Pressable(
      key: key,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.l),
          side: BorderSide(color: c.line.withValues(alpha: 0.6)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.l),
          onTap: onTap,
          child: SizedBox(
            width: _width,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: child,
            ),
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
                  Icon(AppIcons.plus, color: c.brand, size: 20),
                  const SizedBox(height: 2),
                  // Two lines at most (Urdu with large text wraps).
                  Text(
                    context.l10n.addAccount,
                    style: context.text.labelMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

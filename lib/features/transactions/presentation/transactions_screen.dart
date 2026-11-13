import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/dates/date_range.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/paged_scroll_listener.dart';
import '../../../core/widgets/period_navigator.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/watch.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../domain/entry_query.dart';
import '../domain/transaction_type.dart';
import '../domain/transactions_repository.dart';
import 'form/entry_editor_screen.dart';
import 'list/entry_list.dart';
import 'list/filter_bar.dart';
import 'list/transaction_list_bloc.dart';

/// Transactions tab (spec 3.2 #4): one budget cycle at a time, like a
/// statement. ‹ › steps through cycles (forward as far as the newest entry,
/// so a future-dated one is never out of reach); the cycle's name opens
/// This month / All time / Pick a month. The period's spending and income
/// sit on top; chips narrow it by kind, Filter by account, category or tag.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionListBloc>(),
      child: const _TransactionsView(),
    );
  }
}

/// What the chips show. Expenses and income leave udhaar out, so the list
/// adds up to the month's Spent and Income.
enum _Kind {
  all,
  expenses,
  income,
  udhaar,
  transfers;

  static _Kind of(EntryQuery q) => q.onlyUdhaar
      ? udhaar
      : q.types.contains(TransactionType.expense)
      ? expenses
      : q.types.contains(TransactionType.income)
      ? income
      : q.types.contains(TransactionType.transfer)
      ? transfers
      : all;

  EntryQuery applyTo(EntryQuery q) => q.copyWith(
    types: switch (this) {
      expenses => {TransactionType.expense},
      income => {TransactionType.income},
      transfers => {TransactionType.transfer},
      all || udhaar => {},
    },
    excludeUdhaar: this == expenses || this == income,
    onlyUdhaar: this == udhaar,
  );
}

class _TransactionsView extends StatefulWidget {
  const _TransactionsView();

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

/// The choices behind the month name.
enum _Pick { thisMonth, allTime, month }

class _TransactionsViewState extends State<_TransactionsView> {
  /// Everything ever recorded: the list's and the totals' range for
  /// "All time".
  static final _everything = DateRange(DateTime.utc(1970), DateTime.utc(3000));

  /// The cycle shown; null follows the current one.
  CycleId? _shown;

  /// Every entry, all cycles, instead of one.
  bool _allTime = false;

  BudgetCycle get _cycle => context.read<BudgetCycleCubit>().state;
  CycleId get _current => _cycle.idFor(DateTime.now());

  @override
  void initState() {
    super.initState();
    context.read<TransactionListBloc>().add(
      ListStarted(EntryQuery(range: _cycle.rangeOf(_current))),
    );
  }

  void _show(CycleId? id, {bool allTime = false}) {
    setState(() {
      _shown = id;
      _allTime = allTime;
    });
    final bloc = context.read<TransactionListBloc>();
    bloc.add(
      FiltersChanged(
        bloc.state.query.copyWith(
          range: allTime ? _everything : _cycle.rangeOf(id ?? _current),
        ),
      ),
    );
  }

  /// The month name: this month, all time, or any month from the first
  /// entry to the newest.
  Future<void> _choosePeriod(
    BudgetCycle cycle,
    CycleId current,
    ({DateTime first, DateTime last})? span,
  ) async {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final choice = await pickOne<_Pick>(
      context,
      title: l.showPeriod,
      searchable: false,
      selected: _allTime
          ? _Pick.allTime
          : _shown == null
          ? _Pick.thisMonth
          : null,
      items: [
        PickItem(
          value: _Pick.thisMonth,
          title: l.thisCycle,
          subtitle: cycle.label(current, locale: locale),
        ),
        PickItem(value: _Pick.allTime, title: l.allTime),
        PickItem(value: _Pick.month, title: l.pickMonth),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case null:
        return;
      case _Pick.thisMonth:
        _show(null);
      case _Pick.allTime:
        _show(null, allTime: true);
      case _Pick.month:
        CycleId later(CycleId a, CycleId b) => a.compareTo(b) >= 0 ? a : b;
        var id = span == null
            ? current
            : later(current, cycle.idFor(span.last.toLocal()));
        final first = span == null
            ? current
            : [
                current,
                cycle.idFor(span.first.toLocal()),
              ].reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
        final months = <CycleId>[];
        while (id.compareTo(first) >= 0) {
          months.add(id);
          id = id.previous;
        }
        final picked = await pickOne<CycleId>(
          context,
          title: l.pickMonth,
          selected: _allTime ? null : _shown ?? current,
          items: [
            for (final m in months)
              PickItem(
                value: m,
                title: cycle.label(m, locale: locale),
              ),
          ],
        );
        if (picked != null && mounted) {
          _show(picked == current ? null : picked);
        }
    }
  }

  void _filter(EntryQuery q) =>
      context.read<TransactionListBloc>().add(FiltersChanged(q));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionListBloc>().state;
    final cycle = context.watch<BudgetCycleCubit>().state;
    final l = context.l10n;
    final current = cycle.idFor(DateTime.now());
    final shown = _shown ?? current;
    final q = state.query;
    final kind = _Kind.of(q);
    final more = moreFilterCount(q);

    return BlocListener<BudgetCycleCubit, BudgetCycle>(
      // A new month start re-cuts every cycle: back to the current one.
      listener: (context, _) => _show(null),
      child: PagedScrollListener(
        onNearEnd: () =>
            context.read<TransactionListBloc>().add(const MoreRequested()),
        child: PageScaffold(
          title: l.navTransactions,
          trailing: HeaderButton(
            key: const Key('searchButton'),
            icon: AppIcons.search,
            tooltip: l.search,
            onPressed: () => context.push(Routes.search),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.s,
              ),
              sliver: SliverToBoxAdapter(
                // Forward as far as the newest entry (or this cycle).
                child: Watch<({DateTime first, DateTime last})?>(
                  () => getIt<TransactionsRepository>().watchSpan(),
                  builder: (context, span) {
                    final at = span?.last;
                    final last = at == null
                        ? current
                        : [
                            current,
                            cycle.idFor(at.toLocal()),
                          ].reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
                    return _MonthCard(
                      label: _allTime
                          ? l.allTime
                          : cycle.label(
                              shown,
                              locale: Localizations.localeOf(
                                context,
                              ).toLanguageTag(),
                            ),
                      range: _allTime ? _everything : cycle.rangeOf(shown),
                      onLabelTap: () => _choosePeriod(cycle, current, span),
                      onPrevious: _allTime ? null : () => _show(shown.previous),
                      onNext: _allTime || shown.compareTo(last) >= 0
                          ? null
                          : () => _show(
                              shown.next == current ? null : shown.next,
                            ),
                    );
                  },
                ),
              ),
            ),
            // Stays put while the list scrolls under it.
            PinnedHeaderSliver(
              child: _FrostedBar(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    key: const Key('kindChips'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    children: [
                      // First, so it's always in view; the chips follow.
                      PillButton(
                        key: const Key('moreFilters'),
                        icon: AppIcons.filter,
                        label: filterLabel(l.filter, more),
                        selected: more > 0,
                        showChevron: true,
                        onTap: () async {
                          final next = await pickMoreFilters(context, q);
                          if (next != null) _filter(next);
                        },
                      ),
                      const SizedBox(width: AppSpacing.s),
                      for (final (k, label) in [
                        (_Kind.all, l.kindAll),
                        (_Kind.expenses, l.kindExpenses),
                        (_Kind.income, l.typeIncome),
                        (_Kind.udhaar, l.typeUdhaar),
                        (_Kind.transfers, l.kindTransfers),
                      ]) ...[
                        if (k != _Kind.all) const SizedBox(width: AppSpacing.s),
                        PillButton(
                          key: Key('kind-${k.name}'),
                          label: label,
                          selected: kind == k,
                          onTap: () => _filter(k.applyTo(q)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (state.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: q.hasFilters || kind != _Kind.all
                    ? EmptyState(
                        icon: AppIcons.filter,
                        title: l.noMatches,
                        message: l.noMatchesBody,
                      )
                    : EmptyState(
                        icon: AppIcons.transactions.filled,
                        title: _allTime
                            ? l.noTransactions
                            : l.noEntriesThisMonth,
                        message: _allTime
                            ? l.noTransactionsBody
                            : l.noEntriesThisMonthBody,
                        action: shown == current
                            ? FilledButton(
                                onPressed: () => EntryEditor.open(context),
                                child: Text(l.addTransaction),
                              )
                            : null,
                      ),
              )
            else if (state.days.isNotEmpty)
              // All time: each month's name above its card.
              EntryListSlivers(days: state.days, cycleHeaders: _allTime),
            if (state.hasMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.l),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ‹ November 2026 › over the cycle's Spent and Income, each on one line
/// (a very long figure shrinks to fit rather than wrapping). Udhaar is
/// left out, as on Home; amounts hide with the balances.
class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.label,
    required this.range,
    required this.onLabelTap,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final DateRange range;

  /// Opens the choice of period (this month, all time, a month).
  final VoidCallback onLabelTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final currency = context.watch<CurrencyCubit>().state;
    final masked = context.watch<HideBalanceCubit>().state.masked;
    // Centred in its half, under the month name. Until the period's
    // figures arrive the amount keeps its place but shows nothing, never
    // the previous period's.
    Widget total(String name, Widget amount, {required bool ready}) => Column(
      children: [
        Text(name, style: context.text.bodySmall),
        const SizedBox(height: 2),
        Opacity(
          opacity: ready ? 1 : 0,
          child: FittedBox(fit: BoxFit.scaleDown, child: amount),
        ),
      ],
    );

    return DecoratedBox(
      key: const Key('monthCard'),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: c.line.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s,
          AppSpacing.xs,
          AppSpacing.s,
          AppSpacing.m,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PeriodNavigator(
              label: label,
              onLabelTap: onLabelTap,
              previousTooltip: l.previousPeriod,
              nextTooltip: l.nextPeriod,
              onPrevious: onPrevious,
              onNext: onNext,
            ),
            Divider(color: c.line.withValues(alpha: 0.7)),
            const SizedBox(height: AppSpacing.s),
            Watch<PeriodTotals>(
              // A new period starts empty rather than with the last one's
              // figures.
              key: ValueKey(range),
              () => getIt<TransactionsRepository>().watchTotals(range),
              builder: (context, totals) {
                final t = totals ?? PeriodTotals.empty;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: total(
                            l.spent,
                            AmountText(
                              t.expenseIn(currency),
                              key: const Key('monthSpent'),
                              masked: masked,
                              style: context.text.titleLarge,
                            ),
                            ready: totals != null,
                          ),
                        ),
                        VerticalDivider(
                          width: AppSpacing.xl,
                          color: c.line.withValues(alpha: 0.7),
                        ),
                        Expanded(
                          child: total(
                            l.income,
                            AmountText(
                              t.incomeIn(currency),
                              key: const Key('monthIncome'),
                              signed: true,
                              colored: true,
                              masked: masked,
                              style: context.text.titleLarge,
                            ),
                            ready: totals != null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width strip of frosted page colour, so rows scrolling beneath a
/// pinned header blur out instead of showing through.
class _FrostedBar extends StatelessWidget {
  const _FrostedBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: ColoredBox(
        color: context.colors.paper.withValues(alpha: 0.72),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          child: child,
        ),
      ),
    ),
  );
}

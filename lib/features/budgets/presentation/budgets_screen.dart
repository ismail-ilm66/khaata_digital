import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/di/injection.dart';
import '../../../core/money/money.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/category_kind.dart';
import '../../categories/presentation/category_badge.dart';
import '../../categories/presentation/category_grid.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/domain/entry_query.dart';
import '../../transactions/presentation/entries_screen.dart';
import '../domain/budget.dart';
import 'budget_bar.dart';
import 'budgets_bloc.dart';

/// Budgets (spec 3.2 #6): one cycle at a time, overall + per category.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BudgetsBloc>()..add(const BudgetsStarted()),
      child: const _BudgetsView(),
    );
  }
}

class _BudgetsView extends StatelessWidget {
  const _BudgetsView();

  Future<void> _editLimit(
    BuildContext context, {
    required Money? current,
    required String title,
    String? categoryId,
  }) async {
    final bloc = context.read<BudgetsBloc>();
    final l = context.l10n;
    final result = await showAmountSheet(
      context,
      title: title,
      fieldLabel: l.budgetLimit,
      currency: context.read<CurrencyCubit>().state,
      saveLabel: l.save,
      invalidMessage: l.invalidAmount,
      initial: current,
      removeLabel: current == null ? null : l.removeBudget,
    );
    switch (result) {
      case AmountEntered(:final amount):
        bloc.add(BudgetSet(amount, categoryId: categoryId));
      case AmountRemoved():
        bloc.add(BudgetCleared(categoryId: categoryId));
      case null:
    }
  }

  Future<void> _addCategoryBudget(
    BuildContext context,
    BudgetOverview o,
  ) async {
    final all = [
      for (final c in await getIt<CategoriesRepository>().all())
        if (c.kind == CategoryKind.expense) c,
    ];
    if (!context.mounted) return;
    final budgeted = {for (final l in o.lines) l.category!.id};
    final picked = await pickCategory(
      context,
      categories: [
        for (final c in all)
          if (!budgeted.contains(c.id)) c,
      ],
    );
    if (picked == null || !context.mounted) return;
    await _editLimit(
      context,
      current: null,
      title: picked.name,
      categoryId: picked.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cycle = context.watch<BudgetCycleCubit>().state;
    return BlocConsumer<BudgetsBloc, BudgetsState>(
      listenWhen: (a, b) => b.copied != null && a.copied != b.copied,
      listener: (context, s) => showToast(context, l.copiedBudgets(s.copied!)),
      builder: (context, s) {
        final o = s.overview;
        return PageScaffold(
          title: l.budgets,
          trailing: o == null
              ? null
              : IconButton.filled(
                  key: const Key('addBudget'),
                  tooltip: l.addBudget,
                  onPressed: () => _addCategoryBudget(context, o),
                  icon: const Icon(AppIcons.plus),
                ),
          slivers: [
            if (s.cycle != null)
              SliverToBoxAdapter(
                child: _CycleNavigator(cycle: s.cycle!, budgetCycle: cycle),
              ),
            if (o != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                sliver: SliverList.list(
                  children: [
                    const SizedBox(height: AppSpacing.l),
                    _OverallCard(
                      overview: o,
                      onTap: () => _editLimit(
                        context,
                        current: o.overall?.limit,
                        title: l.overallBudget,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (o.lines.isEmpty && o.overall == null)
                      EmptyState(
                        icon: AppIcons.reports.filled,
                        title: l.noBudgets,
                        message: l.noBudgetsBody,
                        action: TextButton.icon(
                          key: const Key('copyLast'),
                          onPressed: () => context.read<BudgetsBloc>().add(
                            const CopyLastRequested(),
                          ),
                          icon: const Icon(AppIcons.restore, size: 18),
                          label: Text(l.copyLastMonth),
                        ),
                      )
                    else ...[
                      if (o.lines.isNotEmpty)
                        Section(
                          title: l.category,
                          child: SurfaceCard(
                            children: [
                              for (final line in o.lines)
                                _CategoryRow(
                                  line: line,
                                  onTap: () => context.push(
                                    Routes.entries,
                                    extra: EntriesArgs(
                                      title: line.category!.name,
                                      subtitle: cycle.label(
                                        s.cycle!,
                                        locale: _locale(context),
                                      ),
                                      query: EntryQuery(
                                        categoryIds: {line.category!.id},
                                        range: cycle.rangeOf(s.cycle!),
                                      ),
                                    ),
                                  ),
                                  onEdit: () => _editLimit(
                                    context,
                                    current: line.limit,
                                    title: line.category!.name,
                                    categoryId: line.category!.id,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Center(
                        child: TextButton.icon(
                          key: const Key('copyLast'),
                          onPressed: () => context.read<BudgetsBloc>().add(
                            const CopyLastRequested(),
                          ),
                          icon: const Icon(AppIcons.restore, size: 18),
                          label: Text(l.copyLastMonth),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// ‹ 25 Sep – 24 Oct ›
class _CycleNavigator extends StatelessWidget {
  const _CycleNavigator({required this.cycle, required this.budgetCycle});

  final CycleId cycle;
  final BudgetCycle budgetCycle;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BudgetsBloc>();
    final c = context.colors;
    final l = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: const Key('previousCycle'),
          tooltip: l.previousCycle,
          onPressed: () => bloc.add(CycleChanged(cycle.previous)),
          icon: DirectionalIcon(AppIcons.back, size: 18, color: c.ink),
        ),
        Text(
          budgetCycle.label(cycle, locale: _locale(context)),
          style: context.text.titleMedium,
        ),
        IconButton(
          key: const Key('nextCycle'),
          tooltip: l.nextCycle,
          onPressed: () => bloc.add(CycleChanged(cycle.next)),
          icon: DirectionalIcon(AppIcons.arrowRight, size: 18, color: c.ink),
        ),
      ],
    );
  }
}

/// The whole-month budget — the headline of the screen.
class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.overview, required this.onTap});

  final BudgetOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final line = overview.overall;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.l),
      child: InkWell(
        key: const Key('overallBudget'),
        borderRadius: BorderRadius.circular(AppRadii.l),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: line == null
              ? Row(
                  children: [
                    TintedBadge(icon: AppIcons.plus, size: 40),
                    const SizedBox(width: kBadgeGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.overallBudget, style: context.text.titleSmall),
                          Text(
                            l.overallBudgetHint,
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AmountText(
                      overview.totalSpent,
                      style: context.text.titleSmall,
                    ),
                  ],
                )
              : BudgetLineView(
                  name: l.overallBudget,
                  line: line,
                  barHeight: 10,
                ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.line,
    required this.onTap,
    required this.onEdit,
  });

  final BudgetLine line;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('budget-${line.category!.name}'),
      onTap: onTap,
      child: Row(
        children: [
          CategoryBadge(line.category, size: 36),
          const SizedBox(width: kBadgeGap),
          Expanded(
            child: BudgetLineView(name: line.category!.name, line: line),
          ),
          IconButton(
            tooltip: context.l10n.editBudget,
            onPressed: onEdit,
            icon: Icon(AppIcons.edit, size: 18, color: context.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

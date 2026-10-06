import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates/report_period.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/period_navigator.dart';
import '../../../core/widgets/segmented_picker.dart';
import '../../../core/widgets/surface_card.dart';
import '../../categories/domain/category.dart';
import '../../import_export/presentation/export_sheet.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/presentation/entries_screen.dart';
import '../../transactions/presentation/list/filter_bar.dart';
import '../domain/report.dart';
import 'report_charts.dart';
import 'reports_bloc.dart';

/// Reports tab (spec 3.2 #8): any period, full history, the list's filters.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReportsBloc>()..add(const ReportsStarted()),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  /// The donut shows spending, or income when toggled.
  bool _showIncome = false;

  /// The period's name; one in progress reads "25 Sep – 6 Oct" (to today,
  /// or to the last charted day if an entry is dated later).
  String _periodLabel(BuildContext context, ReportQuery q) {
    final span = context.read<ReportsBloc>().state.data?.span;
    return q.period.label(
      context.read<BudgetCycleCubit>().state,
      allTime: context.l10n.allTime,
      locale: Localizations.localeOf(context).toLanguageTag(),
      today: DateTime.now(),
      through: span?.lastDay,
    );
  }

  Future<void> _chooseCustom(BuildContext context, ReportQuery q) async {
    final bloc = context.read<ReportsBloc>();
    final current = q.period.range(q.cycle);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      initialDateRange: current == null
          ? null
          : DateTimeRange(start: current.start, end: current.lastDay),
    );
    if (picked != null) bloc.add(CustomPeriodChosen(picked.start, picked.end));
  }

  void _drillDown(BuildContext context, ReportQuery q, Category? category) {
    if (category == null) return;
    context.push(
      Routes.entries,
      extra: EntriesArgs(
        title: category.name,
        subtitle: _periodLabel(context, q),
        query: q.entriesQuery(categoryIds: {category.id}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<ReportsBloc>().state;
    final q = state.query;
    if (q == null) return const SizedBox.shrink();
    final data = state.data;
    final kindLabels = {
      PeriodKind.day: l.periodDay,
      PeriodKind.week: l.periodWeek,
      PeriodKind.month: l.periodMonth,
      PeriodKind.year: l.periodYear,
      PeriodKind.custom: l.periodCustom,
      PeriodKind.all: l.periodAll,
    };

    return PageScaffold(
      title: l.navReports,
      trailing: IconButton.filledTonal(
        key: const Key('exportButton'),
        tooltip: l.export,
        onPressed: () => showExportSheet(
          context,
          view: q.entriesQuery(),
          viewLabel: _periodLabel(context, q),
        ),
        style: IconButton.styleFrom(backgroundColor: context.colors.surface),
        icon: Icon(AppIcons.share, color: context.colors.ink),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedPicker<PeriodKind>(
                    key: const Key('periodPicker'),
                    value: q.period.kind,
                    onChanged: (k) =>
                        context.read<ReportsBloc>().add(PeriodKindChanged(k)),
                    options: [
                      for (final k in const [
                        PeriodKind.day,
                        PeriodKind.week,
                        PeriodKind.month,
                        PeriodKind.year,
                        PeriodKind.all,
                      ])
                        PickerOption(k, kindLabels[k]!),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                IconButton.filledTonal(
                  key: const Key('period-custom'),
                  tooltip: l.periodCustom,
                  isSelected: q.period.kind == PeriodKind.custom,
                  onPressed: () => _chooseCustom(context, q),
                  style: IconButton.styleFrom(
                    backgroundColor: q.period.kind == PeriodKind.custom
                        ? context.colors.brand.withValues(alpha: 0.14)
                        : context.colors.surfaceMuted,
                  ),
                  icon: Icon(
                    AppIcons.calendar,
                    color: context.colors.ink,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: PeriodNavigator(
              label: _periodLabel(context, q),
              previousTooltip: l.previousPeriod,
              nextTooltip: l.nextPeriod,
              onPrevious: q.period.canStep
                  ? () =>
                        context.read<ReportsBloc>().add(const PeriodStepped(-1))
                  : null,
              onNext: q.period.canStep
                  ? () =>
                        context.read<ReportsBloc>().add(const PeriodStepped(1))
                  : null,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FilterBar(
            query: q.filters,
            onChanged: (f) =>
                context.read<ReportsBloc>().add(ReportFiltersChanged(f)),
          ),
        ),
        if (data == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (data.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: AppIcons.reports.filled,
              title: l.noActivity,
              message: l.noActivityBody,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.l,
              AppSpacing.page,
              0,
            ),
            sliver: SliverList.list(
              children: [
                SurfaceCard(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: l.income,
                            value: AmountText(
                              data.income,
                              signed: true,
                              colored: true,
                              style: context.text.titleMedium,
                            ),
                          ),
                        ),
                        Expanded(
                          child: StatTile(
                            label: l.spent,
                            value: AmountText(
                              data.expense,
                              style: context.text.titleMedium,
                            ),
                          ),
                        ),
                        Expanded(
                          child: StatTile(
                            label: l.net,
                            value: AmountText(
                              data.net,
                              key: const Key('reportNet'),
                              style: context.text.titleMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
                ChartCard(
                  title: _showIncome
                      ? l.incomeByCategory
                      : l.spendingByCategory,
                  trailing: SizedBox(
                    width: 180,
                    child: SegmentedPicker<bool>(
                      key: const Key('donutToggle'),
                      value: _showIncome,
                      onChanged: (v) => setState(() => _showIncome = v),
                      options: [
                        PickerOption(false, l.spent),
                        PickerOption(true, l.income),
                      ],
                    ),
                  ),
                  child: CategoryDonut(
                    slices: _showIncome ? data.earning : data.spending,
                    total: _showIncome ? data.income : data.expense,
                    otherLabel: l.other,
                    noCategoryLabel: l.noCategory,
                    onCategoryTap: (c) => _drillDown(context, q, c),
                  ),
                ),
                if (data.flow.length > 1) ...[
                  const SizedBox(height: AppSpacing.l),
                  ChartCard(
                    title: l.incomeVsSpending,
                    child: FlowBars(
                      points: data.flow,
                      size: data.bucketSize,
                      incomeLabel: l.income,
                      spendingLabel: l.spent,
                    ),
                  ),
                ],
                if (data.balance.length > 1) ...[
                  const SizedBox(height: AppSpacing.l),
                  ChartCard(
                    title: l.balanceTrend,
                    child: BalanceTrend(
                      points: data.balance,
                      size: data.bucketSize,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

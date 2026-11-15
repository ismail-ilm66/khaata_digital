import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates/report_period.dart';
import '../../../core/di/injection.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/period_card.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/widgets/amount_text.dart';
import '../../categories/domain/category.dart';
import '../../people/domain/person.dart';
import '../../import_export/presentation/export_sheet.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/presentation/entries_screen.dart';
import '../../transactions/presentation/list/filter_bar.dart';
import '../domain/report.dart';
import 'report_charts.dart';
import 'reports_bloc.dart';

/// Reports tab (spec 3.2 #8): the same period card as Transactions — the
/// name opens Day / Week / Month / Year / All time / a custom range — with
/// Spent and Income against the period before; then where the money went,
/// bucket by bucket, and the balance. Filter narrows all of it; Spending /
/// Income picks the side the categories and bars show.
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

/// The choices behind the period's name.
enum _Pick { day, week, month, year, all, custom }

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  /// The categories and bars show income instead of spending.
  bool _income = false;

  String _label(ReportPeriod period, {DateTime? through}) => period.label(
    context.read<BudgetCycleCubit>().state,
    allTime: context.l10n.allTime,
    locale: Localizations.localeOf(context).toLanguageTag(),
    today: DateTime.now(),
    through: through,
  );

  /// The period's name; one in progress reads "25 Sep – 6 Oct" (to today,
  /// or to the last charted day if an entry is dated later).
  String _periodLabel(ReportsState state) =>
      _label(state.query!.period, through: state.data?.span?.lastDay);

  Future<void> _choosePeriod(ReportQuery q) async {
    final l = context.l10n;
    final bloc = context.read<ReportsBloc>();
    final pick = await pickOne<_Pick>(
      context,
      title: l.showPeriod,
      searchable: false,
      selected: switch (q.period.kind) {
        PeriodKind.day => _Pick.day,
        PeriodKind.week => _Pick.week,
        PeriodKind.month => _Pick.month,
        PeriodKind.year => _Pick.year,
        PeriodKind.all => _Pick.all,
        PeriodKind.custom => _Pick.custom,
      },
      items: [
        PickItem(value: _Pick.day, title: l.periodDay),
        PickItem(value: _Pick.week, title: l.periodWeek),
        PickItem(value: _Pick.month, title: l.periodMonth),
        PickItem(value: _Pick.year, title: l.periodYear),
        PickItem(value: _Pick.all, title: l.allTime),
        PickItem(value: _Pick.custom, title: l.customRange),
      ],
    );
    if (pick == null || !mounted) return;
    if (pick == _Pick.custom) return _chooseCustom(q);
    bloc.add(
      PeriodKindChanged(switch (pick) {
        _Pick.day => PeriodKind.day,
        _Pick.week => PeriodKind.week,
        _Pick.month => PeriodKind.month,
        _Pick.year => PeriodKind.year,
        _ => PeriodKind.all,
      }),
    );
  }

  Future<void> _chooseCustom(ReportQuery q) async {
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

  void _drillDown(ReportsState state, Category? category) {
    if (category == null) return;
    context.push(
      Routes.entries,
      extra: EntriesArgs(
        title: category.name,
        subtitle: _periodLabel(state),
        query: state.query!.entriesQuery(categoryIds: {category.id}),
      ),
    );
  }

  /// "▼ 12% vs Oct 2026" under a figure, green when it went the good way
  /// (less spending, more income), amber otherwise; nothing when the
  /// period before had none to compare with.
  Widget? _change(
    ReportsState s,
    Money now,
    Money? before, {
    required bool spending,
  }) {
    final previous = s.previous;
    if (previous == null || before == null || before.isZero) return null;
    final l = context.l10n;
    final c = context.colors;
    final vs = _label(previous);
    final pct = ((now.minor - before.minor) * 100 / before.minor).round();
    final good = spending ? pct < 0 : pct > 0;
    final text = pct == 0
        ? l.sameAs(vs)
        : '${pct < 0 ? '▼' : '▲'} ${l.changeVs(pct.abs(), vs)}';
    return Text(
      text,
      key: Key(spending ? 'spentChange' : 'incomeChange'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.labelSmall!.copyWith(
        color: pct == 0 ? c.inkMuted : (good ? c.income : c.warning),
        fontWeight: FontWeight.w700,
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
    final before = state.before;
    final more = moreFilterCount(q.filters);
    // The balance starts at the first money there was, not a run of
    // zeros before it.
    final balance = data == null
        ? const <BalancePoint>[]
        : data.balance.skipWhile((p) => p.balance.isZero).toList();

    return PageScaffold(
      title: l.navReports,
      trailing: HeaderButton(
        key: const Key('exportButton'),
        icon: AppIcons.share,
        tooltip: l.export,
        onPressed: () => showExportSheet(
          context,
          view: q.entriesQuery(),
          viewLabel: _periodLabel(state),
        ),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          sliver: SliverToBoxAdapter(
            child: PeriodCard(
              label: _periodLabel(state),
              onLabelTap: () => _choosePeriod(q),
              onPrevious: q.period.canStep
                  ? () =>
                        context.read<ReportsBloc>().add(const PeriodStepped(-1))
                  : null,
              onNext: q.period.canStep
                  ? () =>
                        context.read<ReportsBloc>().add(const PeriodStepped(1))
                  : null,
              spent: data?.expense,
              income: data?.income,
              spentNote: data == null
                  ? null
                  : _change(
                      state,
                      data.expense,
                      before?.expense,
                      spending: true,
                    ),
              incomeNote: data == null
                  ? null
                  : _change(
                      state,
                      data.income,
                      before?.income,
                      spending: false,
                    ),
              footer: data == null || data.writeOffs.isEmpty
                  ? null
                  : _WriteOffLines(data.writeOffs),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.m),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                children: [
                  PillButton(
                    key: const Key('moreFilters'),
                    icon: AppIcons.filter,
                    label: filterLabel(l.filter, more),
                    selected: more > 0,
                    showChevron: true,
                    onTap: () async {
                      final bloc = context.read<ReportsBloc>();
                      final next = await pickMoreFilters(context, q.filters);
                      if (next != null) bloc.add(ReportFiltersChanged(next));
                    },
                  ),
                  const SizedBox(width: AppSpacing.s),
                  PillButton(
                    key: const Key('showSpending'),
                    label: l.kindSpending,
                    selected: !_income,
                    onTap: () => setState(() => _income = false),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  PillButton(
                    key: const Key('showIncome'),
                    label: l.typeIncome,
                    selected: _income,
                    onTap: () => setState(() => _income = true),
                  ),
                ],
              ),
            ),
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
                ChartCard(
                  key: const Key('whereItWent'),
                  title: _income ? l.whereItCameFrom : l.whereItWent,
                  child: CategoryBars(
                    // A fresh list (folded again) when the side changes.
                    key: ValueKey(_income),
                    slices: _income ? data.earning : data.spending,
                    total: _income ? data.income : data.expense,
                    noCategoryLabel: l.noCategory,
                    onCategoryTap: (c) => _drillDown(state, c),
                  ),
                ),
                if (data.flow.length > 1) ...[
                  const SizedBox(height: AppSpacing.l),
                  ChartCard(
                    key: const Key('periodBars'),
                    title: switch (data.bucketSize) {
                      BucketSize.day => l.dayByDay,
                      BucketSize.cycle => l.monthByMonth,
                      BucketSize.year => l.yearByYear,
                    },
                    trailing: Builder(
                      builder: (context) {
                        final avg = const MoneyFormat().format(
                          PeriodBars.average(
                            data.flow,
                            income: _income,
                            currency: q.currency,
                          ),
                        );
                        return Text(
                          switch (data.bucketSize) {
                            BucketSize.day => l.avgPerDay(avg),
                            BucketSize.cycle => l.avgPerMonth(avg),
                            BucketSize.year => l.avgPerYear(avg),
                          },
                          key: const Key('periodAverage'),
                          style: context.text.bodySmall,
                        );
                      },
                    ),
                    child: PeriodBars(
                      points: data.flow,
                      size: data.bucketSize,
                      income: _income,
                    ),
                  ),
                ],
                if (balance.length > 1) ...[
                  const SizedBox(height: AppSpacing.l),
                  ChartCard(
                    title: l.balanceTrend,
                    child: BalanceTrend(points: balance, size: data.bucketSize),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Under the totals: what was written off, and what was forgiven me, in
/// the period. Apart from Spent and Income, as no money moved. Each opens
/// the list, and each name there its person.
class _WriteOffLines extends StatelessWidget {
  const _WriteOffLines(this.writeOffs);

  final List<WriteOff> writeOffs;

  Future<void> _open(
    BuildContext context,
    String title,
    List<WriteOff> ws,
  ) async {
    final personId = await pickOne<String>(
      context,
      title: title,
      searchable: false,
      items: [
        for (final w in ws)
          PickItem(
            value: w.personId,
            title: w.personName,
            subtitle: [
              context.dayLabel(w.occurredAt.toLocal()),
              if (w.note.isNotEmpty) w.note,
            ].join(' · '),
            trailing: AmountText(w.amount.abs()),
          ),
      ],
    );
    if (personId != null && context.mounted) {
      await context.push(Routes.person(personId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget line(Key key, String label, List<WriteOff> ws) {
      final total = ws.fold(
        Money.zero(ws.first.amount.currency),
        (s, w) => s + w.amount.abs(),
      );
      final people = {for (final w in ws) w.personId}.length;
      return InkWell(
        key: key,
        borderRadius: BorderRadius.circular(AppRadii.s),
        onTap: () => _open(context, label, ws),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: AppSpacing.s,
          ),
          child: Row(
            children: [
              Icon(AppIcons.writeOff, size: 16, color: context.colors.inkMuted),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  '$label · ${l.peopleCount(people)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              AmountText(total, style: context.text.titleSmall),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                AppIcons.chevronRight,
                size: 14,
                color: context.colors.inkMuted,
              ),
            ],
          ),
        ),
      );
    }

    final mine = [
      for (final w in writeOffs)
        if (!w.isForgiven) w,
    ];
    final theirs = [
      for (final w in writeOffs)
        if (w.isForgiven) w,
    ];
    return Column(
      children: [
        if (mine.isNotEmpty)
          line(const Key('reportWrittenOff'), l.writtenOff, mine),
        if (theirs.isNotEmpty)
          line(const Key('reportForgiven'), l.forgivenToYou, theirs),
      ],
    );
  }
}

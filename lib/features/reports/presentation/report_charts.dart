import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/report_period.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_format.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/chart_palette.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_badge.dart';
import '../domain/report.dart';

/// Chart geometry is display-only, so minor units become doubles here and
/// nowhere else.
double _units(Money m) => m.minor / 100;

String _money(Money m) => const MoneyFormat().format(m);

/// A titled chart card. Charts sit on the card surface the palette was
/// validated against.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: context.text.titleSmall)),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            child,
          ],
        ),
      ),
    );
  }
}

/// One donut slice: a category (or "Other") with its share.
class _Slice {
  const _Slice(
    this.label,
    this.total,
    this.color, {
    this.category,
    this.isOther = false,
  });

  final String label;
  final Money total;
  final Color color;
  final Category? category;
  final bool isOther;
}

/// Category donut + legend (spec 3.2 #8). The 7 largest categories get
/// their own slot — colour follows the category, not its rank — and the
/// rest fold into a grey "Other". Tap a slice or legend row to drill down.
class CategoryDonut extends StatefulWidget {
  const CategoryDonut({
    super.key,
    required this.slices,
    required this.total,
    required this.otherLabel,
    required this.noCategoryLabel,
    required this.onCategoryTap,
  });

  final List<CategorySlice> slices;
  final Money total;
  final String otherLabel;
  final String noCategoryLabel;
  final void Function(Category? category) onCategoryTap;

  static const int shown = 7;

  @override
  State<CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<CategoryDonut> {
  int? _touched;

  List<_Slice> _slices(BuildContext context) {
    final palette = ChartPalette.of(context);
    final top = widget.slices.take(CategoryDonut.shown).toList();
    // Stable slot from the category id, so a filter that hides one
    // category never repaints the others.
    final slots = ChartPalette.assign<CategorySlice>(
      top,
      (s) => (s.category?.id ?? 'none').codeUnits.fold(
        0,
        (h, c) => (h * 31 + c) & 0x7fffffff,
      ),
    );
    final rest = widget.slices.skip(CategoryDonut.shown);
    return [
      for (final s in top)
        _Slice(
          s.category?.name ?? widget.noCategoryLabel,
          s.total,
          palette[slots[s]!],
          category: s.category,
        ),
      if (rest.isNotEmpty)
        _Slice(
          widget.otherLabel,
          rest.fold(Money.zero(widget.total.currency), (a, b) => a + b.total),
          ChartPalette.other(context),
          isOther: true,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final slices = _slices(context);
    // Whole percent, rounded half up, in integer maths.
    int percent(Money m) => widget.total.isZero
        ? 0
        : (m.minor * 200 + widget.total.minor) ~/ (widget.total.minor * 2);
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  centerSpaceRadius: 68,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final i = response?.touchedSection?.touchedSectionIndex;
                      if (event is FlTapUpEvent && i != null && i >= 0) {
                        final s = slices[i];
                        if (!s.isOther) widget.onCategoryTap(s.category);
                      }
                      setState(
                        () => _touched = event.isInterestedForInteractions
                            ? i
                            : null,
                      );
                    },
                  ),
                  sections: [
                    for (var i = 0; i < slices.length; i++)
                      PieChartSectionData(
                        value: _units(slices[i].total),
                        color: slices[i].color,
                        radius: _touched == i ? 30 : 24,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AmountText(widget.total, style: context.text.titleLarge),
                  if (_touched != null && _touched! < slices.length)
                    Text(
                      slices[_touched!].label,
                      style: context.text.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        for (final s in slices)
          InkWell(
            key: Key('slice-${s.label}'),
            borderRadius: BorderRadius.circular(AppRadii.s),
            onTap: s.isOther ? null : () => widget.onCategoryTap(s.category),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  if (!s.isOther) ...[
                    CategoryBadge(s.category, size: 28),
                    const SizedBox(width: AppSpacing.s),
                  ],
                  Expanded(
                    child: Text(
                      s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium,
                    ),
                  ),
                  Text(
                    '${percent(s.total)}%',
                    style: context.text.bodySmall!.copyWith(
                      color: c.inkMuted,
                      fontFeatures: AppTypography.tabular,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  AmountText(s.total, style: context.text.labelLarge),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Short bucket labels for the x axis.
String bucketLabel(BucketSize size, DateTime start, String locale) =>
    switch (size) {
      BucketSize.day => DateFormat.d(locale).format(start),
      BucketSize.cycle => DateFormat.MMM(locale).format(start),
      BucketSize.year => DateFormat.y(locale).format(start),
    };

FlTitlesData _xTitles(
  BuildContext context,
  int count,
  String Function(int) label,
) {
  final every = (count / 6).ceil().clamp(1, 1000);
  final style = context.text.labelSmall!;
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: const AxisTitles(),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 22,
        interval: 1,
        getTitlesWidget: (v, meta) {
          final i = v.toInt();
          if (i < 0 || i >= count || i % every != 0) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            meta: meta,
            fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
            child: Text(label(i), style: style),
          );
        },
      ),
    ),
  );
}

/// Income vs spending per bucket: two thin rounded bars, a hairline grid,
/// a tooltip on touch, and a legend (two series).
class FlowBars extends StatelessWidget {
  const FlowBars({
    super.key,
    required this.points,
    required this.size,
    required this.incomeLabel,
    required this.spendingLabel,
  });

  final List<FlowPoint> points;
  final BucketSize size;
  final String incomeLabel;
  final String spendingLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final incomeColor = c.income;
    final spendColor = ChartPalette.of(context)[1];
    final width = points.length > 20
        ? 3.0
        : points.length > 10
        ? 5.0
        : 8.0;
    final maxY = points.fold<double>(
      0,
      (m, p) => [
        m,
        _units(p.income),
        _units(p.expense),
      ].reduce((a, b) => a > b ? a : b),
    );
    final radius = BorderRadius.vertical(top: Radius.circular(width / 2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY == 0 ? 1 : maxY * 1.1,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxY == 0 ? 1 : maxY / 3,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: c.line, strokeWidth: 1),
              ),
              titlesData: _xTitles(
                context,
                points.length,
                (i) => bucketLabel(size, points[i].bucket.start, locale),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => c.ink,
                  tooltipBorderRadius: BorderRadius.circular(AppRadii.s),
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    '${ri == 0 ? incomeLabel : spendingLabel}\n'
                    '${_money(ri == 0 ? points[gi].income : points[gi].expense)}',
                    context.text.labelMedium!.copyWith(color: c.paper),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: [
                      BarChartRodData(
                        toY: _units(points[i].income),
                        color: incomeColor,
                        width: width,
                        borderRadius: radius,
                      ),
                      BarChartRodData(
                        toY: _units(points[i].expense),
                        color: spendColor,
                        width: width,
                        borderRadius: radius,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.l,
          children: [
            _LegendDot(color: incomeColor, label: incomeLabel),
            _LegendDot(color: spendColor, label: spendingLabel),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: AppSpacing.xs + 2),
      Text(label, style: context.text.bodySmall),
    ],
  );
}

/// Balance at the end of each bucket: one 2px line (a single series needs
/// no legend — the card title names it), with a crosshair tooltip.
class BalanceTrend extends StatelessWidget {
  const BalanceTrend({super.key, required this.points, required this.size});

  final List<BalancePoint> points;
  final BucketSize size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final values = [for (final p in points) _units(p.balance)];
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final pad = (hi - lo).abs() * 0.1 + 1;
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: lo - pad,
          maxY: hi + pad,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: c.line, strokeWidth: 1),
          ),
          titlesData: _xTitles(
            context,
            points.length,
            (i) => bucketLabel(size, points[i].bucket.start, locale),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => c.ink,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    _money(points[s.x.toInt()].balance),
                    context.text.labelMedium!.copyWith(color: c.paper),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              color: c.brand,
              barWidth: 2,
              dotData: FlDotData(show: points.length == 1),
              belowBarData: BarAreaData(
                show: true,
                color: c.brand.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

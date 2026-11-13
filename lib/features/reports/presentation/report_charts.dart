import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/report_period.dart';
import '../../../core/money/currency.dart';
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

/// A short axis amount: "850", "12k", "1.2M".
String _compact(double units) {
  final v = units.abs();
  final sign = units < 0 ? '-' : '';
  String trim(double x) => x >= 10
      ? x.round().toString()
      : x.toStringAsFixed(1).replaceAll('.0', '');
  if (v >= 1e6) return '$sign${trim(v / 1e6)}M';
  if (v >= 1e3) return '$sign${trim(v / 1e3)}k';
  return '$sign${v.round()}';
}

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
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(title, style: context.text.titleSmall)),
                // Shrinks rather than pushing past the edge (Urdu, large
                // text, a narrow phone).
                if (trailing != null)
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: trailing,
                    ),
                  ),
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

/// Where the money went (or came from): one row per category, largest
/// first — its badge, name, a bar scaled to the largest, the amount and its
/// whole-percent share. The first [shown] show; "N more" opens the rest.
/// Each category keeps its chart colour (a stable slot from its id, so a
/// filter never repaints the others). Tap a row to see its entries.
class CategoryBars extends StatefulWidget {
  const CategoryBars({
    super.key,
    required this.slices,
    required this.total,
    required this.noCategoryLabel,
    required this.onCategoryTap,
  });

  final List<CategorySlice> slices;
  final Money total;
  final String noCategoryLabel;
  final void Function(Category? category) onCategoryTap;

  static const int shown = 5;

  @override
  State<CategoryBars> createState() => _CategoryBarsState();
}

class _CategoryBarsState extends State<CategoryBars> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final slices = widget.slices;
    final palette = ChartPalette.of(context);
    final slots = ChartPalette.assign<CategorySlice>(
      slices.take(ChartPalette.length).toList(),
      (s) => (s.category?.id ?? 'none').codeUnits.fold(
        0,
        (h, c) => (h * 31 + c) & 0x7fffffff,
      ),
    );
    Color colorOf(CategorySlice s) =>
        slots[s] == null ? ChartPalette.other(context) : palette[slots[s]!];
    final largest = slices.isEmpty ? 0 : slices.first.total.minor;
    // Whole percent, rounded half up, in integer maths.
    int percent(Money m) => widget.total.isZero
        ? 0
        : (m.minor * 200 + widget.total.minor) ~/ (widget.total.minor * 2);

    Widget row({
      required Key key,
      required Widget badge,
      required String name,
      required Money amount,
      required Color color,
      required VoidCallback onTap,
    }) => InkWell(
      key: key,
      borderRadius: BorderRadius.circular(AppRadii.s),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Row(
          children: [
            badge,
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: c.surfaceMuted),
                          FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: largest == 0
                                ? 0
                                : (amount.minor / largest).clamp(0.0, 1.0),
                            child: ColoredBox(color: color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            // Large text on a small phone: shrink rather than spill.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AmountText(amount, style: context.text.labelLarge),
                    Text(
                      '${percent(amount)}%',
                      style: context.text.bodySmall!.copyWith(
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final visible = _all || slices.length <= CategoryBars.shown + 1
        ? slices
        : slices.take(CategoryBars.shown).toList();
    final rest = slices.skip(visible.length).toList();
    return Column(
      children: [
        for (final s in visible)
          row(
            key: Key('slice-${s.category?.name ?? widget.noCategoryLabel}'),
            badge: CategoryBadge(s.category, size: 32),
            name: s.category?.name ?? widget.noCategoryLabel,
            amount: s.total,
            color: colorOf(s),
            onTap: () => widget.onCategoryTap(s.category),
          ),
        if (rest.isNotEmpty)
          row(
            key: const Key('moreCategories'),
            badge: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(32 * 0.32),
              ),
              child: Text(
                '+${rest.length}',
                style: context.text.labelMedium!.copyWith(color: c.inkMuted),
              ),
            ),
            name: l.moreCategories(rest.length),
            amount: rest.fold(
              Money.zero(widget.total.currency),
              (a, s) => a + s.total,
            ),
            color: ChartPalette.other(context),
            onTap: () => setState(() => _all = true),
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

/// Bucket names along the bottom (about six of them) and short amounts
/// up the side at each grid line.
FlTitlesData _titles(
  BuildContext context,
  int count,
  String Function(int) label, {
  required double interval,
}) {
  final every = (count / 6).ceil().clamp(1, 1000);
  final style = context.text.labelSmall!;
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        interval: interval,
        getTitlesWidget: (v, meta) => SideTitleWidget(
          meta: meta,
          child: Text(_compact(v), style: style, maxLines: 1, softWrap: false),
        ),
      ),
    ),
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

/// A grid step that lands on round numbers (1, 2 or 5 × a power of ten),
/// about three lines high.
double _step(double max) {
  if (max <= 0) return 1;
  final raw = max / 3;
  var p = 1.0;
  while (p * 10 <= raw) {
    p *= 10;
  }
  for (final m in [1, 2, 5, 10]) {
    if (p * m >= raw) return p * m;
  }
  return p * 10;
}

/// One side of the money per bucket — spending, or income — as rounded
/// bars, with a dashed line at the average and amounts up the side. One
/// series at a time, so a salary never flattens the spending.
class PeriodBars extends StatelessWidget {
  const PeriodBars({
    super.key,
    required this.points,
    required this.size,
    required this.income,
  });

  final List<FlowPoint> points;
  final BucketSize size;

  /// Income instead of spending.
  final bool income;

  Money valueOf(FlowPoint p) => income ? p.income : p.expense;

  /// The average bucket (only the buckets charted, so a month in progress
  /// is averaged over its days so far).
  static Money average(
    List<FlowPoint> points, {
    required bool income,
    required Currency currency,
  }) {
    if (points.isEmpty) return Money.zero(currency);
    final total = points.fold<int>(
      0,
      (s, p) => s + (income ? p.income : p.expense).minor,
    );
    // Whole rupees: an average to the paisa is false precision.
    final unit = [
      for (var i = 0; i < currency.decimals; i++) 10,
    ].fold(1, (a, b) => a * b);
    return Money((total / points.length / unit).round() * unit, currency);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final color = income ? c.income : ChartPalette.of(context)[1];
    final width = points.length > 20
        ? 5.0
        : points.length > 10
        ? 8.0
        : 14.0;
    final values = [for (final p in points) _units(valueOf(p))];
    final maxY = values.fold<double>(0, (m, v) => v > m ? v : m);
    final step = _step(maxY);
    final top = maxY == 0 ? 1.0 : (maxY / step).ceil() * step;
    final avg = _units(
      average(points, income: income, currency: valueOf(points.first).currency),
    );
    final radius = BorderRadius.vertical(top: Radius.circular(width / 2));
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: top,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: step,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: c.line, strokeWidth: 1),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (avg > 0)
                HorizontalLine(
                  y: avg,
                  color: c.inkMuted,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
            ],
          ),
          titlesData: _titles(
            context,
            points.length,
            (i) => bucketLabel(size, points[i].bucket.start, locale),
            interval: step,
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => c.ink,
              tooltipBorderRadius: BorderRadius.circular(AppRadii.s),
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${bucketLabel(size, points[gi].bucket.start, locale)}\n'
                '${_money(valueOf(points[gi]))}',
                context.text.labelMedium!.copyWith(color: c.paper),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    color: color,
                    width: width,
                    borderRadius: radius,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Balance at the end of each bucket: one 2px line (a single series needs
/// no legend — the card title names it), amounts up the side, with a
/// crosshair tooltip.
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
    final step = _step((hi - lo).abs() == 0 ? hi.abs() : (hi - lo).abs());
    final minY = (lo / step).floor() * step;
    final maxY = (hi / step).ceil() * step == minY
        ? minY + step
        : (hi / step).ceil() * step;
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: step,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: c.line, strokeWidth: 1),
          ),
          titlesData: _titles(
            context,
            points.length,
            (i) => bucketLabel(size, points[i].bucket.start, locale),
            interval: step,
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

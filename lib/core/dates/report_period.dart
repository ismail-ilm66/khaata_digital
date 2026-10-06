import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import 'budget_cycle.dart';
import 'date_range.dart';

enum PeriodKind { day, week, month, year, custom, all }

/// How a period is split for the bar and trend charts.
enum BucketSize { day, cycle, year }

/// A reporting window (spec 1.5 #4): Day / Week / Month / Year / Custom /
/// All time, with no history cap. "Month" is the budget cycle and "Year"
/// is twelve cycles, so a salary-date month start applies here too.
@immutable
class ReportPeriod {
  const ReportPeriod._(this.kind, this.anchor, this.custom);

  ReportPeriod.day(DateTime local) : this._(PeriodKind.day, _day(local), null);
  ReportPeriod.week(DateTime local)
    : this._(PeriodKind.week, _day(local), null);
  ReportPeriod.month(DateTime local)
    : this._(PeriodKind.month, _day(local), null);
  ReportPeriod.year(DateTime local)
    : this._(PeriodKind.year, _day(local), null);
  const ReportPeriod.all() : this._(PeriodKind.all, null, null);

  /// Inclusive of both calendar days.
  ReportPeriod.custom(DateTime firstDay, DateTime lastDay)
    : this._(
        PeriodKind.custom,
        null,
        DateRange(_day(firstDay), _day(lastDay).add(const Duration(days: 1))),
      );

  final PeriodKind kind;

  /// A local day inside the period (null for custom / all).
  final DateTime? anchor;
  final DateRange? custom;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The window, or null for all time.
  DateRange? range(BudgetCycle cycle) {
    final a = anchor;
    switch (kind) {
      case PeriodKind.day:
        return DateRange(a!, DateTime(a.year, a.month, a.day + 1));
      case PeriodKind.week:
        final monday = DateTime(
          a!.year,
          a.month,
          a.day - (a.weekday - DateTime.monday),
        );
        return DateRange(
          monday,
          DateTime(monday.year, monday.month, monday.day + 7),
        );
      case PeriodKind.month:
        return cycle.rangeFor(a!);
      case PeriodKind.year:
        final year = cycle.idFor(a!).year;
        return DateRange(
          cycle.rangeOf(CycleId(year, 1)).start,
          cycle.rangeOf(CycleId(year + 1, 1)).start,
        );
      case PeriodKind.custom:
        return custom;
      case PeriodKind.all:
        return null;
    }
  }

  /// The same kind of period one step earlier / later (custom and all
  /// don't step).
  ReportPeriod shift(int steps, BudgetCycle cycle) {
    final a = anchor;
    if (a == null) return this;
    return switch (kind) {
      PeriodKind.day => ReportPeriod.day(
        DateTime(a.year, a.month, a.day + steps),
      ),
      PeriodKind.week => ReportPeriod.week(
        DateTime(a.year, a.month, a.day + 7 * steps),
      ),
      PeriodKind.month => ReportPeriod.month(
        cycle.rangeOf(_cycleStep(cycle.idFor(a), steps)).start,
      ),
      PeriodKind.year => ReportPeriod.year(
        cycle.rangeOf(CycleId(cycle.idFor(a).year + steps, 1)).start,
      ),
      _ => this,
    };
  }

  static CycleId _cycleStep(CycleId id, int steps) {
    var c = id;
    for (var i = 0; i < steps.abs(); i++) {
      c = steps > 0 ? c.next : c.previous;
    }
    return c;
  }

  bool get canStep => anchor != null;

  /// Bucket size for charts over [span] (the period's range, or the data's
  /// extent for all time).
  static BucketSize bucketFor(DateRange span) {
    final days = span.end.difference(span.start).inDays;
    if (days <= 62) return BucketSize.day;
    if (days <= 3 * 366) return BucketSize.cycle;
    return BucketSize.year;
  }

  /// Consecutive buckets covering [span].
  static List<DateRange> buckets(
    DateRange span,
    BucketSize size,
    BudgetCycle cycle,
  ) {
    final out = <DateRange>[];
    switch (size) {
      case BucketSize.day:
        for (
          var d = span.start;
          d.isBefore(span.end);
          d = DateTime(d.year, d.month, d.day + 1)
        ) {
          out.add(DateRange(d, DateTime(d.year, d.month, d.day + 1)));
        }
      case BucketSize.cycle:
        for (
          var id = cycle.idFor(span.start);
          cycle.rangeOf(id).start.isBefore(span.end);
          id = id.next
        ) {
          out.add(cycle.rangeOf(id));
        }
      case BucketSize.year:
        for (
          var y = cycle.idFor(span.start).year;
          cycle.rangeOf(CycleId(y, 1)).start.isBefore(span.end);
          y++
        ) {
          out.add(
            DateRange(
              cycle.rangeOf(CycleId(y, 1)).start,
              cycle.rangeOf(CycleId(y + 1, 1)).start,
            ),
          );
        }
    }
    return out;
  }

  /// "Mon, 6 Oct" · "6 – 12 Oct" · "25 Sep – 24 Oct" · "2026" · custom ·
  /// [allTime] for all.
  /// "25 Sep – 6 Oct": a date range ends at [today] while the period is
  /// still in progress (and [through], the last day with entries, if that
  /// is later). Calendar months, days and years keep their own names.
  String label(
    BudgetCycle cycle, {
    required String allTime,
    String? locale,
    DateTime? today,
    DateTime? through,
  }) {
    final r = range(cycle);
    if (r == null) return allTime;
    final short = DateFormat('d MMM', locale);
    String span() {
      var last = r.lastDay;
      if (today != null && r.contains(today)) {
        final day = DateTime(today.year, today.month, today.day);
        final upTo = through != null && through.isAfter(day) ? through : day;
        if (upTo.isBefore(last)) {
          last = DateTime(upTo.year, upTo.month, upTo.day);
        }
      }
      return '${short.format(r.start)} – ${short.format(last)}';
    }

    return switch (kind) {
      PeriodKind.day => DateFormat.MMMEd(locale).format(r.start),
      PeriodKind.month when cycle.isCalendar => cycle.label(
        cycle.idFor(r.start),
        locale: locale,
      ),
      PeriodKind.year => '${cycle.idFor(anchor!).year}',
      _ => span(),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod &&
      other.kind == kind &&
      other.anchor == anchor &&
      other.custom == custom;

  @override
  int get hashCode => Object.hash(kind, anchor, custom);
}

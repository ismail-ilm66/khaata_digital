import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import 'date_range.dart';

/// Identifies one budget cycle by the calendar month it **starts** in.
/// With a start day of 25, cycle 2026-09 runs 25 Sep – 24 Oct.
@immutable
class CycleId implements Comparable<CycleId> {
  const CycleId(this.year, this.month)
    : assert(month >= 1 && month <= 12, 'month must be 1–12');

  final int year;
  final int month;

  CycleId get next =>
      month == 12 ? CycleId(year + 1, 1) : CycleId(year, month + 1);
  CycleId get previous =>
      month == 1 ? CycleId(year - 1, 12) : CycleId(year, month - 1);

  @override
  int compareTo(CycleId other) => year != other.year
      ? year.compareTo(other.year)
      : month.compareTo(other.month);

  @override
  bool operator ==(Object other) =>
      other is CycleId && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// The single source of truth for month-cycle date math (spec 3.4).
///
/// A cycle starts at local midnight on its month's start date and ends
/// just before the next month's. The start date is either a fixed day
/// ([startDay], 1–28, so every month has it — no clamping, no drift) or
/// the month's **last working day** (the last Monday–Friday), for salaries
/// credited that way.
@immutable
class BudgetCycle {
  const BudgetCycle(int this.startDay)
    : assert(startDay >= minStartDay && startDay <= maxStartDay);

  /// Calendar months.
  const BudgetCycle.calendar() : startDay = 1;

  /// Starts on the last Monday–Friday of each month. Public holidays are
  /// not considered.
  const BudgetCycle.lastWorkingDay() : startDay = null;

  static const int minStartDay = 1;
  static const int maxStartDay = 28;

  /// Fixed start day, or null for [BudgetCycle.lastWorkingDay].
  final int? startDay;

  bool get isLastWorkingDay => startDay == null;
  bool get isCalendar => startDay == 1;

  /// Local midnight on which the cycle starting in [year]-[month] begins.
  DateTime startIn(int year, int month) {
    final day = startDay;
    if (day != null) return DateTime(year, month, day);
    var d = DateTime(year, month + 1, 0); // last day of the month
    while (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return d;
  }

  /// The cycle containing [moment] (interpreted in local time).
  CycleId idFor(DateTime moment) {
    final local = moment.toLocal();
    final id = CycleId(local.year, local.month);
    return local.isBefore(startIn(id.year, id.month)) ? id.previous : id;
  }

  /// The date range covered by cycle [id].
  DateRange rangeOf(CycleId id) => DateRange(
    startIn(id.year, id.month),
    startIn(id.next.year, id.next.month),
  );

  /// The date range of the cycle containing [moment].
  DateRange rangeFor(DateTime moment) => rangeOf(idFor(moment));

  /// "25 Sep – 24 Oct", or "Sep 2026" for calendar months.
  String label(CycleId id, {String? locale}) {
    final range = rangeOf(id);
    if (isCalendar) return DateFormat.yMMM(locale).format(range.start);
    final f = DateFormat('d MMM', locale);
    return '${f.format(range.start)} – ${f.format(range.lastDay)}';
  }

  /// The `month_start_day` setting: "25", or "last-working".
  String toStorage() => startDay?.toString() ?? _lastWorking;

  /// Reads [toStorage]; anything unrecognised means calendar months.
  static BudgetCycle fromStorage(String stored) {
    if (stored == _lastWorking) return const BudgetCycle.lastWorkingDay();
    final day = int.tryParse(stored);
    return day != null && day >= minStartDay && day <= maxStartDay
        ? BudgetCycle(day)
        : const BudgetCycle.calendar();
  }

  static const String _lastWorking = 'last-working';

  /// Every choice offered in settings: day 1–28, then the last working day.
  static List<BudgetCycle> get choices => [
    for (var d = minStartDay; d <= maxStartDay; d++) BudgetCycle(d),
    const BudgetCycle.lastWorkingDay(),
  ];

  @override
  bool operator ==(Object other) =>
      other is BudgetCycle && other.startDay == startDay;

  @override
  int get hashCode => startDay.hashCode;
}

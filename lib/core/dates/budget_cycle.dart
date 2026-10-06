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
/// A cycle starts at local midnight on [startDay] and ends just before
/// [startDay] of the next month. [startDay] is limited to 1–28 so every
/// month contains it — no clamping, no drifting cycles.
@immutable
class BudgetCycle {
  const BudgetCycle(this.startDay)
    : assert(startDay >= minStartDay && startDay <= maxStartDay);

  /// Calendar months.
  const BudgetCycle.calendar() : startDay = 1;

  static const int minStartDay = 1;
  static const int maxStartDay = 28;

  final int startDay;

  /// The cycle containing [moment] (interpreted in local time).
  CycleId idFor(DateTime moment) {
    final local = moment.toLocal();
    final id = CycleId(local.year, local.month);
    return local.day >= startDay ? id : id.previous;
  }

  /// The date range covered by cycle [id].
  DateRange rangeOf(CycleId id) => DateRange(
    DateTime(id.year, id.month, startDay),
    DateTime(id.year, id.month + 1, startDay),
  );

  /// The date range of the cycle containing [moment].
  DateRange rangeFor(DateTime moment) => rangeOf(idFor(moment));

  /// "25 Sep – 24 Oct", or "Sep 2026" for calendar months.
  String label(CycleId id, {String? locale}) {
    final range = rangeOf(id);
    if (startDay == 1) return DateFormat.yMMM(locale).format(range.start);
    final f = DateFormat('d MMM', locale);
    return '${f.format(range.start)} – ${f.format(range.lastDay)}';
  }

  @override
  bool operator ==(Object other) =>
      other is BudgetCycle && other.startDay == startDay;

  @override
  int get hashCode => startDay.hashCode;
}

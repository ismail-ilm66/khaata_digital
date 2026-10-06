import 'package:meta/meta.dart';

import '../../features/recurring/domain/recurrence.dart';

/// When a repeating entry falls due. Occurrences are counted from [start]
/// so a monthly rule anchored on the 31st clamps to the 30th / 28th / 29th
/// in short months and returns to the 31st afterwards — it never drifts
/// (spec complaint #7, month-end-safe).
@immutable
class RecurrenceSchedule {
  const RecurrenceSchedule({
    required this.start,
    required this.frequency,
    this.interval = 1,
    this.end,
  }) : assert(interval >= 1);

  /// Local time of the first occurrence.
  final DateTime start;
  final RecurrenceFrequency frequency;
  final int interval;

  /// Local time; no occurrences after it.
  final DateTime? end;

  /// The [n]th occurrence (0 = [start]), clamped to the month's last day.
  DateTime occurrence(int n) {
    final step = n * interval;
    final s = start;
    return switch (frequency) {
      RecurrenceFrequency.daily => DateTime(
        s.year,
        s.month,
        s.day + step,
        s.hour,
        s.minute,
      ),
      RecurrenceFrequency.weekly => DateTime(
        s.year,
        s.month,
        s.day + 7 * step,
        s.hour,
        s.minute,
      ),
      RecurrenceFrequency.monthly => _clamped(s.year, s.month + step, s),
      RecurrenceFrequency.yearly => _clamped(s.year + step, s.month, s),
    };
  }

  static DateTime _clamped(int year, int month, DateTime anchor) {
    final first = DateTime(year, month);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    final day = anchor.day <= lastDay ? anchor.day : lastDay;
    return DateTime(first.year, first.month, day, anchor.hour, anchor.minute);
  }

  /// The first occurrence strictly after [after], or null past [end].
  DateTime? nextAfter(DateTime after) {
    // Jump close to [after], then step — fast even for old daily rules.
    var n = _estimate(after);
    while (n > 0 && occurrence(n - 1).isAfter(after)) {
      n--;
    }
    while (!occurrence(n).isAfter(after)) {
      n++;
    }
    final next = occurrence(n);
    return end != null && next.isAfter(end!) ? null : next;
  }

  /// Every occurrence in `(after, until]`, in order — what a materializer
  /// must create when the app catches up.
  List<DateTime> dueBetween(DateTime after, DateTime until) {
    final out = <DateTime>[];
    var next = nextAfter(after);
    while (next != null && !next.isAfter(until)) {
      out.add(next);
      next = nextAfter(next);
    }
    return out;
  }

  int _estimate(DateTime after) {
    if (!after.isAfter(start)) return 0;
    final days = after.difference(start).inDays;
    final units = switch (frequency) {
      RecurrenceFrequency.daily => days,
      RecurrenceFrequency.weekly => days ~/ 7,
      RecurrenceFrequency.monthly => days ~/ 31,
      RecurrenceFrequency.yearly => days ~/ 366,
    };
    return units ~/ interval;
  }
}

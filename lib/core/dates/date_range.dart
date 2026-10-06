import 'package:meta/meta.dart';

/// A half-open range of local time: [start] inclusive, [end] exclusive.
@immutable
class DateRange {
  DateRange(this.start, this.end)
    : assert(!end.isBefore(start), 'end must not precede start');

  final DateTime start;
  final DateTime end;

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  /// The last calendar day inside the range (for "25 Sep – 24 Oct" labels).
  DateTime get lastDay {
    final d = end.subtract(const Duration(days: 1));
    return DateTime(d.year, d.month, d.day);
  }

  /// Epoch-millisecond bounds for database queries.
  int get startMillis => start.millisecondsSinceEpoch;
  int get endMillis => end.millisecondsSinceEpoch;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start – $end)';
}

import 'package:meta/meta.dart';

/// A date with no time of day, such as when something is due. Stored as
/// UTC midnight of that date, so it never moves when the phone's time zone
/// changes.
@immutable
class CalendarDay implements Comparable<CalendarDay> {
  const CalendarDay(this.year, this.month, this.day);

  /// The day [local] falls on, on this phone.
  factory CalendarDay.of(DateTime local) =>
      CalendarDay(local.year, local.month, local.day);

  factory CalendarDay.fromStorage(DateTime utc) =>
      CalendarDay(utc.year, utc.month, utc.day);

  final int year;
  final int month;
  final int day;

  DateTime toStorage() => DateTime.utc(year, month, day);

  /// Local midnight, for date pickers and labels.
  DateTime toLocal() => DateTime(year, month, day);

  bool isBefore(CalendarDay other) => compareTo(other) < 0;

  @override
  int compareTo(CalendarDay other) => toStorage().compareTo(other.toStorage());

  @override
  bool operator ==(Object other) =>
      other is CalendarDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '$year-${'$month'.padLeft(2, '0')}-${'$day'.padLeft(2, '0')}';
}

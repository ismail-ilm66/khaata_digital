import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/recurrence.dart';
import 'package:khaata_digital/features/recurring/domain/recurrence.dart';

RecurrenceSchedule monthly(DateTime start, {int interval = 1, DateTime? end}) =>
    RecurrenceSchedule(
      start: start,
      frequency: RecurrenceFrequency.monthly,
      interval: interval,
      end: end,
    );

void main() {
  group('monthly on the 31st clamps and never drifts (M3 acceptance)', () {
    final rule = monthly(DateTime(2026, 1, 31, 9));

    test(
      'clamps to the last day of short months, then returns to the 31st',
      () {
        expect(
          [for (var n = 0; n < 6; n++) rule.occurrence(n)],
          [
            DateTime(2026, 1, 31, 9),
            DateTime(2026, 2, 28, 9),
            DateTime(2026, 3, 31, 9),
            DateTime(2026, 4, 30, 9),
            DateTime(2026, 5, 31, 9),
            DateTime(2026, 6, 30, 9),
          ],
        );
      },
    );

    test('leap-year February gets the 29th', () {
      expect(
        monthly(DateTime(2028, 1, 31)).occurrence(1),
        DateTime(2028, 2, 29),
      );
    });

    test('rolls over the year', () {
      expect(
        monthly(DateTime(2026, 11, 30)).occurrence(3),
        DateTime(2027, 2, 28),
      );
    });

    test('the 29th and 30th clamp only in February', () {
      final r = monthly(DateTime(2026, 1, 30));
      expect(r.occurrence(1), DateTime(2026, 2, 28));
      expect(r.occurrence(2), DateTime(2026, 3, 30));
    });
  });

  test('yearly on 29 Feb falls on 28 Feb in common years', () {
    final r = RecurrenceSchedule(
      start: DateTime(2024, 2, 29),
      frequency: RecurrenceFrequency.yearly,
    );
    expect(r.occurrence(1), DateTime(2025, 2, 28));
    expect(r.occurrence(4), DateTime(2028, 2, 29));
  });

  test('daily and weekly step by calendar days', () {
    final d = RecurrenceSchedule(
      start: DateTime(2026, 2, 27, 8),
      frequency: RecurrenceFrequency.daily,
    );
    expect(d.occurrence(2), DateTime(2026, 3, 1, 8));
    final w = RecurrenceSchedule(
      start: DateTime(2026, 12, 28),
      frequency: RecurrenceFrequency.weekly,
      interval: 2,
    );
    expect(w.occurrence(1), DateTime(2027, 1, 11));
  });

  group('nextAfter / dueBetween', () {
    final rule = monthly(DateTime(2026, 1, 31, 9));

    test('next is strictly after the given moment', () {
      expect(
        rule.nextAfter(DateTime(2026, 1, 31, 9)),
        DateTime(2026, 2, 28, 9),
      );
      expect(rule.nextAfter(DateTime(2026, 1, 1)), DateTime(2026, 1, 31, 9));
      expect(rule.nextAfter(DateTime(2026, 4, 15)), DateTime(2026, 4, 30, 9));
    });

    test('catching up after weeks offline returns every missed occurrence', () {
      expect(rule.dueBetween(DateTime(2026, 1, 31, 9), DateTime(2026, 5, 1)), [
        DateTime(2026, 2, 28, 9),
        DateTime(2026, 3, 31, 9),
        DateTime(2026, 4, 30, 9),
      ]);
    });

    test('respects the end date', () {
      final ending = monthly(DateTime(2026, 1, 31), end: DateTime(2026, 3, 1));
      expect(ending.nextAfter(DateTime(2026, 2, 28)), isNull);
      expect(
        ending.dueBetween(DateTime(2025, 12, 1), DateTime(2027)),
        hasLength(2),
      );
    });

    test('stays fast for an old daily rule', () {
      final daily = RecurrenceSchedule(
        start: DateTime(2000),
        frequency: RecurrenceFrequency.daily,
      );
      final sw = Stopwatch()..start();
      expect(daily.nextAfter(DateTime(2026, 10, 6, 12)), DateTime(2026, 10, 7));
      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });
}

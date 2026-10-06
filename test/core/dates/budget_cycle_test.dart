import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';

/// Calendar days between two local dates, immune to DST shifts.
int calendarDays(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('BudgetCycle(25) — salary on the 25th', () {
    const cycle = BudgetCycle(25);

    test('a date on/after the 25th belongs to that month\'s cycle', () {
      expect(cycle.idFor(DateTime(2026, 9, 25)), const CycleId(2026, 9));
      expect(cycle.idFor(DateTime(2026, 10, 6)), const CycleId(2026, 9));
      expect(
        cycle.idFor(DateTime(2026, 10, 24, 23, 59, 59)),
        const CycleId(2026, 9),
      );
      expect(cycle.idFor(DateTime(2026, 10, 25)), const CycleId(2026, 10));
    });

    test('range is [25 Sep 00:00, 25 Oct 00:00)', () {
      final r = cycle.rangeOf(const CycleId(2026, 9));
      expect(r.start, DateTime(2026, 9, 25));
      expect(r.end, DateTime(2026, 10, 25));
      expect(r.lastDay, DateTime(2026, 10, 24));
      expect(r.contains(DateTime(2026, 10, 24, 23, 59)), isTrue);
      expect(r.contains(DateTime(2026, 10, 25)), isFalse);
      expect(r.contains(DateTime(2026, 9, 24, 23, 59)), isFalse);
    });

    test('label matches spec 3.2: "25 Sep – 24 Oct"', () {
      expect(
        cycle.label(const CycleId(2026, 9), locale: 'en'),
        '25 Sep – 24 Oct',
      );
    });

    test(
      'February in a leap year (2024): 25 Jan – 24 Feb, 25 Feb – 24 Mar',
      () {
        expect(cycle.idFor(DateTime(2024, 2, 24)), const CycleId(2024, 1));
        expect(cycle.idFor(DateTime(2024, 2, 29)), const CycleId(2024, 2));
        final feb = cycle.rangeOf(const CycleId(2024, 2));
        expect(feb.start, DateTime(2024, 2, 25));
        expect(feb.end, DateTime(2024, 3, 25));
        expect(calendarDays(feb.start, feb.end), 29);
      },
    );

    test('February in a common year (2025) is 28 days long', () {
      final feb = cycle.rangeOf(const CycleId(2025, 2));
      expect(calendarDays(feb.start, feb.end), 28);
      expect(cycle.idFor(DateTime(2025, 3, 1)), const CycleId(2025, 2));
    });

    test('rolls over the year boundary', () {
      expect(cycle.idFor(DateTime(2027, 1, 10)), const CycleId(2026, 12));
      final dec = cycle.rangeOf(const CycleId(2026, 12));
      expect(dec.start, DateTime(2026, 12, 25));
      expect(dec.end, DateTime(2027, 1, 25));
      expect(
        cycle.label(const CycleId(2026, 12), locale: 'en'),
        '25 Dec – 24 Jan',
      );
    });

    test('consecutive cycles tile time with no gaps or overlaps', () {
      var id = const CycleId(2023, 11);
      for (var i = 0; i < 40; i++) {
        expect(cycle.rangeOf(id).end, cycle.rangeOf(id.next).start);
        id = id.next;
      }
    });

    test(
      'every day of a leap year maps to the cycle whose range contains it',
      () {
        for (
          var d = DateTime(2024);
          d.year == 2024;
          d = DateTime(d.year, d.month, d.day + 1)
        ) {
          expect(cycle.rangeFor(d).contains(d), isTrue, reason: '$d');
        }
      },
    );
  });

  group('BudgetCycle.calendar()', () {
    const cycle = BudgetCycle.calendar();

    test('equals calendar months', () {
      expect(cycle.idFor(DateTime(2026, 2, 28)), const CycleId(2026, 2));
      final feb = cycle.rangeOf(const CycleId(2024, 2));
      expect(feb.start, DateTime(2024, 2));
      expect(feb.end, DateTime(2024, 3));
      expect(cycle.label(const CycleId(2026, 9), locale: 'en'), 'Sep 2026');
    });
  });

  group('BudgetCycle(28) — latest allowed start', () {
    const cycle = BudgetCycle(28);

    test('Feb 28 starts a cycle in both leap and common years', () {
      expect(cycle.idFor(DateTime(2025, 2, 28)), const CycleId(2025, 2));
      expect(cycle.idFor(DateTime(2024, 2, 29)), const CycleId(2024, 2));
      expect(cycle.idFor(DateTime(2025, 3, 27)), const CycleId(2025, 2));
    });
  });

  test('UTC timestamps are bucketed by local date', () {
    const cycle = BudgetCycle(25);
    final local = DateTime(2026, 10, 25, 0, 30);
    expect(cycle.idFor(local.toUtc()), const CycleId(2026, 10));
  });

  group('BudgetCycle.lastWorkingDay() — salary on the last working day', () {
    const cycle = BudgetCycle.lastWorkingDay();
    // Worked out on a calendar (weekends are Saturday and Sunday).

    test('starts on the last Monday–Friday of each month', () {
      expect(cycle.startIn(2026, 9), DateTime(2026, 9, 30)); // Wednesday
      expect(cycle.startIn(2026, 10), DateTime(2026, 10, 30)); // 31st: Sat
      expect(cycle.startIn(2026, 8), DateTime(2026, 8, 31)); // Monday
      expect(cycle.startIn(2026, 12), DateTime(2026, 12, 31)); // Thursday
      expect(cycle.startIn(2027, 1), DateTime(2027, 1, 29)); // 31st: Sun
      expect(cycle.startIn(2027, 2), DateTime(2027, 2, 26)); // 28th: Sun
      expect(cycle.startIn(2028, 2), DateTime(2028, 2, 29)); // leap, Tue
    });

    test('a day belongs to the cycle that started on or before it', () {
      expect(
        cycle.idFor(DateTime(2026, 9, 29, 23, 59)),
        const CycleId(2026, 8),
      );
      expect(cycle.idFor(DateTime(2026, 9, 30)), const CycleId(2026, 9));
      expect(
        cycle.idFor(DateTime(2026, 10, 29, 23, 59)),
        const CycleId(2026, 9),
      );
      expect(cycle.idFor(DateTime(2026, 10, 30)), const CycleId(2026, 10));
    });

    test('range runs to the next last working day; label shows real dates', () {
      final r = cycle.rangeOf(const CycleId(2026, 9));
      expect(r.start, DateTime(2026, 9, 30));
      expect(r.end, DateTime(2026, 10, 30));
      expect(cycle.label(const CycleId(2026, 9)), '30 Sep – 29 Oct');
    });

    test('rolls over the year boundary', () {
      expect(cycle.idFor(DateTime(2027, 1, 10)), const CycleId(2026, 12));
      final r = cycle.rangeOf(const CycleId(2026, 12));
      expect(r.start, DateTime(2026, 12, 31));
      expect(r.end, DateTime(2027, 1, 29));
    });

    test(
      'three years of cycles tile with no gaps; each starts on a weekday',
      () {
        var id = const CycleId(2026, 1);
        for (var i = 0; i < 36; i++) {
          final r = cycle.rangeOf(id);
          expect(r.end, cycle.rangeOf(id.next).start);
          expect(r.start.weekday, lessThanOrEqualTo(DateTime.friday));
          expect(r.start.month, id.month);
          // No weekday comes after it in the same month.
          for (
            var d = r.start.add(const Duration(days: 1));
            d.month == id.month;
            d = d.add(const Duration(days: 1))
          ) {
            expect(d.weekday, greaterThan(DateTime.friday));
          }
          id = id.next;
        }
      },
    );
  });

  group('storage', () {
    test('round-trips every choice', () {
      for (final c in BudgetCycle.choices) {
        expect(BudgetCycle.fromStorage(c.toStorage()), c);
      }
      expect(BudgetCycle.choices, hasLength(28 + 1));
    });

    test('reads existing day values and rejects garbage', () {
      expect(BudgetCycle.fromStorage('25'), const BudgetCycle(25));
      expect(
        BudgetCycle.fromStorage('last-working'),
        const BudgetCycle.lastWorkingDay(),
      );
      for (final bad in ['', '0', '29', 'last-5', 'last', 'x']) {
        expect(BudgetCycle.fromStorage(bad), const BudgetCycle.calendar());
      }
    });
  });

  group('CycleId', () {
    test('next/previous wrap years', () {
      expect(const CycleId(2026, 12).next, const CycleId(2027, 1));
      expect(const CycleId(2026, 1).previous, const CycleId(2025, 12));
    });

    test('orders chronologically', () {
      final ids = [
        const CycleId(2026, 1),
        const CycleId(2025, 12),
        const CycleId(2026, 2),
      ]..sort();
      expect(ids, [
        const CycleId(2025, 12),
        const CycleId(2026, 1),
        const CycleId(2026, 2),
      ]);
    });
  });
}

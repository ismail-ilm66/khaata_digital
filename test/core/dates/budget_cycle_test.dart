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

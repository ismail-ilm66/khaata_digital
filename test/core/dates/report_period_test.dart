import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/dates/date_range.dart';
import 'package:khaata_digital/core/dates/report_period.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));
  const calendar = BudgetCycle.calendar();
  const salary25 = BudgetCycle(25);
  final tue = DateTime(2026, 10, 6, 15); // a Tuesday

  test('day', () {
    final r = ReportPeriod.day(tue).range(calendar)!;
    expect(r, DateRange(DateTime(2026, 10, 6), DateTime(2026, 10, 7)));
  });

  test('week runs Monday to Sunday', () {
    final r = ReportPeriod.week(tue).range(calendar)!;
    expect(r.start, DateTime(2026, 10, 5));
    expect(r.end, DateTime(2026, 10, 12));
  });

  test('month is the budget cycle', () {
    expect(
      ReportPeriod.month(tue).range(salary25)!.start,
      DateTime(2026, 9, 25),
    );
    expect(ReportPeriod.month(tue).range(calendar)!.start, DateTime(2026, 10));
  });

  test('year is twelve cycles', () {
    final r = ReportPeriod.year(tue).range(salary25)!;
    expect(r.start, DateTime(2026, 1, 25));
    expect(r.end, DateTime(2027, 1, 25));
    final early = ReportPeriod.year(DateTime(2026, 1, 10)).range(salary25)!;
    expect(
      early.start,
      DateTime(2025, 1, 25),
      reason: '10 Jan is in the Dec 2025 cycle',
    );
  });

  test('custom includes both days', () {
    final r = ReportPeriod.custom(
      DateTime(2026, 7, 1),
      DateTime(2026, 7, 15),
    ).range(calendar)!;
    expect(r.end, DateTime(2026, 7, 16));
  });

  test('all time has no range and no stepping', () {
    expect(const ReportPeriod.all().range(calendar), isNull);
    expect(const ReportPeriod.all().canStep, isFalse);
  });

  test('stepping moves by whole periods, across years', () {
    expect(
      ReportPeriod.week(tue).shift(-1, calendar).range(calendar)!.start,
      DateTime(2026, 9, 28),
    );
    final dec = ReportPeriod.month(DateTime(2026, 12, 30)).shift(1, salary25);
    expect(dec.range(salary25)!.start, DateTime(2027, 1, 25));
    expect(
      ReportPeriod.year(tue).shift(-1, calendar).range(calendar)!.start,
      DateTime(2025),
    );
  });

  group('buckets', () {
    test('size by span: days ≤ 62, cycles ≤ 3 years, then years', () {
      expect(
        ReportPeriod.bucketFor(DateRange(DateTime(2026), DateTime(2026, 3))),
        BucketSize.day,
      );
      expect(
        ReportPeriod.bucketFor(DateRange(DateTime(2026), DateTime(2027))),
        BucketSize.cycle,
      );
      expect(
        ReportPeriod.bucketFor(DateRange(DateTime(2018), DateTime(2027))),
        BucketSize.year,
      );
    });

    test('tile the span exactly', () {
      final span = ReportPeriod.year(tue).range(salary25)!;
      final b = ReportPeriod.buckets(span, BucketSize.cycle, salary25);
      expect(b, hasLength(12));
      expect(b.first.start, span.start);
      expect(b.last.end, span.end);
      for (var i = 1; i < b.length; i++) {
        expect(b[i].start, b[i - 1].end);
      }
    });

    test('daily buckets for a week', () {
      final b = ReportPeriod.buckets(
        ReportPeriod.week(tue).range(calendar)!,
        BucketSize.day,
        calendar,
      );
      expect(b, hasLength(7));
    });
  });

  test('labels', () {
    String label(ReportPeriod p, BudgetCycle c) =>
        p.label(c, allTime: 'All time', locale: 'en');
    expect(label(ReportPeriod.month(tue), salary25), '25 Sep – 24 Oct');
    expect(label(ReportPeriod.week(tue), calendar), '5 Oct – 11 Oct');
    expect(label(ReportPeriod.year(tue), calendar), '2026');
    expect(label(const ReportPeriod.all(), calendar), 'All time');
  });

  group('labels for a period in progress', () {
    const payday = BudgetCycle.lastWorkingDay();
    final today = DateTime(2026, 10, 6, 15);

    test('a cycle reads from its start to today', () {
      expect(
        ReportPeriod.month(today).label(payday, allTime: 'All', today: today),
        '30 Sep – 6 Oct',
      );
      expect(
        ReportPeriod.week(today).label(payday, allTime: 'All', today: today),
        '5 Oct – 6 Oct',
      );
    });

    test('a later-dated entry extends it; never past the period end', () {
      final p = ReportPeriod.month(today);
      expect(
        p.label(
          payday,
          allTime: 'All',
          today: today,
          through: DateTime(2026, 10, 12),
        ),
        '30 Sep – 12 Oct',
      );
      expect(
        p.label(
          payday,
          allTime: 'All',
          today: today,
          through: DateTime(2026, 11, 3),
        ),
        '30 Sep – 29 Oct',
      );
    });

    test('past periods and calendar months keep their names', () {
      expect(
        ReportPeriod.month(
          DateTime(2026, 9, 1),
        ).label(payday, allTime: 'All', today: today),
        '31 Aug – 29 Sep',
      );
      expect(
        ReportPeriod.month(
          today,
        ).label(const BudgetCycle.calendar(), allTime: 'All', today: today),
        'Oct 2026',
      );
    });
  });
}

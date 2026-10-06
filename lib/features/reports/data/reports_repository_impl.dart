import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../core/dates/date_range.dart';
import '../../../core/dates/report_period.dart';
import '../../../core/db/app_database.dart';
import '../../../core/money/money.dart';
import '../../categories/data/categories_repository_impl.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/report.dart';

/// Reports from SQL aggregates (spec 4.1: "all SQL aggregation in DAO");
/// only bucketing into days / cycles / years happens here, through
/// [ReportPeriod] — the same calendar code as everything else.
@LazySingleton(as: ReportsRepository)
class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<ReportData> watch(ReportQuery q) {
    final dao = _db.transactionsDao;
    final range = q.period.range(q.cycle);
    final f = q.filters;
    final daily = dao
        .dailyTotals(
          types: f.types,
          accountIds: f.accountIds,
          categoryIds: f.categoryIds,
          tagNames: f.tags,
          fromMillis: range?.startMillis,
          toMillis: range?.endMillis,
        )
        .watch();
    final byCategory = dao
        .categoryTotals(
          types: f.types,
          accountIds: f.accountIds,
          categoryIds: f.categoryIds,
          tagNames: f.tags,
          fromMillis: range?.startMillis,
          toMillis: range?.endMillis,
        )
        .watch();
    final balance = dao
        .balanceChanges(q.currency.code, accountIds: f.accountIds)
        .watch();
    final categories = _db.categoriesDao.watchActive();

    return daily
        .combineLatest(byCategory, (d, c) => (d, c))
        .combineLatest(balance, (dc, b) => (dc.$1, dc.$2, b))
        .combineLatest(categories, (x, cats) {
          final (days, cats_, changes) = x;
          return _build(q, range, days, cats_, changes, {
            for (final c in cats) c.id: c.toDomain(),
          });
        });
  }

  static DateTime _parseDay(String day) {
    final p = day.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  ReportData _build(
    ReportQuery q,
    DateRange? range,
    List<({String day, TransactionType type, String currency, int total})> days,
    List<
      ({String? categoryId, TransactionType type, String currency, int total})
    >
    cats,
    List<({String? day, int delta})> changes,
    Map<String, Category> categories,
  ) {
    final code = q.currency.code;
    Money m(int minor) => Money(minor, q.currency);

    // Totals and per-category slices, in the report currency.
    var income = 0;
    var expense = 0;
    final spend = <String?, int>{};
    final earn = <String?, int>{};
    for (final c in cats) {
      if (c.currency != code) continue;
      if (c.type == TransactionType.income) {
        income += c.total;
        earn.update(c.categoryId, (v) => v + c.total, ifAbsent: () => c.total);
      } else {
        expense += c.total;
        spend.update(c.categoryId, (v) => v + c.total, ifAbsent: () => c.total);
      }
    }
    List<CategorySlice> slices(Map<String?, int> totals) => [
      for (final e in totals.entries)
        CategorySlice(e.key == null ? null : categories[e.key], m(e.value)),
    ]..sort((a, b) => b.total.minor.compareTo(a.total.minor));

    // The span to chart: the period, or for all time the data's extent.
    final dated = [
      for (final d in days)
        if (d.currency == code)
          (at: _parseDay(d.day), type: d.type, total: d.total),
    ];
    final opening = changes
        .where((c) => c.day == null)
        .fold(0, (s, c) => s + c.delta);
    final deltas = [
      for (final c in changes)
        if (c.day != null) (at: _parseDay(c.day!), delta: c.delta),
    ]..sort((a, b) => a.at.compareTo(b.at));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateRange? span = range;
    // A period still in progress is charted up to today (or its last
    // entry, if one is dated later), not across empty future days.
    if (span != null && span.contains(now)) {
      final lastEntry = [
        ...dated.map((d) => d.at),
        if (deltas.isNotEmpty) deltas.last.at,
      ].fold(today, (a, b) => b.isAfter(a) ? b : a);
      final end = DateTime(lastEntry.year, lastEntry.month, lastEntry.day + 1);
      if (end.isBefore(span.end)) span = DateRange(span.start, end);
    }
    if (span == null) {
      final days = [
        ...dated.map((d) => d.at),
        if (deltas.isNotEmpty) ...[deltas.first.at, deltas.last.at],
      ];
      if (days.isNotEmpty) {
        final first = days.reduce((a, b) => a.isBefore(b) ? a : b);
        // Through today, or the last entry if any are dated in the future.
        final last = days.fold(today, (a, b) => a.isAfter(b) ? a : b);
        span = DateRange(first, DateTime(last.year, last.month, last.day + 1));
      }
    }

    final size = span == null ? BucketSize.day : ReportPeriod.bucketFor(span);
    final buckets = span == null
        ? <DateRange>[]
        : ReportPeriod.buckets(span, size, q.cycle);
    final flowIn = List.filled(buckets.length, 0);
    final flowOut = List.filled(buckets.length, 0);
    for (final d in dated) {
      final i = _bucketOf(buckets, d.at);
      if (i == null) continue;
      if (d.type == TransactionType.income) {
        flowIn[i] += d.total;
      } else {
        flowOut[i] += d.total;
      }
    }

    // Running balance: opening + every change before each bucket's end.
    // Stops at today (or the last future-dated change): beyond that the
    // line would only run flat into months that haven't happened.
    final horizon = deltas.isNotEmpty && deltas.last.at.isAfter(today)
        ? deltas.last.at
        : today;
    final balance = <BalancePoint>[];
    var running = opening;
    var k = 0;
    for (final b in buckets) {
      if (b.start.isAfter(horizon)) break;
      while (k < deltas.length && deltas[k].at.isBefore(b.end)) {
        running += deltas[k].delta;
        k++;
      }
      balance.add(BalancePoint(b, m(running)));
    }

    return ReportData(
      span: span,
      bucketSize: size,
      income: m(income),
      expense: m(expense),
      spending: slices(spend),
      earning: slices(earn),
      flow: [
        for (var i = 0; i < buckets.length; i++)
          FlowPoint(buckets[i], m(flowIn[i]), m(flowOut[i])),
      ],
      balance: balance,
    );
  }

  /// Index of the bucket containing [day], or null if outside.
  static int? _bucketOf(List<DateRange> buckets, DateTime day) {
    var lo = 0;
    var hi = buckets.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final b = buckets[mid];
      if (day.isBefore(b.start)) {
        hi = mid - 1;
      } else if (!day.isBefore(b.end)) {
        lo = mid + 1;
      } else {
        return mid;
      }
    }
    return null;
  }
}

import '../../../core/money/currency.dart';
import '../../../core/money/fixed_point.dart';
import '../../../core/money/money.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/exchange_record.dart';

/// The Hysab Kytab ACTIVITIES layout (spec 3.3), plus Kharcha extension
/// columns appended after it. Hysab Kytab ignores columns it doesn't know;
/// Kharcha uses them to re-import with nothing lost.
abstract final class HkColumns {
  static const type = 'Voucher Type';
  static const date = 'Voucher Date';
  static const amount = 'Voucher Amount';
  static const description = 'Description';
  static const category = 'Category Name';
  static const account = 'Account Name';
  static const tags = 'Tags';
  static const events = 'Events';
  static const place = 'Place';
  static const travelRate = 'Travel Currency Rate';
  static const travelSymbol = 'Travel Currency Symbol';
  static const travelAmount = 'Travel Currency Amount';
  static const travelLocation = 'Travel Location';
  static const travelDate = 'Travel Date';

  // Kharcha extensions.
  static const currency = 'Currency';
  static const time = 'Time';
  static const person = 'Person';
  static const kharchaType = 'Kharcha Type';
  static const kharchaId = 'Kharcha Id';

  static const hysabKytab = [
    type,
    date,
    amount,
    description,
    category,
    account,
    tags,
    events,
    place,
    travelRate,
    travelSymbol,
    travelAmount,
    travelLocation,
    travelDate,
  ];
  static const all = [
    ...hysabKytab,
    currency,
    time,
    person,
    kharchaType,
    kharchaId,
  ];

  static const noCategory = 'No Category';
  static const expense = 'Expense';
  static const income = 'Income';
  static const transfer = 'Transfer';
}

/// Writes [ExchangeRecord]s as Hysab Kytab rows and reads them back.
abstract final class HkSheet {
  // ── Writing ───────────────────────────────────────────────────────────

  /// Header + one row per record (two per transfer or udhaar entry, the
  /// way Hysab Kytab exports them: destination first, then source).
  static List<List<String>> write(Iterable<ExchangeRecord> records) => [
    HkColumns.all,
    for (final r in records) ..._rows(r),
  ];

  static List<List<String>> _rows(ExchangeRecord r) {
    String amt(Money m) => FixedPoint.format(m.minor, m.currency.decimals);
    List<String> row({
      required String type,
      required Money amount,
      required String account,
      String category = HkColumns.noCategory,
      String rate = '',
      String symbol = '',
      String foreign = '',
    }) => [
      type,
      _date(r.at),
      amt(amount),
      r.note,
      category,
      account,
      r.tags.join(', '),
      r.events.join(', '),
      r.place ?? '',
      rate,
      symbol,
      foreign,
      '',
      '',
      amount.currency.code,
      _time(r.at),
      r.person ?? '',
      r.type.name,
      r.id ?? '',
    ];

    // Udhaar: Hysab Kytab keeps people as accounts and moves money by
    // transfer, so write it that way, naming the person in [person].
    if (r.person != null) {
      final gave = r.type == TransactionType.expense;
      return [
        row(
          type: HkColumns.transfer,
          amount: r.amount,
          account: gave ? r.person! : r.account,
        ),
        row(
          type: HkColumns.transfer,
          amount: -r.amount,
          account: gave ? r.account : r.person!,
        ),
      ];
    }
    switch (r.type) {
      case TransactionType.transfer:
        final received = r.toAmount ?? r.amount;
        final cross = received.currency != r.amount.currency;
        return [
          row(
            type: HkColumns.transfer,
            amount: received,
            account: r.toAccount!,
          ),
          row(
            type: HkColumns.transfer,
            amount: -r.amount,
            account: r.account,
            rate: cross && r.fxRateMicros != null
                ? FixedPoint.format(r.fxRateMicros!, Money.rateScale)
                : '',
            symbol: cross ? received.currency.symbol : '',
            foreign: cross ? amt(received) : '',
          ),
        ];
      case TransactionType.expense:
        return [
          row(
            type: HkColumns.expense,
            amount: -r.amount,
            account: r.account,
            category: r.category ?? HkColumns.noCategory,
          ),
        ];
      case TransactionType.income:
        return [
          row(
            type: HkColumns.income,
            amount: r.amount,
            account: r.account,
            category: r.category ?? HkColumns.noCategory,
          ),
        ];
      case TransactionType.adjustment:
        return [
          row(
            type: r.amount.isNegative ? HkColumns.expense : HkColumns.income,
            amount: r.amount,
            account: r.account,
            category: r.category ?? HkColumns.noCategory,
          ),
        ];
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _date(DateTime d) =>
      '${_two(d.day)}/${_two(d.month)}/${d.year}';
  static String _time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  // ── Reading ───────────────────────────────────────────────────────────

  /// Reads rows (first row = header). Accepts Hysab Kytab files (pairs
  /// transfers by date + opposite amounts, as its export interleaves them)
  /// and Kharcha files (pairs by Kharcha Id; restores currency, time,
  /// person and adjustments). [defaultCurrency] applies when a file has no
  /// Currency column.
  static ExchangeResult read(
    List<List<String>> rows, {
    Currency defaultCurrency = Currency.pkr,
  }) {
    if (rows.isEmpty) return const ExchangeResult([], []);
    final col = _Columns(rows.first);
    final parsed = <_Row>[];
    final warnings = <ExchangeWarning>[];
    for (var i = 1; i < rows.length; i++) {
      final cells = rows[i];
      if (cells.every((c) => c.trim().isEmpty)) continue;
      final row = _Row.parse(cells, col, i + 1, defaultCurrency);
      if (row == null) {
        warnings.add(
          ExchangeWarning(
            i + 1,
            ExchangeWarningKind.unreadableRow,
            cells.join(' | '),
          ),
        );
      } else {
        parsed.add(row);
      }
    }

    final records = <ExchangeRecord>[];
    final lines = <List<int>>[];
    final used = <int>{};
    for (var i = 0; i < parsed.length; i++) {
      if (used.contains(i)) continue;
      final r = parsed[i];
      if (r.hkType != HkColumns.transfer) {
        records.add(r.single());
        lines.add([r.line]);
        continue;
      }
      final j = _partner(parsed, i, used);
      if (j == null) {
        warnings.add(
          ExchangeWarning(
            r.line,
            ExchangeWarningKind.unpairedTransfer,
            r.account,
          ),
        );
        records.add(r.asAdjustment());
        lines.add([r.line]);
        continue;
      }
      used.add(j);
      records.add(_Row.pair(r, parsed[j]));
      lines.add([r.line, parsed[j].line]);
    }
    return ExchangeResult(records, warnings, lines: lines);
  }

  /// The row completing the transfer at [i]: same Kharcha Id if present;
  /// otherwise the nearest later unused transfer row on the same date with
  /// the opposite sign and equal size (Hysab Kytab writes them adjacently).
  static int? _partner(List<_Row> rows, int i, Set<int> used) {
    final r = rows[i];
    for (var j = i + 1; j < rows.length; j++) {
      if (used.contains(j)) continue;
      final o = rows[j];
      if (o.hkType != HkColumns.transfer) continue;
      if (r.id != null && r.id!.isNotEmpty) {
        if (o.id == r.id) return j;
        continue;
      }
      final opposite = o.amount.isNegative != r.amount.isNegative;
      final sameSize =
          o.amount.minor.abs() == r.amount.minor.abs() ||
          o.amount.currency != r.amount.currency;
      if (o.day == r.day && opposite && sameSize) return j;
      if (o.day != r.day) break;
    }
    return null;
  }
}

class _Columns {
  _Columns(List<String> header) {
    for (var i = 0; i < header.length; i++) {
      _index[_norm(header[i])] = i;
    }
    // Some older Hysab Kytab exports call it plain "Type".
    _index.putIfAbsent(
      _norm(HkColumns.type),
      () => _index[_norm('Type')] ?? -1,
    );
  }

  final Map<String, int> _index = {};

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  String get(List<String> cells, String column) {
    final i = _index[_norm(column)] ?? -1;
    return i >= 0 && i < cells.length ? cells[i].trim() : '';
  }
}

class _Row {
  _Row({
    required this.line,
    required this.hkType,
    required this.day,
    required this.at,
    required this.amount,
    required this.account,
    required this.note,
    required this.category,
    required this.tags,
    required this.events,
    required this.place,
    required this.person,
    required this.kharchaType,
    required this.id,
    required this.fxRateMicros,
    required this.travel,
  });

  final int line;
  final String hkType;
  final String day;
  final DateTime at;

  /// Signed as in the file.
  final Money amount;
  final String account;
  final String note;
  final String? category;
  final List<String> tags;
  final List<String> events;
  final String? place;
  final String? person;
  final TransactionType? kharchaType;
  final String? id;
  final int? fxRateMicros;

  /// Hysab Kytab travel amount in its own currency ("100.0" + "\$").
  final Money? travel;

  static _Row? parse(
    List<String> cells,
    _Columns c,
    int line,
    Currency fallback,
  ) {
    String get(String col) => c.get(cells, col);
    final date = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
    ).firstMatch(get(HkColumns.date));
    final currencyCode = get(HkColumns.currency);
    final currency = currencyCode.isEmpty
        ? fallback
        : Currency.of(currencyCode);
    final amount = Money.parse(get(HkColumns.amount), currency, round: true);
    final hkType = _type(get(HkColumns.type));
    if (date == null || amount == null || hkType == null) return null;

    final time = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(get(HkColumns.time));
    // Midday when no time is given, to dodge timezone drift (spec 3.3).
    final at = DateTime(
      int.parse(date.group(3)!),
      int.parse(date.group(2)!),
      int.parse(date.group(1)!),
      time == null ? 12 : int.parse(time.group(1)!),
      time == null ? 0 : int.parse(time.group(2)!),
    );
    // Impossible dates (31/02) would roll over; treat them as unreadable.
    if (at.day != int.parse(date.group(1)!) ||
        at.month != int.parse(date.group(2)!)) {
      return null;
    }

    // Hysab Kytab travel-currency fields on non-transfer rows describe a
    // foreign purchase; Kharcha keeps them in the note.
    var note = get(HkColumns.description);
    final travel = [
      if (get(HkColumns.travelSymbol).isNotEmpty &&
          !_isZero(get(HkColumns.travelAmount)))
        '${get(HkColumns.travelAmount)} ${get(HkColumns.travelSymbol)}',
      if (get(HkColumns.travelRate).isNotEmpty && hkType != HkColumns.transfer)
        '@ ${get(HkColumns.travelRate)}',
      if (get(HkColumns.travelLocation).isNotEmpty)
        get(HkColumns.travelLocation),
      if (get(HkColumns.travelDate).isNotEmpty) get(HkColumns.travelDate),
    ];
    if (travel.isNotEmpty && hkType != HkColumns.transfer) {
      note = [
        if (note.isNotEmpty) note,
        'Travel: ${travel.join(', ')}',
      ].join(' · ');
    }

    final category = get(HkColumns.category);
    final person = get(HkColumns.person);
    final id = get(HkColumns.kharchaId);
    return _Row(
      line: line,
      hkType: hkType,
      day: get(HkColumns.date),
      at: at,
      amount: amount,
      account: get(HkColumns.account),
      note: note,
      category:
          category.isEmpty ||
              category.toLowerCase() == HkColumns.noCategory.toLowerCase()
          ? null
          : category,
      tags: _split(get(HkColumns.tags)),
      events: _split(get(HkColumns.events)),
      place: get(HkColumns.place).isEmpty ? null : get(HkColumns.place),
      person: person.isEmpty ? null : person,
      kharchaType: TransactionType.values
          .asNameMap()[get(HkColumns.kharchaType)],
      id: id.isEmpty ? null : id,
      fxRateMicros: FixedPoint.parse(
        get(HkColumns.travelRate),
        Money.rateScale,
        round: true,
      ),
      travel: _travel(get(HkColumns.travelSymbol), get(HkColumns.travelAmount)),
    );
  }

  static Money? _travel(String symbol, String amount) {
    final currency = symbol.isEmpty ? null : Currency.fromSymbol(symbol);
    if (currency == null || _isZero(amount)) return null;
    return Money.parse(amount, currency, round: true)?.abs();
  }

  static bool _isZero(String s) =>
      (FixedPoint.parse(s, 6, round: true) ?? 0) == 0;

  static String? _type(String raw) => switch (raw.trim().toLowerCase()) {
    'expense' => HkColumns.expense,
    'income' => HkColumns.income,
    'transfer' => HkColumns.transfer,
    _ => null,
  };

  static List<String> _split(String raw) {
    final seen = <String>{};
    return [
      for (final t in raw.split(','))
        if (t.trim().isNotEmpty && seen.add(t.trim().toLowerCase())) t.trim(),
    ];
  }

  ExchangeRecord _record({
    required TransactionType type,
    required Money amount,
    required String account,
    String? toAccount,
    Money? toAmount,
    int? fx,
    String? person,
  }) => ExchangeRecord(
    id: id,
    type: type,
    at: at,
    amount: amount,
    account: account,
    toAccount: toAccount,
    toAmount: toAmount,
    fxRateMicros: fx,
    category: type == TransactionType.transfer || person != null
        ? null
        : category,
    person: person,
    note: note,
    place: place,
    tags: tags,
    events: events,
  );

  ExchangeRecord single() {
    if (kharchaType == TransactionType.adjustment) {
      return _record(
        type: TransactionType.adjustment,
        amount: amount,
        account: account,
      );
    }
    final income = hkType == HkColumns.income;
    return _record(
      type: income ? TransactionType.income : TransactionType.expense,
      amount: amount.abs(),
      account: account,
    );
  }

  /// An unpaired transfer row: money moved in or out of [account] alone.
  ExchangeRecord asAdjustment() => _record(
    type: TransactionType.adjustment,
    amount: amount,
    account: account,
  );

  /// Joins two transfer rows (either order) into one record.
  static ExchangeRecord pair(_Row a, _Row b) {
    final dest = a.amount.isNegative ? b : a;
    final src = a.amount.isNegative ? a : b;
    final person = src.person ?? dest.person;
    if (person != null) {
      // Udhaar: the person is the side named as an account.
      final gave = dest.account == person;
      return src._record(
        type: gave ? TransactionType.expense : TransactionType.income,
        amount: dest.amount.abs(),
        account: gave ? src.account : dest.account,
        person: person,
      );
    }
    // Cross-currency: a Kharcha file states each side's currency; a
    // Hysab Kytab file gives the received side as travel-currency fields.
    final travel = src.travel ?? dest.travel;
    final toAmount = dest.amount.currency != src.amount.currency
        ? dest.amount.abs()
        : travel != null && travel.currency != src.amount.currency
        ? travel
        : null;
    return src._record(
      type: TransactionType.transfer,
      amount: src.amount.abs(),
      account: src.account,
      toAccount: dest.account,
      toAmount: toAmount,
      fx: toAmount == null ? null : src.fxRateMicros ?? dest.fxRateMicros,
    );
  }
}

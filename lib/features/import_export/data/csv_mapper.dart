import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/exchange_record.dart';
import '../domain/import_plan.dart';

/// Reads any CSV through a user-confirmed [CsvMapping] (spec 3.1 #10:
/// "generic CSV import with column mapper").
abstract final class CsvMapper {
  /// A first guess from the header's words; null when no date or amount
  /// column can be found.
  static CsvMapping? guess(List<String> header) {
    int? find(List<String> words) {
      for (var i = 0; i < header.length; i++) {
        final h = header[i].toLowerCase();
        if (words.any(h.contains)) return i;
      }
      return null;
    }

    final date = find(['date', 'day', 'time']);
    final amount = find(['amount', 'value', 'sum', 'price', 'total']);
    if (date == null || amount == null) return null;
    return CsvMapping(
      date: date,
      amount: amount,
      type: find(['type', 'kind', 'debit/credit', 'dr/cr']),
      account: find(['account', 'wallet', 'bank']),
      category: find(['category', 'group']),
      note: find(['note', 'description', 'memo', 'details', 'narration']),
      tags: find(['tag', 'label']),
      dateOrder: _guessOrder(header.length > date ? header[date] : ''),
    );
  }

  static DateOrder _guessOrder(String header) =>
      header.toLowerCase().contains('mm/dd') ? DateOrder.mdy : DateOrder.dmy;

  /// Records from [rows] (first row = header). Rows with no readable date
  /// or amount become warnings, like the Hysab Kytab reader's.
  static ExchangeResult read(
    List<List<String>> rows,
    CsvMapping m, {
    required Currency currency,
  }) {
    final records = <ExchangeRecord>[];
    final lines = <List<int>>[];
    final warnings = <ExchangeWarning>[];
    String cell(List<String> r, int? i) =>
        i != null && i < r.length ? r[i].trim() : '';

    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.every((c) => c.trim().isEmpty)) continue;
      final at = parseDate(cell(r, m.date), m.dateOrder);
      final signed = Money.parse(
        cell(r, m.amount).replaceAll(',', ''),
        currency,
        round: true,
      );
      final type = _type(cell(r, m.type), signed);
      final account = cell(r, m.account).isEmpty
          ? m.defaultAccount
          : cell(r, m.account);
      if (at == null || signed == null || signed.isZero || account.isEmpty) {
        warnings.add(
          ExchangeWarning(
            i + 1,
            ExchangeWarningKind.unreadableRow,
            r.join(' | '),
          ),
        );
        continue;
      }
      final category = cell(r, m.category);
      records.add(
        ExchangeRecord(
          type: type,
          at: at,
          amount: signed.abs(),
          account: account,
          category: category.isEmpty ? null : category,
          note: cell(r, m.note),
          tags: [
            for (final t in cell(r, m.tags).split(','))
              if (t.trim().isNotEmpty) t.trim(),
          ],
        ),
      );
      lines.add([i + 1]);
    }
    return ExchangeResult(records, warnings, lines: lines);
  }

  static TransactionType _type(String word, Money? signed) {
    final w = word.toLowerCase();
    if (const ['income', 'credit', 'cr', 'in', 'deposit'].contains(w)) {
      return TransactionType.income;
    }
    if (const ['expense', 'debit', 'dr', 'out', 'withdrawal'].contains(w)) {
      return TransactionType.expense;
    }
    return signed != null && signed.isNegative
        ? TransactionType.expense
        : TransactionType.income;
  }

  /// "25/08/2025", "08-25-2025", "2025-08-25", optionally with "14:30".
  /// Midday when no time is given (spec 3.3). Null for impossible dates.
  static DateTime? parseDate(String raw, DateOrder order) {
    final m = RegExp(
      r'^(\d{1,4})[/\-.](\d{1,2})[/\-.](\d{1,4})(?:[ T](\d{1,2}):(\d{2}))?',
    ).firstMatch(raw.trim());
    if (m == null) return null;
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    final c = int.parse(m.group(3)!);
    final (y, mo, d) = switch (order) {
      _ when m.group(1)!.length == 4 => (a, b, c),
      DateOrder.ymd => (a, b, c),
      DateOrder.dmy => (c, b, a),
      DateOrder.mdy => (c, a, b),
    };
    final year = y < 100 ? 2000 + y : y;
    final h = m.group(4) == null ? 12 : int.parse(m.group(4)!);
    final min = m.group(5) == null ? 0 : int.parse(m.group(5)!);
    final at = DateTime(year, mo, d, h, min);
    // Reject rollovers such as 31/02.
    if (at.year != year || at.month != mo || at.day != d) return null;
    return at;
  }
}

import 'package:injectable/injectable.dart';

import '../../../core/money/currency.dart';
import '../../../core/money/fixed_point.dart';
import '../../../core/money/money.dart';
import '../../accounts/domain/account.dart';
import '../../transactions/domain/entry_query.dart';
import '../../transactions/domain/ledger_entry.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../transactions/domain/transactions_repository.dart';
import '../domain/exchange_record.dart';
import '../domain/exporter.dart';
import 'hk_sheet.dart';
import 'spreadsheet_codec.dart';

/// An [EntryView] as a file record.
ExchangeRecord recordOf(EntryView v) {
  final e = v.entry;
  final local = e.occurredAt.toLocal();
  return ExchangeRecord(
    id: e.id,
    type: e.type,
    at: DateTime(local.year, local.month, local.day, local.hour, local.minute),
    amount: e.amount,
    account: v.accountName,
    toAccount: v.toAccountName,
    toAmount: e.toAmount,
    fxRateMicros: e.fxRateMicros,
    category: v.category?.name,
    person: v.personName,
    note: e.note,
    place: e.place,
    tags: e.tags,
    events: e.events,
  );
}

@LazySingleton(as: Exporter)
class ExportService implements Exporter {
  ExportService(this._transactions, this._accounts);

  final TransactionsRepository _transactions;
  final AccountsRepository _accounts;

  /// Clock for the file name; tests pin it.
  DateTime Function() now = DateTime.now;

  /// Large enough to never page.
  static const int _all = 1 << 30;

  @override
  Future<ExportFile> export(
    EntryQuery query,
    ExportFormat format, {
    String label = 'All',
  }) async {
    final page = await _transactions.watch(query.copyWith(limit: _all)).first;
    // Oldest first, like Hysab Kytab's own export.
    final views = page.items.reversed.toList();
    final activities = HkSheet.write(views.map(recordOf));

    final List<int> bytes;
    if (format == ExportFormat.csv) {
      bytes = SpreadsheetCodec.encodeCsv(activities);
    } else {
      final overview = await _accounts.watchOverview().first;
      bytes = SpreadsheetCodec.encodeXlsx([
        (name: SpreadsheetCodec.activitiesSheet, rows: activities),
        (name: 'ACCOUNT', rows: _accountRows(overview)),
        (name: 'CATEGORY', rows: _categoryRows(views)),
      ]);
    }
    return ExportFile(
      name: _fileName(label, format),
      mime: format.mime,
      bytes: bytes,
    );
  }

  static String _amt(Money m) =>
      FixedPoint.format(m.minor, m.currency.decimals);

  /// Hysab Kytab's ACCOUNT sheet: Balance Amount = closing − opening.
  static List<List<String>> _accountRows(AccountsOverview o) => [
    const [
      'Title',
      'Opening Balance',
      'Balance Amount',
      'Closing Balance',
      'Currency',
    ],
    for (final s in o.accounts)
      [
        s.account.name,
        _amt(s.account.openingBalance),
        _amt(s.balance - s.account.openingBalance),
        _amt(s.balance),
        s.account.currency.code,
      ],
  ];

  /// Hysab Kytab's CATEGORY sheet, totalled over the exported entries
  /// (udhaar excluded — it isn't income or spending).
  static List<List<String>> _categoryRows(List<EntryView> views) {
    final totals = <(String, String, Currency), Money>{};
    for (final v in views) {
      final c = v.category;
      if (c == null || v.isUdhaar || v.entry.type == TransactionType.transfer) {
        continue;
      }
      final kind = v.entry.type == TransactionType.income
          ? 'Income'
          : 'Expense';
      final key = (c.name, kind, v.entry.amount.currency);
      totals.update(
        key,
        (m) => m + v.entry.amount.abs(),
        ifAbsent: () => v.entry.amount.abs(),
      );
    }
    return [
      const ['Title', 'Balance Amount', 'Category Type', 'Currency'],
      for (final MapEntry(:key, :value) in totals.entries)
        [key.$1, _amt(value), key.$2, key.$3.code],
    ];
  }

  String _fileName(String label, ExportFormat format) {
    final d = now();
    String two(int n) => n.toString().padLeft(2, '0');
    final safe = label
        .replaceAll(RegExp(r'[^\w\- ]+'), '')
        .trim()
        .replaceAll(' ', '_');
    return 'Kharcha_${safe.isEmpty ? 'Export' : safe}_${d.year}-${two(d.month)}-${two(d.day)}.${format.extension}';
  }
}

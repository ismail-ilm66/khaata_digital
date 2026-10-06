import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/import_export/data/hk_sheet.dart';
import 'package:khaata_digital/features/import_export/data/spreadsheet_codec.dart';
import 'package:khaata_digital/features/import_export/domain/exchange_record.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

Money rs(String v) => Money.parse(v, Currency.pkr)!;

final records = [
  ExchangeRecord(
    id: 'a1',
    type: TransactionType.expense,
    at: DateTime(2025, 8, 25, 13, 45),
    amount: rs('2520.50'),
    account: 'Meezan Bank',
    category: 'Food & Drink',
    note: 'Lunch, with "Abdullah"',
    tags: const ['office', 'lunch'],
    events: const ['Eid 2026'],
    place: 'Karachi',
  ),
  ExchangeRecord(
    id: 'a2',
    type: TransactionType.income,
    at: DateTime(2025, 8, 27, 9, 0),
    amount: rs('150000'),
    account: 'Meezan Bank',
    category: 'Salary',
  ),
  ExchangeRecord(
    id: 'a3',
    type: TransactionType.transfer,
    at: DateTime(2025, 8, 27, 10, 5),
    amount: rs('5395'),
    account: 'Nayapay',
    toAccount: 'Savings',
  ),
  ExchangeRecord(
    id: 'a4',
    type: TransactionType.transfer,
    at: DateTime(2025, 9, 1, 18, 30),
    amount: Money.major(100, Currency.usd),
    account: 'Payoneer',
    toAccount: 'Meezan Bank',
    toAmount: rs('28250'),
    fxRateMicros: 282500000,
  ),
  ExchangeRecord(
    id: 'a5',
    type: TransactionType.expense,
    at: DateTime(2025, 8, 31, 12, 0),
    amount: rs('4500'),
    account: 'Meezan Bank',
    person: 'Mudassir Bhai',
    note: 'Cargo Shorts',
  ),
  ExchangeRecord(
    id: 'a6',
    type: TransactionType.income,
    at: DateTime(2025, 9, 3, 12, 0),
    amount: rs('2000'),
    account: 'Cash',
    person: 'Mudassir Bhai',
  ),
  ExchangeRecord(
    id: 'a7',
    type: TransactionType.adjustment,
    at: DateTime(2025, 9, 4, 8, 0),
    amount: rs('-50'),
    account: 'Cash',
  ),
  ExchangeRecord(
    id: 'a8',
    type: TransactionType.expense,
    at: DateTime(2025, 9, 5, 21, 15),
    amount: rs('0.01'),
    account: 'نقد',
    note: 'اردو نوٹ',
  ),
];

void main() {
  group('round trip (M4 acceptance: re-imports with zero diff)', () {
    test('rows', () {
      final back = HkSheet.read(HkSheet.write(records));
      expect(back.warnings, isEmpty);
      expect(back.records, records);
    });

    test('CSV bytes', () {
      final bytes = SpreadsheetCodec.encodeCsv(HkSheet.write(records));
      final back = HkSheet.read(SpreadsheetCodec.activities(bytes, csv: true));
      expect(back.records, records);
    });

    test('XLSX bytes', () {
      final bytes = SpreadsheetCodec.encodeXlsx([
        (name: SpreadsheetCodec.activitiesSheet, rows: HkSheet.write(records)),
        (
          name: 'ACCOUNT',
          rows: const [
            ['Title', 'Opening Balance', 'Balance Amount', 'Closing Balance'],
          ],
        ),
      ]);
      final sheets = SpreadsheetCodec.decodeXlsx(bytes);
      expect(sheets.map((s) => s.name), ['ACTIVITIES', 'ACCOUNT']);
      final back = HkSheet.read(SpreadsheetCodec.activities(bytes, csv: false));
      expect(back.records, records);
    });
  });

  group('writes the Hysab Kytab layout', () {
    final rows = HkSheet.write(records);

    test('the first 14 columns are Hysab Kytab\'s, in order', () {
      expect(rows.first.take(14), HkColumns.hysabKytab);
    });

    test('expenses are negative; dates are DD/MM/YYYY', () {
      expect(rows[1].take(6), [
        'Expense',
        '25/08/2025',
        '-2520.50',
        'Lunch, with "Abdullah"',
        'Food & Drink',
        'Meezan Bank',
      ]);
    });

    test('a transfer is two rows, destination first', () {
      expect(rows[3].take(6), [
        'Transfer',
        '27/08/2025',
        '5395.00',
        '',
        'No Category',
        'Savings',
      ]);
      expect(rows[4].take(6), [
        'Transfer',
        '27/08/2025',
        '-5395.00',
        '',
        'No Category',
        'Nayapay',
      ]);
    });

    test('udhaar is a transfer to/from the person, like Hysab Kytab', () {
      final gave = rows.where((r) => r.last == 'a5').toList();
      expect(gave.map((r) => r[5]), ['Mudassir Bhai', 'Meezan Bank']);
    });
  });

  group('reads a real Hysab Kytab export (no Kharcha columns)', () {
    // Rows copied from the shape of the user's export: all text, '.0'
    // amounts, interleaved transfer pairs, people as accounts.
    final hk = [
      HkColumns.hysabKytab,
      [
        'Expense',
        '25/08/2025',
        '-2520.0',
        'Abdullah Sibtain Lunch ',
        'Food & Drink',
        'Meezan Bank',
        '',
        '',
        '',
        '',
        '',
        '0.0',
        '',
        '',
      ],
      [
        'Income',
        '27/08/2025',
        '5395.0',
        '',
        'Savings',
        'Nayapay',
        '',
        '',
        '',
        '',
        '',
        '0.0',
        '',
        '',
      ],
      [
        'Transfer',
        '27/08/2025',
        '5395.0',
        '',
        'No Category',
        'Savings',
        '',
        '',
        '',
        '',
        '',
        '0.0',
        '',
        '',
      ],
      [
        'Transfer',
        '27/08/2025',
        '-5395.0',
        '',
        'No Category',
        'Nayapay',
        '',
        '',
        '',
        '',
        '',
        '0.0',
        '',
        '',
      ],
      [
        'Transfer',
        '31/08/2025',
        '4500.0',
        'Cargo Shorts ',
        'No Category',
        'Mudassir Bhai',
        '',
        '',
        '',
        '',
        '',
        '0.0',
        '',
        '',
      ],
      [
        'Transfer',
        '31/08/2025',
        '-4500.0',
        'Cargo Shorts ',
        'No Category',
        'Meezan Bank',
        '',
        '',
        '',
        '',
        '',
        '0.0',
        '',
        '',
      ],
      [
        'Expense',
        '02/09/2025',
        '-1000.0',
        'Dinner',
        'Travel',
        'Cash',
        'trip, Trip',
        '',
        'Dubai Mall',
        '75.0',
        'AED',
        '50.0',
        'Dubai',
        '01/09/2025',
      ],
      [
        'Transfer',
        '03/09/2025',
        '999.0',
        '',
        'No Category',
        'Cash',
        '',
        '',
        '',
        '',
        '',
        '0.0',
        '',
        '',
      ],
    ];
    final result = HkSheet.read(hk);
    final r = result.records;

    test('types, midday dates, amounts and No Category', () {
      expect(r[0].type, TransactionType.expense);
      expect(r[0].amount, rs('2520'));
      expect(r[0].at, DateTime(2025, 8, 25, 12));
      expect(r[0].note, 'Abdullah Sibtain Lunch');
      expect(r[1].category, 'Savings');
    });

    test('pairs transfers into one record each', () {
      expect(r[2].type, TransactionType.transfer);
      expect(r[2].account, 'Nayapay');
      expect(r[2].toAccount, 'Savings');
      expect(r[2].category, isNull);
      expect(r[3].account, 'Meezan Bank');
      expect(
        r[3].toAccount,
        'Mudassir Bhai',
        reason: 'people-as-accounts are resolved in M5',
      );
    });

    test('travel currency fields go into the note; tags dedupe', () {
      expect(r[4].note, 'Dinner · Travel: 50.0 AED, @ 75.0, Dubai, 01/09/2025');
      expect(r[4].tags, ['trip']);
      expect(r[4].place, 'Dubai Mall');
    });

    test('an unpaired transfer becomes an adjustment with a warning', () {
      expect(r.last.type, TransactionType.adjustment);
      expect(r.last.amount, rs('999'));
      expect(result.warnings.single.kind, ExchangeWarningKind.unpairedTransfer);
    });
  });

  test('accepts an older "Type" header and skips unreadable rows', () {
    final result = HkSheet.read([
      ['Type', 'Voucher Date', 'Voucher Amount', 'Account Name'],
      ['Expense', '01/01/2026', '-10.0', 'Cash'],
      ['Expense', 'yesterday', '-10.0', 'Cash'],
    ]);
    expect(result.records, hasLength(1));
    expect(result.warnings.single.kind, ExchangeWarningKind.unreadableRow);
  });
}

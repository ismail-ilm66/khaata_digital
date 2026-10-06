import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/features/import_export/data/hk_sheet.dart';
import 'package:khaata_digital/features/import_export/data/spreadsheet_codec.dart';
import 'package:khaata_digital/features/import_export/data/xls_reader.dart';

/// Fixtures come from tool/make_xls_fixtures.py (synthetic, not personal).
List<int> fixture(String name) =>
    File('test/fixtures/import/$name').readAsBytesSync();

void main() {
  group('XlsReader', () {
    test('reads a Hysab Kytab export: three text sheets in order', () {
      final sheets = XlsReader.read(fixture('hk_sample.xls'));
      expect(sheets.map((s) => s.name), ['ACTIVITIES', 'ACCOUNT', 'CATEGORY']);
      final activities = sheets.first.rows;
      expect(activities.first, HkColumns.hysabKytab);
      expect(activities, hasLength(17));
      expect(activities[1], [
        'Expense',
        '01/09/2026',
        '-2520.0',
        'Lunch', // trimmed
        'Food & Drink',
        'Meezan Bank',
        'Office, Lunch, office',
        '',
        '',
        '',
        '',
        '0.0',
        '',
        '',
      ]);
      expect(activities[11][3], 'چائے', reason: 'Unicode survives');
      expect(sheets[1].rows[2], [
        'Meezan Bank',
        '10000.0',
        '104230.0',
        '114230.0',
      ]);
    });

    test('numbers (MULRK, NUMBER) read as plain text', () {
      final numbers = XlsReader.read(fixture('biff8_cells.xls')).first.rows;
      expect(numbers[0], ['int', 'float', 'neg', 'big', '', '']);
      expect(numbers[1].take(4), ['10', '1.25', '-1.5', '123456789.125']);
      expect(numbers[5].take(4), ['50', '5.25', '-7.5', '123456789.125']);
      expect(numbers[6], everyElement(''), reason: 'empty row kept');
      expect(numbers[7][5], 'gap');
    });

    test('strings split across CONTINUE records come back whole', () {
      final sheets = XlsReader.read(fixture('biff8_cells.xls'));
      final strings = sheets[1].rows;
      expect(strings, hasLength(600));
      for (final r in [0, 199, 387, 599]) {
        final n = r.toString().padLeft(4, '0');
        expect(strings[r][0], 'row $n ${'abcdefghij' * 3}');
        expect(strings[r][1], 'قطار $n ${'اردو متن ' * 3}'.trim());
      }
      expect(sheets[2].rows, isEmpty, reason: 'empty sheet');
    });

    test('rejects files that are not .xls', () {
      expect(XlsReader.looksLikeXls([1, 2, 3]), isFalse);
      expect(() => XlsReader.read('a,b\n1,2'.codeUnits), throwsFormatException);
      final truncated = fixture('hk_sample.xls').sublist(0, 1024);
      expect(() => XlsReader.read(truncated), throwsFormatException);
    });
  });

  group('SpreadsheetCodec.decode detects the format', () {
    test('xls, xlsx and csv', () {
      expect(
        SpreadsheetCodec.decode(fixture('hk_sample.xls')).first.name,
        'ACTIVITIES',
      );
      final xlsx = SpreadsheetCodec.encodeXlsx([
        (
          name: 'ACTIVITIES',
          rows: [
            ['a', 'b'],
          ],
        ),
      ]);
      expect(SpreadsheetCodec.decode(xlsx).single.rows, [
        ['a', 'b'],
      ]);
      final csv = SpreadsheetCodec.encodeCsv([
        ['x', 'y'],
      ]);
      expect(SpreadsheetCodec.activities(SpreadsheetCodec.decode(csv)), [
        ['x', 'y'],
      ]);
    });
  });
}

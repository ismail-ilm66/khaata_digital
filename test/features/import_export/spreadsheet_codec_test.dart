import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/features/import_export/data/spreadsheet_codec.dart';

void main() {
  test('a SQLite database (an app backup) is recognised, not read as CSV', () {
    final db = File('test/fixtures/golden/v2/kharcha.db').readAsBytesSync();
    expect(SpreadsheetCodec.looksLikeDatabase(db), isTrue);
    expect(
      () => SpreadsheetCodec.decode(db),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          SpreadsheetCodec.databaseFile,
        ),
      ),
    );
  });

  test('other binary junk is unreadable, not a one-column table', () {
    final junk = [0x00, 0x01, 0xFF, 0x10, 0x00, 0x41, 0x0A, 0x00, 0x42];
    expect(() => SpreadsheetCodec.decode(junk), throwsFormatException);
  });

  test('a real CSV still decodes', () {
    final csv = utf8.encode('Date,Amount\n2026-10-01,250\n');
    expect(SpreadsheetCodec.looksLikeDatabase(csv), isFalse);
    expect(SpreadsheetCodec.activities(SpreadsheetCodec.decode(csv)), [
      ['Date', 'Amount'],
      ['2026-10-01', '250'],
    ]);
  });
}

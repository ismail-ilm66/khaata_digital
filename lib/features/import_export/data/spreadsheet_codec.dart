import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

/// A named table of text cells (first row = header).
typedef Sheet = ({String name, List<List<String>> rows});

/// Turns sheets into `.xlsx` / `.csv` bytes and back. Cells are text, as in
/// Hysab Kytab's own export, so amounts never pass through floating point.
abstract final class SpreadsheetCodec {
  static const String activitiesSheet = 'ACTIVITIES';

  /// An `.xlsx` with one worksheet per [sheets] entry, in order.
  static List<int> encodeXlsx(List<Sheet> sheets) {
    final book = Excel.createExcel();
    final placeholder = book.getDefaultSheet()!;
    for (final s in sheets) {
      final sheet = book[s.name];
      for (final row in s.rows) {
        sheet.appendRow([for (final c in row) TextCellValue(c)]);
      }
    }
    if (!sheets.any((s) => s.name == placeholder)) book.delete(placeholder);
    book.setDefaultSheet(sheets.first.name);
    return book.encode()!;
  }

  /// Every worksheet in an `.xlsx`, cells as trimmed text.
  static List<Sheet> decodeXlsx(List<int> bytes) {
    final book = Excel.decodeBytes(bytes);
    return [
      for (final name in book.tables.keys)
        (
          name: name,
          rows: [
            for (final row in book.tables[name]!.rows)
              [for (final cell in row) _text(cell?.value)],
          ],
        ),
    ];
  }

  static String _text(CellValue? v) => switch (v) {
    null => '',
    TextCellValue(:final value) => (value.text ?? '').trim(),
    _ => v.toString().trim(),
  };

  /// UTF-8 CSV with a byte-order mark so Excel shows Urdu correctly.
  static List<int> encodeCsv(List<List<String>> rows) =>
      utf8.encode(Csv(addBom: true).encode(rows));

  static List<List<String>> decodeCsv(List<int> bytes) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1);
    return [
      for (final row in Csv().decode(text)) [for (final c in row) '$c'.trim()],
    ];
  }

  /// The activities table from any supported spreadsheet: the ACTIVITIES
  /// worksheet of an `.xlsx` (or its first sheet), or a whole CSV.
  static List<List<String>> activities(List<int> bytes, {required bool csv}) {
    if (csv) return decodeCsv(bytes);
    final sheets = decodeXlsx(bytes);
    return sheets
        .firstWhere(
          (s) => s.name.toUpperCase() == activitiesSheet,
          orElse: () => sheets.first,
        )
        .rows;
  }
}

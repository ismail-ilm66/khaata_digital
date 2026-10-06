import 'package:equatable/equatable.dart';

import '../../transactions/domain/entry_query.dart';

enum ExportFormat {
  xlsx(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ),
  csv('csv', 'text/csv');

  const ExportFormat(this.extension, this.mime);
  final String extension;
  final String mime;
}

class ExportFile extends Equatable {
  const ExportFile({
    required this.name,
    required this.mime,
    required this.bytes,
  });

  final String name;
  final String mime;
  final List<int> bytes;

  @override
  List<Object?> get props => [name, mime, bytes.length];
}

/// Writes entries in Hysab Kytab's layout (spec 3.3) so a Kharcha export is
/// re-importable into Kharcha — and Hysab Kytab.
abstract interface class Exporter {
  /// Every entry matching [query] (its limit is ignored: exports are never
  /// cut short). [label] goes into the file name.
  Future<ExportFile> export(
    EntryQuery query,
    ExportFormat format, {
    String label,
  });
}

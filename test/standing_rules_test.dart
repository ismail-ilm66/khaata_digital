import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source with `//` comments removed, so docs may mention banned words.
String _code(File f) => f
    .readAsLinesSync()
    .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
    .join('\n');

/// Enforces the spec's standing rules mechanically, so they can't regress.
void main() {
  Iterable<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

  test('no `double` in money, dates, database, data or domain code', () {
    final dirs = [
      'lib/core/money',
      'lib/core/dates',
      'lib/core/db',
      ...Directory('lib/features')
          .listSync()
          .whereType<Directory>()
          .expand((f) => ['${f.path}/data', '${f.path}/domain'])
          .where((d) => Directory(d).existsSync()),
    ];
    final offenders = [
      for (final dir in dirs)
        for (final file in dartFiles(dir))
          if (RegExp(r'\bdouble\b').hasMatch(_code(file))) file.path,
    ];
    expect(offenders, isEmpty, reason: 'Money is integer minor units only');
  });

  test('no network, analytics or ads packages outside backup', () {
    const banned = [
      'package:http/',
      'package:dio/',
      'firebase',
      'analytics',
      'google_mobile_ads',
      'sentry',
    ];
    final offenders = [
      for (final file in dartFiles('lib'))
        if (!file.path.contains('/features/backup/'))
          for (final b in banned)
            if (file.readAsStringSync().contains("import '$b") ||
                file.readAsStringSync().contains('import "$b'))
              '${file.path} → $b',
    ];
    expect(offenders, isEmpty);
  });

  test('icons come only from the AppIcons registry', () {
    // One icon language app-wide: no direct Material icons or icon-font
    // imports outside the registry.
    const registry = 'lib/core/widgets/app_icons.dart';
    final offenders = [
      for (final file in dartFiles('lib'))
        if (!file.path.endsWith(registry) &&
            (RegExp(r'\bIcons\.').hasMatch(_code(file)) ||
                _code(file).contains('package:phosphor_flutter')))
          file.path,
    ];
    expect(offenders, isEmpty);
  });

  test('date-cycle math lives only in BudgetCycle', () {
    // Building month boundaries by hand (`DateTime(y, m + 1, …)`) anywhere
    // else bypasses the custom month-start setting.
    final pattern = RegExp(r'DateTime\([^)]*\.month\s*[+-]\s*1');
    final offenders = [
      for (final file in dartFiles('lib'))
        if (!file.path.endsWith('core/dates/budget_cycle.dart') &&
            pattern.hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty);
  });
}

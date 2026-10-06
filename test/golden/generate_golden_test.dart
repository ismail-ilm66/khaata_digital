@Tags(['golden-generator'])
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';

import '../helpers/test_db.dart';
import 'golden_rows.dart';

/// One-shot generator for the **current** schema's golden database. Run
/// it once per schema version, then never again for that version:
///
///   KHARCHA_GENERATE_GOLDEN=1 flutter test test/golden/generate_golden_test.dart
///
/// Writes `test/fixtures/golden/v<schemaVersion>/kharcha.db` and refuses to
/// overwrite an existing fixture. expected.json is written by hand.
void main() {
  final enabled = Platform.environment['KHARCHA_GENERATE_GOLDEN'] == '1';

  test(
    'generate the golden database for the current schema',
    () async {
      final db = testDb();
      addTearDown(db.close);
      final salary = await seedGoldenRows(db);

      // v2: an imported entry is remembered by its source hash.
      await db
          .into(db.importHashes)
          .insert(
            ImportHashesCompanion.insert(
              hash: 'a' * 64,
              transactionId: Value(salary),
              importedAt: DateTime.utc(2026, 10, 6),
            ),
          );

      final out = File('test/fixtures/golden/v${db.schemaVersion}/kharcha.db');
      expect(out.existsSync(), isFalse, reason: 'fixtures are frozen');
      out.parent.createSync(recursive: true);
      await db.customStatement("VACUUM INTO '${out.absolute.path}'");
    },
    skip: enabled ? false : 'set KHARCHA_GENERATE_GOLDEN=1 to generate',
  );
}

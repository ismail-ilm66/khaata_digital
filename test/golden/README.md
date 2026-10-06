# Golden databases

`test/fixtures/golden/vN/` holds one real database file per schema version
ever shipped, plus `expected.json` with balances worked out **by hand**.
`golden_backup_test.dart` opens every one with the current app (running
migrations) and must reproduce those numbers to the paisa. This is a release
gate: a migration that breaks any fixture cannot ship.

## Changing the schema

1. Edit `lib/core/db/tables.dart` and bump `schemaVersion` in
   `lib/core/db/app_database.dart`.
2. `dart run drift_dev make-migrations` — snapshots the new schema into
   `drift_schemas/` and generates step-by-step helpers and migration tests.
3. Write the migration step in `AppDatabase.migration.onUpgrade`.
4. In `generate_golden_test.dart`, add rows that use the new columns or
   tables (shared rows live in `golden_rows.dart`). Run it once with
   `KHARCHA_GENERATE_GOLDEN=1` to write `vN/kharcha.db`, hand-compute
   `vN/expected.json`, and commit both.
5. Never edit or regenerate an older fixture.

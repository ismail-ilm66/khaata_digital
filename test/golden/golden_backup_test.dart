import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/features/accounts/data/accounts_dao.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';

/// Release gate (spec 3.4): every golden database from every schema
/// version ever shipped must open in the current app — migrating if
/// needed — and reproduce its known balances to the paisa.
void main() {
  final fixtures =
      Directory(
          'test/fixtures/golden',
        ).listSync().whereType<Directory>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('at least one golden fixture exists', () {
    expect(fixtures, isNotEmpty);
  });

  for (final dir in fixtures) {
    final name = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;

    group('golden $name', () {
      late AppDatabase db;
      late Map<String, dynamic> expected;

      setUp(() async {
        expected =
            jsonDecode(File('${dir.path}/expected.json').readAsStringSync())
                as Map<String, dynamic>;
        // Work on a copy: opening may migrate the file in place.
        final tmp = await Directory.systemTemp.createTemp('kharcha_golden_');
        final copy = await File(
          '${dir.path}/kharcha.db',
        ).copy('${tmp.path}/kharcha.db');
        db = AppDatabase(NativeDatabase(copy));
        addTearDown(() async {
          await db.close();
          await tmp.delete(recursive: true);
        });
      });

      test('passes the integrity check', () async {
        expect(await db.checkIntegrity(), isTrue);
      });

      test('reproduces every account balance to the paisa', () async {
        final balances = await db.accountsDao.balances();
        expect({
          for (final b in balances) b.account.name: b.balanceMinor,
        }, expected['accounts']);
        expect(
          (await db.accountsDao.archived()).map((a) => a.name),
          expected['archived_accounts'],
        );
        expect(
          AccountBalance.totalsByCurrency(balances),
          expected['net_worth'],
        );
      });

      test('reproduces udhaar balances', () async {
        expect({
          for (final p in await db.peopleDao.balances())
            p.person.name: p.byCurrency,
        }, expected['people']);
      });

      test('keeps every row', () async {
        final counts = expected['row_counts'] as Map<String, dynamic>;
        for (final MapEntry(key: table, value: count) in counts.entries) {
          final row = await db
              .customSelect('SELECT COUNT(*) AS n FROM $table')
              .getSingle();
          expect(row.read<int>('n'), count, reason: table);
        }
      });

      test('keeps settings', () async {
        final settings = expected['settings'] as Map<String, dynamic>;
        for (final key in SettingKey.values) {
          final stored = settings[key.storageKey];
          if (stored != null) {
            expect(await db.settingsDao.read(key), stored, reason: key.name);
          }
        }
      });
    });
  }
}

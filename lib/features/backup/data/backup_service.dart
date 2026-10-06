import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/app_database.dart';
import '../../transactions/data/receipt_store.dart';
import '../domain/backup.dart';
import 'backup_archive.dart';

/// Builds `.kharcha` archives and restores them (spec 3.4, M5).
///
/// Restore never risks existing data: the backup's database is first
/// written to a temp file, migrated to this app's schema and integrity
/// checked on its own connection. Only then is it attached to the live
/// database and copied in, inside one transaction — any error rolls the
/// whole restore back.
@lazySingleton
class BackupService {
  BackupService(this._db, this._receipts);

  final AppDatabase _db;
  final ReceiptStore _receipts;

  /// Replaceable in tests.
  DateTime Function() now = DateTime.now;
  Future<String> Function() appVersion = _packageVersion;
  int iterations = BackupArchive.defaultIterations;

  /// Automatic on-device copies kept (spec 3.4: "retains last 8").
  static const int keepOnDevice = 8;
  static const String deviceFolder = 'backups';

  /// This app's schema version; newer backups can't be restored.
  int get schemaVersion => _db.schemaVersion;

  static Future<String> _packageVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  /// `Kharcha-backup-2026-10-06-1430.kharcha`
  static String fileName(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Kharcha-backup-${at.year}-${two(at.month)}-${two(at.day)}-'
        '${two(at.hour)}${two(at.minute)}.${BackupFile.extension}';
  }

  // Off the UI isolate. Static so the closures capture only their
  // arguments, never this service (whose database can't be sent).
  static Future<List<int>> _pack(
    BackupManifest manifest,
    List<int> database,
    Map<String, List<int>> receipts,
    String? passphrase,
    int iterations,
  ) => Isolate.run(
    () => BackupArchive.pack(
      manifest: manifest,
      database: database,
      receipts: receipts,
      passphrase: passphrase,
      iterations: iterations,
    ),
  );

  static Future<BackupManifest> _inspect(List<int> bytes) =>
      Isolate.run(() => BackupArchive.manifestOf(bytes));

  static Future<BackupContents> _unpack(List<int> bytes, String? passphrase) =>
      Isolate.run(() => BackupArchive.unpack(bytes, passphrase: passphrase));

  // ── Backup ────────────────────────────────────────────────────────────

  Future<BackupFile> create({String? passphrase}) async {
    final tmp = await Directory.systemTemp.createTemp('kharcha_backup_');
    try {
      final snapshot = p.join(tmp.path, BackupArchive.databaseName);
      // A consistent, compacted copy, even while the app keeps writing.
      await _db.customStatement('VACUUM INTO ?', [snapshot]);
      final database = await File(snapshot).readAsBytes();
      final receipts = await _receiptFiles();
      final manifest = await _manifest();
      final bytes = await _pack(
        manifest,
        database,
        receipts,
        passphrase,
        iterations,
      );
      return BackupFile(
        fileName(manifest.createdAt.toLocal()),
        bytes,
        BackupArchive.manifestOf(bytes),
      );
    } finally {
      await tmp.delete(recursive: true);
    }
  }

  Future<Map<String, List<int>>> _receiptFiles() async {
    final out = <String, List<int>>{};
    for (final a in await _db.select(_db.attachments).get()) {
      final file = File(await _receipts.pathOf(a.fileName));
      if (await file.exists()) out[a.fileName] = await file.readAsBytes();
    }
    return out;
  }

  Future<BackupManifest> _manifest() async {
    final counts = <String, int>{};
    for (final t in _db.allTables) {
      counts[t.actualTableName] = await _count(
        'SELECT COUNT(*) AS n FROM ${t.actualTableName}',
      );
    }
    final range = await _db
        .customSelect(
          'SELECT MIN(occurred_at) AS a, MAX(occurred_at) AS b, COUNT(*) AS n '
          'FROM transactions WHERE deleted_at IS NULL',
        )
        .getSingle();
    DateTime? at(String c) {
      final v = range.read<int?>(c);
      return v == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
    }

    return BackupManifest(
      schemaVersion: _db.schemaVersion,
      appVersion: await appVersion(),
      createdAt: now().toUtc(),
      rowCounts: counts,
      accounts: await _count(
        'SELECT COUNT(*) AS n FROM accounts WHERE deleted_at IS NULL',
      ),
      transactions: range.read<int>('n'),
      first: at('a'),
      last: at('b'),
    );
  }

  Future<int> _count(String sql) async =>
      (await _db.customSelect(sql).getSingle()).read<int>('n');

  /// Notes a finished backup in the history (`backup_meta`).
  Future<void> record(BackupFile file, BackupDestination destination) => _db
      .into(_db.backupMeta)
      .insert(
        BackupMetaCompanion.insert(
          createdAt: file.manifest.createdAt,
          destination: destination.name,
          schemaVersion: file.manifest.schemaVersion,
          rowCounts: jsonEncode(file.manifest.rowCounts),
        ),
      );

  /// The latest backup; [offDevice] skips the automatic on-device copies,
  /// which don't survive an uninstall.
  Stream<BackupRecord?> watchLast({bool offDevice = false}) {
    final q = _db.select(_db.backupMeta)
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)])
      ..limit(1);
    if (offDevice) {
      q.where((b) => b.destination.equals(BackupDestination.device.name).not());
    }
    return q.watchSingleOrNull().map(
      (r) => r == null
          ? null
          : BackupRecord(
              createdAt: r.createdAt,
              destination:
                  BackupDestination.values.asNameMap()[r.destination] ??
                  BackupDestination.file,
              schemaVersion: r.schemaVersion,
            ),
    );
  }

  /// When the latest backup to [destination] (or anywhere) was made.
  Future<DateTime?> lastAt([BackupDestination? destination]) async {
    final q = _db.selectOnly(_db.backupMeta)
      ..addColumns([_db.backupMeta.createdAt.max()]);
    if (destination != null) {
      q.where(_db.backupMeta.destination.equals(destination.name));
    }
    final ms = await q
        .map((r) => r.read(_db.backupMeta.createdAt.max()))
        .getSingle();
    return ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<Directory> _deviceDir() async {
    final dir = Directory(p.join((await _receipts.root()).path, deviceFolder));
    await dir.create(recursive: true);
    return dir;
  }

  /// Keeps [file] in the app's own storage and prunes to the newest
  /// [keepOnDevice] copies.
  Future<File> saveOnDevice(BackupFile file) async {
    final dir = await _deviceDir();
    final out = await File(
      p.join(dir.path, file.name),
    ).writeAsBytes(file.bytes, flush: true);
    final all = await deviceBackups();
    for (final old in all.skip(keepOnDevice)) {
      await old.delete();
    }
    await record(file, BackupDestination.device);
    return out;
  }

  /// On-device copies, newest first.
  Future<List<File>> deviceBackups() async {
    final dir = await _deviceDir();
    final files = [
      await for (final f in dir.list())
        if (f is File && f.path.endsWith('.${BackupFile.extension}')) f,
    ]..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    return files;
  }

  // ── Restore ───────────────────────────────────────────────────────────

  /// Reads just the manifest, for the preview. Throws [BackupFailure].
  Future<BackupManifest> inspect(List<int> bytes) => _inspect(bytes);

  /// Restores [bytes]. Throws [BackupFailure] — always before any existing
  /// data has changed.
  Future<RestoreResult> restore(
    List<int> bytes, {
    required RestoreMode mode,
    String? passphrase,
  }) async {
    final contents = await _unpack(bytes, passphrase);
    if (contents.manifest.schemaVersion > _db.schemaVersion) {
      throw const BackupFailure(BackupFailureKind.newerApp);
    }

    final tmp = await Directory.systemTemp.createTemp('kharcha_restore_');
    final root = (await _receipts.root()).path;
    final incoming = Directory(p.join(root, '${ReceiptStore.folder}.incoming'));
    try {
      final staged = File(p.join(tmp.path, 'restore.db'));
      await staged.writeAsBytes(contents.database, flush: true);
      await _migrateAndVerify(staged);

      if (await incoming.exists()) await incoming.delete(recursive: true);
      await incoming.create(recursive: true);
      for (final MapEntry(key: name, value: data)
          in contents.receipts.entries) {
        await File(p.join(incoming.path, name)).writeAsBytes(data, flush: true);
      }

      await _db.customStatement('ATTACH DATABASE ? AS bk', [staged.path]);
      try {
        await _db.transaction(() async {
          await _db.customStatement('PRAGMA defer_foreign_keys = ON');
          await (mode == RestoreMode.replace ? _replace() : _merge());
        });
      } on BackupFailure {
        rethrow;
      } catch (e) {
        throw BackupFailure(BackupFailureKind.conflict, '$e');
      } finally {
        await _db.customStatement('DETACH DATABASE bk');
      }

      await _placeReceipts(
        incoming,
        Directory(p.join(root, ReceiptStore.folder)),
        mode,
      );
      _db.markTablesUpdated(_db.allTables);
      return RestoreResult(
        mode: mode,
        manifest: contents.manifest,
        accounts: await _count(
          'SELECT COUNT(*) AS n FROM accounts WHERE deleted_at IS NULL',
        ),
        transactions: await _count(
          'SELECT COUNT(*) AS n FROM transactions WHERE deleted_at IS NULL',
        ),
        receipts: await _count('SELECT COUNT(*) AS n FROM attachments'),
      );
    } finally {
      if (await incoming.exists()) await incoming.delete(recursive: true);
      await tmp.delete(recursive: true);
    }
  }

  /// Opens the staged copy on its own connection: runs any migrations
  /// from its schema version to ours, then checks integrity and keys.
  static Future<void> _migrateAndVerify(File staged) async {
    final db = AppDatabase(NativeDatabase(staged));
    try {
      if (!await db.checkIntegrity()) {
        throw const BackupFailure(BackupFailureKind.integrity);
      }
      final broken = await db.customSelect('PRAGMA foreign_key_check').get();
      if (broken.isNotEmpty) {
        throw const BackupFailure(BackupFailureKind.integrity, 'foreign keys');
      }
      // Fold the WAL back in so the attached file is complete.
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } on BackupFailure {
      rethrow;
    } catch (e) {
      throw BackupFailure(BackupFailureKind.integrity, '$e');
    } finally {
      await db.close();
    }
  }

  /// Tables copied by a restore, parents before children. Backup history
  /// stays this device's own.
  List<String> get _tables => [
    for (final t in _db.allTables)
      if (t.actualTableName != _db.backupMeta.actualTableName)
        t.actualTableName,
  ];

  Future<List<String>> _columns(String schema, String table) async => [
    for (final r
        in await _db.customSelect('PRAGMA $schema.table_info($table)').get())
      r.read<String>('name'),
  ];

  /// Columns both copies have (an older backup was migrated, so normally
  /// all of them).
  Future<List<String>> _shared(String table) async {
    final theirs = (await _columns('bk', table)).toSet();
    return [
      for (final c in await _columns('main', table))
        if (theirs.contains(c)) c,
    ];
  }

  Future<void> _replace() async {
    for (final t in _tables.reversed) {
      await _db.customStatement('DELETE FROM main.$t');
    }
    for (final t in _tables) {
      final cols = (await _shared(t)).join(', ');
      await _db.customStatement(
        'INSERT INTO main.$t ($cols) SELECT $cols FROM bk.$t',
      );
    }
  }

  /// Keeps everything here and adds what the backup has that this device
  /// doesn't. Same-name accounts, categories, people, tags and events are
  /// treated as one (the backup's rows are re-pointed at this device's);
  /// for entries in both copies the more recent edit wins.
  Future<void> _merge() async {
    await _db.customStatement(
      'CREATE TEMP TABLE IF NOT EXISTS restore_map '
      '(old TEXT PRIMARY KEY, new TEXT NOT NULL)',
    );
    await _db.customStatement('DELETE FROM temp.restore_map');

    const live = 'm.deleted_at IS NULL AND b.deleted_at IS NULL';
    const sameName = 'm.name = b.name COLLATE NOCASE';
    final matches = {
      'accounts': '$sameName AND $live',
      'categories': 'm.kind = b.kind AND $sameName AND $live',
      'people': '$sameName AND $live',
      'tags': sameName,
      'events': sameName,
    };
    for (final MapEntry(key: t, value: on) in matches.entries) {
      await _db.customStatement(
        'INSERT OR IGNORE INTO temp.restore_map (old, new) '
        'SELECT b.id, m.id FROM bk.$t b JOIN main.$t m ON $on '
        'WHERE b.id <> m.id AND NOT EXISTS '
        '(SELECT 1 FROM main.$t x WHERE x.id = b.id)',
      );
    }

    const references = {
      'categories': ['parent_id'],
      'transactions': [
        'account_id',
        'to_account_id',
        'category_id',
        'person_id',
      ],
      'transaction_tags': ['tag_id'],
      'transaction_events': ['event_id'],
      'budgets': ['category_id'],
    };
    const newerWins = {
      'accounts',
      'categories',
      'people',
      'transactions',
      'recurring_rules',
    };
    for (final t in _tables) {
      final cols = await _shared(t);
      final refs = references[t] ?? const [];
      final select = [
        for (final c in cols)
          refs.contains(c)
              ? 'COALESCE((SELECT new FROM temp.restore_map '
                    'WHERE old = b.$c), b.$c)'
              : 'b.$c',
      ].join(', ');
      final unmapped = cols.contains('id')
          ? 'b.id NOT IN (SELECT old FROM temp.restore_map)'
          : 'true';
      final into =
          'INTO main.$t (${cols.join(', ')}) '
          'SELECT $select FROM bk.$t b WHERE $unmapped';
      if (newerWins.contains(t)) {
        final set = [
          for (final c in cols)
            if (c != 'id') '$c = excluded.$c',
        ].join(', ');
        await _db.customStatement(
          'INSERT $into ON CONFLICT(id) DO UPDATE SET $set '
          'WHERE excluded.updated_at > $t.updated_at',
        );
      } else {
        // Settings, budgets, labels, receipts, import history: keep ours.
        await _db.customStatement('INSERT OR IGNORE $into');
      }
    }
  }

  static Future<void> _placeReceipts(
    Directory incoming,
    Directory receipts,
    RestoreMode mode,
  ) async {
    if (mode == RestoreMode.replace) {
      final old = Directory('${receipts.path}.old');
      if (await old.exists()) await old.delete(recursive: true);
      if (await receipts.exists()) await receipts.rename(old.path);
      await incoming.rename(receipts.path);
      if (await old.exists()) await old.delete(recursive: true);
      return;
    }
    await receipts.create(recursive: true);
    await for (final f in incoming.list()) {
      if (f is! File) continue;
      final target = File(p.join(receipts.path, p.basename(f.path)));
      if (!await target.exists()) await f.rename(target.path);
    }
  }
}

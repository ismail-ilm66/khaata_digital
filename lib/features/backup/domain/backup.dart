import 'package:equatable/equatable.dart';

/// The cleartext description inside every `.kharcha` archive (spec 3.4).
/// Stays readable even when the data is encrypted, so restore can preview
/// a backup before asking for its passphrase.
class BackupManifest extends Equatable {
  const BackupManifest({
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.rowCounts,
    required this.accounts,
    required this.transactions,
    this.first,
    this.last,
    this.files = const {},
    this.encryption,
  });

  /// Bumped only if the archive layout itself changes.
  static const int formatVersion = 1;
  static const String format = 'kharcha-backup';

  final int schemaVersion;
  final String appVersion;
  final DateTime createdAt;

  /// Table name → row count.
  final Map<String, int> rowCounts;

  /// For the restore preview: active accounts, live entries and their
  /// date range.
  final int accounts;
  final int transactions;
  final DateTime? first;
  final DateTime? last;

  /// Archive path → SHA-256 of its plain bytes (`data.db`, `receipts/…`).
  final Map<String, String> files;

  /// Null when not encrypted.
  final BackupEncryption? encryption;

  bool get encrypted => encryption != null;

  BackupManifest copyWith({
    Map<String, String>? files,
    BackupEncryption? Function()? encryption,
  }) => BackupManifest(
    schemaVersion: schemaVersion,
    appVersion: appVersion,
    createdAt: createdAt,
    rowCounts: rowCounts,
    accounts: accounts,
    transactions: transactions,
    first: first,
    last: last,
    files: files ?? this.files,
    encryption: encryption == null ? this.encryption : encryption(),
  );

  Map<String, Object?> toJson() => {
    'format': format,
    'format_version': formatVersion,
    'schema_version': schemaVersion,
    'app_version': appVersion,
    'created_at': createdAt.toUtc().toIso8601String(),
    'row_counts': rowCounts,
    'summary': {
      'accounts': accounts,
      'transactions': transactions,
      'first': first?.toUtc().toIso8601String(),
      'last': last?.toUtc().toIso8601String(),
    },
    'files': files,
    'encryption': encryption?.toJson(),
  };

  /// Throws [BackupFailure] when [json] isn't a Kharcha manifest.
  static BackupManifest fromJson(Object? json) {
    try {
      final m = json! as Map<String, Object?>;
      if (m['format'] != format) throw const BackupFailure.notABackup();
      if ((m['format_version']! as int) > formatVersion) {
        throw const BackupFailure(BackupFailureKind.newerApp);
      }
      final summary = m['summary']! as Map<String, Object?>;
      DateTime? date(Object? s) =>
          s == null ? null : DateTime.parse(s as String).toUtc();
      final enc = m['encryption'] as Map<String, Object?>?;
      return BackupManifest(
        schemaVersion: m['schema_version']! as int,
        appVersion: m['app_version']! as String,
        createdAt: date(m['created_at'])!,
        rowCounts: (m['row_counts']! as Map).cast<String, int>(),
        accounts: summary['accounts']! as int,
        transactions: summary['transactions']! as int,
        first: date(summary['first']),
        last: date(summary['last']),
        files: (m['files']! as Map).cast<String, String>(),
        encryption: enc == null ? null : BackupEncryption.fromJson(enc),
      );
    } on BackupFailure {
      rethrow;
    } catch (_) {
      throw const BackupFailure.notABackup();
    }
  }

  @override
  List<Object?> get props => [
    schemaVersion,
    appVersion,
    createdAt,
    rowCounts,
    accounts,
    transactions,
    first,
    last,
    files,
    encryption,
  ];
}

/// AES-256-GCM with a key from PBKDF2-HMAC-SHA256 over the passphrase.
class BackupEncryption extends Equatable {
  const BackupEncryption({required this.salt, required this.iterations});

  static const String cipher = 'AES-256-GCM';
  static const String kdf = 'PBKDF2-HMAC-SHA256';

  final List<int> salt;
  final int iterations;

  Map<String, Object?> toJson() => {
    'cipher': cipher,
    'kdf': kdf,
    'salt': salt,
    'iterations': iterations,
  };

  static BackupEncryption fromJson(Map<String, Object?> j) {
    if (j['cipher'] != cipher || j['kdf'] != kdf) {
      throw const BackupFailure(BackupFailureKind.newerApp);
    }
    return BackupEncryption(
      salt: (j['salt']! as List).cast<int>(),
      iterations: j['iterations']! as int,
    );
  }

  @override
  List<Object?> get props => [salt, iterations];
}

enum BackupFailureKind {
  /// Not a `.kharcha` file at all.
  notABackup,

  /// Made by a newer Kharcha (schema or archive format).
  newerApp,

  /// Encrypted and the passphrase is missing or wrong.
  wrongPassphrase,

  /// A file's SHA-256 doesn't match the manifest: damaged or edited.
  damaged,

  /// The database inside fails SQLite's integrity check.
  integrity,

  /// Merging hit a conflict it can't resolve (nothing was changed).
  conflict,
}

/// A backup or restore that couldn't complete. Restores fail *before*
/// touching existing data (spec 3.4: "a failed restore can never destroy
/// existing data").
class BackupFailure extends Equatable implements Exception {
  const BackupFailure(this.kind, [this.detail = '']);
  const BackupFailure.notABackup() : this(BackupFailureKind.notABackup);

  final BackupFailureKind kind;
  final String detail;

  @override
  List<Object?> get props => [kind, detail];

  @override
  String toString() =>
      'BackupFailure($kind${detail.isEmpty ? '' : ': $detail'})';
}

/// Replace wipes this device's data first; merge keeps it and adds what's
/// missing (the newer edit wins for entries in both).
enum RestoreMode { replace, merge }

/// Where a backup went.
enum BackupDestination {
  /// A file the user saved (Storage Access Framework / Files app).
  file,

  /// The user's own Google Drive, in a visible "Kharcha Backups" folder.
  drive,

  /// Automatic copies kept in the app's own storage (before imports and
  /// restores, and weekly when Drive isn't connected).
  device,
}

/// One row of backup history (`backup_meta`).
class BackupRecord extends Equatable {
  const BackupRecord({
    required this.createdAt,
    required this.destination,
    required this.schemaVersion,
  });

  final DateTime createdAt;
  final BackupDestination destination;
  final int schemaVersion;

  @override
  List<Object?> get props => [createdAt, destination, schemaVersion];
}

/// A finished archive, ready to save or upload.
class BackupFile extends Equatable {
  const BackupFile(this.name, this.bytes, this.manifest);

  static const String extension = 'kharcha';

  final String name;
  final List<int> bytes;
  final BackupManifest manifest;

  @override
  List<Object?> get props => [name, manifest];
}

/// What a restore did.
class RestoreResult extends Equatable {
  const RestoreResult({
    required this.mode,
    required this.manifest,
    required this.accounts,
    required this.transactions,
    required this.receipts,
  });

  final RestoreMode mode;
  final BackupManifest manifest;

  /// After the restore, on this device.
  final int accounts;
  final int transactions;
  final int receipts;

  @override
  List<Object?> get props => [mode, manifest, accounts, transactions, receipts];
}

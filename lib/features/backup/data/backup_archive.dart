import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';

import '../domain/backup.dart';

/// The contents of a `.kharcha` archive once opened and verified.
typedef BackupContents = ({
  BackupManifest manifest,
  List<int> database,
  Map<String, List<int>> receipts,
});

/// The `.kharcha` file format (spec 3.4): a ZIP holding `manifest.json`
/// (always cleartext), `data.db` and `receipts/<file>`. When encrypted,
/// `data.db` and the receipts travel together as one AES-256-GCM sealed
/// `payload.bin` (nonce + ciphertext + tag), and the manifest records the
/// key-derivation salt and iteration count.
///
/// Pure Dart with no I/O, so it runs in a background isolate.
abstract final class BackupArchive {
  static const String manifestName = 'manifest.json';
  static const String databaseName = 'data.db';
  static const String receiptsFolder = 'receipts';
  static const String payloadName = 'payload.bin';

  /// PBKDF2 rounds for new encrypted backups.
  static const int defaultIterations = 120000;

  static final _aes = AesGcm.with256bits();

  static String sha256(List<int> bytes) =>
      hash.sha256.convert(bytes).toString();

  /// Builds the archive. [manifest]'s `files` and `encryption` are filled
  /// in here.
  static Future<List<int>> pack({
    required BackupManifest manifest,
    required List<int> database,
    required Map<String, List<int>> receipts,
    String? passphrase,
    int iterations = defaultIterations,
  }) async {
    final inner = <String, List<int>>{
      databaseName: database,
      for (final MapEntry(key: name, value: bytes) in receipts.entries)
        '$receiptsFolder/$name': bytes,
    };
    var m = manifest.copyWith(
      files: {for (final e in inner.entries) e.key: sha256(e.value)},
      encryption: () => null,
    );

    final outer = Archive();
    if (passphrase == null) {
      for (final e in inner.entries) {
        outer.addFile(_file(e.key, e.value, compress: e.key == databaseName));
      }
    } else {
      final salt = SecretKeyData.random(length: 16).bytes;
      m = m.copyWith(
        encryption: () => BackupEncryption(salt: salt, iterations: iterations),
      );
      final plain = _zip({
        for (final e in inner.entries)
          e.key: _file(e.key, e.value, compress: e.key == databaseName),
      });
      final box = await _aes.encrypt(
        plain,
        secretKey: await _key(passphrase, m.encryption!),
      );
      outer.addFile(_file(payloadName, box.concatenation(), compress: false));
    }
    outer.addFile(
      _file(
        manifestName,
        utf8.encode(const JsonEncoder.withIndent('  ').convert(m.toJson())),
        compress: true,
      ),
    );
    return ZipEncoder().encode(outer)!;
  }

  /// Just the manifest, for the restore preview (no passphrase needed).
  static BackupManifest manifestOf(List<int> bytes) => _manifest(_unzip(bytes));

  /// Opens and verifies every file against the manifest's SHA-256.
  static Future<BackupContents> unpack(
    List<int> bytes, {
    String? passphrase,
  }) async {
    final outer = _unzip(bytes);
    final manifest = _manifest(outer);
    var files = outer;
    final enc = manifest.encryption;
    if (enc != null) {
      final payload = outer.findFile(payloadName);
      if (payload == null) throw const BackupFailure(BackupFailureKind.damaged);
      if (passphrase == null || passphrase.isEmpty) {
        throw const BackupFailure(BackupFailureKind.wrongPassphrase);
      }
      final List<int> plain;
      try {
        plain = await _aes.decrypt(
          SecretBox.fromConcatenation(
            _bytes(payload),
            nonceLength: _aes.nonceLength,
            macLength: _aes.macAlgorithm.macLength,
          ),
          secretKey: await _key(passphrase, enc),
        );
      } on SecretBoxAuthenticationError {
        throw const BackupFailure(BackupFailureKind.wrongPassphrase);
      } catch (_) {
        throw const BackupFailure(BackupFailureKind.damaged);
      }
      files = _unzip(plain, failure: BackupFailureKind.damaged);
    }

    List<int>? database;
    final receipts = <String, List<int>>{};
    if (!manifest.files.containsKey(databaseName)) {
      throw const BackupFailure(BackupFailureKind.damaged, 'no database');
    }
    for (final MapEntry(key: path, value: expected) in manifest.files.entries) {
      final file = files.findFile(path);
      if (file == null) {
        throw BackupFailure(BackupFailureKind.damaged, 'missing $path');
      }
      final content = _bytes(file);
      if (sha256(content) != expected) {
        throw BackupFailure(BackupFailureKind.damaged, 'changed $path');
      }
      if (path == databaseName) {
        database = content;
      } else {
        final name = path.substring(receiptsFolder.length + 1);
        if (!path.startsWith('$receiptsFolder/') || !_safeName(name)) {
          throw BackupFailure(BackupFailureKind.damaged, 'bad path $path');
        }
        receipts[name] = content;
      }
    }
    return (manifest: manifest, database: database!, receipts: receipts);
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static bool _safeName(String n) =>
      n.isNotEmpty &&
      !n.contains('/') &&
      !n.contains('\\') &&
      n != '.' &&
      n != '..';

  static Future<SecretKey> _key(String passphrase, BackupEncryption e) =>
      Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: e.iterations,
        bits: 256,
      ).deriveKeyFromPassword(password: passphrase, nonce: e.salt);

  static ArchiveFile _file(
    String name,
    List<int> bytes, {
    required bool compress,
  }) {
    final f = ArchiveFile(name, bytes.length, bytes);
    // Receipts are already JPEG-compressed; storing them is faster.
    if (!compress) f.compress = false;
    return f;
  }

  static List<int> _zip(Map<String, ArchiveFile> files) {
    final a = Archive();
    files.values.forEach(a.addFile);
    return ZipEncoder().encode(a)!;
  }

  static Archive _unzip(
    List<int> bytes, {
    BackupFailureKind failure = BackupFailureKind.notABackup,
  }) {
    try {
      return ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (_) {
      throw BackupFailure(failure);
    }
  }

  static BackupManifest _manifest(Archive a) {
    final f = a.findFile(manifestName);
    if (f == null) throw const BackupFailure.notABackup();
    try {
      return BackupManifest.fromJson(jsonDecode(utf8.decode(_bytes(f))));
    } on FormatException {
      throw const BackupFailure.notABackup();
    }
  }

  static Uint8List _bytes(ArchiveFile f) {
    final c = f.content;
    return c is Uint8List ? c : Uint8List.fromList(c as List<int>);
  }
}

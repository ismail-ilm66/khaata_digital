import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/db/columns.dart';
import '../../../core/error/app_failure.dart';

/// Metadata for a receipt written to disk.
@immutable
class StoredReceipt {
  const StoredReceipt(this.fileName, this.mime, this.byteSize, this.sha256);

  final String fileName;
  final String mime;
  final int byteSize;
  final String sha256;
}

/// Receipt images live as compressed JPEGs in `<app documents>/receipts/`
/// (spec 1.5 #3) and are referenced from the `attachments` table by file
/// name. The SHA-256 lets a restore verify every byte (M5).
class ReceiptStore {
  ReceiptStore({required this.root, required this.compress});

  /// The app documents directory.
  final Future<Directory> Function() root;

  /// Returns JPEG bytes for the image at a path, or null if unreadable.
  final Future<List<int>?> Function(String sourcePath) compress;

  static const String folder = 'receipts';

  Future<Directory> _dir() async {
    final dir = Directory(p.join((await root()).path, folder));
    await dir.create(recursive: true);
    return dir;
  }

  Future<StoredReceipt> store(String sourcePath) async {
    final List<int>? bytes;
    try {
      bytes = await compress(sourcePath);
    } catch (e) {
      throw StorageFailure('Could not read image: $e');
    }
    if (bytes == null || bytes.isEmpty) {
      throw const StorageFailure('Could not read image');
    }
    final name = '${newId()}.jpg';
    await File(
      p.join((await _dir()).path, name),
    ).writeAsBytes(bytes, flush: true);
    return StoredReceipt(
      name,
      'image/jpeg',
      bytes.length,
      sha256.convert(bytes).toString(),
    );
  }

  Future<String> pathOf(String fileName) async =>
      p.join((await _dir()).path, fileName);

  Future<void> delete(String fileName) async {
    final file = File(await pathOf(fileName));
    if (await file.exists()) await file.delete();
  }
}

/// Downscales to at most 1600px and re-encodes as JPEG q75 — sharp enough
/// to read a receipt, small enough (~150–300 KB) to keep backups light.
Future<List<int>?> compressReceiptImage(String sourcePath) =>
    FlutterImageCompress.compressWithFile(
      sourcePath,
      minWidth: 1600,
      minHeight: 1600,
      quality: 75,
      format: CompressFormat.jpeg,
    );

@module
abstract class ReceiptModule {
  /// Tests register a [ReceiptStore] over a temp directory instead.
  @prod
  @lazySingleton
  ReceiptStore get receiptStore => ReceiptStore(
    root: getApplicationDocumentsDirectory,
    compress: compressReceiptImage,
  );
}

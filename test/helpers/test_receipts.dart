import 'dart:io';

import 'package:khaata_digital/features/transactions/data/receipt_store.dart';

/// A [ReceiptStore] over a fresh temp directory whose "compressor" returns
/// the source bytes unchanged (or null for paths containing "broken").
ReceiptStore testReceiptStore() {
  final root = Directory.systemTemp.createTempSync('kharcha_receipts_');
  return ReceiptStore(
    root: () async => root,
    compress: (path) async =>
        path.contains('broken') ? null : File(path).readAsBytesSync(),
  );
}

/// Writes a small fake image and returns its path.
String fakeImage(String name, [List<int> bytes = const [0xFF, 0xD8, 1, 2, 3]]) {
  final dir = Directory.systemTemp.createTempSync('kharcha_img_');
  final file = File('${dir.path}/$name')..writeAsBytesSync(bytes);
  return file.path;
}

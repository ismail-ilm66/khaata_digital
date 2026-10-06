import 'package:khaata_digital/features/backup/domain/backup.dart';
import 'package:khaata_digital/features/backup/domain/cloud_backup_store.dart';

/// An in-memory Google Drive.
class FakeCloudStore implements CloudBackupStore {
  FakeCloudStore({this.available = true});

  @override
  bool available;

  String? account;
  bool failUploads = false;
  final files = <CloudBackup, List<int>>{};
  var _id = 0;

  @override
  Future<String?> signedInAccount() async => account;

  @override
  Future<String> connect() async => account = 'me@example.com';

  @override
  Future<void> disconnect() async => account = null;

  @override
  Future<void> upload(BackupFile file, {bool interactive = true}) async {
    if (failUploads || (account == null && !interactive)) {
      throw StateError('offline');
    }
    account ??= 'me@example.com';
    files[CloudBackup(
          id: '${_id++}',
          name: file.name,
          createdAt: file.manifest.createdAt,
          size: file.bytes.length,
        )] =
        file.bytes;
  }

  @override
  Future<List<CloudBackup>> list() async =>
      files.keys.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<int>> download(CloudBackup backup) async => files[backup]!;

  @override
  Future<void> prune(int keep, {bool interactive = true}) async {
    for (final old in (await list()).skip(keep)) {
      files.remove(old);
    }
  }
}

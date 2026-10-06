import 'package:equatable/equatable.dart';

import 'backup.dart';

/// A backup file in the user's cloud folder.
class CloudBackup extends Equatable {
  const CloudBackup({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int size;

  @override
  List<Object?> get props => [id, name, createdAt, size];
}

/// The user's own cloud storage for backups — Google Drive, into a visible
/// "Kharcha Backups" folder, never a hidden app folder (spec 3.4). The only
/// network access in the app.
abstract interface class CloudBackupStore {
  /// False when this build has no Google sign-in configuration.
  bool get available;

  /// The signed-in account, without showing any UI; null if none.
  Future<String?> signedInAccount();

  /// Asks the user to sign in and allow access to Kharcha's own Drive
  /// files. Returns the account email. Throws if cancelled or refused.
  Future<String> connect();

  Future<void> disconnect();

  /// [interactive] false (background jobs) fails instead of prompting.
  Future<void> upload(BackupFile file, {bool interactive = true});

  /// Newest first.
  Future<List<CloudBackup>> list();

  Future<List<int>> download(CloudBackup backup);

  /// Deletes all but the newest [keep] backups.
  Future<void> prune(int keep, {bool interactive = true});
}

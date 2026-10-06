import 'dart:async';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:injectable/injectable.dart';

import '../domain/backup.dart';
import '../domain/cloud_backup_store.dart';

/// Google Drive backups with the narrow `drive.file` scope: Kharcha can
/// only see files it created, in a "Kharcha Backups" folder the user can
/// open, copy and share like any other.
///
/// OAuth client ids are supplied at build time (see DECISIONS.md):
///   `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` (Android: the web client id)
///   `--dart-define=GOOGLE_IOS_CLIENT_ID=…` (iOS client id)
/// Without them [available] is false and the app offers file backups only.
@prod
@LazySingleton(as: CloudBackupStore)
class GoogleDriveStore implements CloudBackupStore {
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const _scopes = [drive.DriveApi.driveFileScope];
  static const folderName = 'Kharcha Backups';
  static const _folderMime = 'application/vnd.google-apps.folder';

  final _signIn = GoogleSignIn.instance;
  Future<void>? _init;
  GoogleSignInAccount? _account;

  @override
  bool get available => Platform.isIOS
      ? _iosClientId.isNotEmpty
      : Platform.isAndroid && _serverClientId.isNotEmpty;

  Future<void> _ready() => _init ??= _signIn.initialize(
    clientId: Platform.isIOS ? _iosClientId : null,
    serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
  );

  @override
  Future<String?> signedInAccount() async {
    if (!available) return null;
    await _ready();
    _account ??= await _signIn.attemptLightweightAuthentication();
    return _account?.email;
  }

  @override
  Future<String> connect() async {
    await _ready();
    _account = await _signIn.authenticate(scopeHint: _scopes);
    await _account!.authorizationClient.authorizeScopes(_scopes);
    return _account!.email;
  }

  @override
  Future<void> disconnect() async {
    await _ready();
    await _signIn.disconnect();
    _account = null;
  }

  Future<drive.DriveApi> _api({required bool interactive}) async {
    if (await signedInAccount() == null) {
      if (!interactive) throw StateError('Google Drive not connected');
      await connect();
    }
    final client = _account!.authorizationClient;
    final auth =
        await client.authorizationForScopes(_scopes) ??
        (interactive
            ? await client.authorizeScopes(_scopes)
            : throw StateError('Drive access needs the user'));
    return drive.DriveApi(auth.authClient(scopes: _scopes));
  }

  Future<String> _folder(drive.DriveApi api) async {
    final found = await api.files.list(
      q: "mimeType = '$_folderMime' and name = '$folderName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id)',
    );
    final id = found.files?.firstOrNull?.id;
    if (id != null) return id;
    final created = await api.files.create(
      drive.File(name: folderName, mimeType: _folderMime),
      $fields: 'id',
    );
    return created.id!;
  }

  Future<List<drive.File>> _files(drive.DriveApi api) async {
    final folder = await _folder(api);
    final out = <drive.File>[];
    String? page;
    do {
      final r = await api.files.list(
        q: "'$folder' in parents and trashed = false",
        orderBy: 'createdTime desc',
        spaces: 'drive',
        pageToken: page,
        $fields: 'nextPageToken, files(id, name, createdTime, size)',
      );
      out.addAll(
        (r.files ?? const []).where(
          (f) => f.name?.endsWith('.${BackupFile.extension}') ?? false,
        ),
      );
      page = r.nextPageToken;
    } while (page != null);
    return out;
  }

  @override
  Future<void> upload(BackupFile file, {bool interactive = true}) async {
    final api = await _api(interactive: interactive);
    await api.files.create(
      drive.File(name: file.name, parents: [await _folder(api)]),
      uploadMedia: drive.Media(
        Stream.value(file.bytes),
        file.bytes.length,
        contentType: 'application/octet-stream',
      ),
    );
  }

  @override
  Future<List<CloudBackup>> list() async {
    final api = await _api(interactive: true);
    return [
      for (final f in await _files(api))
        CloudBackup(
          id: f.id!,
          name: f.name!,
          createdAt: f.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0),
          size: int.tryParse(f.size ?? '') ?? 0,
        ),
    ];
  }

  @override
  Future<List<int>> download(CloudBackup backup) async {
    final api = await _api(interactive: true);
    final media =
        await api.files.get(
              backup.id,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  @override
  Future<void> prune(int keep, {bool interactive = true}) async {
    final api = await _api(interactive: interactive);
    for (final f in (await _files(api)).skip(keep)) {
      await api.files.delete(f.id!);
    }
  }
}

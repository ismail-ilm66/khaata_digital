import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import '../lifecycle/system_screens.dart';

/// A file the user picked: its name and contents.
typedef PickedFile = ({String name, List<int> bytes});

/// The system "open" and "save" dialogs (Storage Access Framework on
/// Android, the Files app on iOS). Files saved here belong to the user and
/// survive uninstalling Kharcha.
abstract interface class FileGateway {
  /// Null when cancelled.
  Future<PickedFile?> pick();

  /// False when cancelled.
  Future<bool> save({
    required String name,
    required List<int> bytes,
    required String mime,
  });
}

@prod
@LazySingleton(as: FileGateway)
class SystemFileGateway implements FileGateway {
  @override
  Future<PickedFile?> pick() async {
    // Any type: Android can't filter by Kharcha's own extension, and
    // every reader checks the contents anyway.
    final f = await SystemScreens.show(FilePicker.pickFile);
    if (f == null) return null;
    final bytes = await f.xFile.readAsBytes();
    return (name: f.name, bytes: bytes);
  }

  @override
  Future<bool> save({
    required String name,
    required List<int> bytes,
    required String mime,
  }) async =>
      await SystemScreens.show(
        () => FilePicker.saveFile(
          fileName: name,
          bytes: Uint8List.fromList(bytes),
          mimeType: mime,
        ),
      ) !=
      null;
}

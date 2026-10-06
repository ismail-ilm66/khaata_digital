import 'package:khaata_digital/core/files/file_gateway.dart';

/// Records saves and hands out [next] when the app asks to pick a file.
class FakeFileGateway implements FileGateway {
  PickedFile? next;
  final saved = <PickedFile>[];

  @override
  Future<PickedFile?> pick() async => next;

  @override
  Future<bool> save({
    required String name,
    required List<int> bytes,
    required String mime,
  }) async {
    saved.add((name: name, bytes: bytes));
    return true;
  }
}

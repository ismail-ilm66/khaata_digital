import 'package:drift/native.dart' show SqliteException;

import '../error/app_failure.dart';

/// SQLITE_CONSTRAINT_UNIQUE.
const int _uniqueViolation = 2067;

/// Runs [op], turning a unique-index violation into [DuplicateNameFailure]
/// so callers see a domain error instead of a database one.
Future<T> guardUniqueName<T>(String name, Future<T> Function() op) async {
  try {
    return await op();
  } on SqliteException catch (e) {
    if (e.extendedResultCode == _uniqueViolation) {
      throw DuplicateNameFailure(name.trim());
    }
    rethrow;
  }
}

/// Expected, user-facing failures thrown by repositories. Blocs catch these
/// and map them to messages; anything else is a bug.
sealed class AppFailure implements Exception {
  const AppFailure();
}

/// An active row already uses this name (accounts, categories, people).
final class DuplicateNameFailure extends AppFailure {
  const DuplicateNameFailure(this.name);
  final String name;
}

/// Input that cannot be saved; [problem] says why.
final class ValidationFailure extends AppFailure {
  const ValidationFailure(this.problem);
  final EntryProblem problem;
}

/// A file could not be read, compressed or written (e.g. a receipt).
final class StorageFailure extends AppFailure {
  const StorageFailure(this.message);
  final String message;
}

/// Why a transaction draft is invalid.
enum EntryProblem {
  amountRequired,
  accountRequired,
  destinationRequired,
  sameAccount,
  conversionRequired,
}

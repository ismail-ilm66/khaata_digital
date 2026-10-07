/// Tracks system screens Kharcha itself opens (file pickers, share sheet,
/// camera, Google sign-in). They put the app in the background, but coming
/// back from them must not count as "the user left" — the app lock and
/// similar checks ask [isOwnTrip] first.
abstract final class SystemScreens {
  static int _open = 0;
  static DateTime? _closedAt;

  /// Runs [action], which shows a system screen.
  static Future<T> show<T>(Future<T> Function() action) async {
    _open++;
    try {
      return await action();
    } finally {
      _open--;
      _closedAt = DateTime.now();
    }
  }

  /// True while one is open, or just after (the resume event can arrive a
  /// moment after the screen's result).
  static bool isOwnTrip([DateTime? now]) {
    if (_open > 0) return true;
    final closed = _closedAt;
    return closed != null &&
        (now ?? DateTime.now()).difference(closed) < const Duration(seconds: 2);
  }
}

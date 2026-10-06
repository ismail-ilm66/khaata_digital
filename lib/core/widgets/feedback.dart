import 'package:flutter/material.dart';

/// Snackbar helpers. Use the [ScaffoldMessengerState] versions after an
/// `await` (capture `ScaffoldMessenger.of(context)` first).
extension Feedback on ScaffoldMessengerState {
  /// Brief confirmation ("Saved"). Replaces any snackbar on screen.
  void toast(String message) {
    hideCurrentSnackBar();
    showSnackBar(SnackBar(content: Text(message)));
  }

  /// A snackbar with an Undo action, for reversible destructive actions.
  void undo({
    required String message,
    required String undoLabel,
    required VoidCallback onUndo,
  }) {
    hideCurrentSnackBar();
    showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
  }
}

void showToast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).toast(message);

void showUndo(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
}) => ScaffoldMessenger.of(
  context,
).undo(message: message, undoLabel: undoLabel, onUndo: onUndo);

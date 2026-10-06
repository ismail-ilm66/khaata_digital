import 'package:flutter/widgets.dart';

import '../domain/recurring_rule.dart';

/// Creates every due recurring entry, then re-schedules reminders. Runs on
/// app start and from the background job; safe to run any number of
/// times (each occurrence is created exactly once).
Future<int> runRecurringMaintenance(
  RecurringRepository recurring,
  ReminderScheduler reminders, {
  DateTime? now,
}) async {
  final created = await recurring.materializeDue(now ?? DateTime.now());
  try {
    await reminders.sync(await recurring.active());
  } catch (e) {
    // Notifications are best-effort; never block entries on them.
    debugPrint('Kharcha: reminder sync failed: $e');
  }
  return created;
}

// On-device check that a bill reminder is actually delivered (M3
// acceptance). Needs a real device, emulator or iOS simulator:
//
//   Android: adb shell pm grant com.expensetracker.kharcha android.permission.POST_NOTIFICATIONS
//   iOS: tap "Allow" on the first run's notification prompt.
//   flutter test integration_test/reminder_test.dart -d <device-id>
//
// The timing rule (9 am on the due day, etc.) is unit-tested in
// test/features/recurring; here only "when" is shortened to a few seconds
// so the real plugin, scheduler and OS delivery are exercised end to end.
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:khaata_digital/core/dates/recurrence.dart';
import 'package:khaata_digital/core/l10n/gen/app_localizations.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/recurring/data/reminders.dart';
import 'package:khaata_digital/features/recurring/domain/recurrence.dart';
import 'package:khaata_digital/features/recurring/domain/recurring_rule.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a bill reminder is delivered by the OS', (tester) async {
    final plugin = FlutterLocalNotificationsPlugin();
    final scheduler = LocalReminderScheduler(
      plugin,
      () async => lookupAppLocalizations(const Locale('en')),
      timeFor: (_, now) => now.add(const Duration(seconds: 5)),
    );
    expect(
      await scheduler.requestPermission(),
      isTrue,
      reason: 'grant notifications first',
    );

    final due = DateTime.now().add(const Duration(minutes: 1));
    final rule = RecurringRule(
      id: 'integration-reminder',
      template: EntryTemplate(
        type: TransactionType.expense,
        amount: Money.major(4500, Currency.pkr),
        accountId: 'cash',
        note: 'Internet bill',
      ),
      schedule: RecurrenceSchedule(
        start: due,
        frequency: RecurrenceFrequency.monthly,
      ),
      nextRunAt: due,
      remind: true,
    );
    await scheduler.sync([rule]);

    final id = reminderIdFor(rule.id);
    final pending = await plugin.pendingNotificationRequests();
    expect(pending.map((p) => p.id), contains(id), reason: 'scheduled');

    // Inexact alarms may be batched; allow up to two minutes.
    var delivered = false;
    for (var i = 0; i < 60 && !delivered; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final active = await plugin.getActiveNotifications();
      delivered = active.any(
        (n) => n.id == id && (n.body ?? '').contains('Internet bill'),
      );
    }
    expect(
      delivered,
      isTrue,
      reason: 'the reminder fired and is in the notification shade',
    );
    await plugin.cancelAll();
  });
}

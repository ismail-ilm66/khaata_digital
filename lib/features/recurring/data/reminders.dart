import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/money/money_format.dart';
import '../../settings/domain/setting_key.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/recurring_rule.dart';

/// When a rule's bill reminder should fire: 9 am on the due day, or right
/// away (a minute from now) if that morning has already passed. Null when
/// there is nothing upcoming to remind about.
DateTime? reminderTimeFor(RecurringRule rule, DateTime now) {
  final due = rule.nextRunAt;
  if (!rule.remind || due == null || !due.isAfter(now)) return null;
  final morning = DateTime(due.year, due.month, due.day, 9);
  if (morning.isAfter(now)) return morning;
  final soon = now.add(const Duration(minutes: 1));
  return soon.isBefore(due) ? soon : due;
}

/// Stable notification id per rule.
int reminderIdFor(String ruleId) => ruleId.hashCode & 0x7fffffff;

/// Bill reminders via local notifications — no server, no network.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler(
    this._plugin,
    this._l10n, {
    DateTime Function()? now,
    DateTime? Function(RecurringRule rule, DateTime now)? timeFor,
  }) : _now = now ?? DateTime.now,
       _timeFor = timeFor ?? reminderTimeFor;

  final FlutterLocalNotificationsPlugin _plugin;

  /// Strings in the app's language (read from settings, so it also works
  /// in the background isolate).
  final Future<AppLocalizations> Function() _l10n;
  final DateTime Function() _now;

  /// When to fire for a rule; [reminderTimeFor] in the app. The on-device
  /// integration test swaps in "a few seconds from now".
  final DateTime? Function(RecurringRule rule, DateTime now) _timeFor;

  static const _channel = AndroidNotificationDetails(
    'bill_reminders',
    'Bill reminders',
    channelDescription: 'Reminders for repeating bills and payments',
    importance: Importance.high,
    priority: Priority.high,
  );

  static bool _ready = false;

  /// Plugin + timezone setup; safe to call more than once.
  static Future<void> init(FlutterLocalNotificationsPlugin plugin) async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      // Unknown zone name: fall back to UTC offsets (still correct times).
    }
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init(_plugin);
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true) ??
        false;
  }

  @override
  Future<void> sync(List<RecurringRule> rules) async {
    await init(_plugin);
    await _plugin.cancelAll();
    final l10n = await _l10n();
    final now = _now();
    for (final rule in rules) {
      final at = _timeFor(rule, now);
      if (at == null) continue;
      final t = rule.template;
      await _plugin.zonedSchedule(
        id: reminderIdFor(rule.id),
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: l10n.reminderTitle,
        body: l10n.reminderBody(
          t.note.isNotEmpty ? t.note : l10n.recurringEntry,
          const MoneyFormat().format(t.amount),
        ),
      );
    }
  }
}

@module
abstract class ReminderModule {
  @lazySingleton
  FlutterLocalNotificationsPlugin get notifications =>
      FlutterLocalNotificationsPlugin();

  /// Tests register a fake [ReminderScheduler] instead.
  @prod
  @lazySingleton
  ReminderScheduler reminders(
    FlutterLocalNotificationsPlugin plugin,
    SettingsRepository settings,
  ) => LocalReminderScheduler(plugin, () => reminderStrings(settings));
}

/// Reminder strings in the user's chosen app language.
Future<AppLocalizations> reminderStrings(SettingsRepository settings) async =>
    lookupAppLocalizations(Locale(await settings.read(SettingKey.locale)));

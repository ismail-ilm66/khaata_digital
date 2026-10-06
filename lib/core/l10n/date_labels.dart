import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/context_x.dart';

/// Human date labels in the current locale.
extension DateLabels on BuildContext {
  String get _locale => Localizations.localeOf(this).toLanguageTag();

  /// "Today", "Yesterday", or "Fri, 25 Sep" (year added when not this year).
  String dayLabel(DateTime local, {DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final day = DateUtils.dateOnly(local);
    if (day == today) return l10n.today;
    if (day == DateUtils.addDaysToDate(today, -1)) return l10n.yesterday;
    final pattern = day.year == today.year
        ? DateFormat.MMMEd(_locale)
        : DateFormat.yMMMEd(_locale);
    return pattern.format(day);
  }

  /// "Today, 2:30 PM" / "Fri, 25 Sep, 2:30 PM".
  String dateTimeLabel(DateTime local, {DateTime? now}) =>
      '${dayLabel(local, now: now)}, ${DateFormat.jm(_locale).format(local)}';

  /// "Friday, 25 September 2026 · 2:30 PM" for detail screens.
  String longDateTime(DateTime local) =>
      '${DateFormat.yMMMMEEEEd(_locale).format(local)} · '
      '${DateFormat.jm(_locale).format(local)}';
}

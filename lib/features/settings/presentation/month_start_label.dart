import 'package:flutter/widgets.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/theme/context_x.dart';

/// "Day 25" or "Last working day", in the app's language.
String monthStartLabel(BuildContext context, BudgetCycle cycle) {
  final l = context.l10n;
  final day = cycle.startDay;
  return day == null ? l.monthStartLastWorking : l.monthStartDay(day);
}

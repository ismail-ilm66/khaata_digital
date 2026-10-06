import 'package:equatable/equatable.dart';

import '../../../core/dates/budget_cycle.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import 'ledger_entry.dart';
import 'transaction_type.dart';

/// Entries on one local calendar day, with that day's totals.
class DayGroup extends Equatable {
  const DayGroup({
    required this.day,
    required this.entries,
    required this.spent,
    required this.earned,
  });

  /// Local midnight.
  final DateTime day;
  final List<EntryView> entries;

  /// Expense totals per currency (positive).
  final Map<Currency, Money> spent;

  /// Income totals per currency.
  final Map<Currency, Money> earned;

  /// Groups newest-first [views] by local day, preserving order.
  static List<DayGroup> group(List<EntryView> views) {
    final groups = <DayGroup>[];
    for (final v in views) {
      final local = v.entry.occurredAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (groups.isEmpty || groups.last.day != day) {
        groups.add(DayGroup(day: day, entries: [], spent: {}, earned: {}));
      }
      final g = groups.last;
      g.entries.add(v);
      final amount = v.entry.amount;
      void add(Map<Currency, Money> m) =>
          m.update(amount.currency, (x) => x + amount, ifAbsent: () => amount);
      // Udhaar moves money between me and a person; it isn't spending.
      if (v.entry.personId != null) continue;
      if (v.entry.type == TransactionType.expense) add(g.spent);
      if (v.entry.type == TransactionType.income) add(g.earned);
    }
    return groups;
  }

  @override
  List<Object?> get props => [day, entries, spent, earned];
}

/// Day groups that share a budget cycle, for the sticky cycle headers.
class CycleSection extends Equatable {
  const CycleSection(this.cycle, this.days);

  final CycleId cycle;
  final List<DayGroup> days;

  static List<CycleSection> of(List<DayGroup> days, BudgetCycle budgetCycle) {
    final sections = <CycleSection>[];
    for (final d in days) {
      final id = budgetCycle.idFor(d.day);
      if (sections.isEmpty || sections.last.cycle != id) {
        sections.add(CycleSection(id, []));
      }
      sections.last.days.add(d);
    }
    return sections;
  }

  @override
  List<Object?> get props => [cycle, days];
}

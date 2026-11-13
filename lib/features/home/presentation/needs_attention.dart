import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates/calendar_day.dart';
import '../../../core/di/injection.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../../backup/presentation/backup_health.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/presentation/budget_bar.dart';
import '../../categories/presentation/category_badge.dart';
import '../../people/domain/person.dart';
import '../../people/presentation/people_screen.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../to_pay/domain/planned_payment.dart';
import 'home_cubit.dart';

/// Home: one card for whatever wants the user's attention, a row each,
/// hidden when nothing does. In order: a damaged database or an old
/// backup (spec 3.2 #9), category budgets near or over their limit, what's
/// still to pay, and udhaar either way. Each row opens its screen.
class NeedsAttention extends StatelessWidget {
  const NeedsAttention({super.key, required this.state, required this.masked});

  final HomeState state;
  final bool masked;

  /// Ask for a backup when none has left the phone in this many days.
  static const int quietDays = 14;

  /// At most this many budget rows; the Budgets screen has the rest.
  static const int budgetsShown = 3;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyCubit>().state;
    final rows = [
      ?_backup(context),
      ..._budgets(context),
      ?_toPay(context, currency),
      ..._people(context, currency),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Section(
      key: const Key('needsAttention'),
      title: context.l10n.needsAttention,
      child: SurfaceCard(children: rows),
    );
  }

  Widget? _backup(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    void open() => context.push(Routes.backup);
    if (!getIt<BackupHealth>().databaseOk) {
      return SettingTile(
        key: const Key('integrityNudge'),
        leading: TintedBadge(icon: AppIcons.warning, color: c.danger, size: 32),
        title: l.integrityTitle,
        subtitle: l.integrityBody,
        onTap: open,
      );
    }
    // No nagging before the user has recorded anything.
    if (state.recent!.isEmpty) return null;
    final last = state.backup!.last;
    final days = last == null
        ? null
        : DateTime.now().toUtc().difference(last.createdAt).inDays;
    if (days != null && days < quietDays) return null;
    return SettingTile(
      key: const Key('backupNudge'),
      leading: TintedBadge(
        icon: AppIcons.backup.regular,
        color: c.warning,
        size: 32,
      ),
      title: l.backupNudgeTitle,
      subtitle: days == null ? l.backupNudgeNever : l.backupNudgeDays(days),
      onTap: open,
    );
  }

  /// This cycle's category budgets at 80 % or more, fullest first. The
  /// overall budget is on the summary card already.
  Iterable<Widget> _budgets(BuildContext context) {
    if (!state.isCurrent) return const [];
    final c = context.colors;
    return [
      for (final line
          in state.budgets!.lines
              .where((b) => b.status != BudgetStatus.onTrack)
              .take(budgetsShown))
        SettingTile(
          key: Key('attentionBudget-${line.category!.name}'),
          leading: CategoryBadge(line.category, size: 32),
          title: line.category!.name,
          subtitle: budgetLeftLabel(context, line, masked: masked),
          subtitleColor: line.status.color(c),
          onTap: () => context.push(Routes.budgets),
        ),
    ];
  }

  /// One row for the whole list: overdue count first, then what for.
  Widget? _toPay(BuildContext context, Currency currency) {
    final open = state.toPay!;
    if (open.isEmpty) return null;
    final l = context.l10n;
    final today = CalendarDay.of(DateTime.now());
    final late = open
        .where((p) => p.statusOn(today) == DueStatus.overdue)
        .length;
    final names = _names(context, [for (final p in open) p.title]);
    return SettingTile(
      key: const Key('homeToPay'),
      icon: AppIcons.toPay.filled,
      title: l.toPay,
      subtitle: late == 0 ? names : '${l.overdueCount(late)} · $names',
      subtitleColor: late == 0 ? null : context.colors.danger,
      trailing: _amount(context, PlannedPayment.totals(open), currency),
      onTap: () => context.push(Routes.toPay),
    );
  }

  /// "You'll receive" and "You owe", each naming the people, largest first.
  Iterable<Widget> _people(BuildContext context, Currency currency) {
    final l = context.l10n;
    final c = context.colors;
    final people = state.people!;
    Money owed(PersonSummary p) => p.balance[currency] ?? Money.zero(currency);
    List<String> who(bool Function(PersonSummary) side) {
      final list = people.people.where(side).toList()
        ..sort((a, b) => owed(b).abs().minor.compareTo(owed(a).abs().minor));
      return [for (final p in list) p.person.name];
    }

    Widget row(
      Key key,
      String title,
      List<String> names,
      Map<Currency, Money> totals,
      Color color,
      PeopleTab tab,
    ) => SettingTile(
      key: key,
      icon: AppIcons.people.filled,
      title: title,
      subtitle: _names(context, names),
      trailing: _amount(context, totals, currency, color: color),
      onTap: () => context.push(Routes.peopleTab(tab.name)),
    );

    return [
      if (people.payable.isNotEmpty)
        row(
          const Key('payable'),
          l.youOwe,
          who((p) => p.balance.values.any((m) => m.isNegative)),
          people.payable,
          c.ink,
          PeopleTab.owe,
        ),
      if (people.receivable.isNotEmpty)
        row(
          const Key('receivable'),
          l.youllReceive,
          who((p) => p.balance.values.any((m) => m.isPositive)),
          people.receivable,
          c.income,
          PeopleTab.receive,
        ),
    ];
  }

  /// The total in the home currency (or the first there is).
  Widget _amount(
    BuildContext context,
    Map<Currency, Money> totals,
    Currency currency, {
    Color? color,
  }) => AmountText(
    totals[currency] ?? totals.values.first,
    masked: masked,
    style: context.text.titleSmall!.copyWith(color: color),
  );

  /// "Ali, Zain +3": the first two, then how many more.
  static String _names(BuildContext context, List<String> names) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shown = names.take(2).join(rtl ? '، ' : ', ');
    return names.length > 2 ? '$shown +${names.length - 2}' : shown;
  }
}

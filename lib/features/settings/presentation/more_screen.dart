import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates/calendar_day.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/watch.dart';
import '../../accounts/domain/account.dart';
import '../../backup/data/backup_service.dart';
import '../../backup/domain/backup.dart';
import '../../backup/presentation/backup_health.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/presentation/budget_bar.dart';
import '../../onboarding/presentation/home_tour.dart';
import '../../people/domain/person.dart';
import '../../recurring/domain/recurring_rule.dart';
import '../../to_pay/domain/planned_payment.dart';
import 'cubit/preference_cubits.dart';

/// More tab: what you look after — your money and its backups — and one
/// way into Settings. Each row says on the right what's worth knowing now:
/// how many, how much of the budget is used, what's overdue, when the last
/// backup left the phone.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageScaffold(
      title: l10n.navMore,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          sliver: SliverList.list(
            children: [
              Section(
                title: l10n.yourMoney,
                child: SurfaceCard(
                  children: [
                    SettingTile(
                      key: const Key('accountsTile'),
                      icon: AppIcons.accounts.filled,
                      title: l10n.accounts,
                      trailing: _Count(
                        () => getIt<AccountsRepository>().watchOverview().map(
                          (o) => o.accounts.length,
                        ),
                      ),
                      onTap: () => context.push(Routes.accounts),
                    ),
                    SettingTile(
                      key: const Key('budgetsTile'),
                      icon: AppIcons.budgets.filled,
                      title: l10n.budgets,
                      trailing: const _BudgetUsed(),
                      onTap: () => context.push(Routes.budgets),
                    ),
                    SettingTile(
                      key: const Key('peopleTile'),
                      icon: AppIcons.people.filled,
                      title: l10n.people,
                      trailing: _Count(
                        () => getIt<PeopleRepository>().watchOverview().map(
                          (o) => o.people.length,
                        ),
                      ),
                      onTap: () => context.push(Routes.people),
                    ),
                    SettingTile(
                      key: const Key('toPayTile'),
                      icon: AppIcons.toPay.filled,
                      title: l10n.toPay,
                      trailing: const _ToPayDue(),
                      onTap: () => context.push(Routes.toPay),
                    ),
                    SettingTile(
                      key: const Key('recurringTile'),
                      icon: AppIcons.recurring.filled,
                      title: l10n.recurring,
                      trailing: _Count(
                        () => getIt<RecurringRepository>().watchAll().map(
                          (rules) => rules.length,
                        ),
                      ),
                      onTap: () => context.push(Routes.recurring),
                    ),
                    SettingTile(
                      key: const Key('categoriesTile'),
                      icon: AppIcons.tag,
                      title: l10n.categories,
                      onTap: () => context.push(Routes.categories),
                    ),
                  ],
                ),
              ),
              SurfaceCard(
                children: [
                  const _BackupTile(),
                  SettingTile(
                    key: const Key('settingsTile'),
                    icon: AppIcons.theme.filled,
                    title: l10n.settingsTitle,
                    subtitle: l10n.settingsHint,
                    onTap: () => context.push(Routes.settings),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SurfaceCard(
                children: [
                  SettingTile(
                    key: const Key('tourTile'),
                    icon: AppIcons.guide,
                    title: l10n.howToUse,
                    onTap: () => replayHomeTour(context),
                  ),
                  SettingTile(
                    key: const Key('aboutTile'),
                    icon: AppIcons.shield,
                    title: l10n.about,
                    onTap: () => context.push(Routes.about),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A row's value on the right: quiet, or [color] when it needs a look.
class _Value extends StatelessWidget {
  const _Value(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.text.bodyMedium!.copyWith(
      color: color ?? context.colors.inkMuted,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// How many there are; nothing at zero (or until the count arrives).
class _Count extends StatelessWidget {
  const _Count(this.source);

  final Stream<int> Function() source;

  @override
  Widget build(BuildContext context) => Watch<int>(
    source,
    builder: (context, n) =>
        n == null || n == 0 ? const SizedBox.shrink() : _Value('$n'),
  );
}

/// This month's overall budget, "55% used" (amber near the limit, red
/// over it); with category budgets only, how many there are.
class _BudgetUsed extends StatelessWidget {
  const _BudgetUsed();

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<BudgetCycleCubit>().state;
    final currency = context.watch<CurrencyCubit>().state;
    final id = cycle.idFor(DateTime.now());
    return Watch<BudgetOverview>(
      () => getIt<BudgetsRepository>().watch(id, cycle, currency),
      sourceKey: (cycle, currency, id),
      builder: (context, o) {
        final l = context.l10n;
        if (o == null || o.isEmpty) return const SizedBox.shrink();
        final overall = o.overall;
        if (overall == null) return _Value(l.budgetCount(o.lines.length));
        return _Value(
          l.budgetUsed((overall.permille / 10).round()),
          color: overall.status == BudgetStatus.onTrack
              ? null
              : overall.status.color(context.colors),
        );
      },
    );
  }
}

/// What's still to pay: "1 overdue" in red, or how many are open.
class _ToPayDue extends StatelessWidget {
  const _ToPayDue();

  @override
  Widget build(BuildContext context) => Watch<List<PlannedPayment>>(
    getIt<ToPayRepository>().watchOpen,
    builder: (context, open) {
      if (open == null || open.isEmpty) return const SizedBox.shrink();
      final today = CalendarDay.of(DateTime.now());
      final late = open
          .where((p) => p.statusOn(today) == DueStatus.overdue)
          .length;
      return late == 0
          ? _Value('${open.length}')
          : _Value(
              context.l10n.overdueCount(late),
              color: context.colors.danger,
            );
    },
  );
}

/// The latest backup that left the phone. Wrapped so "not loaded yet"
/// (null) and "never" (`last` null) stay distinct.
typedef _LastBackup = ({BackupRecord? last});

/// Backup & data (backups, import, export): when the last backup left the
/// phone, in amber once that's [backupQuietDays] ago or never.
class _BackupTile extends StatelessWidget {
  const _BackupTile();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Watch<_LastBackup>(
      () => getIt<BackupService>()
          .watchLast(offDevice: true)
          .map((last) => (last: last)),
      builder: (context, status) {
        final last = status?.last;
        final days = last == null
            ? null
            : DateTime.now().toUtc().difference(last.createdAt).inDays;
        return SettingTile(
          key: const Key('backupTile'),
          icon: AppIcons.backup.filled,
          title: l.backupAndData,
          subtitle: status == null
              ? null
              : days == null
              ? l.noBackupYet
              : l.backedUpDays(days),
          subtitleColor:
              status != null && (days == null || days >= backupQuietDays)
              ? context.colors.warning
              : null,
          onTap: () => context.push(Routes.backup),
        );
      },
    );
  }
}

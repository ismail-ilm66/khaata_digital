import '../../security/presentation/reveal_balances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/presentation/form/entry_editor_screen.dart';
import '../domain/person.dart';
import 'person_badge.dart';
import 'write_off_sheet.dart';
import '../../../core/widgets/watch.dart';

/// One person's udhaar ledger (spec 3.2 #7): balance, I gave / I received /
/// Settle up (paid back, or written off), and every entry and write-off
/// with the running balance after it.
class PersonScreen extends StatelessWidget {
  const PersonScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = getIt<PeopleRepository>();
    return Watch<Person?>(
      () => repo.watchPerson(id),
      sourceKey: id,
      builder: (context, p) => Watch<List<LedgerLine>>(
        () => repo.watchLedger(id),
        sourceKey: id,
        builder: (context, lines) {
          if (p == null || lines == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _PersonView(person: p, lines: lines);
        },
      ),
    );
  }
}

class _PersonView extends StatelessWidget {
  const _PersonView({required this.person, required this.lines});

  final Person person;
  final List<LedgerLine> lines;

  Future<void> _remove(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    Navigator.pop(context);
    await getIt<PeopleRepository>().archive(person.id);
    messenger.toast(l.personRemoved);
  }

  /// The balance now, in [like]'s currency (the newest line holds it).
  Money _balanceIn(Money like) =>
      lines
          .where((x) => x.runningBalance.currency == like.currency)
          .firstOrNull
          ?.runningBalance ??
      Money.zero(like.currency);

  /// Settle up asks how the balance closed: paid back (an entry in an
  /// account), or let go (a write-off, which touches no account).
  Future<void> _settle(BuildContext context, Money balance) async {
    final l = context.l10n;
    final owed = balance.isPositive; // they owe me
    final masked = context.read<HideBalanceCubit>().state.masked;
    final choice = await pickOne<_Settle>(
      context,
      title: masked
          ? l.settleUp
          : l.settleAmount(const MoneyFormat().format(balance.abs())),
      searchable: false,
      items: [
        PickItem(
          value: _Settle.paid,
          title: owed ? l.theyPaidBack : l.iPaidBack,
          subtitle: owed ? l.theyPaidBackHint : l.iPaidBackHint,
          leading: _ChoiceBadge(
            owed ? AppIcons.arrowDownLeft : AppIcons.arrowUpRight,
          ),
        ),
        PickItem(
          value: _Settle.writeOff,
          title: owed ? l.writeItOff : l.theyLetItGo,
          subtitle: owed ? l.writeItOffHint : l.theyLetItGoHint,
          leading: const _ChoiceBadge(AppIcons.writeOff),
        ),
      ],
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      // They owe me → I receive it back; I owe → I give it.
      case _Settle.paid:
        await EntryEditor.udhaar(
          context,
          personId: person.id,
          direction: owed ? UdhaarDirection.received : UdhaarDirection.gave,
          amount: balance.abs(),
        );
      case _Settle.writeOff:
        final result = await showWriteOffSheet(
          context,
          personName: person.name,
          max: balance.abs(),
          forgiven: !owed,
        );
        if (result is! WriteOffSaved) return;
        await getIt<PeopleRepository>().writeOff(
          person.id,
          owed ? result.amount : -result.amount,
          occurredAt: result.occurredAt,
          note: result.note,
        );
    }
  }

  Future<void> _editWriteOff(
    BuildContext context,
    WriteOff w, {
    required Money balance,
  }) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repo = getIt<PeopleRepository>();
    // As much as was open before this write-off: it can take all of that.
    final before = balance + w.amount;
    final max = before.isNegative == w.isForgiven && !before.isZero
        ? before.abs()
        : w.amount.abs();
    final result = await showWriteOffSheet(
      context,
      personName: person.name,
      max: max,
      forgiven: w.isForgiven,
      existing: w,
    );
    switch (result) {
      case null:
        return;
      case WriteOffSaved(:final amount, :final occurredAt, :final note):
        await repo.editWriteOff(
          w.id,
          w.isForgiven ? -amount : amount,
          occurredAt: occurredAt,
          note: note,
        );
      case WriteOffDeleted():
        await repo.removeWriteOff(w.id);
        messenger.undo(
          message: l.writeOffDeleted,
          undoLabel: l.undo,
          onUndo: () => repo.restoreWriteOff(w.id),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final currency = context.watch<CurrencyCubit>().state;
    final balance = lines.isEmpty
        ? Money.zero(currency)
        : lines
              .firstWhere(
                (x) => x.runningBalance.currency == currency,
                orElse: () => lines.first,
              )
              .runningBalance;
    final status = balance.isZero
        ? l.settled
        : balance.isPositive
        ? l.owesYou
        : l.youOweThem;

    return PageScaffold(
      title: person.name,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BalanceEyeButton(buttonKey: Key('personEye')),
          PopupMenuButton<void>(
            icon: Icon(AppIcons.overflow, color: c.ink),
            itemBuilder: (_) => [
              PopupMenuItem(
                key: const Key('removePerson'),
                onTap: () => _remove(context),
                child: Text(l.removePerson),
              ),
            ],
          ),
        ],
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          sliver: SliverList.list(
            children: [
              SurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Column(
                    children: [
                      PersonBadge(person.name, size: 56),
                      const SizedBox(height: AppSpacing.m),
                      Text(status, style: context.text.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      AmountText(
                        balance.abs(),
                        key: const Key('personBalance'),
                        masked: context.watch<HideBalanceCubit>().state.masked,
                        style: context.text.displaySmall!.copyWith(
                          color: balance.isPositive ? c.income : c.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  PillButton(
                    key: const Key('iGave'),
                    icon: AppIcons.arrowUpRight,
                    label: l.iGave,
                    onTap: () => EntryEditor.udhaar(
                      context,
                      personId: person.id,
                      direction: UdhaarDirection.gave,
                    ),
                  ),
                  PillButton(
                    key: const Key('iReceived'),
                    icon: AppIcons.arrowDownLeft,
                    label: l.iReceived,
                    onTap: () => EntryEditor.udhaar(
                      context,
                      personId: person.id,
                      direction: UdhaarDirection.received,
                    ),
                  ),
                  if (!balance.isZero)
                    PillButton(
                      key: const Key('settleUp'),
                      icon: AppIcons.check,
                      label: l.settleUp,
                      selected: true,
                      onTap: () => _settle(context, balance),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (lines.isEmpty)
                EmptyState(
                  icon: AppIcons.people.filled,
                  title: l.noLedger,
                  message: l.noLedgerBody,
                )
              else
                Section(
                  title: l.navTransactions,
                  child: SurfaceCard(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final line in lines)
                        _LedgerRow(
                          line,
                          onWriteOffTap: () => _editWriteOff(
                            context,
                            line.writeOff!,
                            balance: _balanceIn(line.writeOff!.amount),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Settle { paid, writeOff }

/// The neutral icon square beside each Settle up choice.
class _ChoiceBadge extends StatelessWidget {
  const _ChoiceBadge(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      TintedBadge(icon: icon, color: context.colors.inkMuted, size: 36);
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow(this.line, {required this.onWriteOffTap});

  final LedgerLine line;
  final VoidCallback onWriteOffTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final w = line.writeOff;
    final e = line.view?.entry;
    final gave =
        e != null && UdhaarDirection.of(e.type) == UdhaarDirection.gave;
    final note = w?.note ?? e!.note;
    // A write-off moved no money, so there's no account to name.
    final subtitle = [
      context.dayLabel(line.occurredAt.toLocal()),
      ?line.view?.accountName,
      if (note.isNotEmpty) note,
    ].join(' · ');
    return InkWell(
      onTap: w != null
          ? onWriteOffTap
          : () => context.push(Routes.entry(e!.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Row(
          children: [
            Icon(
              w != null
                  ? AppIcons.writeOff
                  : gave
                  ? AppIcons.arrowUpRight
                  : AppIcons.arrowDownLeft,
              size: 18,
              color: context.colors.inkMuted,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w != null
                        ? (w.isForgiven ? l.forgiven : l.writtenOff)
                        : gave
                        ? l.iGave
                        : l.iReceived,
                    style: context.text.titleSmall,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(
                  w?.amount.abs() ?? e!.amount,
                  style: context.text.titleSmall,
                ),
                // The running total gives the balance away.
                AmountText(
                  line.runningBalance,
                  masked: context.watch<HideBalanceCubit>().state.masked,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/money/money.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/presentation/form/entry_editor_screen.dart';
import '../domain/person.dart';
import 'person_badge.dart';

/// One person's udhaar ledger (spec 3.2 #7): balance, I gave / I received /
/// Settle up, and every entry with the running balance after it.
class PersonScreen extends StatelessWidget {
  const PersonScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = getIt<PeopleRepository>();
    return StreamBuilder<Person?>(
      stream: repo.watchPerson(id),
      builder: (context, person) => StreamBuilder<List<LedgerLine>>(
        stream: repo.watchLedger(id),
        builder: (context, ledger) {
          final p = person.data;
          final lines = ledger.data;
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
      trailing: PopupMenuButton<void>(
        icon: Icon(AppIcons.overflow, color: c.ink),
        itemBuilder: (_) => [
          PopupMenuItem(
            key: const Key('removePerson'),
            onTap: () => _remove(context),
            child: Text(l.removePerson),
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
                      // They owe me → I receive it back; I owe → I give it.
                      onTap: () => EntryEditor.udhaar(
                        context,
                        personId: person.id,
                        direction: balance.isPositive
                            ? UdhaarDirection.received
                            : UdhaarDirection.gave,
                        amount: balance.abs(),
                      ),
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
                    children: [for (final line in lines) _LedgerRow(line)],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow(this.line);

  final LedgerLine line;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = line.view.entry;
    final gave = UdhaarDirection.of(e.type) == UdhaarDirection.gave;
    final subtitle = [
      context.dayLabel(e.occurredAt.toLocal()),
      line.view.accountName,
      if (e.note.isNotEmpty) e.note,
    ].join(' · ');
    return InkWell(
      onTap: () => context.push(Routes.entry(e.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Row(
          children: [
            Icon(
              gave ? AppIcons.arrowUpRight : AppIcons.arrowDownLeft,
              size: 18,
              color: context.colors.inkMuted,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gave ? l.iGave : l.iReceived,
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
                AmountText(e.amount, style: context.text.titleSmall),
                AmountText(line.runningBalance, style: context.text.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

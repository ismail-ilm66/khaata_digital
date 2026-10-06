import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/surface_card.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../domain/person.dart';
import 'person_badge.dart';

/// People / Udhaar (spec 3.2 #7): who owes you, whom you owe.
class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  static Future<void> addPerson(BuildContext context) async {
    final l = context.l10n;
    final name = await editTextSheet(
      context,
      title: l.addPerson,
      initial: '',
      hint: l.personName,
      doneLabel: l.save,
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      final id = await getIt<PeopleRepository>().create(name);
      if (context.mounted) await context.push(Routes.person(id));
    } on DuplicateNameFailure {
      if (context.mounted) showToast(context, l.duplicatePersonName(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<PeopleOverview>(
      stream: getIt<PeopleRepository>().watchOverview(),
      builder: (context, snap) {
        final o = snap.data;
        return PageScaffold(
          title: l.people,
          trailing: IconButton.filled(
            key: const Key('addPerson'),
            tooltip: l.addPerson,
            onPressed: () => addPerson(context),
            icon: const Icon(AppIcons.plus),
          ),
          slivers: [
            if (o != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                sliver: SliverList.list(
                  children: [
                    UdhaarTotals(overview: o),
                    const SizedBox(height: AppSpacing.xl),
                    if (o.people.isEmpty)
                      EmptyState(
                        icon: AppIcons.people.filled,
                        title: l.noPeople,
                        message: l.noPeopleBody,
                        action: FilledButton(
                          onPressed: () => addPerson(context),
                          child: Text(l.addPerson),
                        ),
                      )
                    else
                      SurfaceCard(
                        padding: EdgeInsets.zero,
                        children: [
                          for (final p in o.people) PersonTile(summary: p),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "You'll receive" / "You owe" side by side (also on Home).
class UdhaarTotals extends StatelessWidget {
  const UdhaarTotals({super.key, required this.overview, this.onTap});

  final PeopleOverview overview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final currency = context.watch<CurrencyCubit>().state;
    Widget tile(
      String label,
      Map<Currency, Money> totals,
      Color color,
      Key key,
    ) => Expanded(
      child: Material(
        key: key,
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadii.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.m),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: StatTile(
              label: label,
              value: AmountText(
                totals[currency] ?? Money.zero(currency),
                style: context.text.titleLarge!.copyWith(color: color),
              ),
            ),
          ),
        ),
      ),
    );
    return Row(
      children: [
        tile(
          l.youllReceive,
          overview.receivable,
          c.income,
          const Key('receivable'),
        ),
        const SizedBox(width: AppSpacing.s),
        tile(l.youOwe, overview.payable, c.ink, const Key('payable')),
      ],
    );
  }
}

/// A person with where you stand: "Owes you Rs 3,500" / "You owe" / "Settled".
class PersonTile extends StatelessWidget {
  const PersonTile({super.key, required this.summary});

  final PersonSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final currency = context.watch<CurrencyCubit>().state;
    final balance =
        summary.balance[currency] ??
        summary.balance.values.firstOrNull ??
        Money.zero(currency);
    final status = balance.isZero
        ? l.settled
        : balance.isPositive
        ? l.owesYou
        : l.youOweThem;
    return InkWell(
      key: Key('person-${summary.person.name}'),
      onTap: () => context.push(Routes.person(summary.person.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Row(
          children: [
            PersonBadge(summary.person.name),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.person.name, style: context.text.titleSmall),
                  Text(status, style: context.text.bodySmall),
                ],
              ),
            ),
            if (!balance.isZero)
              AmountText(
                balance.abs(),
                style: context.text.titleSmall!.copyWith(
                  color: balance.isPositive ? c.income : c.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
import '../../../core/widgets/segmented_picker.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../domain/person.dart';
import 'person_badge.dart';
import '../../../core/widgets/watch.dart';

/// Which people the People screen lists.
enum PeopleTab {
  receive,
  owe,
  settled;

  /// The `?tab=` value in the route (Home's totals open a tab directly).
  static PeopleTab parse(String? value) =>
      values.asNameMap()[value] ?? PeopleTab.receive;
}

enum _Sort { largest, smallest, name }

/// People / Udhaar (spec 3.2 #7): who owes you, whom you owe — one tab
/// each, plus everyone who's settled, with search and sorting.
class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key, this.initialTab = PeopleTab.receive});

  final PeopleTab initialTab;

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
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late PeopleTab _tab = widget.initialTab;
  _Sort _sort = _Sort.largest;
  String _query = '';

  /// This person's balance in the home currency (else any currency).
  static Money _balance(PersonSummary p, Currency currency) =>
      p.balance[currency] ??
      p.balance.values.firstOrNull ??
      Money.zero(currency);

  List<PersonSummary> _visible(List<PersonSummary> all, Currency currency) {
    final q = _query.trim().toLowerCase();
    final list = [
      for (final p in all)
        if (q.isEmpty || p.person.name.toLowerCase().contains(q))
          if (switch (_tab) {
            PeopleTab.receive => _balance(p, currency).isPositive,
            PeopleTab.owe => _balance(p, currency).isNegative,
            PeopleTab.settled => p.isSettled,
          })
            p,
    ];
    int size(PersonSummary p) => _balance(p, currency).minor.abs();
    switch (_sort) {
      case _Sort.largest:
        list.sort((a, b) => size(b).compareTo(size(a)));
      case _Sort.smallest:
        list.sort((a, b) => size(a).compareTo(size(b)));
      case _Sort.name:
        list.sort(
          (a, b) => a.person.name.toLowerCase().compareTo(
            b.person.name.toLowerCase(),
          ),
        );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final currency = context.watch<CurrencyCubit>().state;
    final sortLabels = {
      _Sort.largest: l.sortLargest,
      _Sort.smallest: l.sortSmallest,
      _Sort.name: l.sortName,
    };
    return Watch<PeopleOverview>(
      getIt<PeopleRepository>().watchOverview,
      builder: (context, o) {
        final people = o == null
            ? const <PersonSummary>[]
            : _visible(o.people, currency);
        final total = switch (_tab) {
          PeopleTab.receive => o?.receivable[currency],
          PeopleTab.owe => o?.payable[currency],
          PeopleTab.settled => null,
        };
        return PageScaffold(
          title: l.people,
          trailing: IconButton.filled(
            key: const Key('addPerson'),
            tooltip: l.addPerson,
            onPressed: () => PeopleScreen.addPerson(context),
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
                    SegmentedPicker<PeopleTab>(
                      key: const Key('peopleTabs'),
                      value: _tab,
                      onChanged: (t) => setState(() => _tab = t),
                      options: [
                        PickerOption(PeopleTab.receive, l.youllReceive),
                        PickerOption(PeopleTab.owe, l.youOwe),
                        PickerOption(PeopleTab.settled, l.settled),
                      ],
                    ),
                    if (total != null) ...[
                      const SizedBox(height: AppSpacing.l),
                      AmountText(
                        total,
                        key: const Key('peopleTabTotal'),
                        style: context.text.headlineMedium!.copyWith(
                          color: _tab == PeopleTab.receive ? c.income : c.ink,
                        ),
                      ),
                      Text(
                        l.peopleCount(people.length),
                        style: context.text.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.l),
                    TextField(
                      key: const Key('peopleSearch'),
                      onChanged: (q) => setState(() => _query = q),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l.searchPeople,
                        prefixIcon: const Icon(AppIcons.search),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: PillButton(
                        key: const Key('peopleSort'),
                        label: sortLabels[_sort]!,
                        icon: AppIcons.filter,
                        showChevron: true,
                        onTap: () async {
                          final picked = await pickOne<_Sort>(
                            context,
                            title: l.sortBy,
                            selected: _sort,
                            items: [
                              for (final MapEntry(:key, :value)
                                  in sortLabels.entries)
                                PickItem(value: key, title: value),
                            ],
                          );
                          if (picked != null) setState(() => _sort = picked);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    if (o.people.isEmpty)
                      EmptyState(
                        icon: AppIcons.people.filled,
                        title: l.noPeople,
                        message: l.noPeopleBody,
                        action: FilledButton(
                          onPressed: () => PeopleScreen.addPerson(context),
                          child: Text(l.addPerson),
                        ),
                      )
                    else if (people.isEmpty)
                      EmptyState(
                        icon: AppIcons.people.filled,
                        message: _query.trim().isNotEmpty
                            ? l.noPeopleMatch(_query.trim())
                            : switch (_tab) {
                                PeopleTab.receive => l.nobodyOwesYou,
                                PeopleTab.owe => l.youOweNobody,
                                PeopleTab.settled => l.noneSettled,
                              },
                      )
                    else
                      SurfaceCard(
                        padding: EdgeInsets.zero,
                        children: [
                          for (final p in people) PersonTile(summary: p),
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
  const UdhaarTotals({
    super.key,
    required this.overview,
    this.onReceivable,
    this.onPayable,
    this.masked = false,
  });

  final PeopleOverview overview;

  /// Opens "You'll receive" / "You owe".
  final VoidCallback? onReceivable;
  final VoidCallback? onPayable;

  /// Dots instead of amounts (Home, while balances are hidden).
  final bool masked;

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
      VoidCallback? onTap,
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
                masked: masked,
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
          onReceivable,
        ),
        const SizedBox(width: AppSpacing.s),
        tile(
          l.youOwe,
          overview.payable,
          c.ink,
          const Key('payable'),
          onPayable,
        ),
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

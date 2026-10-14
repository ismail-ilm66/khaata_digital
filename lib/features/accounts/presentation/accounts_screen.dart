import 'ordered_accounts.dart';
import '../../security/presentation/reveal_balances.dart';
import '../../../core/widgets/pill_button.dart';
import '../../settings/presentation/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../domain/account.dart';
import '../domain/account_presets.dart';
import '../domain/account_type.dart';
import 'account_badge.dart';
import 'account_form_screen.dart';
import 'accounts_bloc.dart';
import '../../../core/widgets/archived_section.dart';
import '../../../core/widgets/empty_state.dart';

/// Accounts (spec 3.2 #5): balances, drag to reorder, net worth, archive.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountsBloc>()..add(const AccountsStarted()),
      child: const _AccountsView(),
    );
  }
}

/// Opens the bank/wallet picker for the user's country, then the form for
/// the choice.
Future<void> addAccount(BuildContext context) async {
  final choice = await showAppSheet<AccountPreset?>(
    context,
    title: context.l10n.addAccount,
    builder: (context) => const _PresetGrid(),
  );
  if (choice == null || !context.mounted) return;
  await context.push(
    Routes.accountForm,
    extra: AccountFormArgs(
      preset: choice == _PresetGrid.custom ? null : choice,
    ),
  );
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final masked = context.watch<HideBalanceCubit>().state.masked;
    return BlocConsumer<AccountsBloc, AccountsState>(
      listenWhen: (a, b) => b.duplicateName != null,
      listener: (context, s) =>
          showToast(context, l.duplicateAccountName(s.duplicateName!)),
      builder: (context, s) {
        final accounts = s.overview.accounts;
        return PageScaffold(
          title: l.accounts,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (accounts.length > 1) ...[
                const _OrderButton(),
                const SizedBox(width: AppSpacing.s),
              ],
              const BalanceEyeButton(buttonKey: Key('accountsEye')),
              const SizedBox(width: AppSpacing.s),
              HeaderButton(
                key: const Key('addAccount'),
                primary: true,
                icon: AppIcons.plus,
                tooltip: l.addAccount,
                onPressed: () => addAccount(context),
              ),
            ],
          ),
          slivers: [
            if (accounts.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: AppIcons.accounts.filled,
                  message: l.noAccounts,
                  action: FilledButton(
                    onPressed: () => addAccount(context),
                    child: Text(l.addAccount),
                  ),
                ),
              ),
            OrderedAccounts(
              accounts: accounts,
              builder: (context, ordered) {
                final byUse = context.watch<AccountsByUseCubit>().state;
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page,
                  ),
                  sliver: SliverReorderableList(
                    itemCount: ordered.length,
                    onReorder: (from, to) => context.read<AccountsBloc>().add(
                      AccountsReordered(from, to),
                    ),
                    // A lifted row is a card of its own.
                    proxyDecorator: (child, _, _) => Material(
                      color: Colors.transparent,
                      child: _AccountRow.lifted(child),
                    ),
                    itemBuilder: (context, i) => _AccountRow(
                      key: ValueKey(ordered[i].account.id),
                      summary: ordered[i],
                      index: i,
                      count: ordered.length,
                      masked: masked,
                      // Dragging only means something in your own order.
                      draggable: !byUse,
                    ),
                  ),
                );
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.s,
                AppSpacing.page,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: SurfaceCard(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            l.netWorth,
                            style: context.text.titleSmall,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final m in s.overview.netWorth.values)
                              AmountText(
                                m,
                                masked: masked,
                                style: context.text.titleMedium,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (s.archived.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.xl,
                  AppSpacing.page,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ArchivedSection(
                    items: [
                      for (final a in s.archived)
                        ArchivedItem(
                          badge: AccountBadge.of(a, size: 32),
                          name: a.name,
                          onRestore: () => context.read<AccountsBloc>().add(
                            AccountUnarchived(a.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One account in the grouped list: rows share one rounded card, joined
/// by inset hairlines, like the grouped lists elsewhere.
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    super.key,
    required this.summary,
    required this.index,
    required this.count,
    required this.masked,
    this.draggable = true,
  });

  final AccountSummary summary;
  final int index;
  final int count;
  final bool masked;
  final bool draggable;

  /// The row being dragged: fully rounded and raised.
  static Widget lifted(Widget row) => Builder(
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.l),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.l),
        child: row,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final a = summary.account;
    final c = context.colors;
    const r = Radius.circular(AppRadii.l);
    final radius = BorderRadius.vertical(
      top: index == 0 ? r : Radius.zero,
      bottom: index == count - 1 ? r : Radius.zero,
    );
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (index > 0)
            Divider(
              indent: AppSpacing.l + 40 + kBadgeGap,
              color: c.line.withValues(alpha: 0.7),
            ),
          _content(context, a, c),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, Account a, AppColors c) {
    return InkWell(
      onTap: () =>
          context.push(Routes.accountForm, extra: AccountFormArgs(account: a)),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.xs,
          AppSpacing.m,
        ),
        child: Row(
          children: [
            AccountBadge.of(a),
            const SizedBox(width: kBadgeGap),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.name,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    [
                      context.accountTypeName(a.type),
                      a.currency.code,
                      if (a.excludeFromTotal) context.l10n.notInTotal,
                    ].join(' · '),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            // Fills its share so every balance sits on the same right
            // edge, shrinking only when too long.
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: AmountText(
                  summary.balance,
                  masked: masked,
                  style: context.text.titleSmall,
                ),
              ),
            ),
            if (draggable)
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s),
                  child: Icon(AppIcons.dragHandle, size: 18, color: c.inkMuted),
                ),
              )
            else
              const SizedBox(width: AppSpacing.m),
          ],
        ),
      ),
    );
  }
}

class _PresetGrid extends StatelessWidget {
  const _PresetGrid();

  /// Sentinel for "Custom" (a null pop means the sheet was dismissed).
  static const custom = AccountPreset(
    key: '_custom',
    name: '',
    type: AccountType.cash,
    color: 0,
    monogram: '',
  );

  @override
  Widget build(BuildContext context) {
    Widget cell({
      required Widget badge,
      required String label,
      required VoidCallback onTap,
      Key? key,
    }) => InkResponse(
      key: key,
      onTap: onTap,
      radius: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          badge,
          const SizedBox(height: AppSpacing.s),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium,
          ),
        ],
      ),
    );

    final country = context.watch<CountryCubit>().state;
    final grid = GridView.count(
      shrinkWrap: true,
      primary: false,
      crossAxisCount: 3,
      childAspectRatio: 1.05,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.xl,
      ),
      children: [
        for (final p in AccountPresets.forCountry(country.code))
          cell(
            key: Key('preset-${p.key}'),
            badge: AccountBadge(
              type: p.type,
              iconKey: p.key,
              color: p.color,
              size: 52,
            ),
            label: p.name,
            onTap: () => Navigator.pop(context, p),
          ),
        cell(
          key: const Key('preset-custom'),
          badge: const TintedBadge(icon: AppIcons.plus, size: 52),
          label: context.l10n.custom,
          onTap: () => Navigator.pop(context, custom),
        ),
      ],
    );
    // Which country's banks: tap to switch (saved as the country).
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.m,
            ),
            // The pill drops under the label when space runs out.
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.xs,
              children: [
                Text(context.l10n.banksIn, style: context.text.bodySmall),
                PillButton(
                  key: const Key('presetCountry'),
                  leading: CountryFlag(country, size: 16),
                  label: countryName(context, country),
                  showChevron: true,
                  onTap: () async {
                    final c = await pickCountry(context, country);
                    if (c != null && context.mounted) {
                      await context.read<CountryCubit>().set(c);
                    }
                  },
                ),
              ],
            ),
          ),
          grid,
        ],
      ),
    );
  }
}

/// Sort: "Most used first" or your own order (which brings back the drag
/// handles). Rarely changed, so it lives behind a header button.
class _OrderButton extends StatelessWidget {
  const _OrderButton();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final byUse = context.watch<AccountsByUseCubit>().state;
    return HeaderButton(
      key: const Key('accountsByUse'),
      icon: AppIcons.sortByUse,
      tooltip: l.sortBy,
      onPressed: () async {
        final v = await pickOne<bool>(
          context,
          title: l.sortBy,
          selected: byUse,
          items: [
            PickItem(
              value: true,
              title: l.mostUsedFirst,
              subtitle: l.mostUsedFirstOn,
            ),
            PickItem(
              value: false,
              title: l.yourOrder,
              subtitle: l.mostUsedFirstOff,
            ),
          ],
        );
        if (v != null && context.mounted) {
          await context.read<AccountsByUseCubit>().set(v);
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
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

/// Opens the Pakistani bank/wallet picker, then the form for the choice.
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
    final c = context.colors;
    final masked = context.watch<HideBalanceCubit>().state;
    return BlocConsumer<AccountsBloc, AccountsState>(
      listenWhen: (a, b) => b.duplicateName != null,
      listener: (context, s) =>
          showToast(context, l.duplicateAccountName(s.duplicateName!)),
      builder: (context, s) {
        final accounts = s.overview.accounts;
        return PageScaffold(
          title: l.accounts,
          trailing: IconButton.filled(
            key: const Key('addAccount'),
            tooltip: l.addAccount,
            onPressed: () => addAccount(context),
            icon: const Icon(AppIcons.plus),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              sliver: SliverReorderableList(
                itemCount: accounts.length,
                onReorder: (from, to) => context.read<AccountsBloc>().add(
                  AccountsReordered(from, to),
                ),
                proxyDecorator: (child, _, _) =>
                    Material(color: Colors.transparent, child: child),
                itemBuilder: (context, i) => Padding(
                  key: ValueKey(accounts[i].account.id),
                  padding: const EdgeInsets.only(bottom: AppSpacing.s),
                  child: _AccountRow(
                    summary: accounts[i],
                    index: i,
                    masked: masked,
                  ),
                ),
              ),
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
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: const Key('archivedSection'),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      title: Text(
                        '${l.archived} · ${s.archived.length}',
                        style: context.text.labelLarge!.copyWith(
                          color: c.inkMuted,
                        ),
                      ),
                      children: [
                        SurfaceCard(
                          children: [
                            for (final a in s.archived)
                              Row(
                                children: [
                                  Opacity(
                                    opacity: 0.6,
                                    child: AccountBadge.of(a, size: 32),
                                  ),
                                  const SizedBox(width: AppSpacing.m),
                                  Expanded(
                                    child: Text(
                                      a.name,
                                      style: context.text.bodyMedium,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context
                                        .read<AccountsBloc>()
                                        .add(AccountUnarchived(a.id)),
                                    child: Text(l.restore),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.summary,
    required this.index,
    required this.masked,
  });

  final AccountSummary summary;
  final int index;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final a = summary.account;
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.m),
        onTap: () => context.push(
          Routes.accountForm,
          extra: AccountFormArgs(account: a),
        ),
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
              AmountText(
                summary.balance,
                masked: masked,
                style: context.text.titleSmall,
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s),
                  child: Icon(AppIcons.dragHandle, size: 18, color: c.inkMuted),
                ),
              ),
            ],
          ),
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

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 1.05,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.xl,
      ),
      children: [
        for (final p in AccountPresets.all)
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
  }
}

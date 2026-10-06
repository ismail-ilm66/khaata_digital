import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/fixed_point.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../domain/account.dart';
import '../domain/account_presets.dart';
import '../domain/account_type.dart';
import 'account_badge.dart';
import 'account_form_cubit.dart';

/// Route argument: edit [account], or create (optionally from [preset]).
@immutable
class AccountFormArgs {
  const AccountFormArgs({this.account, this.preset});

  final Account? account;
  final AccountPreset? preset;
}

class AccountFormScreen extends StatelessWidget {
  const AccountFormScreen({super.key, required this.args});

  final AccountFormArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<AccountFormCubit>();
        if (args.account case final a?) {
          cubit.startEdit(a);
        } else {
          cubit.startNew(
            preset: args.preset,
            currency: getIt<CurrencyCubit>().state,
          );
        }
        return cubit;
      },
      child: const _AccountForm(),
    );
  }
}

class _AccountForm extends StatefulWidget {
  const _AccountForm();

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late final AccountFormCubit _cubit = context.read<AccountFormCubit>();
  late final _name = TextEditingController(text: _cubit.state.draft.name);
  late final _opening = TextEditingController(
    text: _cubit.state.draft.openingBalance.isZero
        ? ''
        : FixedPoint.format(
            _cubit.state.draft.openingBalance.minor,
            _cubit.state.draft.currency.decimals,
          ),
  );

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final d = _cubit.state.draft;
    _cubit
      ..update(
        d.copyWith(
          name: _name.text,
          openingBalance: AmountField.read(_opening, d.currency),
        ),
      )
      ..save();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<AccountFormCubit, AccountFormState>(
      listenWhen: (a, b) =>
          a.status != b.status || a.duplicateName != b.duplicateName,
      listener: (context, s) {
        if (s.status
            case AccountFormStatus.saved || AccountFormStatus.archived) {
          Navigator.pop(context);
          showToast(
            context,
            s.status == AccountFormStatus.archived
                ? l.accountArchived
                : l.saved,
          );
        }
        if (s.duplicateName) _formKey.currentState!.validate();
      },
      builder: (context, s) {
        final d = s.draft;
        return PageScaffold(
          title: s.isEditing ? l.editAccount : l.newAccount,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SurfaceCard(
                        children: [
                          Row(
                            children: [
                              AccountBadge(
                                type: d.type,
                                iconKey: d.iconKey,
                                color: d.color,
                                size: 48,
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('accountName'),
                                  controller: _name,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    labelText: l.accountName,
                                  ),
                                  onChanged: (_) {
                                    if (s.duplicateName) _cubit.update(d);
                                  },
                                  validator: (v) {
                                    if ((v ?? '').trim().isEmpty) {
                                      return l.nameRequired;
                                    }
                                    if (s.duplicateName) {
                                      return l.duplicateAccountName(v!.trim());
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          AmountField(
                            key: const Key('openingBalance'),
                            controller: _opening,
                            currency: d.currency,
                            label: l.openingBalance,
                            invalidMessage: l.invalidAmount,
                            allowNegative: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Section(
                        title: l.accountType,
                        child: Wrap(
                          spacing: AppSpacing.s,
                          runSpacing: AppSpacing.s,
                          children: [
                            for (final t in AccountType.values)
                              PillButton(
                                label: context.accountTypeName(t),
                                selected: d.type == t,
                                onTap: () => _cubit.update(d.copyWith(type: t)),
                              ),
                          ],
                        ),
                      ),
                      SurfaceCard(
                        children: [
                          SettingTile(
                            icon: AppIcons.accounts.filled,
                            title: l.currency,
                            trailing: Text(
                              d.currency.code,
                              style: context.text.titleSmall,
                            ),
                            onTap: () async {
                              final picked = await pickOne<Currency>(
                                context,
                                title: l.currency,
                                selected: d.currency,
                                items: [
                                  for (final c in Currency.known)
                                    PickItem(
                                      value: c,
                                      title: c.code,
                                      subtitle: c.symbol,
                                    ),
                                ],
                              );
                              if (picked != null) {
                                _cubit.update(d.copyWith(currency: picked));
                              }
                            },
                          ),
                          SettingTile(
                            icon: AppIcons.hide,
                            title: l.excludeFromTotal,
                            subtitle: l.excludeFromTotalHint,
                            trailing: Switch(
                              key: const Key('excludeSwitch'),
                              value: d.excludeFromTotal,
                              onChanged: (v) => _cubit.update(
                                d.copyWith(excludeFromTotal: v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        key: const Key('saveAccount'),
                        onPressed: s.status == AccountFormStatus.saving
                            ? null
                            : _save,
                        child: Text(l.save),
                      ),
                      if (s.isEditing) ...[
                        const SizedBox(height: AppSpacing.s),
                        TextButton.icon(
                          key: const Key('archiveAccount'),
                          onPressed: _cubit.archive,
                          icon: const Icon(AppIcons.archive, size: 18),
                          label: Text(l.archive),
                        ),
                      ],
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

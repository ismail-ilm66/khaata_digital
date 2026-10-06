import 'package:flutter/material.dart';

import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../domain/account.dart';
import '../domain/account_presets.dart';
import '../domain/account_type.dart';

/// A preset's monogram in its brand-adjacent colour, or the account type's
/// icon for custom accounts.
class AccountBadge extends StatelessWidget {
  const AccountBadge({
    super.key,
    required this.type,
    this.iconKey,
    this.color,
    this.size = 40,
  });

  AccountBadge.of(Account a, {Key? key, double size = 40})
    : this(
        key: key,
        type: a.type,
        iconKey: a.iconKey,
        color: a.color,
        size: size,
      );

  final AccountType type;
  final String? iconKey;
  final int? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final preset = AccountPresets.byKey(iconKey);
    final tint = color != null ? Color(color!) : context.colors.brand;
    if (preset != null && preset.key != AccountPresets.cash.key) {
      return TintedBadge(monogram: preset.monogram, color: tint, size: size);
    }
    return TintedBadge(
      icon: AppIcons.accountTypes[type.name]!.filled,
      color: tint,
      size: size,
    );
  }
}

extension AccountTypeLabel on BuildContext {
  String accountTypeName(AccountType t) => switch (t) {
    AccountType.cash => l10n.accountTypeCash,
    AccountType.bank => l10n.accountTypeBank,
    AccountType.wallet => l10n.accountTypeWallet,
    AccountType.card => l10n.accountTypeCard,
    AccountType.savings => l10n.accountTypeSavings,
  };
}

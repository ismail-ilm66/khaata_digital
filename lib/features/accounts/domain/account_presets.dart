import 'package:meta/meta.dart';

import 'account_type.dart';

/// A curated Pakistani bank / wallet for the add-account picker (spec 3.1 #2).
@immutable
class AccountPreset {
  const AccountPreset({
    required this.key,
    required this.name,
    required this.type,
    required this.color,
    required this.monogram,
    this.aliases = const [],
  });

  /// Stable id stored as the account's `icon`.
  final String key;
  final String name;
  final AccountType type;

  /// Brand-adjacent ARGB colour for the monogram badge.
  final int color;
  final String monogram;

  /// Other spellings seen in the wild (e.g. Hysab Kytab exports).
  final List<String> aliases;

  bool matches(String accountName) {
    final n = _norm(accountName);
    return _norm(name) == n || aliases.any((a) => _norm(a) == n);
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

abstract final class AccountPresets {
  static const cash = AccountPreset(
    key: 'cash',
    name: 'Cash',
    type: AccountType.cash,
    color: 0xFF5F6B7A,
    monogram: '₨',
  );

  static const List<AccountPreset> all = [
    cash,
    AccountPreset(
      key: 'easypaisa',
      name: 'Easypaisa',
      type: AccountType.wallet,
      color: 0xFF1FA84F,
      monogram: 'EP',
    ),
    AccountPreset(
      key: 'jazzcash',
      name: 'JazzCash',
      type: AccountType.wallet,
      color: 0xFFC8102E,
      monogram: 'JC',
    ),
    AccountPreset(
      key: 'sadapay',
      name: 'SadaPay',
      type: AccountType.wallet,
      color: 0xFF00A88F,
      monogram: 'SP',
    ),
    AccountPreset(
      key: 'nayapay',
      name: 'NayaPay',
      type: AccountType.wallet,
      color: 0xFFE8641B,
      monogram: 'NP',
    ),
    AccountPreset(
      key: 'meezan',
      name: 'Meezan Bank',
      type: AccountType.bank,
      color: 0xFF6A1B6E,
      monogram: 'MB',
      aliases: ['Meezan'],
    ),
    AccountPreset(
      key: 'hbl',
      name: 'HBL',
      type: AccountType.bank,
      color: 0xFF00836B,
      monogram: 'HBL',
      aliases: ['Habib Bank', 'Habib Bank Limited'],
    ),
    AccountPreset(
      key: 'ubl',
      name: 'UBL',
      type: AccountType.bank,
      color: 0xFF0055A5,
      monogram: 'UBL',
      aliases: ['United Bank', 'United Bank Limited'],
    ),
    AccountPreset(
      key: 'mcb',
      name: 'MCB',
      type: AccountType.bank,
      color: 0xFF0B7A4B,
      monogram: 'MCB',
      aliases: ['MCB Bank', 'Muslim Commercial Bank'],
    ),
    AccountPreset(
      key: 'allied',
      name: 'Allied Bank',
      type: AccountType.bank,
      color: 0xFF0F4C81,
      monogram: 'ABL',
      aliases: ['ABL', 'Allied Bank Limited'],
    ),
    AccountPreset(
      key: 'alfalah',
      name: 'Bank Alfalah',
      type: AccountType.bank,
      color: 0xFFB01E23,
      monogram: 'BAF',
      aliases: ['Alfalah'],
    ),
    AccountPreset(
      key: 'askari',
      name: 'Askari Bank',
      type: AccountType.bank,
      color: 0xFF0067B1,
      monogram: 'AKB',
      aliases: ['Askari'],
    ),
    AccountPreset(
      key: 'scb',
      name: 'Standard Chartered',
      type: AccountType.bank,
      color: 0xFF0473EA,
      monogram: 'SC',
      aliases: ['Standard Chartered Bank', 'SCB'],
    ),
  ];

  static AccountPreset? match(String accountName) {
    for (final p in all) {
      if (p.matches(accountName)) return p;
    }
    return null;
  }

  static const _walletWords = ['easypaisa', 'jazzcash', 'sadapay', 'nayapay'];

  /// Best-guess account type from a free-text name (spec 3.3 import rule):
  /// known preset → its type; "bank" → bank; wallet brands → wallet;
  /// "saving" → savings; otherwise cash.
  static AccountType guessType(String accountName) {
    final preset = match(accountName);
    if (preset != null) return preset.type;
    final n = accountName.toLowerCase().replaceAll(' ', '');
    if (n.contains('bank')) return AccountType.bank;
    if (_walletWords.any(n.contains)) return AccountType.wallet;
    if (n.contains('saving')) return AccountType.savings;
    return AccountType.cash;
  }
}

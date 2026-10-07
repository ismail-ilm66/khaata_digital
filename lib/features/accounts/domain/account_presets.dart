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
    monogram: 'Rs',
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

  static AccountPreset? byKey(String? key) {
    for (final p in all) {
      if (p.key == key) return p;
    }
    return null;
  }

  static AccountPreset? match(String accountName) {
    for (final p in all) {
      if (p.matches(accountName)) return p;
    }
    return null;
  }

  static final _wallet = RegExp(
    r'easy\s?paisa|jazz\s?cash|sada\s?pay|naya\s?pay|upaisa|payoneer|paypal|'
    r'wallet|zindigi|keenu',
    caseSensitive: false,
  );
  static final _bank = RegExp(
    r'\bbank|\bhbl\b|\bubl\b|\bmcb\b|\babl\b|\bnbp\b|\bbop\b|meezan|'
    r'alfalah|askari|faysal|habib|allied|islami|soneri|summit|silk|'
    r'chartered|al\s?baraka|\bjs\b|limited|\bltd\b',
    caseSensitive: false,
  );
  static final _card = RegExp(
    r'\bcard\b|credit|visa|master',
    caseSensitive: false,
  );
  static final _savings = RegExp(
    r'saving|committee|\bbc\b|invest|fund|deposit',
    caseSensitive: false,
  );
  static final _cash = RegExp(
    r'\bcash\b|account|purse|pocket',
    caseSensitive: false,
  );

  /// Best-guess account type from a free-text name (spec 3.3 import rule):
  /// a known preset's type; else wallet brands → wallet, bank words and
  /// Pakistani bank names → bank, card → card, savings / committee →
  /// savings, otherwise cash.
  static AccountType guessType(String accountName) {
    final preset = match(accountName);
    if (preset != null) return preset.type;
    if (_wallet.hasMatch(accountName)) return AccountType.wallet;
    if (_bank.hasMatch(accountName)) return AccountType.bank;
    if (_card.hasMatch(accountName)) return AccountType.card;
    if (_savings.hasMatch(accountName)) return AccountType.savings;
    return AccountType.cash;
  }

  /// Whether a name sounds like a money account at all — used to tell
  /// Hysab Kytab's person "accounts" (Mudassir Bhai) from real ones.
  static bool looksLikeAccount(String name) =>
      match(name) != null ||
      [_wallet, _bank, _card, _savings, _cash].any((r) => r.hasMatch(name));
}

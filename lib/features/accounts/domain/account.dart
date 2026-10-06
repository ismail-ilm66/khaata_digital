import 'package:equatable/equatable.dart';

import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import 'account_type.dart';

class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalance,
    this.iconKey,
    this.color,
    this.excludeFromTotal = false,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final AccountType type;
  final Currency currency;
  final Money openingBalance;

  /// An [AccountPreset] key, when created from the picker.
  final String? iconKey;
  final int? color;
  final bool excludeFromTotal;
  final bool isArchived;

  AccountDraft toDraft() => AccountDraft(
    name: name,
    type: type,
    currency: currency,
    openingBalance: openingBalance,
    iconKey: iconKey,
    color: color,
    excludeFromTotal: excludeFromTotal,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    currency,
    openingBalance,
    iconKey,
    color,
    excludeFromTotal,
    isArchived,
  ];
}

/// The editable fields of an account (create and edit).
class AccountDraft extends Equatable {
  const AccountDraft({
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalance,
    this.iconKey,
    this.color,
    this.excludeFromTotal = false,
  });

  final String name;
  final AccountType type;
  final Currency currency;
  final Money openingBalance;
  final String? iconKey;
  final int? color;
  final bool excludeFromTotal;

  AccountDraft copyWith({
    String? name,
    AccountType? type,
    Currency? currency,
    Money? openingBalance,
    bool? excludeFromTotal,
  }) => AccountDraft(
    name: name ?? this.name,
    type: type ?? this.type,
    currency: currency ?? this.currency,
    openingBalance: openingBalance ?? this.openingBalance,
    iconKey: iconKey,
    color: color,
    excludeFromTotal: excludeFromTotal ?? this.excludeFromTotal,
  );

  @override
  List<Object?> get props => [
    name,
    type,
    currency,
    openingBalance,
    iconKey,
    color,
    excludeFromTotal,
  ];
}

class AccountSummary extends Equatable {
  const AccountSummary(this.account, this.balance);

  final Account account;

  /// Current balance in the account's own currency.
  final Money balance;

  @override
  List<Object?> get props => [account, balance];
}

class AccountsOverview extends Equatable {
  const AccountsOverview({required this.accounts, required this.netWorth});

  static const empty = AccountsOverview(accounts: [], netWorth: {});

  /// Active accounts in user order.
  final List<AccountSummary> accounts;

  /// Per currency; excludes accounts marked "exclude from total".
  final Map<Currency, Money> netWorth;

  @override
  List<Object?> get props => [accounts, netWorth];
}

abstract interface class AccountsRepository {
  Stream<AccountsOverview> watchOverview();
  Stream<List<Account>> watchArchived();
  Future<Account?> byId(String id);

  /// Throws [DuplicateNameFailure] when an active account has the name.
  Future<String> create(AccountDraft draft);

  /// Throws [DuplicateNameFailure] when another active account has the name.
  Future<void> update(String id, AccountDraft draft);

  Future<void> archive(String id);

  /// Throws [DuplicateNameFailure] if the name was reused meanwhile.
  Future<void> unarchive(String id);
  Future<void> reorder(List<String> orderedIds);
}

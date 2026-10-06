import 'package:equatable/equatable.dart';

import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../transactions/domain/ledger_entry.dart';
import '../../transactions/domain/transaction_type.dart';

class Person extends Equatable {
  const Person({required this.id, required this.name, this.contactHint});

  final String id;
  final String name;
  final String? contactHint;

  @override
  List<Object?> get props => [id, name, contactHint];
}

/// A person and where you stand with them, per currency:
/// positive = they owe you, negative = you owe them.
class PersonSummary extends Equatable {
  const PersonSummary(this.person, this.balance);

  final Person person;
  final Map<Currency, Money> balance;

  bool get isSettled => balance.values.every((m) => m.isZero);

  @override
  List<Object?> get props => [person, balance];
}

class PeopleOverview extends Equatable {
  const PeopleOverview({
    required this.people,
    required this.receivable,
    required this.payable,
  });

  static const empty = PeopleOverview(people: [], receivable: {}, payable: {});

  /// Everyone, alphabetical.
  final List<PersonSummary> people;

  /// "You'll receive": sum of what people owe you, per currency.
  final Map<Currency, Money> receivable;

  /// "You owe": sum of what you owe people, per currency (positive).
  final Map<Currency, Money> payable;

  static PeopleOverview of(List<PersonSummary> people) {
    final receivable = <Currency, Money>{};
    final payable = <Currency, Money>{};
    for (final p in people) {
      for (final m in p.balance.values) {
        final target = m.isNegative ? payable : receivable;
        final amount = m.abs();
        target.update(m.currency, (x) => x + amount, ifAbsent: () => amount);
      }
    }
    return PeopleOverview(
      people: people,
      receivable: receivable,
      payable: payable,
    );
  }

  @override
  List<Object?> get props => [people, receivable, payable];
}

/// Direction of an udhaar entry, from the user's point of view.
enum UdhaarDirection {
  /// "Maine diya" — money went to them; they owe me (stored as expense).
  gave,

  /// "Maine liya" — money came from them; I owe them (stored as income).
  received;

  TransactionType get type =>
      this == gave ? TransactionType.expense : TransactionType.income;

  static UdhaarDirection of(TransactionType t) =>
      t == TransactionType.income ? received : gave;
}

/// One ledger row with the balance after it (per its currency).
class LedgerLine extends Equatable {
  const LedgerLine(this.view, this.runningBalance);

  final EntryView view;
  final Money runningBalance;

  /// The entry's effect on the person's balance (+ they owe me more).
  static Money effect(LedgerEntry e) =>
      e.type == TransactionType.income ? -e.amount : e.amount;

  /// Builds lines from [newestFirst] entries, accumulating oldest→newest
  /// so each line shows the balance right after it.
  static List<LedgerLine> build(List<EntryView> newestFirst) {
    final running = <Currency, Money>{};
    final lines = <LedgerLine>[];
    for (final v in newestFirst.reversed) {
      final m = effect(v.entry);
      final next = (running[m.currency] ?? Money.zero(m.currency)) + m;
      running[m.currency] = next;
      lines.add(LedgerLine(v, next));
    }
    return lines.reversed.toList();
  }

  @override
  List<Object?> get props => [view, runningBalance];
}

abstract interface class PeopleRepository {
  Stream<PeopleOverview> watchOverview();
  Stream<Person?> watchPerson(String id);

  /// Throws [DuplicateNameFailure] if an active person has the name.
  Future<String> create(String name, {String? contactHint});

  /// Throws [DuplicateNameFailure] if another active person has the name.
  Future<void> rename(String id, String name);
  Future<void> archive(String id);

  /// The person's entries, newest first, with running balances.
  Stream<List<LedgerLine>> watchLedger(String personId);
}

import 'package:equatable/equatable.dart';

import '../../../core/dates/date_range.dart';
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

/// A debt let go (bad debt): no money moved, so no account is touched and
/// it isn't income or spending. [amount] is signed like a balance:
/// + I wrote off what they owed me, − they forgave what I owed them.
class WriteOff extends Equatable {
  const WriteOff({
    required this.id,
    required this.personId,
    required this.personName,
    required this.amount,
    required this.occurredAt,
    this.note = '',
  });

  final String id;
  final String personId;
  final String personName;
  final Money amount;
  final DateTime occurredAt;
  final String note;

  /// They let go of what I owed them (rather than me writing off theirs).
  bool get isForgiven => amount.isNegative;

  @override
  List<Object?> get props => [
    id,
    personId,
    personName,
    amount,
    occurredAt,
    note,
  ];
}

/// One ledger row (an entry, or a write-off) with the balance after it,
/// per its currency.
class LedgerLine extends Equatable {
  const LedgerLine(EntryView this.view, this.runningBalance) : writeOff = null;
  const LedgerLine.writeOff(WriteOff this.writeOff, this.runningBalance)
    : view = null;

  /// The entry, or null when this line is a [writeOff].
  final EntryView? view;
  final WriteOff? writeOff;
  final Money runningBalance;

  DateTime get occurredAt => writeOff?.occurredAt ?? view!.entry.occurredAt;

  /// This line's effect on the balance (+ they owe me more). A write-off
  /// cancels its amount.
  Money get delta => writeOff == null ? effect(view!.entry) : -writeOff!.amount;

  /// The entry's effect on the person's balance (+ they owe me more).
  static Money effect(LedgerEntry e) =>
      e.type == TransactionType.income ? -e.amount : e.amount;

  /// Builds lines from [newestFirst] entries and write-offs, accumulating
  /// oldest→newest so each line shows the balance right after it. On the
  /// same instant a write-off counts as later (it closes what came before).
  static List<LedgerLine> build(
    List<EntryView> newestFirst, [
    List<WriteOff> writeOffsNewestFirst = const [],
  ]) {
    final merged = <LedgerLine>[];
    var i = 0;
    var j = 0;
    while (i < newestFirst.length || j < writeOffsNewestFirst.length) {
      final takeWriteOff =
          j < writeOffsNewestFirst.length &&
          (i == newestFirst.length ||
              !writeOffsNewestFirst[j].occurredAt.isBefore(
                newestFirst[i].entry.occurredAt,
              ));
      // Placeholder balances; the pass below fills them in.
      if (takeWriteOff) {
        final w = writeOffsNewestFirst[j++];
        merged.add(LedgerLine.writeOff(w, Money.zero(w.amount.currency)));
      } else {
        final v = newestFirst[i++];
        merged.add(LedgerLine(v, Money.zero(v.entry.amount.currency)));
      }
    }
    final running = <Currency, Money>{};
    final lines = <LedgerLine>[];
    for (final x in merged.reversed) {
      final m = x.delta;
      final next = (running[m.currency] ?? Money.zero(m.currency)) + m;
      running[m.currency] = next;
      lines.add(
        x.writeOff == null
            ? LedgerLine(x.view!, next)
            : LedgerLine.writeOff(x.writeOff!, next),
      );
    }
    return lines.reversed.toList();
  }

  @override
  List<Object?> get props => [view, writeOff, runningBalance];
}

abstract interface class PeopleRepository {
  Stream<PeopleOverview> watchOverview();
  Stream<Person?> watchPerson(String id);

  /// Throws [DuplicateNameFailure] if an active person has the name.
  Future<String> create(String name, {String? contactHint});

  /// Throws [DuplicateNameFailure] if another active person has the name.
  Future<void> rename(String id, String name);
  Future<void> archive(String id);

  /// The person's entries and write-offs, newest first, with running
  /// balances.
  Stream<List<LedgerLine>> watchLedger(String personId);

  /// Writes off [amount] of the balance with [personId]: + what they owe
  /// me, − what I owe them (forgiven). No account changes.
  Future<String> writeOff(
    String personId,
    Money amount, {
    required DateTime occurredAt,
    String note = '',
  });

  Future<void> editWriteOff(
    String id,
    Money amount, {
    required DateTime occurredAt,
    String note = '',
  });

  Future<void> removeWriteOff(String id);

  /// Undoes [removeWriteOff].
  Future<void> restoreWriteOff(String id);

  /// Everyone's write-offs within [range] (all time when null), newest
  /// first.
  Stream<List<WriteOff>> watchWriteOffs({DateRange? range});
}

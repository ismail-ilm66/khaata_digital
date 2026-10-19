import 'package:equatable/equatable.dart';

import '../../../core/money/fixed_point.dart';
import '../../../core/money/money.dart';
import 'ledger_entry.dart';
import 'transaction_type.dart';

/// One part of a split bill: a person's, or the user's own when
/// [personId] is null.
class SplitShare extends Equatable {
  const SplitShare(this.personId, this.amount);

  final String? personId;
  final Money amount;

  bool get isMine => personId == null;

  @override
  List<Object?> get props => [personId, amount];
}

/// [total] in [ways] equal parts, any remainder going to the first parts
/// (the user's own share comes first). A whole-unit total splits into
/// whole units (1,000 three ways → 334, 333, 333), so nobody owes paisa.
List<Money> evenSplit(Money total, int ways) {
  assert(ways > 0);
  final unit = total.minor % FixedPoint.pow10(total.currency.decimals) == 0
      ? FixedPoint.pow10(total.currency.decimals)
      : 1;
  final units = total.minor ~/ unit;
  final each = units ~/ ways;
  final extra = units % ways;
  return [
    for (var i = 0; i < ways; i++)
      Money((each + (i < extra ? 1 : 0)) * unit, total.currency),
  ];
}

/// Whether [shares] add up to [total] with at least one above zero and
/// none below.
bool sharesAddUp(Money total, List<SplitShare> shares) =>
    shares.every((s) => !s.amount.isNegative) &&
    shares.any((s) => s.amount.isPositive) &&
    Money.sum(shares.map((s) => s.amount), total.currency) == total;

/// The entries a split [bill] is saved as: each person's share as udhaar
/// given to them, then the user's own as an expense in the bill's
/// category. Zero shares are left out. The note, date, account and tags
/// go on every entry; receipts only on the last, so a failed save never
/// leaves stored images behind on entries that were rolled back.
List<EntryDraft> splitDrafts(EntryDraft bill, List<SplitShare> shares) {
  final parts = [
    for (final s in shares)
      if (!s.isMine && s.amount.isPositive) s,
    for (final s in shares)
      if (s.isMine && s.amount.isPositive) s,
  ];
  return [
    for (final (i, s) in parts.indexed)
      EntryDraft(
        type: TransactionType.expense,
        amount: s.amount,
        occurredAt: bill.occurredAt,
        accountId: bill.accountId,
        categoryId: s.isMine ? bill.categoryId : null,
        personId: s.personId,
        note: bill.note,
        place: bill.place,
        tags: bill.tags,
        newReceiptPaths: i == parts.length - 1
            ? bill.newReceiptPaths
            : const [],
      ),
  ];
}

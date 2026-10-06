import 'package:equatable/equatable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import 'transaction_type.dart';

/// A stored receipt image.
class Attachment extends Equatable {
  const Attachment({
    required this.id,
    required this.fileName,
    required this.mime,
    required this.byteSize,
    required this.sha256,
  });

  final String id;
  final String fileName;
  final String mime;
  final int byteSize;
  final String sha256;

  @override
  List<Object?> get props => [id, fileName, mime, byteSize, sha256];
}

/// A stored transaction. Transfers are one entry moving money from
/// [accountId] to [toAccountId].
class LedgerEntry extends Equatable {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    required this.occurredAt,
    this.toAccountId,
    this.toAmount,
    this.fxRateMicros,
    this.categoryId,
    this.personId,
    this.note = '',
    this.place,
    this.tags = const [],
    this.attachments = const [],
  });

  final String id;
  final TransactionType type;

  /// Always positive except for adjustments (signed).
  final Money amount;
  final String accountId;
  final String? toAccountId;

  /// Cross-currency transfers: amount credited, in the destination currency.
  final Money? toAmount;
  final int? fxRateMicros;
  final String? categoryId;
  final String? personId;

  /// UTC.
  final DateTime occurredAt;
  final String note;
  final String? place;
  final List<String> tags;
  final List<Attachment> attachments;

  /// The amount as it affects "my money": expenses negative, income
  /// positive, adjustments as stored, transfers unsigned (they net to zero).
  Money get signedAmount => switch (type) {
    TransactionType.expense => -amount,
    _ => amount,
  };

  /// Pre-fills an edit with exactly the stored values — the date included
  /// (spec complaint #7: editing must never reset the date).
  EntryDraft toDraft() => EntryDraft(
    type: type,
    amount: amount.abs(),
    accountId: accountId,
    toAccountId: toAccountId,
    toAmount: toAmount,
    fxRateMicros: fxRateMicros,
    categoryId: categoryId,
    personId: personId,
    occurredAt: occurredAt,
    note: note,
    place: place,
    tags: tags,
    keptAttachments: attachments,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    amount,
    accountId,
    toAccountId,
    toAmount,
    fxRateMicros,
    categoryId,
    personId,
    occurredAt,
    note,
    place,
    tags,
    attachments,
  ];
}

/// Everything needed to create or edit an entry.
class EntryDraft extends Equatable {
  const EntryDraft({
    required this.type,
    required this.amount,
    required this.occurredAt,
    this.accountId,
    this.toAccountId,
    this.toAmount,
    this.fxRateMicros,
    this.categoryId,
    this.personId,
    this.note = '',
    this.place,
    this.tags = const [],
    this.keptAttachments = const [],
    this.newReceiptPaths = const [],
  });

  final TransactionType type;
  final Money amount;
  final DateTime occurredAt;
  final String? accountId;
  final String? toAccountId;
  final Money? toAmount;
  final int? fxRateMicros;
  final String? categoryId;
  final String? personId;
  final String note;
  final String? place;
  final List<String> tags;

  /// Existing receipts to keep; any others on the entry are removed.
  final List<Attachment> keptAttachments;

  /// Picked image files to compress and attach.
  final List<String> newReceiptPaths;

  bool get isTransfer => type == TransactionType.transfer;

  @override
  List<Object?> get props => [
    type,
    amount,
    occurredAt,
    accountId,
    toAccountId,
    toAmount,
    fxRateMicros,
    categoryId,
    personId,
    note,
    place,
    tags,
    keptAttachments,
    newReceiptPaths,
  ];
}

/// Why [draft] cannot be saved, given its resolved accounts; null if valid.
EntryProblem? validateEntry(EntryDraft draft, {Account? from, Account? to}) {
  if (!draft.amount.isPositive) return EntryProblem.amountRequired;
  if (from == null) return EntryProblem.accountRequired;
  if (!draft.isTransfer) return null;
  if (to == null) return EntryProblem.destinationRequired;
  if (to.id == from.id) return EntryProblem.sameAccount;
  if (to.currency != from.currency &&
      (draft.toAmount == null || !draft.toAmount!.isPositive)) {
    return EntryProblem.conversionRequired;
  }
  return null;
}

/// An entry with the names needed to show it in a list.
class EntryView extends Equatable {
  const EntryView({
    required this.entry,
    required this.accountName,
    required this.accountCurrency,
    this.toAccountName,
    this.category,
  });

  final LedgerEntry entry;
  final String accountName;
  final Currency accountCurrency;
  final String? toAccountName;
  final Category? category;

  @override
  List<Object?> get props => [
    entry,
    accountName,
    accountCurrency,
    toAccountName,
    category,
  ];
}

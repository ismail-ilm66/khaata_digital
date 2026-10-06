import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/money/amount_buffer.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../accounts/domain/account.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_kind.dart';
import '../../../settings/domain/setting_key.dart';
import '../../../settings/domain/settings_repository.dart';
import '../../domain/ledger_entry.dart';
import '../../domain/transaction_type.dart';
import '../../domain/transactions_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────

sealed class TransactionFormEvent {
  const TransactionFormEvent();
}

/// Opens the form empty, or pre-filled from entry [editId].
final class FormStarted extends TransactionFormEvent {
  const FormStarted({this.editId, this.type = TransactionType.expense});
  final String? editId;
  final TransactionType type;
}

final class TypeChanged extends TransactionFormEvent {
  const TypeChanged(this.type);
  final TransactionType type;
}

final class KeyPressed extends TransactionFormEvent {
  const KeyPressed(this.key);
  final KeypadKey key;
}

/// Which amount the keypad types into (cross-currency transfers have two).
final class AmountFocused extends TransactionFormEvent {
  const AmountFocused(this.target);
  final AmountTarget target;
}

final class AccountChanged extends TransactionFormEvent {
  const AccountChanged(this.accountId);
  final String accountId;
}

final class ToAccountChanged extends TransactionFormEvent {
  const ToAccountChanged(this.accountId);
  final String accountId;
}

/// Tapping the selected category again clears it.
final class CategoryTapped extends TransactionFormEvent {
  const CategoryTapped(this.categoryId);
  final String categoryId;
}

final class DateChanged extends TransactionFormEvent {
  const DateChanged(this.local);
  final DateTime local;
}

final class NoteChanged extends TransactionFormEvent {
  const NoteChanged(this.note);
  final String note;
}

/// Comma-separated tags as typed.
final class TagsChanged extends TransactionFormEvent {
  const TagsChanged(this.raw);
  final String raw;
}

final class ReceiptAdded extends TransactionFormEvent {
  const ReceiptAdded(this.path);
  final String path;
}

final class ReceiptRemoved extends TransactionFormEvent {
  const ReceiptRemoved({this.attachment, this.path});
  final Attachment? attachment;
  final String? path;
}

/// Transfers: swap the source and destination accounts.
final class AccountsSwapped extends TransactionFormEvent {
  const AccountsSwapped();
}

final class FormSubmitted extends TransactionFormEvent {
  const FormSubmitted();
}

// ── State ─────────────────────────────────────────────────────────────────

enum AmountTarget { amount, toAmount }

enum FormStatus { loading, ready, saving, saved, failed }

class TransactionFormState extends Equatable {
  const TransactionFormState({
    this.status = FormStatus.loading,
    this.editingId,
    this.type = TransactionType.expense,
    this.amount = const AmountBuffer(),
    this.toAmount = const AmountBuffer(),
    this.focus = AmountTarget.amount,
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.personId,
    this.place,
    required this.occurredAt,
    this.note = '',
    this.tags = const [],
    this.keptAttachments = const [],
    this.newReceiptPaths = const [],
    this.accounts = const [],
    this.categories = const [],
    this.frequentCategoryIds = const [],
    this.problem,
  });

  final FormStatus status;
  final String? editingId;
  final TransactionType type;
  final AmountBuffer amount;

  /// Cross-currency transfers: what the destination receives.
  final AmountBuffer toAmount;
  final AmountTarget focus;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;

  /// Carried through edits untouched (People arrive in M3).
  final String? personId;
  final String? place;

  /// Local time.
  final DateTime occurredAt;
  final String note;
  final List<String> tags;
  final List<Attachment> keptAttachments;
  final List<String> newReceiptPaths;

  /// Accounts to choose from (active, plus the edited entry's own).
  final List<Account> accounts;

  /// All active categories; [visibleCategories] filters by type.
  final List<Category> categories;

  /// Most-used category ids first (from history), for [quickCategories].
  final List<String> frequentCategoryIds;
  final EntryProblem? problem;

  bool get isEditing => editingId != null;
  bool get isTransfer => type == TransactionType.transfer;

  Account? _find(String? id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Account? get account => _find(accountId);
  Account? get toAccount => _find(toAccountId);
  Currency get currency => account?.currency ?? Currency.pkr;
  Currency get toCurrency => toAccount?.currency ?? currency;

  bool get crossCurrency =>
      isTransfer && toAccount != null && toAccount!.currency != currency;

  Money get money => amount.toMoney(currency);
  Money get toMoney => toAmount.toMoney(toCurrency);

  /// Derived rate (destination units per source unit, micros), shown under
  /// a cross-currency transfer; null until both amounts are typed.
  int? get rateMicros {
    if (!crossCurrency || !money.isPositive || !toMoney.isPositive) return null;
    final scale = BigInt.from(
      10,
    ).pow(6 + currency.decimals - toCurrency.decimals);
    final r = BigInt.from(toMoney.minor) * scale ~/ BigInt.from(money.minor);
    return r.toInt();
  }

  List<Category> get visibleCategories {
    final kind = type == TransactionType.income
        ? CategoryKind.income
        : CategoryKind.expense;
    return [
      for (final c in categories)
        if (c.kind == kind) c,
    ];
  }

  /// Fits one row on every phone alongside "All" — no hidden overflow.
  static const int quickCount = 4;

  /// The one-tap row: most-used categories of this type, topped up in
  /// seed order. A selection made from "All" is always shown, first.
  List<Category> get quickCategories {
    final visible = visibleCategories;
    final byId = {for (final c in visible) c.id: c};
    final ordered = <Category>{
      for (final id in frequentCategoryIds)
        if (byId[id] != null) byId[id]!,
      ...visible,
    }.take(quickCount).toList();
    final selected = byId[categoryId];
    if (selected == null || ordered.contains(selected)) return ordered;
    return [selected, ...ordered.take(quickCount - 1)];
  }

  Category? get selectedCategory =>
      visibleCategories.where((c) => c.id == categoryId).firstOrNull;

  int get receiptCount => keptAttachments.length + newReceiptPaths.length;

  bool get canSave =>
      status == FormStatus.ready && money.isPositive && account != null;

  EntryDraft toDraft() => EntryDraft(
    type: type,
    amount: money,
    accountId: accountId,
    toAccountId: isTransfer ? toAccountId : null,
    toAmount: crossCurrency ? toMoney : null,
    fxRateMicros: crossCurrency ? rateMicros : null,
    categoryId: isTransfer ? null : categoryId,
    personId: personId,
    place: place,
    occurredAt: occurredAt.toUtc(),
    note: note,
    tags: tags,
    keptAttachments: keptAttachments,
    newReceiptPaths: newReceiptPaths,
  );

  TransactionFormState copyWith({
    FormStatus? status,
    String? editingId,
    TransactionType? type,
    AmountBuffer? amount,
    AmountBuffer? toAmount,
    AmountTarget? focus,
    String? accountId,
    String? Function()? toAccountId,
    String? Function()? categoryId,
    String? personId,
    String? place,
    DateTime? occurredAt,
    String? note,
    List<String>? tags,
    List<Attachment>? keptAttachments,
    List<String>? newReceiptPaths,
    List<Account>? accounts,
    List<Category>? categories,
    List<String>? frequentCategoryIds,
    EntryProblem? Function()? problem,
  }) => TransactionFormState(
    status: status ?? this.status,
    editingId: editingId ?? this.editingId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    toAmount: toAmount ?? this.toAmount,
    focus: focus ?? this.focus,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId != null ? toAccountId() : this.toAccountId,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
    personId: personId ?? this.personId,
    place: place ?? this.place,
    occurredAt: occurredAt ?? this.occurredAt,
    note: note ?? this.note,
    tags: tags ?? this.tags,
    keptAttachments: keptAttachments ?? this.keptAttachments,
    newReceiptPaths: newReceiptPaths ?? this.newReceiptPaths,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    frequentCategoryIds: frequentCategoryIds ?? this.frequentCategoryIds,
    problem: problem != null ? problem() : this.problem,
  );

  @override
  List<Object?> get props => [
    status,
    editingId,
    type,
    amount,
    toAmount,
    focus,
    accountId,
    toAccountId,
    categoryId,
    personId,
    place,
    occurredAt,
    note,
    tags,
    keptAttachments,
    newReceiptPaths,
    accounts,
    categories,
    frequentCategoryIds,
    problem,
  ];
}

// ── Bloc ──────────────────────────────────────────────────────────────────

/// Drives the Add / Edit transaction sheet (spec 3.2 #3).
@injectable
class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  TransactionFormBloc(
    this._transactions,
    this._accounts,
    this._categories,
    this._settings,
  ) : super(TransactionFormState(occurredAt: DateTime.now())) {
    on<FormStarted>(_onStarted);
    on<TypeChanged>(_onType);
    on<KeyPressed>(_onKey);
    on<AmountFocused>((e, emit) => emit(state.copyWith(focus: e.target)));
    on<AccountChanged>(_onAccount);
    on<ToAccountChanged>(
      (e, emit) => emit(
        state.copyWith(toAccountId: () => e.accountId, problem: () => null),
      ),
    );
    on<CategoryTapped>(
      (e, emit) => emit(
        state.copyWith(
          categoryId: () =>
              state.categoryId == e.categoryId ? null : e.categoryId,
        ),
      ),
    );
    on<DateChanged>((e, emit) => emit(state.copyWith(occurredAt: e.local)));
    on<NoteChanged>((e, emit) => emit(state.copyWith(note: e.note)));
    on<TagsChanged>((e, emit) => emit(state.copyWith(tags: parseTags(e.raw))));
    on<ReceiptAdded>(
      (e, emit) => emit(
        state.copyWith(newReceiptPaths: [...state.newReceiptPaths, e.path]),
      ),
    );
    on<ReceiptRemoved>(_onReceiptRemoved);
    on<AccountsSwapped>(_onSwap);
    on<FormSubmitted>(_onSubmit);
  }

  final TransactionsRepository _transactions;
  final AccountsRepository _accounts;
  final CategoriesRepository _categories;
  final SettingsRepository _settings;

  /// Splits "office, lunch,  Office" → ["office", "lunch"] (case-insensitive
  /// de-dupe, order kept).
  static List<String> parseTags(String raw) {
    final seen = <String>{};
    return [
      for (final t in raw.split(','))
        if (t.trim().isNotEmpty && seen.add(t.trim().toLowerCase())) t.trim(),
    ];
  }

  Future<void> _onStarted(
    FormStarted e,
    Emitter<TransactionFormState> emit,
  ) async {
    final accounts = [
      for (final s in (await _accounts.watchOverview().first).accounts)
        s.account,
    ];
    final categories = await _categories.all();
    final frequent = await _transactions.frequentCategoryIds(limit: 12);

    if (e.editId case final id?) {
      final entry = await _transactions.byId(id);
      if (entry == null) {
        emit(state.copyWith(status: FormStatus.failed));
        return;
      }
      // An archived account still shows on its old entries.
      for (final needed in [entry.accountId, entry.toAccountId]) {
        if (needed != null && !accounts.any((a) => a.id == needed)) {
          final a = await _accounts.byId(needed);
          if (a != null) accounts.add(a);
        }
      }
      emit(
        TransactionFormState(
          status: FormStatus.ready,
          editingId: id,
          type: entry.type,
          amount: AmountBuffer.fromMoney(entry.amount),
          toAmount: entry.toAmount == null
              ? const AmountBuffer()
              : AmountBuffer.fromMoney(entry.toAmount!),
          accountId: entry.accountId,
          toAccountId: entry.toAccountId,
          categoryId: entry.categoryId,
          personId: entry.personId,
          place: entry.place,
          occurredAt: entry.occurredAt.toLocal(),
          note: entry.note,
          tags: entry.tags,
          keptAttachments: entry.attachments,
          accounts: accounts,
          categories: categories,
          frequentCategoryIds: frequent,
        ),
      );
      return;
    }

    final last = await _settings.read(SettingKey.lastAccountId);
    final account =
        accounts.where((a) => a.id == last).firstOrNull ?? accounts.firstOrNull;
    final base = TransactionFormState(
      status: FormStatus.ready,
      accountId: account?.id,
      occurredAt: DateTime.now(),
      accounts: accounts,
      categories: categories,
      frequentCategoryIds: frequent,
    );
    emit(e.type == TransactionType.expense ? base : _withType(base, e.type));
  }

  void _onType(TypeChanged e, Emitter<TransactionFormState> emit) =>
      emit(_withType(state, e.type));

  /// Switching type drops a category of the wrong kind and, for transfers,
  /// picks a destination different from the source.
  TransactionFormState _withType(TransactionFormState s, TransactionType type) {
    var next = s.copyWith(
      type: type,
      focus: AmountTarget.amount,
      problem: () => null,
    );
    final selected = next.categories
        .where((c) => c.id == next.categoryId)
        .firstOrNull;
    if (selected != null && !next.visibleCategories.contains(selected)) {
      next = next.copyWith(categoryId: () => null);
    }
    if (type == TransactionType.transfer &&
        (next.toAccountId == null || next.toAccountId == next.accountId)) {
      final other = next.accounts
          .where((a) => a.id != next.accountId)
          .firstOrNull;
      next = next.copyWith(toAccountId: () => other?.id);
    }
    return next;
  }

  void _onKey(KeyPressed e, Emitter<TransactionFormState> emit) {
    if (state.focus == AmountTarget.toAmount && state.crossCurrency) {
      emit(
        state.copyWith(toAmount: state.toAmount.apply(e.key, state.toCurrency)),
      );
    } else {
      emit(
        state.copyWith(
          amount: state.amount.apply(e.key, state.currency),
          problem: () => null,
        ),
      );
    }
  }

  void _onAccount(AccountChanged e, Emitter<TransactionFormState> emit) {
    final account = state.accounts.firstWhere((a) => a.id == e.accountId);
    // Re-validate the typed text against the new currency's decimals.
    final retyped = Money.parse(
      state.amount.text.isEmpty ? '0' : state.amount.text,
      account.currency,
    );
    emit(
      state.copyWith(
        accountId: e.accountId,
        amount: retyped == null ? const AmountBuffer() : state.amount,
        toAccountId: state.toAccountId == e.accountId ? () => null : null,
        problem: () => null,
      ),
    );
  }

  void _onSwap(AccountsSwapped e, Emitter<TransactionFormState> emit) {
    final to = state.toAccountId;
    if (to == null) return;
    // The typed amount only survives if it's still in the right currency.
    final keep = !state.crossCurrency;
    emit(
      state.copyWith(
        accountId: to,
        toAccountId: () => state.accountId,
        amount: keep ? null : const AmountBuffer(),
        toAmount: const AmountBuffer(),
        focus: AmountTarget.amount,
        problem: () => null,
      ),
    );
  }

  void _onReceiptRemoved(ReceiptRemoved e, Emitter<TransactionFormState> emit) {
    emit(
      state.copyWith(
        keptAttachments: [
          for (final a in state.keptAttachments)
            if (a != e.attachment) a,
        ],
        newReceiptPaths: [
          for (final p in state.newReceiptPaths)
            if (p != e.path) p,
        ],
      ),
    );
  }

  Future<void> _onSubmit(
    FormSubmitted e,
    Emitter<TransactionFormState> emit,
  ) async {
    if (state.status == FormStatus.saving) return;
    emit(state.copyWith(status: FormStatus.saving, problem: () => null));
    try {
      await _transactions.save(state.toDraft(), id: state.editingId);
      if (state.accountId case final id?) {
        await _settings.write(SettingKey.lastAccountId, id);
      }
      emit(state.copyWith(status: FormStatus.saved));
    } on ValidationFailure catch (f) {
      emit(state.copyWith(status: FormStatus.ready, problem: () => f.problem));
    } on StorageFailure {
      // Signal the failure (the sheet shows a message), then allow a retry.
      emit(state.copyWith(status: FormStatus.failed));
      emit(state.copyWith(status: FormStatus.ready));
    }
  }
}

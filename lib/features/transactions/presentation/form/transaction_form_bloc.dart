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
import '../../../people/domain/person.dart';
import '../../../recurring/domain/recurrence.dart';
import '../../../recurring/domain/recurring_rule.dart';
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
  const FormStarted({
    this.editId,
    this.type = TransactionType.expense,
    this.udhaar,
    this.personId,
    this.amount,
  });
  final String? editId;
  final TransactionType type;

  /// Opens in udhaar mode in this direction (People screen actions).
  final UdhaarDirection? udhaar;
  final String? personId;

  /// Pre-filled amount (e.g. "Settle up").
  final Money? amount;
}

/// Switches to udhaar mode (money given to / received from a person).
final class UdhaarChosen extends TransactionFormEvent {
  const UdhaarChosen();
}

final class UdhaarDirectionChanged extends TransactionFormEvent {
  const UdhaarDirectionChanged(this.direction);
  final UdhaarDirection direction;
}

/// A person created from the editor: add to the list and select them.
final class PersonAdded extends TransactionFormEvent {
  const PersonAdded(this.person);
  final Person person;
}

final class PersonChanged extends TransactionFormEvent {
  const PersonChanged(this.personId);
  final String personId;
}

/// New entries only: repeat at [frequency] (null = once), optionally with
/// a bill reminder.
final class RepeatChanged extends TransactionFormEvent {
  const RepeatChanged(this.frequency, {this.remind = false});
  final RecurrenceFrequency? frequency;
  final bool remind;
}

final class TypeChanged extends TransactionFormEvent {
  const TypeChanged(this.type);
  final TransactionType type;
}

/// Text typed into an amount field (grouping commas allowed). Text that
/// isn't a valid amount for the currency is ignored.
final class AmountTyped extends TransactionFormEvent {
  const AmountTyped(this.text, {this.target = AmountTarget.amount});
  final String text;
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
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.personId,
    this.place,
    required this.occurredAt,
    this.note = '',
    this.tags = const [],
    this.events = const [],
    this.keptAttachments = const [],
    this.newReceiptPaths = const [],
    this.accounts = const [],
    this.categories = const [],
    this.frequentCategoryIds = const [],
    this.frequentAccountIds = const [],
    this.homeCurrency = Currency.pkr,
    this.isUdhaar = false,
    this.people = const [],
    this.repeat,
    this.remind = false,
    this.problem,
  });

  final FormStatus status;
  final String? editingId;
  final TransactionType type;
  final AmountBuffer amount;

  /// Cross-currency transfers: what the destination receives.
  final AmountBuffer toAmount;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;

  /// The person in udhaar mode.
  final String? personId;
  final String? place;

  /// Local time.
  final DateTime occurredAt;
  final String note;
  final List<String> tags;

  /// Carried through edits untouched (no events UI; set by imports).
  final List<String> events;
  final List<Attachment> keptAttachments;
  final List<String> newReceiptPaths;

  /// Accounts to choose from (active, plus the edited entry's own).
  final List<Account> accounts;

  /// All active categories; [visibleCategories] filters by type.
  final List<Category> categories;

  /// Most-used category ids first (from history), for [quickCategories].
  final List<String> frequentCategoryIds;

  /// Most-used account ids first, for [accountsByUse].
  final List<String> frequentAccountIds;

  /// Shown on the amount until an account is chosen.
  final Currency homeCurrency;

  /// Udhaar mode: [type] is expense ("I gave") or income ("I received")
  /// and the entry is linked to [personId], with no category.
  final bool isUdhaar;
  final List<Person> people;

  /// New entries: repeat at this frequency (null = once).
  final RecurrenceFrequency? repeat;
  final bool remind;
  final EntryProblem? problem;

  bool get isEditing => editingId != null;
  bool get isTransfer => type == TransactionType.transfer;
  UdhaarDirection get udhaarDirection => UdhaarDirection.of(type);
  Person? get person => people.where((p) => p.id == personId).firstOrNull;

  Account? _find(String? id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Account? get account => _find(accountId);
  Account? get toAccount => _find(toAccountId);
  Currency get currency => account?.currency ?? homeCurrency;
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

  /// Most-used first; never-used ones keep their usual order after.
  static List<T> _byUse<T>(
    List<T> items,
    String Function(T) id,
    List<String> ids,
  ) {
    final rank = {for (final (i, x) in ids.indexed) x: i};
    final unused = ids.length;
    return [
      ...items,
    ]..sort((a, b) => (rank[id(a)] ?? unused).compareTo(rank[id(b)] ?? unused));
  }

  List<Account> get accountsByUse =>
      _byUse(accounts, (a) => a.id, frequentAccountIds);

  /// The full category list (the "All" grid), most-used first.
  List<Category> get categoriesByUse =>
      _byUse(visibleCategories, (c) => c.id, frequentCategoryIds);

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

  /// What's missing before saving, checked when Save is tapped (the
  /// amount instead keeps Save disabled until it's typed).
  EntryProblem? get missing {
    if (account == null) return EntryProblem.accountRequired;
    if (isUdhaar && personId == null) return EntryProblem.personRequired;
    if (!isTransfer && !isUdhaar && selectedCategory == null) {
      return EntryProblem.categoryRequired;
    }
    return null;
  }

  bool get canSave => status == FormStatus.ready && money.isPositive;

  EntryDraft toDraft() => EntryDraft(
    type: type,
    amount: money,
    accountId: accountId,
    toAccountId: isTransfer ? toAccountId : null,
    toAmount: crossCurrency ? toMoney : null,
    fxRateMicros: crossCurrency ? rateMicros : null,
    categoryId: isTransfer || isUdhaar ? null : categoryId,
    personId: isUdhaar ? personId : null,
    place: place,
    occurredAt: occurredAt.toUtc(),
    note: note.trim(),
    tags: tags,
    events: events,
    keptAttachments: keptAttachments,
    newReceiptPaths: newReceiptPaths,
  );

  TransactionFormState copyWith({
    FormStatus? status,
    String? editingId,
    TransactionType? type,
    AmountBuffer? amount,
    AmountBuffer? toAmount,
    String? accountId,
    String? Function()? toAccountId,
    String? Function()? categoryId,
    String? Function()? personId,
    String? place,
    DateTime? occurredAt,
    String? note,
    List<String>? tags,
    List<Attachment>? keptAttachments,
    List<String>? newReceiptPaths,
    List<Account>? accounts,
    List<Category>? categories,
    List<String>? frequentCategoryIds,
    List<String>? frequentAccountIds,
    Currency? homeCurrency,
    bool? isUdhaar,
    List<Person>? people,
    RecurrenceFrequency? Function()? repeat,
    bool? remind,
    EntryProblem? Function()? problem,
  }) => TransactionFormState(
    status: status ?? this.status,
    editingId: editingId ?? this.editingId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    toAmount: toAmount ?? this.toAmount,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId != null ? toAccountId() : this.toAccountId,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
    personId: personId != null ? personId() : this.personId,
    place: place ?? this.place,
    occurredAt: occurredAt ?? this.occurredAt,
    note: note ?? this.note,
    tags: tags ?? this.tags,
    events: events,
    keptAttachments: keptAttachments ?? this.keptAttachments,
    newReceiptPaths: newReceiptPaths ?? this.newReceiptPaths,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    frequentCategoryIds: frequentCategoryIds ?? this.frequentCategoryIds,
    frequentAccountIds: frequentAccountIds ?? this.frequentAccountIds,
    homeCurrency: homeCurrency ?? this.homeCurrency,
    isUdhaar: isUdhaar ?? this.isUdhaar,
    people: people ?? this.people,
    repeat: repeat != null ? repeat() : this.repeat,
    remind: remind ?? this.remind,
    problem: problem != null ? problem() : this.problem,
  );

  @override
  List<Object?> get props => [
    status,
    editingId,
    type,
    amount,
    toAmount,
    accountId,
    toAccountId,
    categoryId,
    personId,
    place,
    occurredAt,
    note,
    tags,
    events,
    keptAttachments,
    newReceiptPaths,
    accounts,
    categories,
    frequentCategoryIds,
    frequentAccountIds,
    homeCurrency,
    isUdhaar,
    people,
    repeat,
    remind,
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
    this._people,
    this._recurring,
    this._reminders,
  ) : super(TransactionFormState(occurredAt: DateTime.now())) {
    on<FormStarted>(_onStarted);
    on<TypeChanged>(_onType);
    on<AmountTyped>(_onAmount);
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
          problem: () => null,
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
    on<UdhaarChosen>(_onUdhaar);
    on<UdhaarDirectionChanged>(
      (e, emit) =>
          emit(state.copyWith(type: e.direction.type, problem: () => null)),
    );
    on<PersonChanged>(
      (e, emit) =>
          emit(state.copyWith(personId: () => e.personId, problem: () => null)),
    );
    on<PersonAdded>(
      (e, emit) => emit(
        state.copyWith(
          people: [...state.people, e.person],
          personId: () => e.person.id,
          problem: () => null,
        ),
      ),
    );
    on<RepeatChanged>(
      (e, emit) =>
          emit(state.copyWith(repeat: () => e.frequency, remind: e.remind)),
    );
    on<FormSubmitted>(_onSubmit);
  }

  final TransactionsRepository _transactions;
  final AccountsRepository _accounts;
  final CategoriesRepository _categories;
  final SettingsRepository _settings;
  final PeopleRepository _people;
  final RecurringRepository _recurring;
  final ReminderScheduler _reminders;

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
    final frequent = await _transactions.frequentCategoryIds(limit: 200);
    final frequentAccounts = await _transactions.frequentAccountIds();
    final home = Currency.of(await _settings.read(SettingKey.currencyCode));
    final people = [
      for (final p in (await _people.watchOverview().first).people) p.person,
    ];

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
          events: entry.events,
          keptAttachments: entry.attachments,
          accounts: accounts,
          categories: categories,
          frequentCategoryIds: frequent,
          frequentAccountIds: frequentAccounts,
          homeCurrency: home,
          isUdhaar: entry.personId != null,
          people: people,
        ),
      );
      return;
    }

    // Nothing is pre-chosen: the account is picked each time, on purpose.
    final base = TransactionFormState(
      status: FormStatus.ready,
      occurredAt: DateTime.now(),
      accounts: accounts,
      categories: categories,
      frequentCategoryIds: frequent,
      frequentAccountIds: frequentAccounts,
      homeCurrency: home,
      people: people,
    );
    if (e.udhaar != null || e.personId != null) {
      final direction = e.udhaar ?? UdhaarDirection.gave;
      emit(
        base.copyWith(
          isUdhaar: true,
          type: direction.type,
          personId: () => e.personId,
          amount: e.amount == null ? null : AmountBuffer.fromMoney(e.amount!),
        ),
      );
      return;
    }
    emit(e.type == TransactionType.expense ? base : _withType(base, e.type));
  }

  void _onType(TypeChanged e, Emitter<TransactionFormState> emit) => emit(
    _withType(state.copyWith(isUdhaar: false, personId: () => null), e.type),
  );

  void _onUdhaar(UdhaarChosen e, Emitter<TransactionFormState> emit) => emit(
    state.copyWith(
      isUdhaar: true,
      type: TransactionType.expense,
      categoryId: () => null,
      toAccountId: () => null,
      toAmount: const AmountBuffer(),
      problem: () => null,
    ),
  );

  /// Switching type drops a category of the wrong kind and, for transfers,
  /// a destination that is the same as the source.
  TransactionFormState _withType(TransactionFormState s, TransactionType type) {
    var next = s.copyWith(type: type, problem: () => null);
    final selected = next.categories
        .where((c) => c.id == next.categoryId)
        .firstOrNull;
    if (selected != null && !next.visibleCategories.contains(selected)) {
      next = next.copyWith(categoryId: () => null);
    }
    if (type == TransactionType.transfer &&
        next.toAccountId != null &&
        next.toAccountId == next.accountId) {
      next = next.copyWith(toAccountId: () => null);
    }
    return next;
  }

  void _onAmount(AmountTyped e, Emitter<TransactionFormState> emit) {
    if (e.target == AmountTarget.toAmount) {
      if (!state.crossCurrency) return;
      final typed = AmountBuffer.typed(e.text, state.toCurrency);
      if (typed != null) emit(state.copyWith(toAmount: typed));
      return;
    }
    final typed = AmountBuffer.typed(e.text, state.currency);
    if (typed != null) {
      emit(state.copyWith(amount: typed, problem: () => null));
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
        // Picking the destination as the source swaps the two.
        toAccountId: state.toAccountId == e.accountId
            ? () => state.accountId
            : null,
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
    if (state.missing case final problem?) {
      emit(state.copyWith(problem: () => problem));
      return;
    }
    emit(state.copyWith(status: FormStatus.saving, problem: () => null));
    try {
      final draft = state.toDraft();
      await _transactions.save(draft, id: state.editingId);
      if (state.repeat case final frequency? when !state.isEditing) {
        await _recurring.create(draft, frequency, remind: state.remind);
        try {
          await _reminders.sync(await _recurring.active());
        } catch (_) {
          // Reminders are best-effort; the entry and rule are saved.
        }
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

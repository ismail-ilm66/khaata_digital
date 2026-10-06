import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../domain/account.dart';
import '../domain/account_presets.dart';
import '../domain/account_type.dart';

enum AccountFormStatus { editing, saving, saved, archived }

class AccountFormState extends Equatable {
  const AccountFormState({
    required this.draft,
    this.editingId,
    this.status = AccountFormStatus.editing,
    this.duplicateName = false,
  });

  final AccountDraft draft;
  final String? editingId;
  final AccountFormStatus status;

  /// The name collides with another active account.
  final bool duplicateName;

  bool get isEditing => editingId != null;

  AccountFormState copyWith({
    AccountDraft? draft,
    AccountFormStatus? status,
    bool? duplicateName,
  }) => AccountFormState(
    draft: draft ?? this.draft,
    editingId: editingId,
    status: status ?? this.status,
    duplicateName: duplicateName ?? this.duplicateName,
  );

  @override
  List<Object?> get props => [draft, editingId, status, duplicateName];
}

/// Create (from a preset or blank) and edit an account.
@injectable
class AccountFormCubit extends Cubit<AccountFormState> {
  AccountFormCubit(this._repo)
    : super(
        const AccountFormState(
          draft: AccountDraft(
            name: '',
            type: AccountType.cash,
            currency: Currency.pkr,
            openingBalance: Money.zero(Currency.pkr),
          ),
        ),
      );

  final AccountsRepository _repo;

  /// A new account, pre-filled from [preset] when chosen in the picker.
  void startNew({AccountPreset? preset, required Currency currency}) {
    emit(
      AccountFormState(
        draft: AccountDraft(
          name: preset?.name ?? '',
          type: preset?.type ?? AccountType.cash,
          currency: currency,
          openingBalance: Money.zero(currency),
          iconKey: preset?.key,
          color: preset?.color,
        ),
      ),
    );
  }

  void startEdit(Account account) =>
      emit(AccountFormState(draft: account.toDraft(), editingId: account.id));

  void update(AccountDraft draft) =>
      emit(state.copyWith(draft: draft, duplicateName: false));

  Future<void> save() async {
    if (state.draft.name.trim().isEmpty) return;
    emit(state.copyWith(status: AccountFormStatus.saving));
    try {
      if (state.editingId case final id?) {
        await _repo.update(id, state.draft);
      } else {
        await _repo.create(state.draft);
      }
      emit(state.copyWith(status: AccountFormStatus.saved));
    } on DuplicateNameFailure {
      emit(
        state.copyWith(status: AccountFormStatus.editing, duplicateName: true),
      );
    }
  }

  Future<void> archive() async {
    final id = state.editingId;
    if (id == null) return;
    await _repo.archive(id);
    emit(state.copyWith(status: AccountFormStatus.archived));
  }
}

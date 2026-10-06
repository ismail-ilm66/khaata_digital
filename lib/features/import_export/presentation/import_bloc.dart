import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/files/file_gateway.dart';
import '../../accounts/domain/account.dart';
import '../../backup/data/backup_service.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../data/csv_mapper.dart';
import '../data/import_service.dart';
import '../data/spreadsheet_codec.dart';
import '../domain/import_plan.dart';

sealed class ImportEvent {
  const ImportEvent();
}

class ImportFileChosen extends ImportEvent {
  const ImportFileChosen(this.file);
  final PickedFile file;
}

class ImportMappingChanged extends ImportEvent {
  const ImportMappingChanged(this.mapping);
  final CsvMapping mapping;
}

class ImportMappingConfirmed extends ImportEvent {
  const ImportMappingConfirmed();
}

class ImportRoleChanged extends ImportEvent {
  const ImportRoleChanged(this.name, this.role);
  final String name;
  final ImportRole role;
}

class ImportConfirmed extends ImportEvent {
  const ImportConfirmed();
}

class ImportRestarted extends ImportEvent {
  const ImportRestarted();
}

enum ImportStep { pick, reading, mapping, preview, running, report }

enum ImportProblem { unreadable, empty, failed }

class ImportState extends Equatable {
  const ImportState({
    this.step = ImportStep.pick,
    this.fileName = '',
    this.rows = const [],
    this.mapping,
    this.accounts = const [],
    this.draft,
    this.report,
    this.problem,
  });

  final ImportStep step;
  final String fileName;

  /// The table being mapped (generic CSV only).
  final List<List<String>> rows;
  final CsvMapping? mapping;

  /// Existing account names, for the mapper's default account.
  final List<String> accounts;
  final ImportDraft? draft;
  final ImportReport? report;
  final ImportProblem? problem;

  ImportState copyWith({
    ImportStep? step,
    String? fileName,
    List<List<String>>? rows,
    CsvMapping? mapping,
    List<String>? accounts,
    ImportDraft? draft,
    ImportReport? report,
    ImportProblem? Function()? problem,
  }) => ImportState(
    step: step ?? this.step,
    fileName: fileName ?? this.fileName,
    rows: rows ?? this.rows,
    mapping: mapping ?? this.mapping,
    accounts: accounts ?? this.accounts,
    draft: draft ?? this.draft,
    report: report ?? this.report,
    problem: problem == null ? this.problem : problem(),
  );

  @override
  List<Object?> get props => [
    step,
    fileName,
    rows,
    mapping,
    accounts,
    draft,
    report,
    problem,
  ];
}

/// Import flow (spec 3.2 #10, 3.3): pick → (map columns) → preview with
/// account / person roles → automatic safety backup → import → report.
@injectable
class ImportBloc extends Bloc<ImportEvent, ImportState> {
  ImportBloc(this._import, this._backups, this._currency, this._accounts)
    : super(const ImportState()) {
    on<ImportFileChosen>(_onFile);
    on<ImportMappingChanged>(
      (e, emit) => emit(state.copyWith(mapping: e.mapping)),
    );
    on<ImportMappingConfirmed>(_onMapped);
    on<ImportRoleChanged>(_onRole);
    on<ImportConfirmed>(_onConfirmed);
    on<ImportRestarted>((e, emit) => emit(const ImportState()));
  }

  final ImportService _import;
  final BackupService _backups;
  final CurrencyCubit _currency;
  final AccountsRepository _accounts;

  Future<void> _onFile(ImportFileChosen e, Emitter<ImportState> emit) async {
    emit(ImportState(step: ImportStep.reading, fileName: e.file.name));
    try {
      final sheets = await _import.decode(e.file.bytes);
      final rows = SpreadsheetCodec.activities(sheets);
      if (ImportService.isHysabKytab(rows)) {
        final draft = await _import.draftFile(
          sheets,
          currency: _currency.state,
        );
        _preview(draft, emit);
        return;
      }
      if (rows.length < 2) throw const FormatException('empty');
      final names = [
        for (final a in (await _accounts.watchOverview().first).accounts)
          a.account.name,
      ];
      final guess =
          CsvMapper.guess(rows.first) ?? const CsvMapping(date: 0, amount: 1);
      emit(
        state.copyWith(
          step: ImportStep.mapping,
          rows: rows,
          accounts: names,
          mapping: guess.copyWith(
            defaultAccount: names.isEmpty ? 'Cash' : names.first,
          ),
        ),
      );
    } on FormatException catch (f) {
      emit(
        state.copyWith(
          step: ImportStep.pick,
          problem: () => f.message == 'empty'
              ? ImportProblem.empty
              : ImportProblem.unreadable,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          step: ImportStep.pick,
          problem: () => ImportProblem.unreadable,
        ),
      );
    }
  }

  void _preview(ImportDraft draft, Emitter<ImportState> emit) {
    if (draft.records.isEmpty) {
      emit(
        state.copyWith(
          step: ImportStep.pick,
          problem: () => ImportProblem.empty,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        step: ImportStep.preview,
        draft: draft,
        problem: () => null,
      ),
    );
  }

  Future<void> _onMapped(
    ImportMappingConfirmed e,
    Emitter<ImportState> emit,
  ) async {
    emit(state.copyWith(step: ImportStep.reading));
    final draft = await _import.draftMapped(
      state.rows,
      state.mapping!,
      currency: _currency.state,
    );
    if (draft.records.isEmpty) {
      emit(
        state.copyWith(
          step: ImportStep.mapping,
          problem: () => ImportProblem.empty,
        ),
      );
      return;
    }
    _preview(draft, emit);
  }

  void _onRole(ImportRoleChanged e, Emitter<ImportState> emit) {
    emit(state.copyWith(draft: state.draft!.withRoles({e.name: e.role})));
  }

  Future<void> _onConfirmed(
    ImportConfirmed e,
    Emitter<ImportState> emit,
  ) async {
    if (state.step != ImportStep.preview) return;
    emit(state.copyWith(step: ImportStep.running));
    try {
      // Automatic pre-import backup (spec 3.3).
      await _backups.saveOnDevice(await _backups.create());
      final report = await _import.run(state.draft!);
      emit(state.copyWith(step: ImportStep.report, report: report));
    } catch (_) {
      emit(
        state.copyWith(
          step: ImportStep.preview,
          problem: () => ImportProblem.failed,
        ),
      );
    }
  }
}

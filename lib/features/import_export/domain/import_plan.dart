import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import 'exchange_record.dart';

/// What a name in the file's "Account Name" column becomes in Kharcha.
/// Hysab Kytab keeps people as accounts and records udhaar as transfers;
/// a name marked [person] turns those transfers into udhaar entries.
enum ImportRole { account, person }

/// One account-or-person name found in the file, with the suggested role.
class ImportName extends Equatable {
  const ImportName({
    required this.name,
    required this.role,
    required this.canBePerson,
    required this.existing,
    required this.entries,
    this.opening,
  });

  final String name;

  /// Suggested role (the user can change it in the preview).
  final ImportRole role;

  /// Only names used purely in transfers may become people; a name with
  /// expenses or income of its own is a real account.
  final bool canBePerson;

  /// Already in Kharcha (matched by name, any case).
  final bool existing;

  /// How many entries in the file touch this name.
  final int entries;

  /// Opening balance from the file's ACCOUNT sheet, if any.
  final Money? opening;

  ImportName withRole(ImportRole r) => ImportName(
    name: name,
    role: r,
    canBePerson: canBePerson,
    existing: existing,
    entries: entries,
    opening: opening,
  );

  @override
  List<Object?> get props => [
    name,
    role,
    canBePerson,
    existing,
    entries,
    opening,
  ];
}

/// Where the rows came from.
enum ImportFormat {
  /// Hysab Kytab's export (or Kharcha's own, which uses the same layout).
  hysabKytab,

  /// Any other CSV, read through a [CsvMapping].
  mapped,
}

/// A parsed file, ready to preview and import. Nothing is written yet.
class ImportDraft extends Equatable {
  const ImportDraft({
    required this.format,
    required this.records,
    required this.lines,
    required this.hashes,
    required this.duplicates,
    required this.warnings,
    required this.names,
    this.first,
    this.last,
  });

  final ImportFormat format;

  /// Every readable record in file order …
  final List<ExchangeRecord> records;

  /// … the file rows each came from …
  final List<List<int>> lines;

  /// … its fingerprint (parallel to [records]) …
  final List<String> hashes;

  /// … and which of them are already in Kharcha (indexes into [records]).
  final Set<int> duplicates;
  final List<ExchangeWarning> warnings;
  final List<ImportName> names;

  /// Date range of the file's records.
  final DateTime? first;
  final DateTime? last;

  int get newCount => records.length - duplicates.length;

  ImportDraft withRoles(Map<String, ImportRole> roles) => ImportDraft(
    format: format,
    records: records,
    lines: lines,
    hashes: hashes,
    duplicates: duplicates,
    warnings: warnings,
    names: [
      for (final n in names)
        roles[n.name] != null && (n.canBePerson || roles[n.name] == n.role)
            ? n.withRole(roles[n.name]!)
            : n,
    ],
    first: first,
    last: last,
  );

  @override
  List<Object?> get props => [
    format,
    records,
    hashes,
    duplicates,
    warnings,
    names,
    first,
    last,
  ];
}

/// Why an otherwise readable record was not imported.
enum ImportSkip {
  /// A transfer between two names both marked as people.
  betweenPeople,

  /// An unpaired transfer row on a person (no account to move).
  personAdjustment,
}

/// The outcome shown on the import report screen (spec 3.3).
class ImportReport extends Equatable {
  const ImportReport({
    required this.imported,
    required this.duplicates,
    required this.warnings,
    required this.skipped,
    required this.accountsCreated,
    required this.peopleCreated,
    required this.categoriesCreated,
  });

  final int imported;
  final int duplicates;

  /// From reading the file (unreadable rows, unpaired transfers).
  final List<ExchangeWarning> warnings;

  /// Readable records Kharcha cannot represent, with their file rows.
  final List<({ImportSkip reason, List<int> lines})> skipped;
  final int accountsCreated;
  final int peopleCreated;
  final int categoriesCreated;

  @override
  List<Object?> get props => [
    imported,
    duplicates,
    warnings,
    skipped,
    accountsCreated,
    peopleCreated,
    categoriesCreated,
  ];
}

/// Day-month order for dates in a generic CSV.
enum DateOrder { dmy, mdy, ymd }

/// Which column holds what, for a CSV not in Hysab Kytab's layout.
/// Indexes are 0-based; null = not in the file.
class CsvMapping extends Equatable {
  const CsvMapping({
    required this.date,
    required this.amount,
    this.type,
    this.account,
    this.category,
    this.note,
    this.tags,
    this.dateOrder = DateOrder.dmy,
    this.defaultAccount = '',
  });

  final int date;
  final int amount;

  /// Expense / income words (also debit/credit, dr/cr). Without it the
  /// amount's sign decides: negative = expense.
  final int? type;
  final int? account;
  final int? category;
  final int? note;
  final int? tags;
  final DateOrder dateOrder;

  /// Used when there's no account column, or a row's cell is empty.
  final String defaultAccount;

  CsvMapping copyWith({
    int? date,
    int? amount,
    int? Function()? type,
    int? Function()? account,
    int? Function()? category,
    int? Function()? note,
    int? Function()? tags,
    DateOrder? dateOrder,
    String? defaultAccount,
  }) => CsvMapping(
    date: date ?? this.date,
    amount: amount ?? this.amount,
    type: type == null ? this.type : type(),
    account: account == null ? this.account : account(),
    category: category == null ? this.category : category(),
    note: note == null ? this.note : note(),
    tags: tags == null ? this.tags : tags(),
    dateOrder: dateOrder ?? this.dateOrder,
    defaultAccount: defaultAccount ?? this.defaultAccount,
  );

  @override
  List<Object?> get props => [
    date,
    amount,
    type,
    account,
    category,
    note,
    tags,
    dateOrder,
    defaultAccount,
  ];
}

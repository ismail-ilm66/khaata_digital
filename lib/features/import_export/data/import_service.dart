import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../core/db/app_database.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../accounts/domain/account_type.dart';
import '../../categories/domain/category_kind.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/exchange_record.dart';
import '../domain/import_plan.dart';
import 'csv_mapper.dart';
import 'hk_sheet.dart';
import 'spreadsheet_codec.dart';

/// Hysab Kytab / Kharcha / generic CSV import (spec 3.3, M5).
///
/// Two steps: [draftFile] / [draftMapped] read and preview without writing;
/// [run] writes everything in one database transaction. Imports are
/// idempotent: each record's fingerprint is stored in `import_hashes`, and
/// Kharcha's own files also carry entry ids.
@lazySingleton
class ImportService {
  ImportService(this._db);

  final AppDatabase _db;

  // ── Reading ───────────────────────────────────────────────────────────

  /// Every sheet of an `.xls`, `.xlsx` or `.csv` file, parsed off the UI
  /// isolate. Throws [FormatException] when the file can't be read.
  Future<List<Sheet>> decode(List<int> bytes) => _decode(bytes);

  // Static so each isolate closure captures only its arguments.
  static Future<List<Sheet>> _decode(List<int> bytes) =>
      Isolate.run(() => SpreadsheetCodec.decode(bytes));

  static Future<ExchangeResult> _readHk(
    List<List<String>> rows,
    Currency currency,
  ) => Isolate.run(() => HkSheet.read(rows, defaultCurrency: currency));

  static Future<ExchangeResult> _readMapped(
    List<List<String>> rows,
    CsvMapping mapping,
    Currency currency,
  ) => Isolate.run(() => CsvMapper.read(rows, mapping, currency: currency));

  /// True when the table has Hysab Kytab's (or Kharcha's) header.
  static bool isHysabKytab(List<List<String>> rows) {
    if (rows.isEmpty) return false;
    final header = rows.first.map((h) => h.trim().toLowerCase()).toSet();
    return (header.contains('voucher type') || header.contains('type')) &&
        header.contains('voucher date') &&
        header.contains('voucher amount');
  }

  /// A draft from a Hysab Kytab or Kharcha file.
  Future<ImportDraft> draftFile(
    List<Sheet> sheets, {
    required Currency currency,
  }) async {
    final rows = SpreadsheetCodec.activities(sheets);
    final result = await _readHk(rows, currency);
    return _draft(
      ImportFormat.hysabKytab,
      result,
      rows,
      _openings(SpreadsheetCodec.named(sheets, 'ACCOUNT')?.rows, currency),
    );
  }

  /// A draft from any CSV through the user's column mapping.
  Future<ImportDraft> draftMapped(
    List<List<String>> rows,
    CsvMapping mapping, {
    required Currency currency,
  }) async {
    final result = await _readMapped(rows, mapping, currency);
    return _draft(ImportFormat.mapped, result, rows, const {});
  }

  /// Opening balances from a Hysab Kytab / Kharcha ACCOUNT sheet.
  static Map<String, Money> _openings(
    List<List<String>>? rows,
    Currency fallback,
  ) {
    if (rows == null || rows.length < 2) return const {};
    final header = [for (final h in rows.first) h.trim().toLowerCase()];
    final title = header.indexOf('title');
    final opening = header.indexOf('opening balance');
    final cur = header.indexOf('currency');
    if (title < 0 || opening < 0) return const {};
    return {
      for (final r in rows.skip(1))
        if (r.length > opening && r[title].trim().isNotEmpty)
          r[title].trim(): ?Money.parse(
            r[opening],
            cur >= 0 && r.length > cur && r[cur].trim().isNotEmpty
                ? Currency.of(r[cur].trim())
                : fallback,
            round: true,
          ),
    };
  }

  Future<ImportDraft> _draft(
    ImportFormat format,
    ExchangeResult result,
    List<List<String>> rows,
    Map<String, Money> openings,
  ) async {
    final records = result.records;
    final hashes = fingerprints(rows, result.lines);

    // Already imported, or (Kharcha files) already here by id.
    final duplicates = <int>{};
    final known = await _existing(
      'SELECT hash AS k FROM import_hashes WHERE hash IN',
      hashes,
    );
    final ids = await _existing(
      'SELECT id AS k FROM transactions WHERE id IN',
      [for (final r in records) ?r.id],
    );
    for (var i = 0; i < records.length; i++) {
      if (known.contains(hashes[i]) || ids.contains(records[i].id)) {
        duplicates.add(i);
      }
    }
    final names = await _names(records, openings);
    final days = [for (final r in records) r.at]..sort();
    return ImportDraft(
      format: format,
      records: records,
      lines: result.lines,
      hashes: hashes,
      duplicates: duplicates,
      warnings: result.warnings,
      names: names,
      first: days.firstOrNull,
      last: days.lastOrNull,
    );
  }

  /// SHA-256 of each record's source cells plus how many identical
  /// records came before it, so two genuinely identical rows (two Rs 100
  /// chais on one day) both import, once.
  static List<String> fingerprints(
    List<List<String>> rows,
    List<List<int>> lines,
  ) {
    final seen = <String, int>{};
    return [
      for (final ls in lines)
        () {
          final content = [
            for (final l in ls) rows[l - 1].map((c) => c.trim()).join('\u001f'),
          ].join('\u001e');
          final n = seen.update(content, (v) => v + 1, ifAbsent: () => 0);
          return sha256.convert(utf8.encode('$content\u001d$n')).toString();
        }(),
    ];
  }

  Future<Set<String>> _existing(String sql, List<String> keys) async {
    final found = <String>{};
    const chunk = 500; // under SQLite's bound-variable limit
    for (var i = 0; i < keys.length; i += chunk) {
      final part = keys.sublist(i, (i + chunk).clamp(0, keys.length));
      final rows = await _db
          .customSelect(
            '$sql (${List.filled(part.length, '?').join(',')})',
            variables: [for (final k in part) Variable.withString(k)],
          )
          .get();
      found.addAll(rows.map((r) => r.read<String>('k')));
    }
    return found;
  }

  Future<List<ImportName>> _names(
    List<ExchangeRecord> records,
    Map<String, Money> openings,
  ) async {
    final count = <String, int>{};
    final ownEntries = <String>{}; // used outside transfers
    void use(String name, {required bool transferOnly}) {
      count.update(name, (v) => v + 1, ifAbsent: () => 1);
      if (!transferOnly) ownEntries.add(name);
    }

    for (final r in records) {
      // Hysab Kytab adjustments come from unpaired transfer rows.
      final moving =
          r.type == TransactionType.transfer ||
          r.type == TransactionType.adjustment;
      use(r.account, transferOnly: moving && r.person == null);
      if (r.toAccount != null) use(r.toAccount!, transferOnly: true);
    }
    // Names only in the ACCOUNT sheet still matter for their openings.
    for (final name in openings.keys) {
      count.putIfAbsent(name, () => 0);
    }

    final accounts = {
      for (final b in await _db.accountsDao.balances())
        b.account.name.toLowerCase(),
    };
    final people = {
      for (final b in await _db.peopleDao.balances())
        b.person.name.toLowerCase(),
    };
    final names = <ImportName>[];
    for (final MapEntry(key: name, value: n) in count.entries) {
      final lower = name.toLowerCase();
      final isAccount = accounts.contains(lower);
      final canBePerson = !ownEntries.contains(name) && !isAccount;
      final person =
          canBePerson &&
          (people.contains(lower) || !AccountGuess.looksLikeMoney(name));
      names.add(
        ImportName(
          name: name,
          role: person ? ImportRole.person : ImportRole.account,
          canBePerson: canBePerson,
          existing: isAccount || (person && people.contains(lower)),
          entries: n,
          opening: openings[name],
        ),
      );
    }
    // Accounts first, then people; busiest first within each.
    names.sort((a, b) {
      final role = a.role.index.compareTo(b.role.index);
      return role != 0 ? role : b.entries.compareTo(a.entries);
    });
    return names;
  }

  // ── Writing ───────────────────────────────────────────────────────────

  /// Imports every new record of [draft] (with its roles) atomically.
  Future<ImportReport> run(ImportDraft draft) =>
      _db.transaction(() => _Writer(_db, draft).run());
}

/// Guesses an account's type from its name (spec 3.3) and whether a name
/// sounds like a money account at all (vs a person).
abstract final class AccountGuess {
  static final _wallet = RegExp(
    r'easy\s?paisa|jazz\s?cash|sada\s?pay|naya\s?pay|upaisa|payoneer|paypal|'
    r'wallet|zindigi|keenu',
    caseSensitive: false,
  );
  static final _bank = RegExp(
    r'\bbank|\bhbl\b|\bubl\b|\bmcb\b|\babl\b|\bnbp\b|\bbop\b|meezan|'
    r'alfalah|askari|faysal|habib|allied|islami|soneri|summit|silk|'
    r'chartered|al\s?baraka|\bjs\b|limited|\bltd\b',
    caseSensitive: false,
  );
  static final _card = RegExp(
    r'\bcard\b|credit|visa|master',
    caseSensitive: false,
  );
  static final _savings = RegExp(
    r'saving|committee|\bbc\b|invest|fund|deposit',
    caseSensitive: false,
  );
  static final _cash = RegExp(
    r'\bcash\b|account|purse|pocket',
    caseSensitive: false,
  );

  static AccountType typeOf(String name) {
    if (_wallet.hasMatch(name)) return AccountType.wallet;
    if (_bank.hasMatch(name)) return AccountType.bank;
    if (_card.hasMatch(name)) return AccountType.card;
    if (_savings.hasMatch(name)) return AccountType.savings;
    return AccountType.cash;
  }

  static bool looksLikeMoney(String name) =>
      [_wallet, _bank, _card, _savings, _cash].any((r) => r.hasMatch(name));
}

/// One import run, inside a database transaction.
class _Writer {
  _Writer(this._db, this._draft);

  final AppDatabase _db;
  final ImportDraft _draft;

  final _accounts = <String, String>{}; // lower name → id
  final _emptyAccounts = <String>{}; // ids with no entries and no opening
  final _people = <String, String>{};
  final _newPeople = <String>{};
  final _categories = <String, String>{}; // "kind|lower name" → id
  final _accountUse = <String, int>{};
  late final Map<String, ImportName> _names = {
    for (final n in _draft.names) n.name: n,
  };
  int _accountsCreated = 0;
  int _categoriesCreated = 0;

  ImportRole _role(String name) => _names[name]?.role ?? ImportRole.account;

  Future<ImportReport> run() async {
    await _load();
    var imported = 0;
    final skipped = <({ImportSkip reason, List<int> lines})>[];
    final now = DateTime.now().toUtc();

    for (var i = 0; i < _draft.records.length; i++) {
      if (_draft.duplicates.contains(i)) continue;
      final r = _draft.records[i];
      final entry = await _entry(r);
      if (entry is ImportSkip) {
        skipped.add((reason: entry, lines: _draft.lines[i]));
        continue;
      }
      final id = await _db.transactionsDao.add(
        entry as TransactionsCompanion,
        tags: r.tags,
        events: r.events,
      );
      await _db
          .into(_db.importHashes)
          .insert(
            ImportHashesCompanion.insert(
              hash: _draft.hashes[i],
              transactionId: Value(id),
              importedAt: now,
            ),
          );
      imported++;
    }
    await _personOpenings();

    return ImportReport(
      imported: imported,
      duplicates: _draft.duplicates.length,
      warnings: _draft.warnings,
      skipped: skipped,
      accountsCreated: _accountsCreated,
      peopleCreated: _newPeople.length,
      categoriesCreated: _categoriesCreated,
    );
  }

  Future<void> _load() async {
    final used = {
      for (final row
          in await _db
              .customSelect(
                'SELECT account_id AS a FROM transactions '
                'UNION SELECT to_account_id FROM transactions '
                'WHERE to_account_id IS NOT NULL',
              )
              .get())
        row.read<String>('a'),
    };
    for (final b in await _db.accountsDao.balances()) {
      final a = b.account;
      _accounts[a.name.toLowerCase()] = a.id;
      if (!used.contains(a.id) && a.openingBalanceMinor == 0) {
        _emptyAccounts.add(a.id);
      }
    }
    for (final b in await _db.peopleDao.balances()) {
      _people[b.person.name.toLowerCase()] = b.person.id;
    }
    for (final c in await _db.categoriesDao.active()) {
      _categories['${c.kind.name}|${c.name.toLowerCase()}'] = c.id;
    }
  }

  /// The entry to insert for [r], or why it can't be.
  Future<Object> _entry(ExchangeRecord r) async {
    if (r.person != null) {
      return _udhaar(
        gave: r.type == TransactionType.expense,
        account: r.account,
        person: r.person!,
        amount: r.amount,
        r: r,
      );
    }
    if (r.type == TransactionType.transfer) {
      final fromPerson = _role(r.account) == ImportRole.person;
      final toPerson = _role(r.toAccount!) == ImportRole.person;
      if (fromPerson && toPerson) return ImportSkip.betweenPeople;
      if (toPerson) {
        return _udhaar(
          gave: true,
          account: r.account,
          person: r.toAccount!,
          amount: r.amount,
          r: r,
        );
      }
      if (fromPerson) {
        return _udhaar(
          gave: false,
          account: r.toAccount!,
          person: r.account,
          amount: r.toAmount ?? r.amount,
          r: r,
        );
      }
      final to = r.toAmount ?? r.amount;
      return _base(r, r.amount).copyWith(
        accountId: Value(await _account(r.account, r.amount.currency)),
        toAccountId: Value(await _account(r.toAccount!, to.currency)),
        toAmountMinor: Value(r.toAmount?.minor),
        fxRateMicros: Value(r.toAmount == null ? null : r.fxRateMicros),
      );
    }
    if (_role(r.account) == ImportRole.person) {
      return ImportSkip.personAdjustment;
    }
    final kind = switch (r.type) {
      TransactionType.income => CategoryKind.income,
      TransactionType.expense => CategoryKind.expense,
      _ => null,
    };
    return _base(r, r.amount).copyWith(
      accountId: Value(await _account(r.account, r.amount.currency)),
      categoryId: Value(
        kind == null || r.category == null
            ? null
            : await _category(kind, r.category!),
      ),
    );
  }

  Future<TransactionsCompanion> _udhaar({
    required bool gave,
    required String account,
    required String person,
    required Money amount,
    required ExchangeRecord r,
  }) async => _base(r, amount).copyWith(
    type: Value(gave ? TransactionType.expense : TransactionType.income),
    accountId: Value(await _account(account, amount.currency)),
    personId: Value(await _person(person)),
  );

  TransactionsCompanion _base(ExchangeRecord r, Money amount) =>
      TransactionsCompanion.insert(
        id: r.id == null ? const Value.absent() : Value(r.id!),
        type: r.type,
        amountMinor: amount.minor,
        currencyCode: amount.currency.code,
        accountId: '', // set by the caller
        occurredAt: r.at.toUtc(),
        note: Value(r.note),
        place: Value(r.place),
      );

  Future<String> _account(String name, Currency currency) async {
    final key = name.toLowerCase();
    final known = _accounts[key];
    final opening = _names[name]?.opening;
    if (known != null) {
      // A fresh, untouched account (e.g. the seeded Cash) adopts the
      // file's opening balance, so imported balances come out right.
      if (_emptyAccounts.remove(known) && opening != null && !opening.isZero) {
        await _db.accountsDao.edit(
          known,
          AccountsCompanion(openingBalanceMinor: Value(opening.minor)),
        );
      }
      _accountUse.update(known, (v) => v + 1, ifAbsent: () => 1);
      return known;
    }
    final id = await _db.accountsDao.create(
      name: name,
      type: AccountGuess.typeOf(name),
      currencyCode: (opening?.currency ?? currency).code,
      openingBalanceMinor: opening?.minor ?? 0,
    );
    _accounts[key] = id;
    _accountsCreated++;
    _accountUse[id] = 1;
    return id;
  }

  Future<String> _person(String name) async {
    final key = name.toLowerCase();
    final known = _people[key];
    if (known != null) return known;
    final id = await _db.peopleDao.create(name: name);
    _people[key] = id;
    _newPeople.add(name);
    return id;
  }

  Future<String> _category(CategoryKind kind, String name) async {
    final key = '${kind.name}|${name.toLowerCase()}';
    final known = _categories[key];
    if (known != null) return known;
    final id = await _db.categoriesDao.create(name: name, kind: kind);
    _categories[key] = id;
    _categoriesCreated++;
    return id;
  }

  /// A new person's opening balance from the ACCOUNT sheet ("Sami owes me
  /// Rs 3,000 from before") becomes an udhaar entry, offset by an equal
  /// adjustment on the busiest account so no account balance changes.
  Future<void> _personOpenings() async {
    final at = (_draft.first ?? DateTime.now()).toUtc();
    for (final n in _draft.names) {
      final opening = n.opening;
      if (n.role != ImportRole.person ||
          opening == null ||
          opening.isZero ||
          !_newPeople.contains(n.name)) {
        continue;
      }
      final account =
          _busiestAccount() ?? await _account('Cash', opening.currency);
      final gave = !opening.isNegative; // positive: they owe me
      const note = 'Opening balance (imported)';
      await _db.transactionsDao.add(
        TransactionsCompanion.insert(
          type: gave ? TransactionType.expense : TransactionType.income,
          amountMinor: opening.minor.abs(),
          currencyCode: opening.currency.code,
          accountId: account,
          personId: Value(await _person(n.name)),
          occurredAt: at,
          note: const Value(note),
        ),
      );
      await _db.transactionsDao.add(
        TransactionsCompanion.insert(
          type: TransactionType.adjustment,
          amountMinor: opening.minor, // undoes the account movement
          currencyCode: opening.currency.code,
          accountId: account,
          occurredAt: at,
          note: const Value(note),
        ),
      );
    }
  }

  String? _busiestAccount() {
    String? best;
    var most = 0;
    for (final MapEntry(key: id, value: n) in _accountUse.entries) {
      if (n > most) (best, most) = (id, n);
    }
    return best;
  }
}

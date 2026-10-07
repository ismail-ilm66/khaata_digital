import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/dates/date_range.dart';
import 'package:khaata_digital/core/dates/report_period.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/accounts/domain/account_presets.dart';
import 'package:khaata_digital/features/accounts/domain/account_type.dart';
import 'package:khaata_digital/features/backup/domain/backup.dart';
import 'package:khaata_digital/features/import_export/domain/exchange_record.dart';
import 'package:khaata_digital/features/reports/domain/report.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

/// Value semantics that blocs rely on (equal state = no rebuild) and the
/// small rules that live in domain types.
void main() {
  group('AccountPresets', () {
    test('matches curated names and aliases, any spelling', () {
      expect(AccountPresets.match('easypaisa')?.key, 'easypaisa');
      expect(AccountPresets.match('Jazz-Cash')?.key, 'jazzcash');
      expect(AccountPresets.match('Mudassir Bhai'), isNull);
    });

    test('guesses a type from any name', () {
      expect(AccountPresets.guessType('Meezan Bank'), AccountType.bank);
      expect(AccountPresets.guessType('Standard Chartered'), AccountType.bank);
      expect(AccountPresets.guessType('Nayapay'), AccountType.wallet);
      expect(AccountPresets.guessType('Payoneer'), AccountType.wallet);
      expect(AccountPresets.guessType('Visa card'), AccountType.card);
      expect(AccountPresets.guessType('Family committee'), AccountType.savings);
      expect(AccountPresets.guessType('Purse'), AccountType.cash);
    });

    test('tells money accounts from people', () {
      for (final account in [
        'Cash',
        'Meezan Bank',
        'EasyPaisa',
        'Savings',
        'HBL',
      ]) {
        expect(
          AccountPresets.looksLikeAccount(account),
          isTrue,
          reason: account,
        );
      }
      for (final person in ['Mudassir Bhai', 'Sannan', 'Ir Ma', 'Billa g']) {
        expect(
          AccountPresets.looksLikeAccount(person),
          isFalse,
          reason: person,
        );
      }
    });
  });

  group('backup manifest', () {
    final manifest = BackupManifest(
      schemaVersion: 2,
      appVersion: '1.0.0+1',
      createdAt: DateTime.utc(2026, 10, 6, 9, 30),
      rowCounts: const {'transactions': 12},
      accounts: 3,
      transactions: 12,
      first: DateTime.utc(2025, 8, 25),
      last: DateTime.utc(2026, 10, 6),
      files: const {'data.db': 'abc'},
      encryption: const BackupEncryption(salt: [1, 2, 3], iterations: 1000),
    );

    test('survives JSON both ways, equal by value', () {
      final back = BackupManifest.fromJson(manifest.toJson());
      expect(back, manifest);
      expect(back.hashCode, manifest.hashCode);
      expect(back.encrypted, isTrue);
    });

    test('refuses other formats, newer versions and unknown ciphers', () {
      Map<String, Object?> json() => manifest.toJson();
      expect(
        () => BackupManifest.fromJson(json()..['format'] = 'zip'),
        throwsA(const BackupFailure.notABackup()),
      );
      expect(
        () => BackupManifest.fromJson(json()..['format_version'] = 99),
        throwsA(const BackupFailure(BackupFailureKind.newerApp)),
      );
      expect(
        () => BackupManifest.fromJson(
          json()..['encryption'] = {'cipher': 'ROT13', 'kdf': 'x'},
        ),
        throwsA(const BackupFailure(BackupFailureKind.newerApp)),
      );
      expect(
        () => BackupManifest.fromJson('nonsense'),
        throwsA(const BackupFailure.notABackup()),
      );
    });

    test('failures read clearly in logs', () {
      expect(
        const BackupFailure(
          BackupFailureKind.damaged,
          'changed data.db',
        ).toString(),
        'BackupFailure(BackupFailureKind.damaged: changed data.db)',
      );
      expect(
        const BackupFailure(BackupFailureKind.integrity).toString(),
        'BackupFailure(BackupFailureKind.integrity)',
      );
    });
  });

  group('reports', () {
    final range = DateRange(DateTime(2026, 10, 1), DateTime(2026, 10, 2));
    final pkr = Money.major(10, Currency.pkr);

    test('query copyWith keeps cycle and currency', () {
      final q = ReportQuery(
        period: ReportPeriod.month(DateTime(2026, 10, 6)),
        cycle: const BudgetCycle.lastWorkingDay(),
        currency: Currency.pkr,
      );
      final changed = q.copyWith(
        filters: const EntryQuery(types: {TransactionType.expense}),
      );
      expect(changed.cycle, q.cycle);
      expect(changed.currency, q.currency);
      expect(changed, isNot(q));
      expect(changed.copyWith(filters: const EntryQuery()), q);
    });

    test('chart points are values', () {
      expect(FlowPoint(range, pkr, pkr), FlowPoint(range, pkr, pkr));
      expect(BalancePoint(range, pkr), BalancePoint(range, pkr));
      expect(BalancePoint(range, pkr), isNot(BalancePoint(range, pkr + pkr)));
    });
  });

  test('DateRange: value equality and readable', () {
    final a = DateRange(DateTime(2026, 9, 30), DateTime(2026, 10, 30));
    expect(a, DateRange(DateTime(2026, 9, 30), DateTime(2026, 10, 30)));
    expect(a.hashCode, DateRange(a.start, a.end).hashCode);
    expect(a.toString(), contains('2026-09-30'));
  });

  test('ExchangeRecord and warnings are values', () {
    final r = ExchangeRecord(
      type: TransactionType.expense,
      at: DateTime(2026, 9, 1, 12),
      amount: Money.major(2520, Currency.pkr),
      account: 'Meezan Bank',
      category: 'Food & Drink',
      note: 'Lunch',
    );
    expect(r.toString(), contains('Meezan Bank'));
    expect(
      const ExchangeWarning(3, ExchangeWarningKind.unreadableRow),
      const ExchangeWarning(3, ExchangeWarningKind.unreadableRow),
    );
    expect(ExchangeResult([r], const []), ExchangeResult([r], const []));
  });

  test('EntryDraft: equal drafts are equal (no spurious form rebuilds)', () {
    EntryDraft draft(String note) => EntryDraft(
      type: TransactionType.expense,
      amount: Money.major(100, Currency.pkr),
      accountId: 'cash',
      occurredAt: DateTime.utc(2026, 10, 6),
      note: note,
      tags: const ['office'],
    );
    expect(draft('Chai'), draft('Chai'));
    expect(draft('Chai'), isNot(draft('Samosa')));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/error/app_failure.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/accounts/data/accounts_repository_impl.dart';
import 'package:khaata_digital/features/accounts/domain/account.dart';
import 'package:khaata_digital/features/accounts/domain/account_type.dart';

import '../../helpers/test_db.dart';

AccountDraft draft(
  String name, {
  Currency currency = Currency.pkr,
  int opening = 0,
  bool exclude = false,
}) => AccountDraft(
  name: name,
  type: AccountType.bank,
  currency: currency,
  openingBalance: Money(opening, currency),
  excludeFromTotal: exclude,
);

void main() {
  late AppDatabase db;
  late AccountsRepositoryImpl repo;

  setUp(() {
    db = testDb();
    repo = AccountsRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('overview has balances in Money and per-currency net worth', () async {
    await repo.create(draft('HBL', opening: 500000));
    await repo.create(draft('Savings', opening: 900000, exclude: true));
    await repo.create(draft('Wise', currency: Currency.usd, opening: 2500));

    final o = await repo.watchOverview().first;
    expect(o.accounts.map((a) => a.account.name), [
      'Cash',
      'HBL',
      'Savings',
      'Wise',
    ]);
    expect(o.accounts[1].balance, const Money(500000, Currency.pkr));
    expect(o.netWorth, {
      Currency.pkr: const Money(500000, Currency.pkr),
      Currency.usd: const Money(2500, Currency.usd),
    });
  });

  test('duplicate active names raise DuplicateNameFailure', () async {
    await repo.create(draft('HBL'));
    await expectLater(
      repo.create(draft(' hbl ')),
      throwsA(isA<DuplicateNameFailure>()),
    );
    final id = await repo.create(draft('UBL'));
    await expectLater(
      repo.update(id, draft('HBL')),
      throwsA(isA<DuplicateNameFailure>()),
    );
  });

  test('archived names are reusable (complaint #8)', () async {
    final first = await repo.create(draft('Meezan Bank'));
    await repo.archive(first);
    await repo.create(draft('Meezan Bank'));

    final archived = await repo.watchArchived().first;
    expect(archived.single.id, first);
    expect(archived.single.isArchived, isTrue);
    await expectLater(
      repo.unarchive(first),
      throwsA(isA<DuplicateNameFailure>()),
    );
  });

  test('update edits every field', () async {
    final id = await repo.create(draft('HBL'));
    await repo.update(
      id,
      draft('HBL Current', currency: Currency.usd, opening: 100, exclude: true),
    );
    final a = (await repo.byId(id))!;
    expect(a.name, 'HBL Current');
    expect(a.currency, Currency.usd);
    expect(a.openingBalance, const Money(100, Currency.usd));
    expect(a.excludeFromTotal, isTrue);
  });

  test('reorder persists', () async {
    final a = await repo.create(draft('A'));
    final b = await repo.create(draft('B'));
    final cash = (await repo.watchOverview().first).accounts.first.account.id;
    await repo.reorder([b, a, cash]);
    expect(
      (await repo.watchOverview().first).accounts.map((x) => x.account.name),
      ['B', 'A', 'Cash'],
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/error/app_failure.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/people/data/people_repository_impl.dart';
import 'package:khaata_digital/features/people/domain/person.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';

import '../../helpers/test_repos.dart';

Money rs(int r) => Money.major(r, Currency.pkr);

void main() {
  late TestRepos r;
  late PeopleRepositoryImpl repo;
  late String cash;

  setUp(() async {
    r = TestRepos();
    repo = PeopleRepositoryImpl(r.db, r.transactions);
    cash = await r.cashId();
  });
  tearDown(() => r.close());

  Future<void> gave(String person, int rupees, int day) => r.ledger.expense(
    cash,
    rupees * 100,
    personId: person,
    at: DateTime(2026, 9, day, 12).toUtc(),
  );
  Future<void> received(String person, int rupees, int day) => r.ledger.income(
    cash,
    rupees * 100,
    personId: person,
    at: DateTime(2026, 9, day, 12).toUtc(),
  );

  test('totals match the sum of each ledger (M3 acceptance)', () async {
    final ali = await repo.create('Ali');
    final sara = await repo.create('Sara');
    await gave(ali, 5000, 1);
    await received(ali, 2000, 5);
    await gave(ali, 500, 9);
    await received(sara, 1200, 3);

    final o = await repo.watchOverview().first;
    expect(o.receivable, {Currency.pkr: rs(3500)});
    expect(o.payable, {Currency.pkr: rs(1200)});

    for (final p in o.people) {
      final ledger = await repo.watchLedger(p.person.id).first;
      final sum = ledger.fold(
        rs(0),
        (acc, l) => acc + LedgerLine.effect(l.view.entry),
      );
      expect(p.balance[Currency.pkr], sum, reason: p.person.name);
      expect(
        ledger.first.runningBalance,
        sum,
        reason: 'newest line shows the current balance',
      );
    }
  });

  test(
    'ledger is newest first with a running balance after each line',
    () async {
      final ali = await repo.create('Ali');
      await gave(ali, 5000, 1);
      await received(ali, 2000, 5);
      await gave(ali, 500, 9);

      final ledger = await repo.watchLedger(ali).first;
      expect(ledger.map((l) => l.runningBalance), [
        rs(3500),
        rs(3000),
        rs(5000),
      ]);
    },
  );

  test('settling up brings the balance to zero', () async {
    final ali = await repo.create('Ali');
    await gave(ali, 700, 1);
    await received(ali, 700, 2);
    final o = await repo.watchOverview().first;
    expect(o.people.single.isSettled, isTrue);
    expect(o.receivable, isEmpty);
  });

  test(
    'names are unique among active people; archived names are reusable',
    () async {
      final ali = await repo.create('Ali');
      await expectLater(
        repo.create('ali'),
        throwsA(isA<DuplicateNameFailure>()),
      );
      await repo.archive(ali);
      await repo.create('Ali');
      final names = (await repo.watchOverview().first).people.map(
        (p) => p.person.name,
      );
      expect(names, ['Ali']);
    },
  );

  test('rename', () async {
    final id = await repo.create('Mudasir');
    await repo.rename(id, 'Mudassir Bhai');
    expect((await repo.watchPerson(id).first)!.name, 'Mudassir Bhai');
  });

  test('entries list and search by the person\'s name', () async {
    final ali = await repo.create('Mudassir Bhai');
    await gave(ali, 100, 1);
    final views =
        (await r.transactions.watch(const EntryQuery(search: 'mudassir')).first)
            .items;
    expect(views.single.personName, 'Mudassir Bhai');
    expect(views.single.isUdhaar, isTrue);
  });
}

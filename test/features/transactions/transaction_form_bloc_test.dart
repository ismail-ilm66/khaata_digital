import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/error/app_failure.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/people/domain/person.dart';
import 'package:khaata_digital/features/recurring/domain/recurrence.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:khaata_digital/features/transactions/presentation/form/transaction_form_bloc.dart';

import '../../helpers/test_repos.dart';

void main() {
  late TestRepos r;
  late TransactionFormBloc bloc;

  setUp(() {
    r = TestRepos();
    bloc = r.formBloc();
  });
  tearDown(() async {
    await bloc.close();
    await r.close();
  });

  /// Adds [event] and waits until the bloc has processed it.
  Future<TransactionFormState> send(TransactionFormEvent event) async {
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
    await pumpEventQueue();
    return bloc.state;
  }

  Future<void> keys(String text, {AmountTarget target = AmountTarget.amount}) =>
      send(AmountTyped(text, target: target));

  test('a new expense starts with no account, no category, and now', () async {
    final s = await send(const FormStarted());
    expect(s.status, FormStatus.ready);
    expect(s.type, TransactionType.expense);
    expect(s.accountId, isNull);
    expect(s.currency, Currency.pkr, reason: 'home currency until chosen');
    expect(s.categoryId, isNull);
    expect(DateTime.now().difference(s.occurredAt).inSeconds, lessThan(5));
    expect(s.canSave, isFalse, reason: 'no amount yet');
  });

  test('the 3-second path: amount → account → category → save', () async {
    final food = await r.categoryId('Food & Drink');
    await send(const FormStarted());
    await send(AccountChanged(await r.cashId()));
    await keys('2520');
    await send(CategoryTapped(food));
    final s = await send(const FormSubmitted());

    expect(s.status, FormStatus.saved);
    final saved =
        (await r.transactions.watch(const EntryQuery()).first).items.single;
    expect(saved.entry.amount, Money.major(2520, Currency.pkr));
    expect(saved.category!.name, 'Food & Drink');
  });

  test('saving needs an account, then a category', () async {
    final food = await r.categoryId('Food & Drink');
    await send(const FormStarted());
    await keys('500');
    var s = await send(const FormSubmitted());
    expect(s.problem, EntryProblem.accountRequired);

    s = await send(AccountChanged(await r.cashId()));
    expect(s.problem, isNull, reason: 'choosing clears it');
    s = await send(const FormSubmitted());
    expect(s.problem, EntryProblem.categoryRequired);
    expect(s.status, FormStatus.ready);
    expect(
      (await r.transactions.watch(const EntryQuery()).first).items,
      isEmpty,
    );

    s = await send(CategoryTapped(food));
    expect(s.problem, isNull);
    expect((await send(const FormSubmitted())).status, FormStatus.saved);
  });

  test('accounts and the full category list are ordered by use', () async {
    final cash = await r.cashId();
    final bank = await r.ledger.account('Bank');
    final wallet = await r.ledger.account('Wallet');
    final mobile = await r.categoryId('Mobile');
    for (var i = 0; i < 3; i++) {
      await r.ledger.expense(wallet, 100, categoryId: mobile);
    }
    await r.ledger.transfer(bank, cash, 100);
    await r.ledger.expense(bank, 100);

    final s = await send(const FormStarted());
    expect(s.accountsByUse.map((a) => a.id), [wallet, bank, cash]);
    expect(s.categoriesByUse.first.name, 'Mobile');
    expect(
      s.categoriesByUse.length,
      s.visibleCategories.length,
      reason: 'unused ones still listed',
    );
  });

  test(
    'editing pre-fills every stored value, the date included (complaint #7)',
    () async {
      final at = DateTime(2025, 8, 25, 13, 45);
      final food = await r.categoryId('Food & Drink');
      await send(const FormStarted());
      await send(AccountChanged(await r.cashId()));
      await keys('2520.5');
      await send(CategoryTapped(food));
      await send(DateChanged(at));
      await send(const NoteChanged('Lunch'));
      await send(const TagsChanged('office, lunch'));
      await send(const FormSubmitted());
      final id = (await r.transactions.watch(const EntryQuery()).first)
          .items
          .single
          .entry
          .id;

      final edit = r.formBloc();
      edit.add(FormStarted(editId: id));
      await pumpEventQueue();
      final s = edit.state;
      expect(s.isEditing, isTrue);
      expect(s.occurredAt, at);
      expect(s.amount.text, '2520.5');
      expect(s.categoryId, food);
      expect(s.note, 'Lunch');
      expect(s.tags, [
        'lunch',
        'office',
      ], reason: 'stored tags come back alphabetical');

      edit.add(const NoteChanged('Lunch with team'));
      edit.add(const FormSubmitted());
      await pumpEventQueue();
      final stored = (await r.transactions.byId(id))!;
      expect(
        stored.occurredAt.toLocal(),
        at,
        reason: 'saving an edit never resets the date',
      );
      expect(stored.note, 'Lunch with team');
      await edit.close();
    },
  );

  test(
    'switching to income drops an expense category; transfer picks no destination',
    () async {
      final food = await r.categoryId('Food & Drink');
      await r.ledger.account('Bank');
      await send(const FormStarted());
      await send(AccountChanged(await r.cashId()));
      await send(CategoryTapped(food));
      var s = await send(const TypeChanged(TransactionType.income));
      expect(s.categoryId, isNull);
      expect(s.visibleCategories.every((c) => c.kind.name == 'income'), isTrue);

      s = await send(const TypeChanged(TransactionType.transfer));
      expect(s.toAccountId, isNull);
    },
  );

  test('tapping the selected category again clears it', () async {
    final food = await r.categoryId('Food & Drink');
    await send(const FormStarted());
    await send(CategoryTapped(food));
    expect((await send(CategoryTapped(food))).categoryId, isNull);
  });

  test(
    'cross-currency transfer: typing fills "receives" and derives the rate',
    () async {
      final usd = await r.ledger.account('Payoneer', currency: 'USD');
      final cash = await r.cashId();
      await send(const FormStarted());
      await send(AccountChanged(usd));
      await send(const TypeChanged(TransactionType.transfer));
      await send(ToAccountChanged(cash));
      await keys('100');
      await keys('28250', target: AmountTarget.toAmount);

      final s = bloc.state;
      expect(s.crossCurrency, isTrue);
      expect(s.money, Money.major(100, Currency.usd));
      expect(s.toMoney, Money.major(28250, Currency.pkr));
      expect(s.rateMicros, 282500000);

      expect((await send(const FormSubmitted())).status, FormStatus.saved);
      expect(await r.ledger.balanceOf(cash), 2825000);
    },
  );

  test('a validation problem is shown and the form stays editable', () async {
    final usd = await r.ledger.account('Payoneer', currency: 'USD');
    await send(const FormStarted());
    await send(AccountChanged(usd));
    await send(const TypeChanged(TransactionType.transfer));
    await send(ToAccountChanged(await r.cashId()));
    await keys('10');
    final s = await send(const FormSubmitted());
    expect(s.problem, EntryProblem.conversionRequired);
    expect(s.status, FormStatus.ready);
  });

  test('tags parse, trim and de-duplicate', () {
    expect(TransactionFormBloc.parseTags(' office, Lunch ,, OFFICE,lunch '), [
      'office',
      'Lunch',
    ]);
  });

  test(
    'quick categories put the most-used first, topped up in seed order',
    () async {
      final cash = await r.cashId();
      final grocery = await r.categoryId('Grocery');
      final mobile = await r.categoryId('Mobile');
      for (var i = 0; i < 3; i++) {
        await r.ledger.expense(cash, 100, categoryId: grocery);
      }
      await r.ledger.expense(cash, 100, categoryId: mobile);

      final s = await send(const FormStarted());
      final names = s.quickCategories.map((c) => c.name).toList();
      expect(names, hasLength(TransactionFormState.quickCount));
      expect(names.take(2), ['Grocery', 'Mobile']);
      expect(names[2], 'Personal', reason: 'then seed order');
    },
  );

  test('a category picked from "All" shows first in the quick row', () async {
    final wedding = await r.categoryId('Wedding');
    await send(const FormStarted());
    final s = await send(CategoryTapped(wedding));
    expect(s.quickCategories.first.name, 'Wedding');
    expect(s.quickCategories, hasLength(TransactionFormState.quickCount));
  });

  test(
    'swap exchanges transfer accounts and keeps a same-currency amount',
    () async {
      final bank = await r.ledger.account('Bank');
      await send(const FormStarted());
      await send(const TypeChanged(TransactionType.transfer));
      await send(AccountChanged(await r.cashId()));
      await send(ToAccountChanged(bank));
      await keys('300');
      final before = bloc.state;
      final s = await send(const AccountsSwapped());
      expect(s.accountId, before.toAccountId);
      expect(s.toAccountId, before.accountId);
      expect(s.amount.text, '300');
    },
  );

  group('udhaar mode', () {
    test('records a person-linked entry with no category', () async {
      final ali = await r.people.create('Ali');
      final food = await r.categoryId('Food & Drink');
      await send(const FormStarted());
      await send(CategoryTapped(food));
      await send(const UdhaarChosen());
      await send(PersonChanged(ali));
      await send(AccountChanged(await r.cashId()));
      await keys('5000');
      expect((await send(const FormSubmitted())).status, FormStatus.saved);

      final e = (await r.transactions.watch(const EntryQuery()).first)
          .items
          .single
          .entry;
      expect(e.personId, ali);
      expect(e.type, TransactionType.expense, reason: 'I gave');
      expect(e.categoryId, isNull);
      final o = await r.people.watchOverview().first;
      expect(o.receivable[Currency.pkr], Money.major(5000, Currency.pkr));
    });

    test('"I received" is stored as income', () async {
      final ali = await r.people.create('Ali');
      await send(FormStarted(personId: ali, udhaar: UdhaarDirection.received));
      await send(AccountChanged(await r.cashId()));
      await keys('300');
      await send(const FormSubmitted());
      final e = (await r.transactions.watch(const EntryQuery()).first)
          .items
          .single
          .entry;
      expect(e.type, TransactionType.income);
    });

    test('needs a person', () async {
      await send(const FormStarted());
      await send(const UdhaarChosen());
      await send(AccountChanged(await r.cashId()));
      await keys('10');
      final s = await send(const FormSubmitted());
      expect(s.problem, EntryProblem.personRequired);
      expect(
        await r.transactions
            .watch(const EntryQuery())
            .first
            .then((p) => p.items),
        isEmpty,
      );
    });

    test('settle up pre-fills person, direction and amount', () async {
      final ali = await r.people.create('Ali');
      final s = await send(
        FormStarted(
          personId: ali,
          udhaar: UdhaarDirection.received,
          amount: Money.major(3500, Currency.pkr),
        ),
      );
      expect(s.isUdhaar, isTrue);
      expect(s.person!.name, 'Ali');
      expect(s.udhaarDirection, UdhaarDirection.received);
      expect(s.amount.text, '3500');
    });

    test('editing an udhaar entry reopens in udhaar mode', () async {
      final ali = await r.people.create('Ali');
      final cash = await r.cashId();
      final id = await r.ledger.expense(cash, 100, personId: ali);
      final edit = r.formBloc()..add(FormStarted(editId: id));
      await pumpEventQueue();
      expect(edit.state.isUdhaar, isTrue);
      expect(edit.state.personId, ali);
      await edit.close();
    });

    test('switching back to expense drops the person', () async {
      final ali = await r.people.create('Ali');
      await send(FormStarted(personId: ali));
      final s = await send(const TypeChanged(TransactionType.expense));
      expect(s.isUdhaar, isFalse);
      expect(s.personId, isNull);
    });

    test('a person added from the editor is selected', () async {
      await send(const FormStarted());
      await send(const UdhaarChosen());
      final s = await send(const PersonAdded(Person(id: 'p1', name: 'Sara')));
      expect(s.person!.name, 'Sara');
    });
  });

  group('repeat', () {
    Future<void> ready() async {
      await send(const FormStarted());
      await send(AccountChanged(await r.cashId()));
      await send(CategoryTapped(await r.categoryId('Grocery')));
    }

    test('saving with Repeat creates a rule and syncs reminders', () async {
      await ready();
      await send(
        const RepeatChanged(RecurrenceFrequency.monthly, remind: true),
      );
      await keys('45000');
      await send(const FormSubmitted());

      final rules = await r.recurring.active();
      expect(rules.single.frequency, RecurrenceFrequency.monthly);
      expect(rules.single.remind, isTrue);
      expect(rules.single.template.amount, Money.major(45000, Currency.pkr));
      expect(r.reminders.last, hasLength(1));
    });

    test('no rule without Repeat', () async {
      await ready();
      await keys('5');
      expect((await send(const FormSubmitted())).status, FormStatus.saved);
      expect(await r.recurring.active(), isEmpty);
    });
  });
}

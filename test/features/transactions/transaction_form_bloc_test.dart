import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/error/app_failure.dart';
import 'package:khaata_digital/core/money/amount_buffer.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:khaata_digital/features/transactions/presentation/form/transaction_form_bloc.dart';

import '../../helpers/test_repos.dart';

void main() {
  late TestRepos r;
  late TransactionFormBloc bloc;

  setUp(() {
    r = TestRepos();
    bloc = TransactionFormBloc(
      r.transactions,
      r.accounts,
      r.categories,
      r.settings,
    );
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

  Future<void> keys(String digits) async {
    for (final d in digits.split('')) {
      await send(
        KeyPressed(
          d == '.' ? KeypadKey.decimal : KeypadKey.digit(int.parse(d)),
        ),
      );
    }
  }

  test(
    'a new expense defaults to the first account, now, and no category',
    () async {
      final s = await send(const FormStarted());
      expect(s.status, FormStatus.ready);
      expect(s.type, TransactionType.expense);
      expect(s.account!.name, 'Cash');
      expect(s.categoryId, isNull);
      expect(DateTime.now().difference(s.occurredAt).inSeconds, lessThan(5));
      expect(s.canSave, isFalse, reason: 'no amount yet');
    },
  );

  test('the 3-second path: amount → category → save', () async {
    final food = await r.categoryId('Food & Drink');
    await send(const FormStarted());
    await keys('2520');
    await send(CategoryTapped(food));
    final s = await send(const FormSubmitted());

    expect(s.status, FormStatus.saved);
    final saved =
        (await r.transactions.watch(const EntryQuery()).first).items.single;
    expect(saved.entry.amount, Money.major(2520, Currency.pkr));
    expect(saved.category!.name, 'Food & Drink');
  });

  test('remembers the last-used account for the next entry', () async {
    final bank = await r.ledger.account('Meezan Bank');
    await send(const FormStarted());
    await send(AccountChanged(bank));
    await keys('5');
    await send(const FormSubmitted());
    expect(await r.settings.read(SettingKey.lastAccountId), bank);

    final next = TransactionFormBloc(
      r.transactions,
      r.accounts,
      r.categories,
      r.settings,
    );
    next.add(const FormStarted());
    await pumpEventQueue();
    expect(next.state.accountId, bank);
    await next.close();
  });

  test(
    'editing pre-fills every stored value, the date included (complaint #7)',
    () async {
      final at = DateTime(2025, 8, 25, 13, 45);
      final food = await r.categoryId('Food & Drink');
      await send(const FormStarted());
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

      final edit = TransactionFormBloc(
        r.transactions,
        r.accounts,
        r.categories,
        r.settings,
      );
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
    'switching to income drops an expense category; transfer picks a destination',
    () async {
      final food = await r.categoryId('Food & Drink');
      await r.ledger.account('Bank');
      await send(const FormStarted());
      await send(CategoryTapped(food));
      var s = await send(const TypeChanged(TransactionType.income));
      expect(s.categoryId, isNull);
      expect(s.visibleCategories.every((c) => c.kind.name == 'income'), isTrue);

      s = await send(const TypeChanged(TransactionType.transfer));
      expect(s.toAccount!.name, 'Bank');
    },
  );

  test('tapping the selected category again clears it', () async {
    final food = await r.categoryId('Food & Drink');
    await send(const FormStarted());
    await send(CategoryTapped(food));
    expect((await send(CategoryTapped(food))).categoryId, isNull);
  });

  test(
    'cross-currency transfer: keypad fills "receives" and derives the rate',
    () async {
      final usd = await r.ledger.account('Payoneer', currency: 'USD');
      final cash = await r.cashId();
      await send(const FormStarted());
      await send(AccountChanged(usd));
      await send(const TypeChanged(TransactionType.transfer));
      await send(ToAccountChanged(cash));
      await keys('100');
      await send(const AmountFocused(AmountTarget.toAmount));
      await keys('28250');

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
      await r.ledger.account('Bank');
      await send(const FormStarted());
      await send(const TypeChanged(TransactionType.transfer));
      await keys('300');
      final before = bloc.state;
      final s = await send(const AccountsSwapped());
      expect(s.accountId, before.toAccountId);
      expect(s.toAccountId, before.accountId);
      expect(s.amount.text, '300');
    },
  );
}

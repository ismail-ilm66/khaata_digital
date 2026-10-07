import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:khaata_digital/features/transactions/presentation/list/transaction_list_bloc.dart';

import '../../helpers/test_repos.dart';

void main() {
  late TestRepos r;
  late TransactionListBloc bloc;
  late String cash;

  setUp(() async {
    r = TestRepos();
    bloc = TransactionListBloc(r.transactions);
    cash = await r.cashId();
  });
  tearDown(() async {
    await bloc.close();
    await r.close();
  });

  Future<void> save(
    int rupees, {
    TransactionType type = TransactionType.expense,
    DateTime? at,
    String note = '',
  }) => r.transactions.save(
    EntryDraft(
      type: type,
      amount: Money.major(rupees, Currency.pkr),
      accountId: cash,
      occurredAt: (at ?? DateTime(2026, 9, 26, 12)).toUtc(),
      note: note,
    ),
  );

  Future<TransactionListState> settle() async {
    await pumpEventQueue();
    return bloc.state;
  }

  test('groups by day with daily totals', () async {
    await save(100, at: DateTime(2026, 9, 26, 9));
    await save(250, at: DateTime(2026, 9, 26, 18));
    await save(
      5000,
      type: TransactionType.income,
      at: DateTime(2026, 9, 26, 10),
    );
    await save(40, at: DateTime(2026, 9, 25, 12));
    bloc.add(const ListStarted());
    final s = await settle();

    expect(s.days, hasLength(2));
    expect(s.days.first.day, DateTime(2026, 9, 26));
    expect(s.days.first.spent[Currency.pkr], Money.major(350, Currency.pkr));
    expect(s.days.first.earned[Currency.pkr], Money.major(5000, Currency.pkr));
    expect(s.days.last.spent[Currency.pkr], Money.major(40, Currency.pkr));
  });

  test('updates live when an entry is added', () async {
    bloc.add(const ListStarted());
    expect((await settle()).isEmpty, isTrue);
    await save(10);
    expect((await settle()).days.single.entries, hasLength(1));
  });

  test('filters and search restart the query', () async {
    await save(100, note: 'chai');
    await save(200, type: TransactionType.income);
    bloc.add(const ListStarted());
    await settle();

    bloc.add(const FiltersChanged(EntryQuery(types: {TransactionType.income})));
    expect(
      (await settle()).days.single.entries.single.entry.type,
      TransactionType.income,
    );

    bloc.add(FiltersChanged(bloc.state.query.cleared()));
    bloc.add(const SearchChanged('chai'));
    expect((await settle()).days.single.entries.single.entry.note, 'chai');
  });

  test('delete then undo', () async {
    await save(100);
    bloc.add(const ListStarted());
    final id = (await settle()).days.single.entries.single.entry.id;

    // The very first state after a swipe already lacks the row (a
    // dismissed Dismissible must leave the tree on the next frame).
    final next = bloc.stream.first;
    bloc.add(EntryDeleted(id));
    expect((await next).days, isEmpty);
    var s = await settle();
    expect(s.isEmpty, isTrue);
    expect(s.lastDeletedId, id);

    bloc.add(const DeleteUndone());
    s = await settle();
    expect(s.days.single.entries.single.entry.id, id);
    expect(s.lastDeletedId, isNull);
  });

  test('loads more pages on request', () async {
    for (var d = 1; d <= 70; d++) {
      await save(1, at: DateTime(2026, 1, 1).add(Duration(days: d)));
    }
    bloc.add(const ListStarted());
    var s = await settle();
    expect(s.hasMore, isTrue);
    final first = s.days.length;

    bloc.add(const MoreRequested());
    s = await settle();
    expect(s.days.length, greaterThan(first));
    expect(s.hasMore, isFalse);
    expect(s.days.length, 70);
  });
}

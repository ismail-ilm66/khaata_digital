import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/features/accounts/domain/account_presets.dart';
import 'package:khaata_digital/features/accounts/domain/account_type.dart';
import 'package:khaata_digital/features/accounts/presentation/account_form_cubit.dart';
import 'package:khaata_digital/features/accounts/presentation/accounts_bloc.dart';

import '../../helpers/test_repos.dart';

void main() {
  late TestRepos r;
  setUp(() => r = TestRepos());
  tearDown(() => r.close());

  group('AccountFormCubit', () {
    test('a preset pre-fills name, type, badge and colour', () {
      final cubit = AccountFormCubit(r.accounts)
        ..startNew(
          preset: AccountPresets.byKey('jazzcash'),
          currency: Currency.pkr,
        );
      final d = cubit.state.draft;
      expect(d.name, 'JazzCash');
      expect(d.type, AccountType.wallet);
      expect(d.iconKey, 'jazzcash');
      expect(d.color, isNotNull);
    });

    test('saving a duplicate name flags it instead of saving', () async {
      final cubit = AccountFormCubit(r.accounts)
        ..startNew(currency: Currency.pkr);
      cubit.update(cubit.state.draft.copyWith(name: 'cash'));
      await cubit.save();
      expect(cubit.state.duplicateName, isTrue);
      expect(cubit.state.status, AccountFormStatus.editing);
    });

    test('archive from the edit form', () async {
      final id = await r.ledger.account('Old');
      final cubit = AccountFormCubit(r.accounts)
        ..startEdit((await r.accounts.byId(id))!);
      await cubit.archive();
      expect(cubit.state.status, AccountFormStatus.archived);
      expect((await r.accounts.watchArchived().first).single.id, id);
    });
  });

  group('AccountsBloc', () {
    test('reorder moves the row at once and persists it', () async {
      await r.ledger.account('A');
      await r.ledger.account('B');
      final bloc = AccountsBloc(r.accounts)..add(const AccountsStarted());
      await pumpEventQueue();
      expect(bloc.state.overview.accounts.map((a) => a.account.name), [
        'Cash',
        'A',
        'B',
      ]);

      bloc.add(const AccountsReordered(2, 0)); // drag B to the top
      await pumpEventQueue();
      expect(bloc.state.overview.accounts.map((a) => a.account.name), [
        'B',
        'Cash',
        'A',
      ]);
      expect(
        (await r.accounts.watchOverview().first).accounts.map(
          (a) => a.account.name,
        ),
        ['B', 'Cash', 'A'],
      );
      await bloc.close();
    });

    test('unarchiving a name now in use reports the clash', () async {
      final old = await r.ledger.account('HBL');
      await r.accounts.archive(old);
      await r.ledger.account('HBL');
      final bloc = AccountsBloc(r.accounts)..add(const AccountsStarted());
      final names = <String?>[];
      final sub = bloc.stream.listen((s) => names.add(s.duplicateName));
      bloc.add(AccountUnarchived(old));
      await pumpEventQueue();
      expect(names, contains('HBL'));
      await sub.cancel();
      await bloc.close();
    });
  });
}

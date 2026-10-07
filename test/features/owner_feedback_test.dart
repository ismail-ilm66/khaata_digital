import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/router/routes.dart';
import 'package:khaata_digital/core/widgets/amount_text.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/people/presentation/people_screen.dart';
import 'package:khaata_digital/features/security/domain/device_auth.dart';
import 'package:khaata_digital/features/security/presentation/lock_cubit.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';
import 'package:khaata_digital/features/transactions/presentation/widgets/entry_tile.dart';

import '../helpers/fake_device_auth.dart';
import '../helpers/test_app.dart';
import '../helpers/test_db.dart';
import '../helpers/ui.dart';

/// The owner's round of improvements after M7.
void main() {
  late AppDatabase db;
  late String cash;

  setUp(() async {
    db = await setUpTestApp();
    cash = (await db.accountsDao.balances()).single.account.id;
  });

  Future<void> start(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const KharchaApp());
    await t.pumpAndSettle();
  }

  bool masked(WidgetTester t, Key key) =>
      t.widget<AmountText>(find.byKey(key)).masked;

  group('balances', () {
    testWidgets('hidden by default, income / spent / left too', (t) async {
      expect(SettingKey.hideBalance.defaultValue, 'true');
      expect(getIt<HideBalanceCubit>().state, isTrue);
      await start(t);
      expect(masked(t, const Key('netWorth')), isTrue);
      await t.tap(find.byKey(const Key('summaryToggle')));
      await t.pumpAndSettle();
      final stats = t.widgetList<AmountText>(find.byType(AmountText));
      expect(
        stats.where((a) => !a.masked),
        isEmpty,
        reason: 'nothing on Home shows',
      );
    });

    testWidgets('with the lock on, showing asks for Face ID first', (t) async {
      (getIt<DeviceAuth>() as FakeDeviceAuth).kind = BiometricKind.face;
      await t.runAsync(() async {
        final lock = getIt<LockCubit>();
        await lock.load();
        await lock.setPin('2580');
        await lock.setBiometric(true, reason: 'on');
      });
      await start(t);
      await t.tap(find.byKey(const Key('hideBalance')));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pumpAndSettle();
      expect(getIt<HideBalanceCubit>().state, isFalse);
      expect(masked(t, const Key('netWorth')), isFalse);

      // Hiding again never asks.
      final asked = (getIt<DeviceAuth>() as FakeDeviceAuth).asked.length;
      await t.tap(find.byKey(const Key('hideBalance')));
      await t.pumpAndSettle();
      expect(getIt<HideBalanceCubit>().state, isTrue);
      expect((getIt<DeviceAuth>() as FakeDeviceAuth).asked, hasLength(asked));
    });

    testWidgets('without fingerprint / face it asks for the PIN', (t) async {
      (getIt<DeviceAuth>() as FakeDeviceAuth).kind = null;
      await t.runAsync(() async {
        final lock = getIt<LockCubit>();
        await lock.load();
        await lock.setPin('2580');
      });
      await start(t);
      await t.tap(find.byKey(const Key('hideBalance')));
      await t.pumpAndSettle();
      expect(find.text('Enter your current PIN'), findsOneWidget);
      Future<void> type(String pin) async {
        for (final d in pin.split('')) {
          await t.tap(find.byKey(Key('key-d$d')).last);
          await t.pump();
        }
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)),
        );
        await t.pumpAndSettle();
      }

      await type('1111');
      expect(getIt<HideBalanceCubit>().state, isTrue, reason: 'wrong PIN');
      await type('2580');
      expect(getIt<HideBalanceCubit>().state, isFalse);
    });
  });

  testWidgets('swiping to delete asks; Cancel keeps the entry', (t) async {
    await t.runAsync(() => TestLedger(db).expense(cash, 5000));
    await start(t);
    await t.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('Transactions'),
      ),
    );
    await t.pumpAndSettle();
    await t.drag(find.byType(EntryTile), const Offset(-600, 0));
    await t.pumpAndSettle();
    expect(find.text('Delete this entry?'), findsOneWidget);
    await t.tap(find.byKey(const Key('cancelAction')));
    await t.pumpAndSettle();
    expect(find.byType(EntryTile), findsOneWidget);
  });

  testWidgets('Home: accounts sit right below the main card', (t) async {
    await start(t);
    final accounts = t.getTopLeft(find.text('Accounts')).dy;
    final budgets = t.getTopLeft(find.text('Budgets')).dy;
    expect(accounts, lessThan(budgets));
  });

  group('People tabs', () {
    late String ali;
    late String sara;
    late String zain;

    setUp(() async {
      final l = TestLedger(db);
      ali = await db.peopleDao.create(name: 'Ali');
      sara = await db.peopleDao.create(name: 'Sara');
      zain = await db.peopleDao.create(name: 'Zain');
      await db.peopleDao.create(name: 'Hamza'); // settled (nothing)
      await l.expense(cash, 500000, personId: ali); // Ali owes 5,000
      await l.expense(cash, 120000, personId: zain); // Zain owes 1,200
      await l.income(cash, 300000, personId: sara); // I owe Sara 3,000
    });

    List<String> listed(WidgetTester t) => [
      for (final e in find.byType(PersonTile).evaluate())
        (e.widget as PersonTile).summary.person.name,
    ];

    testWidgets('Home totals open their own tab', (t) async {
      await start(t);
      await revealAndTap(t, find.byKey(const Key('payable')));
      expect(listed(t), ['Sara']);
      t.element(find.byType(PeopleScreen)).pop();
      await t.pumpAndSettle();
      await revealAndTap(t, find.byKey(const Key('receivable')));
      expect(listed(t), ['Ali', 'Zain'], reason: 'largest first');
    });

    testWidgets('settled tab, search and sort', (t) async {
      await start(t);
      unawaited(
        t.element(find.byType(GlassNavBar)).push(Routes.peopleTab('settled')),
      );
      await t.pumpAndSettle();
      expect(listed(t), ['Hamza']);

      await t.tap(find.text("You'll receive"));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('peopleSearch')), 'zai');
      await t.pumpAndSettle();
      expect(listed(t), ['Zain']);
      await t.enterText(find.byKey(const Key('peopleSearch')), '');
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('peopleSort')));
      await t.pumpAndSettle();
      await t.tap(find.text('Smallest first'));
      await t.pumpAndSettle();
      expect(listed(t), ['Zain', 'Ali']);
    });
  });

  group('Home: this month', () {
    testWidgets('folded until the chevron is tapped', (t) async {
      await start(t);
      expect(find.byKey(const Key('statSpent')), findsNothing);
      expect(find.byKey(const Key('previousPeriod')), findsNothing);
      await t.tap(find.byKey(const Key('summaryToggle')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('statSpent')), findsOneWidget);
      expect(find.byKey(const Key('previousPeriod')), findsOneWidget);
      await t.tap(find.byKey(const Key('summaryToggle')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('statSpent')), findsNothing);
    });

    testWidgets('Left has an ⓘ explaining it is not money in accounts', (
      t,
    ) async {
      await start(t);
      await t.tap(find.byKey(const Key('summaryToggle')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('info-Left')));
      await t.pumpAndSettle();
      expect(find.text('What “Left” means'), findsOneWidget);
      expect(
        find.textContaining('isn’t the money in your accounts'),
        findsOneWidget,
      );
      expect(find.byType(EntryTile), findsNothing, reason: 'ⓘ, not the list');
      await t.tap(find.byKey(const Key('infoDone')));
      await t.pumpAndSettle();
      expect(find.text('What “Left” means'), findsNothing);
    });

    testWidgets('Spent / Income / Left open the entries behind them', (
      t,
    ) async {
      final now = DateTime.now().toUtc();
      await t.runAsync(() async {
        final l = TestLedger(db);
        final ali = await db.peopleDao.create(name: 'Ali');
        final food = (await db.categoriesDao.active())
            .firstWhere((c) => c.name == 'Food & Drink')
            .id;
        await l.expense(cash, 120000, categoryId: food, at: now);
        await l.expense(cash, 50000, personId: ali, at: now); // udhaar
        await l.income(cash, 9000000, at: now);
        await l.expense(
          cash,
          70000,
          categoryId: food,
          at: now.subtract(const Duration(days: 400)),
        );
      });
      await start(t);
      await t.tap(find.byKey(const Key('summaryToggle')));
      await t.pumpAndSettle();

      Future<int> rowsFor(Key stat) async {
        await t.tap(find.byKey(stat));
        await t.pumpAndSettle();
        final n = find.byType(EntryTile).evaluate().length;
        t.element(find.byType(EntryTile).first).pop();
        await t.pumpAndSettle();
        return n;
      }

      expect(
        await rowsFor(const Key('statSpent')),
        1,
        reason:
            'no udhaar, '
            'nothing from another month',
      );
      expect(await rowsFor(const Key('statIncome')), 1);
      expect(await rowsFor(const Key('statLeft')), 2);
    });
  });

  testWidgets('Accounts: every balance sits on the same right edge', (t) async {
    await t.runAsync(() async {
      final l = TestLedger(db);
      await l.account('Meezan Bank', opening: 25755000);
      await l.account('JazzCash', opening: 1000);
    });
    await getIt<HideBalanceCubit>().set(false);
    await start(t);
    unawaited(t.element(find.byType(GlassNavBar)).push(Routes.accounts));
    await t.pumpAndSettle();
    final rights = {
      for (final name in ['Cash', 'Meezan Bank', 'JazzCash'])
        t
            .getRect(
              find.descendant(
                of: find.ancestor(
                  of: find.text(name),
                  matching: find.byType(InkWell),
                ),
                matching: find.byType(AmountText),
              ),
            )
            .right
            .round(),
    };
    expect(rights, hasLength(1), reason: 'right edges: $rights');
  });
}

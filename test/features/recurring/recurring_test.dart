import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/recurrence.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/recurring/data/recurring_maintenance.dart';
import 'package:khaata_digital/features/recurring/data/recurring_repository_impl.dart';
import 'package:khaata_digital/features/recurring/data/reminders.dart';
import 'package:khaata_digital/features/recurring/domain/recurrence.dart';
import 'package:khaata_digital/features/recurring/domain/recurring_rule.dart';
import 'package:khaata_digital/features/transactions/domain/entry_query.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

import '../../helpers/fake_reminders.dart';
import '../../helpers/test_repos.dart';

void main() {
  late TestRepos r;
  late RecurringRepositoryImpl repo;
  late String cash;
  late String bills;

  setUp(() async {
    r = TestRepos();
    repo = RecurringRepositoryImpl(r.db, r.transactions);
    cash = await r.cashId();
    bills = await r.categoryId('Bills & Utilities');
  });
  tearDown(() => r.close());

  EntryDraft rent(DateTime local) => EntryDraft(
    type: TransactionType.expense,
    amount: Money.major(45000, Currency.pkr),
    accountId: cash,
    categoryId: bills,
    occurredAt: local.toUtc(),
    note: 'Rent',
    tags: const ['home'],
  );

  Future<List<DateTime>> entryDates() async => [
    for (final v
        in (await r.transactions.watch(const EntryQuery()).first).items)
      v.entry.occurredAt.toLocal(),
  ]..sort();

  test(
    'a rule on the 31st materialises clamped dates (M3 acceptance)',
    () async {
      final first = rent(DateTime(2026, 1, 31, 9));
      await r.transactions.save(first);
      await repo.create(first, RecurrenceFrequency.monthly);

      final created = await repo.materializeDue(DateTime(2026, 6, 1));
      expect(created, 4);
      expect(await entryDates(), [
        DateTime(2026, 1, 31, 9),
        DateTime(2026, 2, 28, 9),
        DateTime(2026, 3, 31, 9),
        DateTime(2026, 4, 30, 9),
        DateTime(2026, 5, 31, 9),
      ]);
      expect((await repo.active()).single.nextRunAt, DateTime(2026, 6, 30, 9));
    },
  );

  test('materialising twice never duplicates', () async {
    final first = rent(DateTime(2026, 1, 31, 9));
    await r.transactions.save(first);
    await repo.create(first, RecurrenceFrequency.monthly);
    await repo.materializeDue(DateTime(2026, 3, 5));
    expect(await repo.materializeDue(DateTime(2026, 3, 5)), 0);
    expect(await entryDates(), [
      DateTime(2026, 1, 31, 9),
      DateTime(2026, 2, 28, 9),
    ], reason: '31 Mar is not due yet');
  });

  test('occurrences copy the template: amount, category, note, tags', () async {
    final first = rent(DateTime(2026, 9, 1, 10));
    await r.transactions.save(first);
    await repo.create(first, RecurrenceFrequency.weekly);
    await repo.materializeDue(DateTime(2026, 9, 8, 12));

    final latest = (await r.transactions.watch(const EntryQuery()).first)
        .items
        .first
        .entry;
    expect(latest.occurredAt.toLocal(), DateTime(2026, 9, 8, 10));
    expect(latest.amount, Money.major(45000, Currency.pkr));
    expect(latest.categoryId, bills);
    expect(latest.note, 'Rent');
    expect(latest.tags, ['home']);
  });

  test('stopping a rule keeps past entries and creates no more', () async {
    final first = rent(DateTime(2026, 1, 10));
    await r.transactions.save(first);
    final id = await repo.create(first, RecurrenceFrequency.monthly);
    await repo.materializeDue(DateTime(2026, 2, 11));
    await repo.delete(id);
    expect(await repo.materializeDue(DateTime(2026, 12, 31)), 0);
    expect(await entryDates(), hasLength(2));
    expect(await repo.watchAll().first, isEmpty);
  });

  test('a broken rule is skipped without blocking others', () async {
    final good = rent(DateTime(2026, 1, 5));
    await r.transactions.save(good);
    await repo.create(good, RecurrenceFrequency.monthly);
    final broken = EntryDraft(
      type: TransactionType.transfer, // transfer to nowhere: invalid
      amount: Money.major(1, Currency.pkr),
      accountId: cash,
      occurredAt: DateTime(2026, 1, 5).toUtc(),
    );
    await repo.create(broken, RecurrenceFrequency.monthly);

    expect(await repo.materializeDue(DateTime(2026, 2, 6)), 1);
  });

  test('template JSON round-trips', () {
    final t = EntryTemplate.fromDraft(rent(DateTime(2026, 1, 31)));
    final json = TemplateCodec.encode(
      t,
      DateTime(2026, 1, 31, 9),
      remind: true,
    );
    final back = TemplateCodec.decode(json);
    expect(back.template, t);
    expect(back.start, DateTime(2026, 1, 31, 9));
    expect(back.remind, isTrue);
  });

  test('watchAll lists rules with names, soonest first', () async {
    final a = rent(DateTime(2026, 9, 1));
    await repo.create(a, RecurrenceFrequency.monthly, remind: true);
    final views = await repo.watchAll().first;
    expect(views.single.accountName, 'Cash');
    expect(views.single.categoryName, 'Bills & Utilities');
    expect(views.single.rule.remind, isTrue);
  });

  group('reminders', () {
    RecurringRule rule({required DateTime next, bool remind = true}) =>
        RecurringRule(
          id: 'r1',
          template: EntryTemplate.fromDraft(rent(next)),
          schedule: RecurrenceSchedule(
            start: next,
            frequency: RecurrenceFrequency.monthly,
          ),
          nextRunAt: next,
          remind: remind,
        );

    test('fire at 9 am on the due day', () {
      expect(
        reminderTimeFor(
          rule(next: DateTime(2026, 10, 25, 18)),
          DateTime(2026, 10, 6),
        ),
        DateTime(2026, 10, 25, 9),
      );
    });

    test('fire a minute from now when the due morning has passed', () {
      expect(
        reminderTimeFor(
          rule(next: DateTime(2026, 10, 6, 18)),
          DateTime(2026, 10, 6, 12),
        ),
        DateTime(2026, 10, 6, 12, 1),
      );
    });

    test('nothing when off, or when the occurrence has passed', () {
      expect(
        reminderTimeFor(
          rule(next: DateTime(2026, 10, 25), remind: false),
          DateTime(2026, 10, 6),
        ),
        isNull,
      );
      expect(
        reminderTimeFor(
          rule(next: DateTime(2026, 10, 1)),
          DateTime(2026, 10, 6),
        ),
        isNull,
      );
    });

    test(
      'maintenance materialises, then syncs reminders for active rules',
      () async {
        final first = rent(DateTime(2026, 1, 31, 9));
        await r.transactions.save(first);
        await repo.create(first, RecurrenceFrequency.monthly, remind: true);
        final scheduler = FakeReminderScheduler();

        final created = await runRecurringMaintenance(
          repo,
          scheduler,
          now: DateTime(2026, 3, 1),
        );
        expect(created, 1);
        expect(scheduler.last.single.nextRunAt, DateTime(2026, 3, 31, 9));
        expect(scheduler.last.single.remind, isTrue);
      },
    );
  });
}

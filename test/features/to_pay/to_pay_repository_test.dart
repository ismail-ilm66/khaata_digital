import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/dates/calendar_day.dart';
import 'package:khaata_digital/core/error/app_failure.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/to_pay/domain/planned_payment.dart';

import '../../helpers/test_repos.dart';

void main() {
  late TestRepos r;
  setUp(() => r = TestRepos());
  tearDown(() => r.close());

  Money rs(int n) => Money.major(n, Currency.pkr);
  PlannedPaymentDraft draft(String title, int n, {CalendarDay? due}) =>
      PlannedPaymentDraft(title: title, amount: rs(n), dueOn: due);

  test(
    'open items: dated soonest first, undated after, in order added',
    () async {
      await r.toPay.add(draft('Charity', 2400));
      await r.toPay.add(
        draft('Fee', 15000, due: const CalendarDay(2026, 10, 20)),
      );
      await r.toPay.add(
        draft('Gift', 3000, due: const CalendarDay(2026, 10, 9)),
      );
      await r.toPay.add(draft('Books', 900));

      final open = await r.toPay.watchOpen().first;
      expect(open.map((p) => p.title), ['Gift', 'Fee', 'Charity', 'Books']);
      expect(PlannedPayment.totals(open), {Currency.pkr: rs(21300)});
    },
  );

  test(
    'paid leaves the list (linked to its entry); unpaid brings it back',
    () async {
      final id = await r.toPay.add(draft('Charity', 2400));
      final entry = await r.ledger.expense(await r.cashId(), 240000);
      await r.toPay.markPaid(id, transactionId: entry);

      expect(await r.toPay.watchOpen().first, isEmpty);
      final paid = (await r.toPay.watchPaid().first).single;
      expect(paid.isPaid, isTrue);
      expect(paid.transactionId, entry);

      await r.toPay.markUnpaid(id);
      final back = (await r.toPay.watchOpen().first).single;
      expect(back.transactionId, isNull);
      expect(await r.toPay.watchPaid().first, isEmpty);
    },
  );

  test('edit, delete, and nothing empty or zero', () async {
    final id = await r.toPay.add(draft('Charity', 2400));
    await r.toPay.update(id, draft('  Sadqa ', 2500));
    expect((await r.toPay.watchOpen().first).single.title, 'Sadqa');
    await r.toPay.remove(id);
    expect(await r.toPay.watchOpen().first, isEmpty);

    expect(
      () => r.toPay.add(draft(' ', 100)),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => r.toPay.add(draft('Zero', 0)),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('due status against today', () {
    const today = CalendarDay(2026, 10, 13);
    PlannedPayment on(CalendarDay? d) =>
        PlannedPayment(id: 'x', title: 't', amount: rs(1), dueOn: d);
    expect(on(null).statusOn(today), DueStatus.noDate);
    expect(
      on(const CalendarDay(2026, 10, 12)).statusOn(today),
      DueStatus.overdue,
    );
    expect(on(today).statusOn(today), DueStatus.today);
    expect(
      on(const CalendarDay(2026, 11, 1)).statusOn(today),
      DueStatus.upcoming,
    );
  });
}

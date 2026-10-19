import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/features/transactions/domain/bill_split.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';

const pkr = Currency.pkr;
Money rs(int rupees) => Money.major(rupees, pkr);

void main() {
  group('evenSplit', () {
    test('equal parts when it divides', () {
      expect(evenSplit(rs(3000), 4), [rs(750), rs(750), rs(750), rs(750)]);
    });

    test('a whole-rupee bill splits in whole rupees, extra to the first', () {
      expect(evenSplit(rs(1000), 3), [rs(334), rs(333), rs(333)]);
    });

    test('a bill with paisa splits to the paisa', () {
      expect(evenSplit(const Money(100001, pkr), 2), [
        const Money(50001, pkr),
        const Money(50000, pkr),
      ]);
    });

    test('always adds back up to the bill', () {
      for (final ways in [1, 2, 3, 7, 11]) {
        final parts = evenSplit(const Money(123457, pkr), ways);
        expect(Money.sum(parts, pkr), const Money(123457, pkr));
      }
    });
  });

  test('sharesAddUp needs the exact total, nothing negative, not all zero', () {
    expect(
      sharesAddUp(rs(300), [
        SplitShare(null, rs(100)),
        SplitShare('a', rs(200)),
      ]),
      isTrue,
    );
    expect(
      sharesAddUp(rs(300), [
        SplitShare(null, rs(100)),
        SplitShare('a', rs(100)),
      ]),
      isFalse,
    );
    expect(
      sharesAddUp(rs(300), [
        SplitShare(null, rs(-100)),
        SplitShare('a', rs(400)),
      ]),
      isFalse,
    );
    expect(
      sharesAddUp(rs(300), [
        SplitShare(null, Money.zero(pkr)),
        SplitShare('a', rs(300)),
      ]),
      isTrue,
    );
  });

  group('splitDrafts', () {
    final bill = EntryDraft(
      type: TransactionType.expense,
      amount: rs(3000),
      occurredAt: DateTime.utc(2026, 10, 19, 12),
      accountId: 'cash',
      categoryId: 'food',
      note: 'Dinner',
      tags: const ['friends'],
      newReceiptPaths: const ['bill.jpg'],
    );

    test('people as udhaar given, then mine as the expense', () {
      final drafts = splitDrafts(bill, [
        SplitShare(null, rs(1000)),
        SplitShare('ali', rs(1200)),
        SplitShare('sara', rs(800)),
      ]);
      expect(drafts.map((d) => (d.personId, d.categoryId, d.amount)), [
        ('ali', null, rs(1200)),
        ('sara', null, rs(800)),
        (null, 'food', rs(1000)),
      ]);
      for (final d in drafts) {
        expect(d.type, TransactionType.expense);
        expect(d.accountId, 'cash');
        expect(d.note, 'Dinner');
        expect(d.tags, ['friends']);
        expect(d.occurredAt, bill.occurredAt);
      }
      expect(
        drafts.map((d) => d.newReceiptPaths),
        [
          isEmpty,
          isEmpty,
          ['bill.jpg'],
        ],
        reason: 'receipts once, on the last entry',
      );
    });

    test('zero shares are left out', () {
      final drafts = splitDrafts(bill, [
        SplitShare(null, Money.zero(pkr)),
        SplitShare('ali', rs(3000)),
      ]);
      expect(drafts.single.personId, 'ali');
      expect(drafts.single.newReceiptPaths, ['bill.jpg']);
    });
  });
}

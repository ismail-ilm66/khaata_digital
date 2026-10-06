import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/theme/app_colors.dart';
import 'package:khaata_digital/core/theme/app_theme.dart';
import 'package:khaata_digital/core/widgets/amount_text.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:khaata_digital/features/transactions/presentation/widgets/entry_tile.dart';

void main() {
  LedgerEntry entry(TransactionType type) => LedgerEntry(
    id: 'x',
    type: type,
    amount: Money.major(500, Currency.pkr),
    accountId: 'a',
    toAccountId: type == TransactionType.transfer ? 'b' : null,
    occurredAt: DateTime.utc(2026),
  );

  Future<(String, Color?)> render(WidgetTester t, TransactionType type) async {
    await t.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: EntryAmount(entry(type))),
    );
    final span =
        t
                .widget<Text>(
                  find.descendant(
                    of: find.byType(AmountText),
                    matching: find.byType(Text),
                  ),
                )
                .textSpan!
            as TextSpan;
    final number = span.children!.last as TextSpan;
    return (span.toPlainText(), number.style!.color);
  }

  testWidgets('expense: minus, ink', (t) async {
    final (text, color) = await render(t, TransactionType.expense);
    expect(text, startsWith('−'));
    expect(color, AppColors.light.ink);
  });

  testWidgets('income: plus, green', (t) async {
    final (text, color) = await render(t, TransactionType.income);
    expect(text, startsWith('+'));
    expect(color, AppColors.light.income);
  });

  testWidgets('transfer: unsigned and neutral, never income-green', (t) async {
    final (text, color) = await render(t, TransactionType.transfer);
    expect(text, startsWith('Rs'));
    expect(color, AppColors.light.ink);
  });
}

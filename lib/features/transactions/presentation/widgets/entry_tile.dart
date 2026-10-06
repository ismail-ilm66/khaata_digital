import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/context_x.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/tinted_badge.dart';
import '../../../categories/presentation/category_badge.dart';
import '../../../people/presentation/person_badge.dart';
import '../../domain/ledger_entry.dart';
import '../../domain/transaction_type.dart';

/// One transaction in a list: badge, what it was, where from, and amount.
class EntryTile extends StatelessWidget {
  const EntryTile(this.view, {super.key, this.onTap});

  final EntryView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final e = view.entry;
    final c = context.colors;
    final transfer = e.type == TransactionType.transfer;

    final udhaar = view.isUdhaar;
    final title = transfer
        ? '${view.accountName} → ${view.toAccountName ?? '—'}'
        : udhaar
        ? view.personName ?? context.l10n.person
        : context.categoryName(view.category);
    final subtitle = [
      if (udhaar)
        e.type == TransactionType.income
            ? context.l10n.iReceived
            : context.l10n.iGave,
      if (e.note.isNotEmpty) e.note,
      if (!transfer) view.accountName,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Row(
          children: [
            transfer
                ? TintedBadge(icon: AppIcons.transfer, size: 40)
                : udhaar
                ? PersonBadge(view.personName ?? '?')
                : CategoryBadge(view.category),
            const SizedBox(width: kBadgeGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  if (subtitle.isNotEmpty || e.attachments.isNotEmpty)
                    Row(
                      children: [
                        if (e.attachments.isNotEmpty) ...[
                          Icon(AppIcons.receipt, size: 13, color: c.inkMuted),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            EntryAmount(e, style: context.text.titleSmall),
          ],
        ),
      ),
    );
  }
}

/// An entry's amount styled by what it does to "my money": expenses in ink
/// with a minus, income green with a plus. Transfers (between my own
/// accounts) and udhaar (a loan, not income) are never income-green.
class EntryAmount extends StatelessWidget {
  const EntryAmount(this.entry, {super.key, this.style});

  final LedgerEntry entry;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final neutral =
        entry.type == TransactionType.transfer || entry.personId != null;
    return AmountText(
      entry.signedAmount,
      signed: entry.type == TransactionType.income,
      colored: !neutral,
      style: style,
    );
  }
}

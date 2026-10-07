import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/money/fixed_point.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../../categories/presentation/category_badge.dart';
import '../domain/ledger_entry.dart';
import '../domain/transaction_type.dart';
import '../domain/transactions_repository.dart';
import 'form/entry_editor_screen.dart';
import 'widgets/entry_tile.dart';
import 'widgets/receipts.dart';
import '../../../core/widgets/watch.dart';
import '../../../core/widgets/app_sheet.dart';

/// One transaction in full, with its receipts (spec 3.2 #4 "tap → detail").
class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Watch<EntryView?>(
      () => getIt<TransactionsRepository>().watchOne(id),
      sourceKey: id,
      builder: (context, view) {
        if (view == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _Detail(view);
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.view);

  final EntryView view;

  Future<void> _delete(BuildContext context) async {
    final repo = getIt<TransactionsRepository>();
    final id = view.entry.id;
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final sure = await confirmSheet(
      context,
      title: l.deleteEntryTitle,
      message: l.deleteEntryBody,
      confirmLabel: l.delete,
    );
    if (!sure || !context.mounted) return;
    Navigator.pop(context);
    await repo.delete(id);
    messenger.undo(
      message: l.deleted,
      undoLabel: l.undo,
      onUndo: () => repo.restore(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = view.entry;
    final l = context.l10n;
    final c = context.colors;
    final transfer = e.type == TransactionType.transfer;
    final receipts = [for (final a in e.attachments) ReceiptRef.stored(a)];

    return PageScaffold(
      title: transfer
          ? l.transferTitle
          : view.isUdhaar
          ? view.personName ?? l.person
          : context.categoryName(view.category),
      subtitle: context.longDateTime(e.occurredAt.toLocal()),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          sliver: SliverList.list(
            children: [
              SurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Column(
                    children: [
                      transfer
                          ? TintedBadge(icon: AppIcons.transfer, size: 56)
                          : CategoryBadge(view.category, size: 56),
                      const SizedBox(height: AppSpacing.m),
                      EntryAmount(e, style: context.text.displaySmall),
                      if (e.toAmount != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AmountText(
                          e.toAmount!,
                          style: context.text.titleMedium!.copyWith(
                            color: c.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              SurfaceCard(
                children: [
                  InfoTile(
                    icon: transfer
                        ? AppIcons.transfer
                        : AppIcons.accounts.filled,
                    label: transfer
                        ? '${l.fromAccount} → ${l.toAccount}'
                        : l.account,
                    value: Text(
                      transfer
                          ? '${view.accountName} → ${view.toAccountName}'
                          : view.accountName,
                    ),
                  ),
                  if (e.fxRateMicros != null)
                    InfoTile(
                      icon: AppIcons.transfer,
                      label: l.exchangeRate,
                      value: Text(
                        l.rateLabel(
                          e.amount.currency.code,
                          FixedPoint.format(
                            e.fxRateMicros!,
                            Money.rateScale,
                          ).replaceFirst(RegExp(r'\.?0+$'), ''),
                          e.toAmount?.currency.code ?? '',
                        ),
                        style: TextStyle(fontFeatures: AppTypography.tabular),
                      ),
                    ),
                  if (e.note.isNotEmpty)
                    InfoTile(
                      icon: AppIcons.note,
                      label: l.note,
                      value: Text(e.note),
                    ),
                  if (e.tags.isNotEmpty)
                    InfoTile(
                      icon: AppIcons.tag,
                      label: l.tags,
                      value: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final t in e.tags)
                            Chip(
                              label: Text(t),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              if (receipts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.l),
                Section(
                  title: l.receipts,
                  child: ReceiptStrip(receipts: receipts),
                ),
              ],
              const SizedBox(height: AppSpacing.l),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const Key('editEntry'),
                      onPressed: () => EntryEditor.open(context, editId: e.id),
                      icon: const Icon(AppIcons.edit, size: 18),
                      label: Text(l.edit),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  TextButton.icon(
                    key: const Key('deleteEntry'),
                    style: TextButton.styleFrom(foregroundColor: c.danger),
                    onPressed: () => _delete(context),
                    icon: const Icon(AppIcons.delete, size: 18),
                    label: Text(l.delete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/feedback/haptics.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_format.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/pill_button.dart';
import '../domain/person.dart';

/// What the write-off sheet decided.
sealed class WriteOffSheetResult {
  const WriteOffSheetResult();
}

/// [amount] is positive, as typed; the direction is the sheet's.
final class WriteOffSaved extends WriteOffSheetResult {
  const WriteOffSaved(this.amount, this.occurredAt, this.note);
  final Money amount;
  final DateTime occurredAt;
  final String note;
}

final class WriteOffDeleted extends WriteOffSheetResult {
  const WriteOffDeleted();
}

/// Write off what [personName] owes (or, [forgiven], mark what I owe them
/// as let go), up to [max], which it starts at. With [existing], edits it
/// or deletes it. No account is touched either way.
Future<WriteOffSheetResult?> showWriteOffSheet(
  BuildContext context, {
  required String personName,
  required Money max,
  required bool forgiven,
  WriteOff? existing,
}) {
  final l = context.l10n;
  return showAppSheet<WriteOffSheetResult>(
    context,
    title: forgiven
        ? (existing == null ? l.theyLetItGo : l.forgiven)
        : (existing == null ? l.writeOff : l.writtenOff),
    builder: (_) => _WriteOffSheet(
      personName: personName,
      max: max,
      forgiven: forgiven,
      existing: existing,
    ),
  );
}

class _WriteOffSheet extends StatefulWidget {
  const _WriteOffSheet({
    required this.personName,
    required this.max,
    required this.forgiven,
    this.existing,
  });

  final String personName;
  final Money max;
  final bool forgiven;
  final WriteOff? existing;

  @override
  State<_WriteOffSheet> createState() => _WriteOffSheetState();
}

class _WriteOffSheetState extends State<_WriteOffSheet> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: AmountField.textOf((widget.existing?.amount ?? widget.max).abs()),
  );
  late final _note = TextEditingController(text: widget.existing?.note);

  /// The local day and time it happened; changing the day keeps the time.
  late DateTime _at = widget.existing?.occurredAt.toLocal() ?? DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _moveTo(DateTime day) {
    Haptics.selection();
    setState(
      () => _at = DateTime(day.year, day.month, day.day, _at.hour, _at.minute),
    );
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) _moveTo(picked);
  }

  void _save() {
    final amount = AmountField.read(_amount, widget.max.currency);
    if (!_form.currentState!.validate() ||
        amount == null ||
        !amount.isPositive) {
      return;
    }
    Navigator.pop(context, WriteOffSaved(amount, _at, _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final money = const MoneyFormat();
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = DateUtils.addDaysToDate(today, -1);
    final day = DateUtils.dateOnly(_at);
    final other = day != today && day != yesterday;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.forgiven
                  ? l.forgiveBody(widget.personName)
                  : l.writeOffBody(widget.personName),
              style: context.text.bodyMedium!.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AppSpacing.l),
            AmountField(
              key: const Key('writeOffAmount'),
              controller: _amount,
              currency: widget.max.currency,
              label: l.amountLabel,
              invalidMessage: l.invalidAmount,
              validator: (m) => m > widget.max
                  ? l.writeOffTooMuch(money.format(widget.max))
                  : null,
            ),
            if (widget.existing == null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l.writeOffWhole, style: context.text.bodySmall),
            ],
            const SizedBox(height: AppSpacing.m),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                PillButton(
                  key: const Key('writeOffToday'),
                  label: l.today,
                  selected: day == today,
                  onTap: () => _moveTo(today),
                ),
                PillButton(
                  key: const Key('writeOffYesterday'),
                  label: l.yesterday,
                  selected: day == yesterday,
                  onTap: () => _moveTo(yesterday),
                ),
                PillButton(
                  key: const Key('writeOffDay'),
                  icon: AppIcons.calendar,
                  label: other ? context.shortDate(day) : l.pickDay,
                  selected: other,
                  onTap: _pickDay,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              key: const Key('writeOffNote'),
              controller: _note,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l.notePlaceholder,
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.lock, size: 16, color: c.inkMuted),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    widget.forgiven
                        ? l.forgiveNoAccounts
                        : l.writeOffNoAccounts(widget.personName),
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            FilledButton(
              key: const Key('writeOffSave'),
              onPressed: _save,
              // Says what will happen, with the amount as it's typed.
              child: ValueListenableBuilder(
                valueListenable: _amount,
                builder: (context, _, _) {
                  if (widget.existing != null) return Text(l.save);
                  final m = AmountField.read(_amount, widget.max.currency);
                  if (m == null || !m.isPositive) {
                    return Text(widget.forgiven ? l.theyLetItGo : l.writeOff);
                  }
                  final amount = money.format(m);
                  return Text(
                    widget.forgiven
                        ? l.forgiveAction(amount)
                        : l.writeOffAction(amount),
                  );
                },
              ),
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: AppSpacing.s),
              TextButton(
                key: const Key('writeOffDelete'),
                style: TextButton.styleFrom(foregroundColor: c.danger),
                onPressed: () =>
                    Navigator.pop(context, const WriteOffDeleted()),
                child: Text(l.delete),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

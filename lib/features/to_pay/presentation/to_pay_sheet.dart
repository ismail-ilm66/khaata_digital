import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/dates/calendar_day.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/money/fixed_point.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/pill_button.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_badge.dart';
import '../../categories/presentation/category_grid.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../domain/planned_payment.dart';

/// What the add / edit sheet decided.
sealed class ToPaySheetResult {
  const ToPaySheetResult();
}

final class ToPaySaved extends ToPaySheetResult {
  const ToPaySaved(this.draft);
  final PlannedPaymentDraft draft;
}

/// Paid outside Kharcha, or already recorded: off the list, no entry.
final class ToPayMarkedPaid extends ToPaySheetResult {
  const ToPayMarkedPaid();
}

final class ToPayDeleted extends ToPaySheetResult {
  const ToPayDeleted();
}

/// Add (or, with [existing], edit) something to pay: what for, how much,
/// and optionally when and under which category it'll be recorded.
Future<ToPaySheetResult?> showToPaySheet(
  BuildContext context, {
  required List<Category> categories,
  PlannedPayment? existing,
}) => showAppSheet<ToPaySheetResult>(
  context,
  title: existing == null ? context.l10n.addToPay : context.l10n.editToPay,
  builder: (_) => _ToPaySheet(categories: categories, existing: existing),
);

class _ToPaySheet extends StatefulWidget {
  const _ToPaySheet({required this.categories, this.existing});

  final List<Category> categories;
  final PlannedPayment? existing;

  @override
  State<_ToPaySheet> createState() => _ToPaySheetState();
}

class _ToPaySheetState extends State<_ToPaySheet> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : FixedPoint.format(
            widget.existing!.amount.minor,
            widget.existing!.amount.currency.decimals,
          ),
  );
  late final _note = TextEditingController(text: widget.existing?.note);
  late String? _categoryId = widget.existing?.categoryId;
  late CalendarDay? _due = widget.existing?.dueOn;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Category? get _category =>
      widget.categories.where((c) => c.id == _categoryId).firstOrNull;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due?.toLocal() ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _due = CalendarDay.of(picked));
  }

  void _save() {
    final currency =
        widget.existing?.amount.currency ?? context.read<CurrencyCubit>().state;
    final amount = AmountField.read(_amount, currency);
    if (!_form.currentState!.validate() ||
        amount == null ||
        !amount.isPositive) {
      return;
    }
    Navigator.pop(
      context,
      ToPaySaved(
        PlannedPaymentDraft(
          title: _title.text.trim(),
          amount: amount,
          categoryId: _categoryId,
          dueOn: _due,
          note: _note.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final currency =
        widget.existing?.amount.currency ??
        context.watch<CurrencyCubit>().state;
    final category = _category;
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
            TextFormField(
              key: const Key('toPayTitle'),
              controller: _title,
              autofocus: widget.existing == null,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.toPayWhat,
                hintText: l.toPayWhatHint,
                counterText: '',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.toPayWhatRequired : null,
            ),
            const SizedBox(height: AppSpacing.m),
            AmountField(
              key: const Key('toPayAmount'),
              controller: _amount,
              currency: currency,
              label: l.amountLabel,
              invalidMessage: l.invalidAmount,
            ),
            const SizedBox(height: AppSpacing.m),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                PillButton(
                  key: const Key('toPayDue'),
                  icon: AppIcons.calendar,
                  label: _due == null
                      ? l.noDueDate
                      : l.dueOn(context.dayLabel(_due!.toLocal())),
                  selected: _due != null,
                  showChevron: true,
                  onTap: _pickDate,
                ),
                if (_due != null)
                  PillButton(
                    key: const Key('toPayClearDue'),
                    icon: AppIcons.close,
                    label: l.clear,
                    onTap: () => setState(() => _due = null),
                  ),
                PillButton(
                  key: const Key('toPayCategory'),
                  leading: category == null
                      ? null
                      : CategoryBadge(category, size: 20),
                  icon: category == null ? AppIcons.tag : null,
                  label: category?.name ?? l.categoryLater,
                  selected: category != null,
                  showChevron: true,
                  onTap: () async {
                    final picked = await pickCategory(
                      context,
                      categories: widget.categories,
                      selectedId: _categoryId,
                    );
                    if (picked != null) {
                      setState(() => _categoryId = picked.id);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              key: const Key('toPayNote'),
              controller: _note,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l.notePlaceholder,
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            FilledButton(
              key: const Key('toPaySave'),
              onPressed: _save,
              child: Text(l.save),
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: AppSpacing.s),
              TextButton(
                key: const Key('toPayMarkPaid'),
                onPressed: () =>
                    Navigator.pop(context, const ToPayMarkedPaid()),
                child: Text(l.markPaidNoEntry),
              ),
              TextButton(
                key: const Key('toPayDelete'),
                style: TextButton.styleFrom(foregroundColor: c.danger),
                onPressed: () async {
                  final yes = await confirmSheet(
                    context,
                    title: l.deleteToPayTitle,
                    message: l.deleteToPayBody,
                    confirmLabel: l.delete,
                  );
                  if (yes && context.mounted) {
                    Navigator.pop(context, const ToPayDeleted());
                  }
                },
                child: Text(l.delete),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

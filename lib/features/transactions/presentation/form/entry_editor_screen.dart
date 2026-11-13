import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/l10n/date_labels.dart';
import '../../../../core/money/amount_buffer.dart';
import '../../../../core/money/fixed_point.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/context_x.dart';
import '../../../../core/widgets/ambient_background.dart';
import '../../../../core/widgets/amount_field.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/hero_amount_field.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/segmented_picker.dart';
import '../../../../core/widgets/tinted_badge.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/account_badge.dart';
import '../../../categories/presentation/category_grid.dart';
import '../../../people/domain/person.dart';
import '../../../people/presentation/person_badge.dart';
import '../../../recurring/domain/recurrence.dart';
import '../../../recurring/domain/recurring_rule.dart';
import '../../../recurring/presentation/recurring_screen.dart';
import '../../../to_pay/domain/planned_payment.dart';
import '../../domain/bill_split.dart';
import '../../domain/transaction_type.dart';
import '../widgets/receipts.dart';
import 'transaction_form_bloc.dart';
import '../../../../core/feedback/haptics.dart';

/// Opens the add / edit screen.
abstract final class EntryEditor {
  static Future<void> open(BuildContext context, {String? editId}) =>
      context.push(editId == null ? Routes.addEntry : Routes.editEntry(editId));

  /// Opens a new udhaar entry with [personId] (People screen actions).
  static Future<void> udhaar(
    BuildContext context, {
    required String personId,
    required UdhaarDirection direction,
    Money? amount,
  }) => context.push(
    Routes.addEntry,
    extra: EntryEditorArgs(
      udhaar: direction,
      personId: personId,
      amount: amount,
    ),
  );

  /// Pays an item on the To-pay list: an expense pre-filled with its
  /// amount, category and title; saving marks the item paid.
  static Future<void> pay(BuildContext context, PlannedPayment item) =>
      context.push(Routes.addEntry, extra: EntryEditorArgs(toPay: item));
}

/// Pre-fill for a new entry.
@immutable
class EntryEditorArgs {
  const EntryEditorArgs({this.udhaar, this.personId, this.amount, this.toPay});

  final UdhaarDirection? udhaar;
  final String? personId;
  final Money? amount;

  /// The To-pay item being paid.
  final PlannedPayment? toPay;
}

/// Add / edit a transaction on its own screen (spec 3.2 #3).
///
/// One job per area, top to bottom: what kind → how much → from which
/// account → for what → note → when → extras, with Save at the bottom
/// (under the keyboard while typing; a tap anywhere puts the keyboard
/// away). Amounts and the note use the phone's own keyboard.
class EntryEditorScreen extends StatelessWidget {
  const EntryEditorScreen({super.key, this.editId, this.args});

  final String? editId;
  final EntryEditorArgs? args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionFormBloc>()
        ..add(
          FormStarted(
            editId: editId,
            udhaar: args?.udhaar,
            personId: args?.personId,
            amount: args?.amount ?? args?.toPay?.amount,
            categoryId: args?.toPay?.categoryId,
            note: args?.toPay?.title,
            plannedPaymentId: args?.toPay?.id,
          ),
        ),
      child: const _Editor(),
    );
  }
}

class _Editor extends StatefulWidget {
  const _Editor();

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  @override
  void initState() {
    super.initState();
    // A new task starts clean: a lingering "Saved" toast would otherwise
    // sit over this screen's Save button.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Read above the Scaffold, which hides the keyboard from its body.
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        // A tap on any empty part of the screen puts the keyboard away;
        // fields do the same for taps on buttons and chips (onTapOutside).
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: AmbientBackground(
            child: SafeArea(
              child: BlocConsumer<TransactionFormBloc, TransactionFormState>(
                listenWhen: (a, b) =>
                    a.status != b.status ||
                    (b.problem != null && a.problem != b.problem),
                listener: (context, s) {
                  if (s.problem != null && s.status == FormStatus.ready) {
                    Haptics.warning();
                  } else if (s.status == FormStatus.saved) {
                    unawaited(Haptics.success());
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    messenger.toast(context.l10n.saved);
                  } else if (s.status == FormStatus.failed) {
                    Haptics.warning();
                    showToast(context, context.l10n.receiptFailed);
                  }
                },
                builder: (context, s) {
                  if (s.status == FormStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(state: s),
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.only(bottom: AppSpacing.l),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AmountHero(state: s, typing: typing),
                              if (s.isTransfer)
                                _TransferAccounts(state: s)
                              else
                                _AccountStrip(
                                  key: const Key('accountStrip'),
                                  label: s.type == TransactionType.income
                                      ? context.l10n.receivedIn
                                      : context.l10n.paidFrom,
                                  accounts: s.accountsByUse,
                                  selectedId: s.accountId,
                                  onSelected: (id) => context
                                      .read<TransactionFormBloc>()
                                      .add(AccountChanged(id)),
                                ),
                              const SizedBox(height: AppSpacing.l),
                              if (s.isUdhaar)
                                _UdhaarSection(state: s)
                              else if (!s.isTransfer) ...[
                                _FieldLabel(context.l10n.category),
                                _QuickCategories(state: s),
                              ],
                              const SizedBox(height: AppSpacing.l),
                              _NoteField(state: s),
                              const SizedBox(height: AppSpacing.l),
                              _WhenSection(state: s),
                              const SizedBox(height: AppSpacing.l),
                              _AddMore(state: s),
                            ],
                          ),
                        ),
                      ),
                      // Under the keyboard, not riding on top of it: back
                      // at the bottom once the keyboard is put away.
                      if (!typing) _SaveButton(state: s),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the editor is recording; udhaar is a mode over expense/income.
enum _Mode {
  expense(TransactionType.expense),
  income(TransactionType.income),
  transfer(TransactionType.transfer),
  udhaar(null);

  const _Mode(this.type);
  final TransactionType? type;

  static _Mode of(TransactionFormState s) => s.isUdhaar
      ? udhaar
      : switch (s.type) {
          TransactionType.income => income,
          TransactionType.transfer => transfer,
          _ => expense,
        };
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s,
        AppSpacing.s,
        AppSpacing.l,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('closeEditor'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(AppIcons.close),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SegmentedPicker<_Mode>(
              key: const Key('typePicker'),
              value: _Mode.of(state),
              onChanged: (m) => context.read<TransactionFormBloc>().add(
                m == _Mode.udhaar ? const UdhaarChosen() : TypeChanged(m.type!),
              ),
              options: [
                PickerOption(_Mode.expense, l.typeExpense),
                PickerOption(_Mode.income, l.typeIncome),
                PickerOption(_Mode.transfer, l.typeTransfer),
                PickerOption(_Mode.udhaar, l.typeUdhaar),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The amount, front and centre, typed with the phone's number pad. A new
/// entry opens with the pad up; editing waits for a tap.
class _AmountHero extends StatelessWidget {
  const _AmountHero({required this.state, required this.typing});

  final TransactionFormState state;

  /// The keyboard is up: tighter, so accounts and categories still show.
  final bool typing;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TransactionFormBloc>();
    return AnimatedPadding(
      duration: AppMotion.base,
      curve: AppMotion.out,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        typing ? AppSpacing.s : AppSpacing.xl,
        AppSpacing.l,
        typing ? AppSpacing.l : AppSpacing.xl,
      ),
      child: Column(
        children: [
          HeroAmountField(
            fieldKey: const Key('amountField'),
            value: state.amount.text,
            currency: state.currency,
            fontSize: typing ? 46 : 56,
            autofocus: !state.isEditing && state.amount.isEmpty,
            onChanged: (text) => bloc.add(AmountTyped(text)),
          ),
          if (state.crossCurrency) _ReceivesField(state: state),
          _ProblemText(state.problem),
        ],
      ),
    );
  }
}

/// Cross-currency transfers: what the other account receives.
class _ReceivesField extends StatelessWidget {
  const _ReceivesField({required this.state});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final rate = state.rateMicros;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: Column(
        children: [
          Text(context.l10n.receives, style: context.text.bodySmall),
          HeroAmountField(
            fieldKey: const Key('toAmountField'),
            value: state.toAmount.text,
            currency: state.toCurrency,
            fontSize: 30,
            onChanged: (text) => context.read<TransactionFormBloc>().add(
              AmountTyped(text, target: AmountTarget.toAmount),
            ),
          ),
          if (rate != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                context.l10n.rateLabel(
                  state.currency.code,
                  FixedPoint.format(
                    rate,
                    Money.rateScale,
                  ).replaceFirst(RegExp(r'\.?0+$'), ''),
                  state.toCurrency.code,
                ),
                style: context.text.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProblemText extends StatelessWidget {
  const _ProblemText(this.problem);

  final EntryProblem? problem;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = switch (problem) {
      null => null,
      EntryProblem.amountRequired => l.problemAmount,
      EntryProblem.accountRequired => l.problemAccount,
      EntryProblem.destinationRequired => l.problemDestination,
      EntryProblem.sameAccount => l.problemSameAccount,
      EntryProblem.conversionRequired => l.problemConversion,
      EntryProblem.personRequired => l.problemPerson,
      EntryProblem.categoryRequired => l.problemCategory,
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.text.bodySmall!.copyWith(color: context.colors.danger),
      ),
    );
  }
}

/// Most-used categories in one tappable row, plus "All" for the full grid.
class _QuickCategories extends StatelessWidget {
  const _QuickCategories({required this.state});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TransactionFormBloc>();
    final quick = state.quickCategories;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in quick)
            Expanded(
              child: CategoryTile(
                category: c,
                badgeSize: 42,
                selected: c.id == state.categoryId,
                onTap: () => bloc.add(CategoryTapped(c.id)),
              ),
            ),
          Expanded(
            child: InkResponse(
              key: const Key('allCategories'),
              radius: 42,
              onTap: () async {
                final picked = await pickCategory(
                  context,
                  categories: state.categoriesByUse,
                  selectedId: state.categoryId,
                );
                if (picked != null && picked.id != state.categoryId) {
                  bloc.add(CategoryTapped(picked.id));
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    // Matches CategoryTile's ring (3px padding + 2px border).
                    padding: const EdgeInsets.all(5),
                    child: TintedBadge(
                      icon: AppIcons.more.regular,
                      color: context.colors.inkMuted,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.allCategories,
                    style: context.text.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every account as a one-tap chip in a sideways-scrolling row, the chosen
/// one scrolled into view. An optional [label] / [trailing] sit above.
class _AccountStrip extends StatefulWidget {
  const _AccountStrip({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
    this.label,
    this.trailing,
  });

  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String? label;
  final Widget? trailing;

  @override
  State<_AccountStrip> createState() => _AccountStripState();
}

class _AccountStripState extends State<_AccountStrip> {
  final _selected = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  @override
  void didUpdateWidget(_AccountStrip old) {
    super.didUpdateWidget(old);
    if (old.selectedId != widget.selectedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  void _reveal() {
    final chip = _selected.currentContext;
    if (chip == null || !mounted) return;
    Scrollable.ensureVisible(
      chip,
      alignment: 0.5,
      duration: AppMotion.base,
      curve: AppMotion.out,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          _FieldLabel(widget.label!, trailing: widget.trailing),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Row(
            children: [
              for (final a in widget.accounts)
                Padding(
                  key: a.id == widget.selectedId ? _selected : null,
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.s),
                  child: PillButton(
                    key: Key('account-${a.name}'),
                    label: a.name,
                    leading: AccountBadge.of(a, size: 20),
                    selected: a.id == widget.selectedId,
                    onTap: () {
                      if (a.id == widget.selectedId) return;
                      Haptics.selection();
                      widget.onSelected(a.id);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Transfers: a From row and a To row of account chips, with swap.
class _TransferAccounts extends StatelessWidget {
  const _TransferAccounts({required this.state});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TransactionFormBloc>();
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccountStrip(
          key: const Key('fromAccount'),
          label: l.fromAccount,
          accounts: state.accountsByUse,
          selectedId: state.accountId,
          onSelected: (id) => bloc.add(AccountChanged(id)),
        ),
        const SizedBox(height: AppSpacing.m),
        _AccountStrip(
          key: const Key('toAccount'),
          label: l.toAccount,
          accounts: [
            for (final a in state.accountsByUse)
              if (a.id != state.accountId) a,
          ],
          selectedId: state.toAccountId,
          onSelected: (id) => bloc.add(ToAccountChanged(id)),
          trailing: TextButton.icon(
            key: const Key('swapAccounts'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Haptics.selection();
              bloc.add(const AccountsSwapped());
            },
            icon: const Icon(AppIcons.transfer, size: 16),
            label: Text(l.swapAccounts),
          ),
        ),
      ],
    );
  }
}

/// The note, typed right here (no sheet).
class _NoteField extends StatefulWidget {
  const _NoteField({required this.state});

  final TransactionFormState state;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final _controller = TextEditingController(text: widget.state.note);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: TextField(
        key: const Key('noteField'),
        controller: _controller,
        minLines: 1,
        maxLines: 4,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        style: context.text.bodyLarge,
        decoration: InputDecoration(
          hintText: context.l10n.notePlaceholder,
          counterText: '',
          prefixIcon: Icon(AppIcons.note, size: 18, color: c.inkMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.l),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.l),
            borderSide: BorderSide(color: c.brand.withValues(alpha: 0.5)),
          ),
        ),
        onChanged: (v) =>
            context.read<TransactionFormBloc>().add(NoteChanged(v)),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}

/// A labelled, tappable card that opens a picker (accounts, person).
class _PickCard extends StatelessWidget {
  const _PickCard({
    super.key,
    required this.label,
    required this.title,
    required this.onTap,
    this.leading,
  });

  final String label;
  final String title;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.m),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.s),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                  ),
                  DirectionalIcon(
                    AppIcons.chevronRight,
                    size: 14,
                    color: c.inkMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section's small label ("Paid from", "When"), with an optional action
/// at the end (Transfer's swap).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.page,
      0,
      AppSpacing.s,
      AppSpacing.xs,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: context.text.labelMedium!.copyWith(
              color: context.colors.inkMuted,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// A choice in a row of equal tiles: a top line (a word or an icon) over a
/// small caption, outlined when chosen. The day buttons and the extras.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.top,
    required this.caption,
    required this.onTap,
    this.selected = false,
  });

  final Widget top;
  final String caption;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.brand : c.ink;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.m),
      side: BorderSide(
        color: selected ? c.brand.withValues(alpha: 0.35) : Colors.transparent,
        width: 1.5,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        child: Material(
          color: selected ? c.brand.withValues(alpha: 0.12) : c.surface,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.s,
              ),
              child: Column(
                children: [
                  // Words shrink rather than being cut off (Urdu, large
                  // text, a narrow phone).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: IconTheme.merge(
                      data: IconThemeData(color: fg, size: 20),
                      child: DefaultTextStyle.merge(
                        style: context.text.titleSmall!.copyWith(color: fg),
                        maxLines: 1,
                        child: top,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      caption,
                      maxLines: 1,
                      style: context.text.labelSmall!.copyWith(
                        color: selected ? c.brand : c.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Equal tiles in one row; [columns] keeps their width the same when some
/// are missing (no Split on an income, no Repeat when editing).
class _TileRow extends StatelessWidget {
  const _TileRow({required this.children, this.columns});

  final List<Widget> children;
  final int? columns;

  @override
  Widget build(BuildContext context) {
    final n = columns ?? children.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s),
            Expanded(
              child: i < children.length ? children[i] : const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }
}

/// When: Today / Yesterday in one tap, any other day from the calendar,
/// and the time on its own. Changing the day keeps the time and back.
class _WhenSection extends StatelessWidget {
  const _WhenSection({required this.state});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TransactionFormBloc>();
    final l = context.l10n;
    final at = state.occurredAt;
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = DateUtils.addDaysToDate(today, -1);
    final day = DateUtils.dateOnly(at);
    final other = day != today && day != yesterday;

    void moveTo(DateTime d) {
      if (d == day) return;
      Haptics.selection();
      bloc.add(
        DateChanged(DateTime(d.year, d.month, d.day, at.hour, at.minute)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(l.whenLabel),
        _TileRow(
          children: [
            _OptionTile(
              key: const Key('dayToday'),
              top: Text(l.today),
              caption: context.shortDate(today),
              selected: day == today,
              onTap: () => moveTo(today),
            ),
            _OptionTile(
              key: const Key('dayYesterday'),
              top: Text(l.yesterday),
              caption: context.shortDate(yesterday),
              selected: day == yesterday,
              onTap: () => moveTo(yesterday),
            ),
            _OptionTile(
              key: const Key('dateChip'),
              top: Text(l.otherDay),
              caption: other ? context.shortDate(day) : l.pickDay,
              selected: other,
              onTap: () => _chooseDay(context, state),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: PillButton(
              key: const Key('timeChip'),
              icon: AppIcons.clock,
              label: context.timeLabel(at),
              showChevron: true,
              onTap: () => _chooseTime(context, state),
            ),
          ),
        ),
      ],
    );
  }
}

/// Receipt, tags, split and repeat as labelled tiles; each caption says
/// what's set ("1 receipt", "Split · 2", "Monthly").
class _AddMore extends StatelessWidget {
  const _AddMore({required this.state});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TransactionFormBloc>();
    final l = context.l10n;
    final receipts = state.receiptCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(l.addMore),
        _TileRow(
          columns: 4,
          children: [
            _OptionTile(
              key: const Key('receiptChip'),
              top: const Icon(AppIcons.camera),
              caption: receipts == 0 ? l.receipt : l.receiptCount(receipts),
              selected: receipts > 0,
              onTap: () async {
                if (receipts == 0) {
                  final path = await pickReceiptImage(context);
                  if (path != null) bloc.add(ReceiptAdded(path));
                  return;
                }
                await showAppSheet<void>(
                  context,
                  title: l.receipts,
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        0,
                        AppSpacing.xl,
                        AppSpacing.xl,
                      ),
                      child:
                          BlocBuilder<
                            TransactionFormBloc,
                            TransactionFormState
                          >(
                            builder: (context, s) => ReceiptStrip(
                              receipts: [
                                for (final a in s.keptAttachments)
                                  ReceiptRef.stored(a),
                                for (final p in s.newReceiptPaths)
                                  ReceiptRef.picked(p),
                              ],
                              onAdd: (path) => bloc.add(ReceiptAdded(path)),
                              onRemove: (r) => bloc.add(
                                ReceiptRemoved(
                                  attachment: r.attachment,
                                  path: r.path,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                );
              },
            ),
            _OptionTile(
              key: const Key('tagsChip'),
              top: const Icon(AppIcons.tag),
              caption: state.tags.isEmpty
                  ? l.tags
                  : l.tagCount(state.tags.length),
              selected: state.tags.isNotEmpty,
              onTap: () async {
                final text = await editTextSheet(
                  context,
                  title: l.tags,
                  initial: state.tags.join(', '),
                  hint: l.tagsHint,
                  doneLabel: l.done,
                );
                if (text != null) bloc.add(TagsChanged(text));
              },
            ),
            if (state.canSplit)
              _OptionTile(
                key: const Key('splitChip'),
                top: Icon(AppIcons.people.regular),
                caption: state.isSplit
                    ? '${l.split} · ${state.splitWith.length}'
                    : l.split,
                selected: state.isSplit,
                onTap: () => _chooseSplitPeople(context, state),
              ),
            if (!state.isEditing && !state.isSplit)
              _OptionTile(
                key: const Key('repeatChip'),
                top: Icon(AppIcons.recurring.regular),
                caption: state.repeat == null
                    ? l.repeat
                    : frequencyLabel(context, state.repeat!),
                selected: state.repeat != null,
                onTap: () => _chooseRepeat(context, state),
              ),
          ],
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.state});

  final TransactionFormState state;

  /// A split bill first asks how it's shared; anything missing is
  /// reported before that.
  Future<void> _save(BuildContext context) async {
    final bloc = context.read<TransactionFormBloc>();
    if (!state.isSplit || state.missing != null) {
      bloc.add(const FormSubmitted());
      return;
    }
    FocusScope.of(context).unfocus();
    final shares = await _confirmSplit(context, state);
    if (shares != null) bloc.add(FormSubmitted(shares: shares));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final label = state.isUdhaar
        ? l.saveUdhaar
        : state.isSplit
        ? l.saveSplit
        : switch (state.type) {
            TransactionType.income => l.saveIncome,
            TransactionType.transfer => l.saveTransfer,
            _ => l.saveExpense,
          };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.xs,
        AppSpacing.l,
        AppSpacing.m,
      ),
      child: FilledButton(
        key: const Key('saveEntry'),
        onPressed: state.canSave ? () => _save(context) : null,
        child: Text(label),
      ),
    );
  }
}

/// A new day, keeping the time.
Future<void> _chooseDay(
  BuildContext context,
  TransactionFormState state,
) async {
  final bloc = context.read<TransactionFormBloc>();
  final current = state.occurredAt;
  final day = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: DateTime(2000),
    lastDate: DateTime.now().add(const Duration(days: 366)),
  );
  if (day == null) return;
  bloc.add(
    DateChanged(
      DateTime(day.year, day.month, day.day, current.hour, current.minute),
    ),
  );
}

/// A new time, keeping the day.
Future<void> _chooseTime(
  BuildContext context,
  TransactionFormState state,
) async {
  final bloc = context.read<TransactionFormBloc>();
  final current = state.occurredAt;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(current),
  );
  if (time == null) return;
  bloc.add(
    DateChanged(
      DateTime(
        current.year,
        current.month,
        current.day,
        time.hour,
        time.minute,
      ),
    ),
  );
}

/// Udhaar: who, and which way the money went.
class _UdhaarSection extends StatelessWidget {
  const _UdhaarSection({required this.state});

  final TransactionFormState state;

  Future<void> _choosePerson(BuildContext context) async {
    final bloc = context.read<TransactionFormBloc>();
    final l = context.l10n;
    const addNew = '_add';
    final picked = await pickOne<String>(
      context,
      title: l.choosePerson,
      selected: state.personId,
      searchable: state.people.isNotEmpty,
      items: [
        _addPersonItem(addNew, l.addPerson),
        for (final p in state.people) _personItem(p),
      ],
    );
    if (picked == null || !context.mounted) return;
    if (picked != addNew) {
      bloc.add(PersonChanged(picked));
      return;
    }
    final person = await _addPerson(context);
    if (person != null) bloc.add(PersonAdded(person));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final person = state.person;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Column(
        children: [
          SegmentedPicker<UdhaarDirection>(
            key: const Key('udhaarDirection'),
            value: state.udhaarDirection,
            onChanged: (d) => context.read<TransactionFormBloc>().add(
              UdhaarDirectionChanged(d),
            ),
            options: [
              PickerOption(UdhaarDirection.gave, l.iGave),
              PickerOption(UdhaarDirection.received, l.iReceived),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          _PickCard(
            key: const Key('personCard'),
            label: l.person,
            title: person?.name ?? l.choosePerson,
            leading: person == null ? null : PersonBadge(person.name, size: 26),
            onTap: () => _choosePerson(context),
          ),
        ],
      ),
    );
  }
}

PickItem<String> _personItem(Person p) => PickItem(
  value: p.id,
  title: p.name,
  leading: PersonBadge(p.name, size: 36),
);

/// "Add person", kept in view above the people in a picker.
PickItem<String> _addPersonItem(String value, String title) => PickItem(
  value: value,
  title: title,
  leading: const TintedBadge(icon: AppIcons.plus, size: 36),
  trailing: const SizedBox.shrink(),
  pinned: true,
);

/// Asks for a new person's name and adds them. Null if cancelled, or if
/// the name is taken (a toast says so).
Future<Person?> _addPerson(BuildContext context) async {
  final l = context.l10n;
  final name = await editTextSheet(
    context,
    title: l.addPerson,
    initial: '',
    hint: l.personName,
    doneLabel: l.save,
  );
  if (name == null || name.isEmpty || !context.mounted) return null;
  try {
    final id = await getIt<PeopleRepository>().create(name);
    return Person(id: id, name: name);
  } on DuplicateNameFailure {
    if (context.mounted) showToast(context, l.duplicatePersonName(name));
    return null;
  }
}

/// Who a bill is split with. "Add person" creates one, ticks them and
/// reopens the list, so several can be added in one go.
Future<void> _chooseSplitPeople(
  BuildContext context,
  TransactionFormState state,
) async {
  final bloc = context.read<TransactionFormBloc>();
  final l = context.l10n;
  const addNew = '_add';
  final added = <Person>[];
  var chosen = {...state.splitWith};
  while (true) {
    final picked = await pickMany<String>(
      context,
      title: l.splitWith,
      selected: chosen,
      doneLabel: l.done,
      clearLabel: l.clear,
      items: [
        _addPersonItem(addNew, l.addPerson),
        for (final p in [...state.people, ...added]) _personItem(p),
      ],
    );
    if (!context.mounted) return;
    if (picked == null) {
      if (added.isEmpty) return;
      break; // Keep the people just added, ticked.
    }
    chosen = picked;
    if (!chosen.remove(addNew)) break;
    final person = await _addPerson(context);
    if (!context.mounted) return;
    if (person != null) {
      added.add(person);
      chosen.add(person.id);
    }
  }
  bloc.add(
    SplitPeopleChanged([
      for (final p in [...state.people, ...added])
        if (chosen.contains(p.id)) p.id,
    ], added: added),
  );
}

/// How a split bill is shared: an amount for the user and for each
/// person, equal to start with. Null if dismissed.
Future<List<SplitShare>?> _confirmSplit(
  BuildContext context,
  TransactionFormState state,
) => showAppSheet<List<SplitShare>>(
  context,
  title: context.l10n.splitTitle(const MoneyFormat().format(state.money)),
  builder: (_) => _SplitSheet(state: state),
);

class _SplitSheet extends StatefulWidget {
  const _SplitSheet({required this.state});

  final TransactionFormState state;

  @override
  State<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends State<_SplitSheet> {
  late final List<SplitShare> _even = widget.state.evenShares;
  late final List<TextEditingController> _fields = [
    for (final s in _even) TextEditingController(text: _text(s.amount)),
  ];

  static String _text(Money m) => AmountBuffer.fromMoney(m).text;

  Money get _total => widget.state.money;

  /// What's typed, or null while any amount is invalid.
  List<SplitShare>? get _shares {
    final shares = <SplitShare>[];
    for (final (i, s) in _even.indexed) {
      final amount = AmountField.read(_fields[i], _total.currency);
      if (amount == null) return null;
      shares.add(SplitShare(s.personId, amount));
    }
    return shares;
  }

  void _splitEqually() {
    for (final (i, s) in _even.indexed) {
      _fields[i].text = _text(s.amount);
    }
  }

  @override
  void dispose() {
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final names = {for (final p in widget.state.splitPeople) p.id: p.name};
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.splitHint,
            style: context.text.bodySmall!.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AppSpacing.m),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final (i, s) in _even.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: Row(
                      children: [
                        PersonBadge(
                          s.isMine ? l.splitYou : names[s.personId]!,
                          size: 36,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: AmountField(
                            key: Key('share-$i'),
                            controller: _fields[i],
                            currency: _total.currency,
                            label: s.isMine ? l.splitYou : names[s.personId]!,
                            invalidMessage: l.invalidAmount,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: Listenable.merge(_fields),
            builder: (context, _) {
              final shares = _shares;
              final ok = shares != null && sharesAddUp(_total, shares);
              final left = shares == null
                  ? null
                  : _total -
                        Money.sum(shares.map((s) => s.amount), _total.currency);
              final format = const MoneyFormat().format;
              final status = ok
                  ? l.splitAddsUp(format(_total))
                  : left == null
                  ? l.invalidAmount
                  : left.isNegative
                  ? l.splitOver(format(-left))
                  : l.splitLeft(format(left));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          status,
                          key: const Key('splitStatus'),
                          style: context.text.bodySmall!.copyWith(
                            color: ok ? c.inkMuted : c.danger,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const Key('splitEqually'),
                        onPressed: _splitEqually,
                        child: Text(l.splitEqually),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  FilledButton(
                    key: const Key('confirmSplit'),
                    onPressed: ok ? () => Navigator.pop(context, shares) : null,
                    child: Text(l.saveSplit),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Repeat: never / daily / weekly / monthly / yearly, and a reminder.
Future<void> _chooseRepeat(
  BuildContext context,
  TransactionFormState state,
) async {
  final bloc = context.read<TransactionFormBloc>();
  final l = context.l10n;
  final result = await showAppSheet<(RecurrenceFrequency?, bool)>(
    context,
    title: l.repeat,
    builder: (sheet) {
      var frequency = state.repeat;
      var remind = state.remind;
      return StatefulBuilder(
        builder: (sheet, setState) {
          Widget option(RecurrenceFrequency? f, String label) => ListTile(
            key: Key('repeat-${f?.name ?? 'never'}'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
            ),
            title: Text(label, style: sheet.text.titleSmall),
            trailing: frequency == f
                ? Icon(AppIcons.check, color: sheet.colors.brand, size: 20)
                : null,
            onTap: () => setState(() {
              frequency = f;
              if (f == null) remind = false;
            }),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              option(null, l.repeatNever),
              for (final f in RecurrenceFrequency.values)
                option(f, frequencyLabel(sheet, f)),
              SwitchListTile(
                key: const Key('remindSwitch'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                title: Text(l.remindMe, style: sheet.text.titleSmall),
                subtitle: Text(l.remindMeHint),
                value: remind,
                onChanged: frequency == null
                    ? null
                    : (v) async {
                        Haptics.selection();
                        if (v) {
                          await getIt<ReminderScheduler>().requestPermission();
                        }
                        setState(() => remind = v);
                      },
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: FilledButton(
                  key: const Key('repeatDone'),
                  onPressed: () => Navigator.pop(sheet, (frequency, remind)),
                  child: Text(l.done),
                ),
              ),
            ],
          );
        },
      );
    },
  );
  if (result != null) bloc.add(RepeatChanged(result.$1, remind: result.$2));
}

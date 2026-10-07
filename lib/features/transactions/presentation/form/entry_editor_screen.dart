import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/l10n/date_labels.dart';
import '../../../../core/money/fixed_point.dart';
import '../../../../core/money/money.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/context_x.dart';
import '../../../../core/widgets/ambient_background.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/hero_amount_field.dart';
import '../../../../core/widgets/pill_button.dart';
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
}

/// Pre-fill for a new entry.
@immutable
class EntryEditorArgs {
  const EntryEditorArgs({this.udhaar, this.personId, this.amount});

  final UdhaarDirection? udhaar;
  final String? personId;
  final Money? amount;
}

/// Add / edit a transaction on its own screen (spec 3.2 #3).
///
/// One job per area, top to bottom: what kind → how much → from which
/// account → for what → note → extras, with Save always above the
/// keyboard. Amounts and the note use the phone's own keyboard. The
/// fastest path stays: + → type amount → category → Save.
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
            amount: args?.amount,
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
        body: AmbientBackground(
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
                                accounts: s.accountsByUse,
                                selectedId: s.accountId,
                                onSelected: (id) => context
                                    .read<TransactionFormBloc>()
                                    .add(AccountChanged(id)),
                              ),
                            const SizedBox(height: AppSpacing.l),
                            if (s.isUdhaar)
                              _UdhaarSection(state: s)
                            else if (!s.isTransfer)
                              _QuickCategories(state: s),
                            const SizedBox(height: AppSpacing.l),
                            _NoteField(state: s),
                            const SizedBox(height: AppSpacing.m),
                            _Extras(state: s),
                          ],
                        ),
                      ),
                    ),
                    _SaveButton(state: s),
                  ],
                );
              },
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
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
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
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.page,
              0,
              AppSpacing.s,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.label!, style: context.text.labelMedium),
                ),
                ?widget.trailing,
              ],
            ),
          ),
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

/// When, tags, receipt and repeat: quiet until used.
class _Extras extends StatelessWidget {
  const _Extras({required this.state});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TransactionFormBloc>();
    final l = context.l10n;
    final receipts = state.receiptCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Wrap(
        spacing: AppSpacing.s,
        runSpacing: AppSpacing.s,
        children: [
          PillButton(
            key: const Key('dateChip'),
            icon: AppIcons.calendar,
            label: context.dateTimeLabel(state.occurredAt),
            showChevron: true,
            onTap: () => _chooseDate(context, state),
          ),
          PillButton(
            key: const Key('tagsChip'),
            icon: AppIcons.tag,
            label: state.tags.isEmpty ? l.tags : l.tagCount(state.tags.length),
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
          PillButton(
            key: const Key('receiptChip'),
            icon: AppIcons.camera,
            label: receipts == 0 ? l.receipt : l.receiptCount(receipts),
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
                        BlocBuilder<TransactionFormBloc, TransactionFormState>(
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
          if (!state.isEditing)
            PillButton(
              key: const Key('repeatChip'),
              icon: AppIcons.recurring.regular,
              label: state.repeat == null
                  ? l.repeat
                  : frequencyLabel(context, state.repeat!),
              selected: state.repeat != null,
              onTap: () => _chooseRepeat(context, state),
            ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.state});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final label = state.isUdhaar
        ? l.saveUdhaar
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
        onPressed: state.canSave
            ? () =>
                  context.read<TransactionFormBloc>().add(const FormSubmitted())
            : null,
        child: Text(label),
      ),
    );
  }
}

Future<void> _chooseDate(
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
  if (day == null || !context.mounted) return;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(current),
  );
  final t = time ?? TimeOfDay.fromDateTime(current);
  bloc.add(
    DateChanged(DateTime(day.year, day.month, day.day, t.hour, t.minute)),
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
      items: [
        PickItem(
          value: addNew,
          title: l.addPerson,
          leading: const TintedBadge(icon: AppIcons.plus, size: 36),
          trailing: const SizedBox.shrink(),
        ),
        for (final p in state.people)
          PickItem(
            value: p.id,
            title: p.name,
            leading: PersonBadge(p.name, size: 36),
          ),
      ],
    );
    if (picked == null || !context.mounted) return;
    if (picked != addNew) {
      bloc.add(PersonChanged(picked));
      return;
    }
    final name = await editTextSheet(
      context,
      title: l.addPerson,
      initial: '',
      hint: l.personName,
      doneLabel: l.save,
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      final id = await getIt<PeopleRepository>().create(name);
      bloc.add(PersonAdded(Person(id: id, name: name)));
    } on DuplicateNameFailure {
      if (context.mounted) showToast(context, l.duplicatePersonName(name));
    }
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

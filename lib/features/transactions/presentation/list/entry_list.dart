import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/context_x.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/tinted_badge.dart';
import '../../../settings/presentation/cubit/preference_cubits.dart';
import '../../domain/day_group.dart';
import '../../domain/ledger_entry.dart';
import '../form/entry_editor_screen.dart';
import '../widgets/day_header.dart';
import '../widgets/entry_tile.dart';
import 'transaction_list_bloc.dart';
import '../../../../core/widgets/app_sheet.dart';

/// The grouped list body shared by Transactions, Search and entry lists:
/// one card per budget cycle with a small label for each day, and
/// swipeable rows (right = edit, left = delete with undo). With
/// [cycleHeaders] each cycle's card has its name above it.
class EntryListSlivers extends StatelessWidget {
  const EntryListSlivers({
    super.key,
    required this.days,
    this.cycleHeaders = true,
  });

  final List<DayGroup> days;

  /// Off where the page already says which cycle it shows (Transactions'
  /// month card).
  final bool cycleHeaders;

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<BudgetCycleCubit>().state;
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget card(List<DayGroup> days) => SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.s,
        AppSpacing.page,
        0,
      ),
      sliver: SliverToBoxAdapter(child: _DaysCard(days)),
    );
    if (!cycleHeaders) return card(days);
    return SliverMainAxisGroup(
      slivers: [
        for (final section in CycleSection.of(days, cycle))
          SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: _CycleHeader(cycle.label(section.cycle, locale: locale)),
              ),
              card(section.days),
            ],
          ),
      ],
    );
  }
}

/// Days in one card: each day's label, then its entries.
class _DaysCard extends StatelessWidget {
  const _DaysCard(this.days);

  final List<DayGroup> days;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(AppRadii.l);
    final divider = Divider(
      // Lines up with the text, past the badge.
      indent: AppSpacing.l + 40 + kBadgeGap,
      color: c.line.withValues(alpha: 0.7),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: radius,
        border: Border.all(color: c.line.withValues(alpha: 0.6)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final day in days) ...[
              DayHeader(day),
              for (var i = 0; i < day.entries.length; i++) ...[
                if (i > 0) divider,
                _SwipeableEntry(day.entries[i]),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// A cycle's name above its card ("Oct 2026"). It scrolls with the list;
/// a pinned one sat over the rows.
class _CycleHeader extends StatelessWidget {
  const _CycleHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page + AppSpacing.xs,
        AppSpacing.l,
        AppSpacing.page,
        0,
      ),
      child: Text(label, style: context.text.titleSmall),
    );
  }
}

class _SwipeableEntry extends StatelessWidget {
  const _SwipeableEntry(this.view);

  final EntryView view;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final id = view.entry.id;
    Widget background(Color color, IconData icon, AlignmentGeometry at) =>
        Container(
          color: color.withValues(alpha: 0.14),
          alignment: at,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Icon(icon, color: color),
        );

    return Dismissible(
      key: ValueKey(id),
      background: background(
        c.brand,
        AppIcons.edit,
        AlignmentDirectional.centerStart,
      ),
      secondaryBackground: background(
        c.danger,
        AppIcons.delete,
        AlignmentDirectional.centerEnd,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await EntryEditor.open(context, editId: id);
          return false;
        }
        final l = context.l10n;
        return confirmSheet(
          context,
          title: l.deleteEntryTitle,
          message: l.deleteEntryBody,
          confirmLabel: l.delete,
        );
      },
      onDismissed: (_) {
        final bloc = context.read<TransactionListBloc>()..add(EntryDeleted(id));
        showUndo(
          context,
          message: context.l10n.deleted,
          undoLabel: context.l10n.undo,
          onUndo: () => bloc.add(const DeleteUndone()),
        );
      },
      child: EntryTile(view, onTap: () => context.push(Routes.entry(id))),
    );
  }
}

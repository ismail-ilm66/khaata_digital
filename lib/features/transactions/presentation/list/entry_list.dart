import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/context_x.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../settings/presentation/cubit/preference_cubits.dart';
import '../../domain/day_group.dart';
import '../../domain/ledger_entry.dart';
import '../form/entry_editor_screen.dart';
import '../widgets/day_header.dart';
import '../widgets/entry_tile.dart';
import 'transaction_list_bloc.dart';

/// The grouped list body shared by Transactions and Search: a sticky
/// header per budget cycle, day headers with totals, and swipeable rows
/// (right = edit, left = delete with undo).
class EntryListSlivers extends StatelessWidget {
  const EntryListSlivers({super.key, required this.days});

  final List<DayGroup> days;

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<BudgetCycleCubit>().state;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return SliverMainAxisGroup(
      slivers: [
        for (final section in CycleSection.of(days, cycle))
          SliverMainAxisGroup(
            slivers: [
              PinnedHeaderSliver(
                child: _CycleHeader(cycle.label(section.cycle, locale: locale)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                sliver: SliverList.list(
                  children: [
                    for (final day in section.days) ...[
                      DayHeader(day),
                      SurfaceCard(
                        padding: EdgeInsets.zero,
                        children: [
                          for (final v in day.entries) _SwipeableEntry(v),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _CycleHeader extends StatelessWidget {
  const _CycleHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.s,
        AppSpacing.page,
        0,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: GlassSurface(
          blur: 16,
          borderRadius: BorderRadius.circular(AppRadii.l),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.xs + 2,
            ),
            child: Text(label, style: context.text.labelLarge),
          ),
        ),
      ),
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
        return true;
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

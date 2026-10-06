import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/files/file_gateway.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/headline_card.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/segmented_picker.dart';
import '../../../core/widgets/surface_card.dart';
import '../../backup/presentation/backup_labels.dart';
import '../domain/exchange_record.dart';
import '../domain/import_plan.dart';
import 'import_bloc.dart';

/// Import from Hysab Kytab, a Kharcha export, or any CSV.
class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ImportBloc>(),
    child: const _ImportView(),
  );
}

class _ImportView extends StatelessWidget {
  const _ImportView();

  Future<void> _pick(BuildContext context) async {
    final bloc = context.read<ImportBloc>();
    final file = await getIt<FileGateway>().pick();
    if (file != null) bloc.add(ImportFileChosen(file));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.watch<ImportBloc>().state;
    final bloc = context.read<ImportBloc>();
    final problem = switch (s.problem) {
      ImportProblem.unreadable => l.importUnreadable,
      ImportProblem.empty => l.importEmpty,
      ImportProblem.failed => l.importFailed,
      null => null,
    };

    Widget page({required List<Widget> children, Widget? bottom}) =>
        PageScaffold(
          title: l.importTitle,
          subtitle: s.fileName.isEmpty ? null : s.fileName,
          bottom: bottom,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              sliver: SliverList.list(
                children: [
                  if (problem != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: Text(
                        problem,
                        key: const Key('importProblem'),
                        style: context.text.bodyMedium!.copyWith(
                          color: context.colors.danger,
                        ),
                      ),
                    ),
                  ...children,
                ],
              ),
            ),
          ],
        );

    Widget busy(String label) => PageScaffold(
      title: l.importTitle,
      subtitle: s.fileName,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.l),
              Text(label, style: context.text.bodyMedium),
            ],
          ),
        ),
      ],
    );

    return switch (s.step) {
      ImportStep.reading => busy(l.reading),
      ImportStep.running => busy(l.importing),
      ImportStep.pick => page(
        bottom: FilledButton.icon(
          key: const Key('importChoose'),
          onPressed: () => _pick(context),
          icon: const Icon(AppIcons.importFile, size: 18),
          label: Text(l.chooseFile),
        ),
        children: [
          EmptyState(icon: AppIcons.importFile, message: l.importIntro),
        ],
      ),
      ImportStep.mapping => page(
        bottom: FilledButton(
          key: const Key('mappingContinue'),
          onPressed: () => bloc.add(const ImportMappingConfirmed()),
          child: Text(l.continueLabel),
        ),
        children: [_Mapper(state: s)],
      ),
      ImportStep.preview => page(
        bottom: _ConfirmBar(draft: s.draft!),
        children: [_Preview(draft: s.draft!)],
      ),
      ImportStep.report => page(
        bottom: FilledButton(
          key: const Key('importDoneButton'),
          onPressed: () => context.go(Routes.home),
          child: Text(l.done),
        ),
        children: [_Report(report: s.report!)],
      ),
    };
  }
}

// ── Column mapper (generic CSV) ──────────────────────────────────────────

class _Mapper extends StatelessWidget {
  const _Mapper({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = state.mapping!;
    final bloc = context.read<ImportBloc>();
    final header = state.rows.first;
    void set(CsvMapping next) => bloc.add(ImportMappingChanged(next));

    Widget column(
      IconData icon,
      String label,
      int? index, {
      required void Function(int?) onPicked,
      bool optional = true,
    }) {
      final sample = index != null && state.rows.length > 1
          ? state.rows[1].elementAtOrNull(index)
          : null;
      return SettingTile(
        icon: icon,
        title: label,
        subtitle: index == null
            ? l.notInFile
            : [
                header[index],
                if (sample?.isNotEmpty ?? false) sample,
              ].join(' · '),
        onTap: () async {
          final picked = await pickOne<int>(
            context,
            title: label,
            selected: index ?? -1,
            items: [
              if (optional) PickItem(value: -1, title: l.notInFile),
              for (var i = 0; i < header.length; i++)
                PickItem(
                  value: i,
                  title: header[i].isEmpty ? '#${i + 1}' : header[i],
                ),
            ],
          );
          if (picked != null) onPicked(picked < 0 ? null : picked);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.mapColumnsHint, style: context.text.bodySmall),
        const SizedBox(height: AppSpacing.l),
        Section(
          title: l.mapColumns,
          child: SurfaceCard(
            children: [
              column(
                AppIcons.calendar,
                l.date,
                m.date,
                optional: false,
                onPicked: (i) => set(m.copyWith(date: i)),
              ),
              column(
                AppIcons.transactions.regular,
                l.colAmount,
                m.amount,
                optional: false,
                onPicked: (i) => set(m.copyWith(amount: i)),
              ),
              column(
                AppIcons.transfer,
                l.colType,
                m.type,
                onPicked: (i) => set(m.copyWith(type: () => i)),
              ),
              column(
                AppIcons.accounts.regular,
                l.account,
                m.account,
                onPicked: (i) => set(m.copyWith(account: () => i)),
              ),
              column(
                AppIcons.filter,
                l.category,
                m.category,
                onPicked: (i) => set(m.copyWith(category: () => i)),
              ),
              column(
                AppIcons.note,
                l.note,
                m.note,
                onPicked: (i) => set(m.copyWith(note: () => i)),
              ),
              column(
                AppIcons.tag,
                l.tags,
                m.tags,
                onPicked: (i) => set(m.copyWith(tags: () => i)),
              ),
            ],
          ),
        ),
        Section(
          title: l.dateOrder,
          child: SegmentedPicker<DateOrder>(
            value: m.dateOrder,
            onChanged: (o) => set(m.copyWith(dateOrder: o)),
            options: const [
              PickerOption(DateOrder.dmy, 'D/M/Y'),
              PickerOption(DateOrder.mdy, 'M/D/Y'),
              PickerOption(DateOrder.ymd, 'Y-M-D'),
            ],
          ),
        ),
        Section(
          title: l.defaultAccount,
          child: SurfaceCard(
            children: [
              SettingTile(
                icon: AppIcons.accounts.regular,
                title: m.defaultAccount,
                onTap: () async {
                  final name = await pickOne<String>(
                    context,
                    title: l.defaultAccount,
                    selected: m.defaultAccount,
                    items: [
                      for (final a in state.accounts)
                        PickItem(value: a, title: a),
                    ],
                  );
                  if (name != null) set(m.copyWith(defaultAccount: name));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Preview ──────────────────────────────────────────────────────────────

class _Preview extends StatelessWidget {
  const _Preview({required this.draft});

  final ImportDraft draft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bloc = context.read<ImportBloc>();
    final warnings = draft.warnings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeadlineCard(
          key: const Key('importSummary'),
          icon: AppIcons.transactions.regular,
          title: l.importNew(draft.newCount),
          subtitle: dateSpan(context, draft.first, draft.last),
          footer: draft.duplicates.isEmpty && draft.newCount > 0
              ? null
              : Text(
                  draft.newCount == 0
                      ? l.importNothingNew
                      : l.importAlready(draft.duplicates.length),
                  style: context.text.bodySmall,
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (warnings.isNotEmpty)
          Section(
            title: l.importWarnings(warnings.length),
            child: SurfaceCard(
              children: [
                for (final w in warnings.take(50))
                  Text(_warning(l, w), style: context.text.bodySmall),
              ],
            ),
          ),
        if (draft.format == ImportFormat.hysabKytab && draft.names.isNotEmpty)
          Section(
            title: l.namesTitle,
            child: SurfaceCard(
              children: [
                Text(l.namesHint, style: context.text.bodySmall),
                for (final n in draft.names)
                  SettingTile(
                    key: Key('name-${n.name}'),
                    icon: n.role == ImportRole.person
                        ? AppIcons.people.regular
                        : AppIcons.accounts.regular,
                    title: n.name,
                    subtitle: [
                      l.nameEntries(n.entries),
                      if (n.existing) l.nameExisting,
                    ].join(' · '),
                    trailing: n.canBePerson
                        ? SizedBox(
                            width: 168,
                            child: SegmentedPicker<ImportRole>(
                              key: Key('role-${n.name}'),
                              value: n.role,
                              onChanged: (r) =>
                                  bloc.add(ImportRoleChanged(n.name, r)),
                              options: [
                                PickerOption(ImportRole.account, l.roleAccount),
                                PickerOption(ImportRole.person, l.rolePerson),
                              ],
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static String _warning(AppLocalizations l, ExchangeWarning w) =>
      switch (w.kind) {
        ExchangeWarningKind.unreadableRow => l.warnUnreadable(w.row),
        ExchangeWarningKind.unpairedTransfer => l.warnUnpaired(w.row, w.detail),
      };
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.draft});

  final ImportDraft draft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.safetyCopyNote,
          style: context.text.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s),
        FilledButton(
          key: const Key('importConfirm'),
          onPressed: draft.newCount == 0
              ? null
              : () => context.read<ImportBloc>().add(const ImportConfirmed()),
          child: Text('${l.importButton} · ${l.importNew(draft.newCount)}'),
        ),
      ],
    );
  }
}

// ── Report ───────────────────────────────────────────────────────────────

class _Report extends StatelessWidget {
  const _Report({required this.report});

  final ImportReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeadlineCard(
          key: const Key('importDone'),
          icon: AppIcons.shield,
          title: l.importDone,
          stats: [
            CountTile(label: l.reportImported, count: report.imported),
            CountTile(label: l.reportDuplicates, count: report.duplicates),
            CountTile(label: l.reportSkipped, count: report.skipped.length),
          ],
          footer: Row(
            children: [
              Expanded(
                child: CountTile(
                  label: l.reportAccounts,
                  count: report.accountsCreated,
                ),
              ),
              Expanded(
                child: CountTile(
                  label: l.reportPeople,
                  count: report.peopleCreated,
                ),
              ),
              Expanded(
                child: CountTile(
                  label: l.reportCategories,
                  count: report.categoriesCreated,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (report.warnings.isNotEmpty || report.skipped.isNotEmpty)
          Section(
            title: l.importWarnings(
              report.warnings.length + report.skipped.length,
            ),
            child: SurfaceCard(
              children: [
                for (final w in report.warnings.take(50))
                  Text(_Preview._warning(l, w), style: context.text.bodySmall),
                for (final s in report.skipped.take(50))
                  Text(switch (s.reason) {
                    ImportSkip.betweenPeople => l.skipBetweenPeople(
                      s.lines.first,
                    ),
                    ImportSkip.personAdjustment => l.skipPersonAdjustment(
                      s.lines.first,
                    ),
                  }, style: context.text.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}

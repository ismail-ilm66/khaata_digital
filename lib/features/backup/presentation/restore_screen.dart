import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/files/file_gateway.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/headline_card.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/segmented_picker.dart';
import '../domain/backup.dart';
import 'backup_labels.dart';
import 'restore_bloc.dart';
import '../../../core/feedback/haptics.dart';

/// The restore wizard for one backup file.
class RestoreScreen extends StatelessWidget {
  const RestoreScreen({super.key, required this.file});

  final PickedFile file;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<RestoreBloc>()..add(RestoreOpened(file)),
    child: BlocListener<RestoreBloc, RestoreState>(
      listenWhen: (a, b) => a.status != b.status || a.failure != b.failure,
      listener: (context, s) {
        if (s.status == RestoreStatus.done) unawaited(Haptics.success());
        if (s.failure != null) Haptics.warning();
      },
      child: const _RestoreView(),
    ),
  );
}

class _RestoreView extends StatelessWidget {
  const _RestoreView();

  Future<void> _confirm(BuildContext context, RestoreState s) async {
    final bloc = context.read<RestoreBloc>();
    String? passphrase;
    if (s.manifest!.encrypted) {
      passphrase = await askPassphrase(context, title: context.l10n.passphrase);
      if (passphrase == null) return;
    }
    bloc.add(RestoreConfirmed(passphrase: passphrase));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.watch<RestoreBloc>().state;
    final done = FilledButton(
      key: const Key('restoreDoneButton'),
      onPressed: () => s.status == RestoreStatus.done
          ? context.go(Routes.home)
          : context.pop(),
      child: Text(l.done),
    );

    return switch (s.status) {
      RestoreStatus.inspecting || RestoreStatus.restoring => PageScaffold(
        title: l.restoreTitle,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                if (s.status == RestoreStatus.restoring) ...[
                  const SizedBox(height: AppSpacing.l),
                  Text(l.restoring, style: context.text.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
      RestoreStatus.failed => PageScaffold(
        title: l.restoreTitle,
        bottom: done,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              key: const Key('restoreFailed'),
              icon: AppIcons.warning,
              message: l.failure(s.failure ?? BackupFailureKind.damaged),
            ),
          ),
        ],
      ),
      RestoreStatus.done => PageScaffold(
        title: l.restoreTitle,
        bottom: done,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              key: const Key('restoreDone'),
              icon: AppIcons.shield,
              title: l.restoreDone,
              message:
                  '${l.restoreVerified}\n\n${l.restoreSummary(s.result!.accounts, s.result!.transactions, s.result!.receipts)}',
            ),
          ),
        ],
      ),
      RestoreStatus.ready => _Preview(
        state: s,
        onConfirm: () => _confirm(context, s),
      ),
    };
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state, required this.onConfirm});

  final RestoreState state;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final m = state.manifest!;
    final receipts = m.files.keys
        .where((k) => k.startsWith('receipts/'))
        .length;
    final replace = state.mode == RestoreMode.replace;

    return PageScaffold(
      title: l.restoreTitle,
      bottom: Column(
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
            key: const Key('restoreConfirm'),
            onPressed: onConfirm,
            style: replace
                ? FilledButton.styleFrom(backgroundColor: c.danger)
                : null,
            child: Text(
              replace ? l.restoreReplaceButton : l.restoreMergeButton,
            ),
          ),
        ],
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          sliver: SliverList.list(
            children: [
              HeadlineCard(
                icon: AppIcons.backup.regular,
                title: backupWhen(context, m.createdAt),
                subtitle: dateSpan(context, m.first, m.last),
                stats: [
                  CountTile(label: l.accounts, count: m.accounts),
                  CountTile(label: l.restoreEntries, count: m.transactions),
                  CountTile(label: l.receipts, count: receipts),
                ],
                footer: Row(
                  children: [
                    if (m.encrypted) ...[
                      Icon(AppIcons.lock, size: 16, color: c.inkMuted),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          l.encryptedBackup,
                          style: context.text.bodySmall,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    Text('v${m.appVersion}', style: context.text.bodySmall),
                  ],
                ),
              ),
              if (state.failure == BackupFailureKind.wrongPassphrase)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.m),
                  child: Text(
                    l.failPassphrase,
                    key: const Key('wrongPassphrase'),
                    style: context.text.bodyMedium!.copyWith(color: c.danger),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              Section(
                title: l.restoreMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedPicker<RestoreMode>(
                      key: const Key('restoreMode'),
                      value: state.mode,
                      onChanged: (m) => context.read<RestoreBloc>().add(
                        RestoreModeChanged(m),
                      ),
                      options: [
                        PickerOption(RestoreMode.replace, l.modeReplace),
                        PickerOption(RestoreMode.merge, l.modeMerge),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      replace ? l.modeReplaceHint : l.modeMergeHint,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

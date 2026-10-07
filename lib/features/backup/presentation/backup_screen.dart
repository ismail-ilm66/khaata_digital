import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/di/injection.dart';
import '../../../core/files/file_gateway.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/headline_card.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../data/backup_service.dart';
import '../domain/backup.dart';
import '../domain/cloud_backup_store.dart';
import 'backup_bloc.dart';
import 'backup_labels.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/feedback/haptics.dart';

/// Backup & restore (spec 3.2 #9).
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<BackupBloc>()..add(const BackupStarted()),
    child: const _BackupView(),
  );
}

class _BackupView extends StatefulWidget {
  const _BackupView();

  @override
  State<_BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<_BackupView> {
  bool _encrypt = false;

  Future<void> _backup(BackupDestination to) async {
    final bloc = context.read<BackupBloc>();
    String? passphrase;
    if (_encrypt) {
      passphrase = await askPassphrase(context, title: context.l10n.passphrase);
      if (passphrase == null) return;
    }
    bloc.add(BackupNow(to, passphrase: passphrase));
  }

  void _openRestore(PickedFile file) =>
      context.push(Routes.restore, extra: file);

  Future<void> _restoreFromFile() async {
    final file = await getIt<FileGateway>().pick();
    if (file != null && mounted) _openRestore(file);
  }

  Future<void> _restoreFromDrive() async {
    final l = context.l10n;
    final cloud = getIt<CloudBackupStore>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final all = await cloud.list();
      if (!mounted) return;
      if (all.isEmpty) return messenger.toast(l.noBackupsFound);
      final chosen = await pickOne<CloudBackup>(
        context,
        title: l.restoreFromDrive,
        items: [
          for (final b in all)
            PickItem(
              value: b,
              title: backupWhen(context, b.createdAt),
              subtitle: _size(b.size),
              leading: const Icon(AppIcons.drive),
            ),
        ],
      );
      if (chosen == null) return;
      final bytes = await cloud.download(chosen);
      if (mounted) _openRestore((name: chosen.name, bytes: bytes));
    } catch (_) {
      messenger.toast(l.driveFailed);
    }
  }

  Future<void> _restoreFromDevice() async {
    final l = context.l10n;
    final files = await getIt<BackupService>().deviceBackups();
    if (!mounted) return;
    if (files.isEmpty) return showToast(context, l.noBackupsFound);
    final chosen = await pickOne<File>(
      context,
      title: l.restoreFromDevice,
      items: [
        for (final f in files)
          PickItem(
            value: f,
            title: backupWhen(context, f.statSync().modified),
            subtitle: _size(f.lengthSync()),
            leading: const Icon(AppIcons.device),
          ),
      ],
    );
    if (chosen == null) return;
    final bytes = await chosen.readAsBytes();
    if (mounted) _openRestore((name: p.basename(chosen.path), bytes: bytes));
  }

  static String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<BackupBloc, BackupState>(
      listenWhen: (a, b) => a.noticeId != b.noticeId,
      listener: (context, s) {
        switch (s.notice!) {
          case BackupNotice.saved || BackupNotice.uploaded:
            unawaited(Haptics.success());
          case BackupNotice.failed || BackupNotice.driveFailed:
            Haptics.warning();
        }
        showToast(context, switch (s.notice!) {
          BackupNotice.saved => l.backupSaved,
          BackupNotice.uploaded => l.backupUploaded,
          BackupNotice.failed => l.backupFailed,
          BackupNotice.driveFailed => l.driveFailed,
        });
      },
      builder: (context, s) {
        final bloc = context.read<BackupBloc>();
        Widget? spinner(BackupDestination d) => s.busy == d
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null;
        return PageScaffold(
          title: l.backupTitle,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              sliver: SliverList.list(
                children: [
                  _StatusCard(last: s.last),
                  const SizedBox(height: AppSpacing.xl),
                  Section(
                    title: l.backupNow,
                    child: SurfaceCard(
                      children: [
                        SettingTile(
                          key: const Key('backupToFile'),
                          icon: AppIcons.file,
                          title: l.backupToFile,
                          subtitle: l.backupToFileHint,
                          trailing: spinner(BackupDestination.file),
                          onTap: s.busy == null
                              ? () => _backup(BackupDestination.file)
                              : null,
                        ),
                        if (s.driveAvailable)
                          SettingTile(
                            key: const Key('backupToDrive'),
                            icon: AppIcons.drive,
                            title: l.backupToDrive,
                            subtitle: l.backupToDriveHint,
                            trailing: spinner(BackupDestination.drive),
                            onTap: s.busy == null
                                ? () => _backup(BackupDestination.drive)
                                : null,
                          ),
                        SettingTile(
                          icon: AppIcons.lock,
                          title: l.encryptBackup,
                          subtitle: l.encryptHint,
                          trailing: AppSwitch(
                            key: const Key('encryptSwitch'),
                            value: _encrypt,
                            onChanged: (v) => setState(() => _encrypt = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Section(
                    title: l.autoBackupSection,
                    child: SurfaceCard(
                      children: [
                        SettingTile(
                          icon: AppIcons.history,
                          title: l.autoBackup,
                          subtitle: l.autoBackupHint,
                          trailing: AppSwitch(
                            key: const Key('autoBackupSwitch'),
                            value: s.auto,
                            onChanged: (v) => bloc.add(AutoBackupToggled(v)),
                          ),
                        ),
                        if (s.auto && s.driveAvailable)
                          SettingTile(
                            icon: AppIcons.wifi,
                            title: l.wifiOnly,
                            subtitle: l.wifiOnlyHint,
                            trailing: AppSwitch(
                              value: s.wifiOnly,
                              onChanged: (v) => bloc.add(WifiOnlyToggled(v)),
                            ),
                          ),
                        if (!s.driveAvailable)
                          Text(
                            l.driveUnavailable,
                            style: context.text.bodySmall,
                          )
                        else if (s.driveAccount == null)
                          SettingTile(
                            key: const Key('driveConnect'),
                            icon: AppIcons.drive,
                            title: l.driveConnect,
                            subtitle: l.driveConnectHint,
                            onTap: () =>
                                bloc.add(const DriveConnectRequested()),
                          )
                        else
                          SettingTile(
                            icon: AppIcons.drive,
                            title: s.driveAccount!,
                            subtitle: l.placeDrive,
                            trailing: TextButton(
                              onPressed: () =>
                                  bloc.add(const DriveDisconnectRequested()),
                              child: Text(l.driveDisconnect),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Section(
                    title: l.restoreSection,
                    child: SurfaceCard(
                      children: [
                        SettingTile(
                          key: const Key('restoreFromFile'),
                          icon: AppIcons.importFile,
                          title: l.restoreFromFile,
                          onTap: _restoreFromFile,
                        ),
                        if (s.driveAvailable)
                          SettingTile(
                            icon: AppIcons.drive,
                            title: l.restoreFromDrive,
                            onTap: _restoreFromDrive,
                          ),
                        SettingTile(
                          key: const Key('restoreFromDevice'),
                          icon: AppIcons.device,
                          title: l.restoreFromDevice,
                          subtitle: l.restoreFromDeviceHint,
                          onTap: _restoreFromDevice,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// "Last backup: 6 Oct 2026, 9:30 AM · Google Drive", or a nudge.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.last});

  final BackupRecord? last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = last;
    return HeadlineCard(
      key: const Key('backupStatus'),
      icon: r == null ? AppIcons.warning : AppIcons.shield,
      color: r == null ? context.colors.warning : null,
      title: r == null ? l.noBackupYet : l.lastBackup,
      subtitle: r == null
          ? l.noBackupBody
          : l.lastBackupAt(
              backupWhen(context, r.createdAt),
              l.place(r.destination),
            ),
    );
  }
}

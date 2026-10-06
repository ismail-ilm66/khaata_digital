import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../../../core/widgets/watch.dart';
import '../data/backup_service.dart';
import '../domain/backup.dart';
import 'backup_health.dart';

/// Home banner (spec 3.2 #9): asks for a backup when none has left the
/// phone in [quietDays] days, and for a restore when the database failed
/// its startup check. Hidden when all is well.
class BackupNudge extends StatelessWidget {
  const BackupNudge({super.key, required this.hasData});

  /// No nagging before the user has recorded anything.
  final bool hasData;

  static const int quietDays = 14;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!getIt<BackupHealth>().databaseOk) {
      return _Banner(
        key: const Key('integrityNudge'),
        danger: true,
        title: l.integrityTitle,
        body: l.integrityBody,
      );
    }
    if (!hasData) return const SizedBox.shrink();
    return Watch<_Status>(
      () => getIt<BackupService>()
          .watchLast(offDevice: true)
          .map((last) => (last: last)),
      builder: (context, status) {
        // Nothing until the first answer, so the banner never flickers in.
        if (status == null) return const SizedBox.shrink();
        final last = status.last;
        final days = last == null
            ? null
            : DateTime.now().toUtc().difference(last.createdAt).inDays;
        if (days != null && days < quietDays) return const SizedBox.shrink();
        return _Banner(
          key: const Key('backupNudge'),
          title: l.backupNudgeTitle,
          body: days == null ? l.backupNudgeNever : l.backupNudgeDays(days),
        );
      },
    );
  }
}

/// The latest off-phone backup. Wrapped so "not loaded yet" (null) and
/// "no backup ever" (`last` null) stay distinct.
typedef _Status = ({BackupRecord? last});

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.title,
    required this.body,
    this.danger = false,
  });

  final String title;
  final String body;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.l),
      child: SurfaceCard(
        children: [
          InkWell(
            onTap: () => context.push(Routes.backup),
            child: Row(
              children: [
                TintedBadge(
                  icon: danger ? AppIcons.warning : AppIcons.backup.regular,
                  color: danger ? c.danger : c.warning,
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleSmall),
                      Text(body, style: context.text.bodySmall),
                    ],
                  ),
                ),
                DirectionalIcon(
                  AppIcons.chevronRight,
                  size: 16,
                  color: c.inkMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

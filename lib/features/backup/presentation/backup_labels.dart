import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../domain/backup.dart';

/// Shared wording for backup screens.
extension BackupLabels on AppLocalizations {
  String place(BackupDestination d) => switch (d) {
    BackupDestination.file => placeFile,
    BackupDestination.drive => placeDrive,
    BackupDestination.device => placeDevice,
  };

  String failure(BackupFailureKind k) => switch (k) {
    BackupFailureKind.notABackup => failNotBackup,
    BackupFailureKind.newerApp => failNewer,
    BackupFailureKind.wrongPassphrase => failPassphrase,
    BackupFailureKind.damaged => failDamaged,
    BackupFailureKind.integrity => failIntegrity,
    BackupFailureKind.conflict => failConflict,
  };
}

/// "6 Oct 2026, 9:30 AM" in the app's language.
String backupWhen(BuildContext context, DateTime at) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final local = at.toLocal();
  return '${DateFormat.yMMMd(locale).format(local)}, '
      '${DateFormat.jm(locale).format(local)}';
}

/// "1 Sep 2026 – 10 Sep 2026"; a single date when both are the same day.
String dateSpan(BuildContext context, DateTime? first, DateTime? last) {
  if (first == null || last == null) return '—';
  final f = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
  final a = f.format(first.toLocal());
  final b = f.format(last.toLocal());
  return a == b ? a : '$a – $b';
}

/// Asks for a backup passphrase (at least 6 characters); null if dismissed.
Future<String?> askPassphrase(BuildContext context, {required String title}) {
  final l = context.l10n;
  return editTextSheet(
    context,
    title: title,
    initial: '',
    hint: l.passphraseHint,
    doneLabel: l.continueLabel,
    icon: AppIcons.lock,
    secret: true,
    minLength: 6,
  );
}

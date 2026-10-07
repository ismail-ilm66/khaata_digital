import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import 'lock_cubit.dart';

/// The phone's own name for its biometrics: "Face ID" / "Touch ID" on
/// iPhone, "Face unlock" / "Fingerprint" on Android.
String biometricName(BuildContext context, BiometricKind? kind) {
  final l = context.l10n;
  return switch (kind) {
    BiometricKind.face => Platform.isIOS ? l.bioFaceId : l.bioFace,
    BiometricKind.fingerprint =>
      Platform.isIOS ? l.bioTouchId : l.bioFingerprint,
    _ => l.useBiometrics, // "Fingerprint or face"
  };
}

IconData biometricIcon(BiometricKind? kind) =>
    kind == BiometricKind.face ? AppIcons.faceId : AppIcons.fingerprint;

/// Right after a PIN is set: on phones with fingerprint / face, offer to
/// use it. Saying yes takes one real scan.
Future<void> offerBiometrics(BuildContext context) async {
  final lock = getIt<LockCubit>();
  final kind = lock.state.biometricKind;
  if (kind == null || lock.state.biometric) return;
  final l = context.l10n;
  final name = biometricName(context, kind);
  final yes = await showAppSheet<bool>(
    context,
    title: l.offerBiometricTitle(name),
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(biometricIcon(kind), size: 48, color: sheet.colors.brand),
          const SizedBox(height: AppSpacing.m),
          Text(
            l.offerBiometricBody,
            textAlign: TextAlign.center,
            style: sheet.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            key: const Key('useBiometric'),
            onPressed: () => Navigator.pop(sheet, true),
            child: Text(l.useBiometricNamed(name)),
          ),
          const SizedBox(height: AppSpacing.s),
          TextButton(
            key: const Key('notNowBiometric'),
            onPressed: () => Navigator.pop(sheet, false),
            child: Text(l.notNow),
          ),
        ],
      ),
    ),
  );
  if (yes == true && context.mounted) {
    await lock.setBiometric(true, reason: l.enableBiometricReason(name));
  }
}

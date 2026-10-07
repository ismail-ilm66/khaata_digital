import 'package:flutter/widgets.dart';

import '../../../core/di/injection.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/theme/context_x.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import 'lock_cubit.dart';
import 'lock_settings_screen.dart';

/// The eye toggle everywhere (Home, More). Hiding is instant; showing
/// balances asks for fingerprint / face — or the PIN — when the app lock
/// is on, so a borrowed, unlocked phone doesn't reveal them.
Future<void> toggleBalances(BuildContext context) async {
  final hide = getIt<HideBalanceCubit>();
  final lock = getIt<LockCubit>();
  Haptics.selection();
  if (!hide.state || !lock.state.enabled) return hide.toggle();
  if (await lock.confirmWithBiometrics(context.l10n.showBalancesReason)) {
    return hide.set(false);
  }
  if (!context.mounted) return;
  if (await confirmCurrentPin(context)) await hide.set(false);
}

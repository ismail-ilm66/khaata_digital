import 'package:flutter/widgets.dart';

import '../../../core/di/injection.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/theme/context_x.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import 'lock_cubit.dart';
import 'lock_settings_screen.dart';

/// The eye on Home: shows or hides balances for this session. Hiding is
/// instant; showing asks for fingerprint / face — or the PIN — when the
/// app lock is on, so a borrowed, unlocked phone doesn't reveal them.
Future<void> toggleBalances(BuildContext context) async {
  final hide = getIt<HideBalanceCubit>();
  Haptics.selection();
  if (!hide.state.masked) return hide.hide();
  if (await _confirm(context)) hide.show();
}

/// More → "Hide balances". Turning it off reveals them, so it asks first
/// in the same way.
Future<void> setHideBalances(BuildContext context, bool on) async {
  final hide = getIt<HideBalanceCubit>();
  Haptics.selection();
  if (on || !hide.state.masked || await _confirm(context)) {
    await hide.setAlways(on);
  }
}

Future<bool> _confirm(BuildContext context) async {
  final lock = getIt<LockCubit>();
  if (!lock.state.enabled) return true;
  if (await lock.confirmWithBiometrics(context.l10n.showBalancesReason)) {
    return true;
  }
  return context.mounted && await confirmCurrentPin(context);
}

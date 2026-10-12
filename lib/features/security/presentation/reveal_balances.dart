import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
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

/// The eye in a page header (Home, Accounts, People, a person): shows or
/// hides every balance for this session.
class BalanceEyeButton extends StatelessWidget {
  const BalanceEyeButton({
    super.key,
    this.buttonKey = const Key('hideBalance'),
  });

  /// Key on the button itself (each page has its own, for tests).
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final masked = context.watch<HideBalanceCubit>().state.masked;
    return IconButton.filledTonal(
      key: buttonKey,
      tooltip: masked ? l.showBalances : l.hideBalances,
      onPressed: () => toggleBalances(context),
      style: IconButton.styleFrom(backgroundColor: c.surface),
      icon: Icon(masked ? AppIcons.hide : AppIcons.show, color: c.ink),
    );
  }
}

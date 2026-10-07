import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import 'lock_cubit.dart';
import 'pin_pad.dart';
import 'biometric_offer.dart';

/// "Immediately", "30 seconds", "1 minute"…
String lockAfterLabel(BuildContext context, Duration d) {
  final l = context.l10n;
  if (d == Duration.zero) return l.lockImmediately;
  return d.inSeconds < 60
      ? l.lockSeconds(d.inSeconds)
      : l.lockMinutes(d.inMinutes);
}

/// Asks for a new PIN twice; null if the user backs out.
Future<String?> askNewPin(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push<String>(MaterialPageRoute(builder: (_) => const _NewPinPage()));

/// Asks for the current PIN; true once it's right.
Future<bool> confirmCurrentPin(BuildContext context) async =>
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push<bool>(MaterialPageRoute(builder: (_) => const _CurrentPinPage())) ??
    false;

/// More → App lock.
class LockSettingsScreen extends StatelessWidget {
  const LockSettingsScreen({super.key});

  Future<void> _turnOn(BuildContext context) async {
    final lock = getIt<LockCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final pin = await askNewPin(context);
    if (pin == null) return;
    await lock.setPin(pin);
    unawaited(Haptics.success());
    messenger.toast(l.lockIsOn);
    if (context.mounted) await offerBiometrics(context);
  }

  Future<void> _change(BuildContext context) async {
    final lock = getIt<LockCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    if (!await confirmCurrentPin(context) || !context.mounted) return;
    final pin = await askNewPin(context);
    if (pin == null) return;
    await lock.setPin(pin);
    unawaited(Haptics.success());
    messenger.toast(l.pinChanged);
  }

  Future<void> _turnOff(BuildContext context) async {
    final lock = getIt<LockCubit>();
    if (!await confirmCurrentPin(context)) return;
    await lock.disable();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<LockCubit, AppLockState>(
      bloc: getIt<LockCubit>(),
      builder: (context, s) => PageScaffold(
        title: l.appLock,
        subtitle: s.enabled ? l.on : l.off,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            sliver: SliverList.list(
              children: [
                Text(l.appLockHint, style: context.text.bodyMedium),
                const SizedBox(height: AppSpacing.l),
                if (!s.enabled)
                  SurfaceCard(
                    children: [
                      SettingTile(
                        key: const Key('turnOnLock'),
                        icon: AppIcons.lock,
                        title: l.turnOnLock,
                        onTap: () => _turnOn(context),
                      ),
                    ],
                  )
                else ...[
                  Section(
                    title: l.appLock,
                    child: SurfaceCard(
                      children: [
                        if (s.biometricAvailable)
                          SettingTile(
                            icon: biometricIcon(s.biometricKind),
                            title: biometricName(context, s.biometricKind),
                            subtitle: l.useBiometricsHint,
                            trailing: AppSwitch(
                              key: const Key('biometricSwitch'),
                              value: s.biometric,
                              onChanged: (on) =>
                                  getIt<LockCubit>().setBiometric(
                                    on,
                                    reason: l.enableBiometricReason(
                                      biometricName(context, s.biometricKind),
                                    ),
                                  ),
                            ),
                          ),
                        SettingTile(
                          key: const Key('lockAfterTile'),
                          icon: AppIcons.timer,
                          title: l.lockAfter,
                          subtitle: l.lockAfterHint,
                          trailing: Text(
                            lockAfterLabel(context, s.lockAfter),
                            style: context.text.titleSmall,
                          ),
                          onTap: () async {
                            final d = await pickOne<Duration>(
                              context,
                              title: l.lockAfter,
                              selected: s.lockAfter,
                              items: [
                                for (final d in LockCubit.lockAfterChoices)
                                  PickItem(
                                    value: d,
                                    title: lockAfterLabel(context, d),
                                  ),
                              ],
                            );
                            if (d != null) {
                              await getIt<LockCubit>().setLockAfter(d);
                            }
                          },
                        ),
                        SettingTile(
                          key: const Key('changePin'),
                          icon: AppIcons.key,
                          title: l.changePin,
                          onTap: () => _change(context),
                        ),
                      ],
                    ),
                  ),
                  SurfaceCard(
                    children: [
                      SettingTile(
                        key: const Key('turnOffLock'),
                        icon: AppIcons.lock,
                        title: l.turnOffLock,
                        onTap: () => _turnOff(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A plain full-screen page around a [PinPad], with a back button.
class _PinPage extends StatelessWidget {
  const _PinPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AmbientBackground(
      child: SafeArea(
        child: Stack(
          children: [
            const Positioned(top: 4, left: 4, child: BackButton()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: child,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NewPinPage extends StatefulWidget {
  const _NewPinPage();

  @override
  State<_NewPinPage> createState() => _NewPinPageState();
}

class _NewPinPageState extends State<_NewPinPage> {
  String? _first;
  bool _mismatch = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _PinPage(
      child: PinPad(
        key: ValueKey(_first == null),
        title: _first == null ? l.choosePin : l.confirmPin,
        message: _mismatch ? l.pinMismatch : null,
        messageIsError: true,
        onComplete: (pin) async {
          if (_first == null) {
            setState(() {
              _first = pin;
              _mismatch = false;
            });
            return true;
          }
          if (pin == _first) {
            Navigator.pop(context, pin);
            return true;
          }
          setState(() {
            _first = null;
            _mismatch = true;
          });
          return false;
        },
      ),
    );
  }
}

class _CurrentPinPage extends StatefulWidget {
  const _CurrentPinPage();

  @override
  State<_CurrentPinPage> createState() => _CurrentPinPageState();
}

class _CurrentPinPageState extends State<_CurrentPinPage> {
  bool _wrong = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _PinPage(
      child: PinPad(
        title: l.currentPin,
        message: _wrong ? l.wrongPin : null,
        messageIsError: true,
        onComplete: (pin) async {
          if (await getIt<LockCubit>().checkPin(pin)) {
            if (context.mounted) Navigator.pop(context, true);
            return true;
          }
          setState(() => _wrong = true);
          return false;
        },
      ),
    );
  }
}

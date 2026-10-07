import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/feedback.dart';
import 'lock_cubit.dart';
import 'pin_pad.dart';
import 'biometric_offer.dart';

/// Sits over the whole app. With the lock on it: shows the lock screen on
/// cold start and when the user comes back after the chosen time away,
/// and covers the app in the app switcher so balances don't show there.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  final LockCubit _lock = getIt<LockCubit>();
  late final AppLifecycleListener _lifecycle;

  /// The app switcher is showing (or about to snapshot) Kharcha.
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () => _cover(true),
      onHide: _lock.backgrounded,
      onShow: _lock.foregrounded,
      onResume: () => _cover(false),
    );
  }

  void _cover(bool on) {
    final want = on && _lock.state.enabled;
    if (want != _covered) setState(() => _covered = want);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LockCubit, AppLockState>(
      bloc: _lock,
      buildWhen: (a, b) => a.locked != b.locked || a.enabled != b.enabled,
      builder: (context, s) => Stack(
        children: [
          // Kept alive underneath, so unlocking lands exactly where the
          // user was.
          ExcludeFocus(excluding: s.locked, child: widget.child),
          if (s.locked) const _LockScreen(key: Key('lockScreen')),
          if (_covered && !s.locked) const _PrivacyCover(),
        ],
      ),
    );
  }
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      key: const Key('privacyCover'),
      color: context.colors.paper,
      child: Center(
        child: Image.asset('assets/splash/mark.png', width: 72, height: 72),
      ),
    ),
  );
}

class _LockScreen extends StatefulWidget {
  const _LockScreen({super.key});

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  final LockCubit _lock = getIt<LockCubit>();
  String? _message;
  bool _error = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _startTicking();
    // Offer fingerprint / face straight away, once.
    WidgetsBinding.instance.addPostFrameCallback((_) => _biometrics());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  bool get _paused {
    final until = _lock.state.pausedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  /// Keeps the pause countdown current.
  void _startTicking() {
    _tick?.cancel();
    if (!_paused) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {});
      if (!_paused) t.cancel();
    });
  }

  Future<void> _biometrics() async {
    if (!mounted || !_lock.state.biometric) return;
    if (await _lock.unlockWithBiometrics(context.l10n.unlockReason)) {
      Haptics.selection();
    }
  }

  Future<bool> _pin(String pin) async {
    final l = context.l10n;
    final result = await _lock.enterPin(pin);
    if (!mounted) return true;
    switch (result) {
      case PinResult.unlocked:
        Haptics.selection();
        return true;
      case PinResult.wrong:
        setState(() {
          _message = l.wrongPin;
          _error = true;
        });
        return false;
      case PinResult.pausedForNow:
        setState(() => _message = null);
        _startTicking();
        return false;
    }
  }

  Future<void> _forgot() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (await _lock.resetWithPhoneLock(l.forgotPinReason)) {
      messenger?.toast(l.lockTurnedOff);
    }
  }

  String _remaining() {
    final left = _lock.state.pausedUntil!.difference(DateTime.now());
    final s = left.inSeconds + 1;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final paused = _paused;
    final biometric = _lock.state.biometric;
    return Positioned.fill(
      child: Material(
        child: AmbientBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/splash/mark.png',
                      width: 64,
                      height: 64,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PinPad(
                      title: l.enterPin,
                      enabled: !paused,
                      message: paused ? l.pinPaused(_remaining()) : _message,
                      messageIsError: paused || _error,
                      onComplete: _pin,
                      // No tooltip: this sits above the navigator, with no
                      // overlay to show one in. The icon carries the label.
                      bottomLeft: biometric
                          ? IconButton(
                              key: const Key('unlockBiometric'),
                              onPressed: _biometrics,
                              icon: Icon(
                                biometricIcon(_lock.state.biometricKind),
                                semanticLabel: biometricName(
                                  context,
                                  _lock.state.biometricKind,
                                ),
                                size: 28,
                                color: c.brand,
                              ),
                            )
                          : null,
                      footer: TextButton(
                        key: const Key('forgotPin'),
                        onPressed: _forgot,
                        child: Text(l.forgotPin),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

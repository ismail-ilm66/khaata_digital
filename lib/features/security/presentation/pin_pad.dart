import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/feedback/haptics.dart';
import '../../../core/money/amount_buffer.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/keypad.dart';
import 'lock_cubit.dart';

/// Four dots and the app's number pad. When the fourth digit lands,
/// [onComplete] decides: true clears quietly; false shakes the dots, gives
/// a warning tap and clears for another try.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.onComplete,
    this.message,
    this.messageIsError = false,
    this.enabled = true,
    this.bottomLeft,
    this.footer,
  });

  final String title;
  final Future<bool> Function(String pin) onComplete;

  /// Shown under the dots (e.g. "Wrong PIN", a pause countdown).
  final String? message;
  final bool messageIsError;

  /// False while entry is paused.
  final bool enabled;
  final Widget? bottomLeft;
  final Widget? footer;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _checking = false;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _key(KeypadKey k) async {
    if (!widget.enabled || _checking) return;
    setState(() {
      if (k == KeypadKey.backspace) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (k == KeypadKey.clear) {
        _pin = '';
      } else if (k.digitValue != null && _pin.length < LockCubit.pinLength) {
        _pin += '${k.digitValue}';
      }
    });
    if (_pin.length < LockCubit.pinLength) return;
    setState(() => _checking = true);
    final ok = await widget.onComplete(_pin);
    if (!mounted) return;
    if (!ok) {
      Haptics.warning();
      await _shake.forward(from: 0);
    }
    if (mounted) {
      setState(() {
        _pin = '';
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: context.text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              sin(_shake.value * pi * 6) * 10 * (1 - _shake.value),
              0,
            ),
            child: child,
          ),
          child: Row(
            key: const Key('pinDots'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < LockCubit.pinLength; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? c.ink : Colors.transparent,
                    border: Border.all(color: c.inkMuted, width: 1.5),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: Center(
            child: widget.message == null
                ? null
                : Text(
                    widget.message!,
                    key: const Key('pinMessage'),
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall!.copyWith(
                      color: widget.messageIsError ? c.danger : c.inkMuted,
                    ),
                  ),
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.enabled ? 1 : 0.35,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Keypad(
              allowDecimal: false,
              keyHeight: 64,
              onKey: _key,
              bottomLeft: widget.bottomLeft,
            ),
          ),
        ),
        ?widget.footer,
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';
import 'app_icons.dart';

/// A labelled group of content. The label is small and quiet so the
/// content leads; optional [trailing] sits opposite. With [onTap] the
/// label itself opens the full screen ("Accounts ›").
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            style: context.text.labelLarge!.copyWith(color: c.inkMuted),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 2),
          DirectionalIcon(AppIcons.chevronRight, size: 14, color: c.inkMuted),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.xs,
              // A tappable label pads itself; the content stays as close.
              bottom: onTap == null ? AppSpacing.s : AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: onTap == null
                        ? label
                        : Semantics(
                            button: true,
                            child: InkWell(
                              key: Key('section-$title'),
                              onTap: onTap,
                              borderRadius: BorderRadius.circular(AppRadii.s),
                              // A larger target around a small label.
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                child: label,
                              ),
                            ),
                          ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

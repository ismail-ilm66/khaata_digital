import 'package:flutter/material.dart';

import 'app_icons.dart';
import '../theme/app_tokens.dart';
import '../theme/context_x.dart';

/// A compact rounded chip-button: optional leading widget, label, and a
/// selected state. Used for the Add sheet's account/date chips and for
/// list filters.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.icon,
    this.selected = false,
    this.showChevron = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final IconData? icon;
  final bool selected;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.brand : c.ink;
    return Material(
      color: selected ? c.brand.withValues(alpha: 0.12) : c.surfaceMuted,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? c.brand.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.s),
              ],
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge!.copyWith(color: fg),
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(AppIcons.chevronDown, size: 14, color: c.inkMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

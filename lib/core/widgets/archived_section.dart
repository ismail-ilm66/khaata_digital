import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';
import 'surface_card.dart';

/// A collapsed "Archived · N" group at the foot of a list (accounts,
/// categories), each row with a Restore button. Archived names are
/// reusable, so restoring can fail with a duplicate — callers handle it.
class ArchivedSection extends StatelessWidget {
  const ArchivedSection({super.key, required this.items});

  final List<ArchivedItem> items;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const Key('archivedSection'),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        title: Text(
          '${l.archived} · ${items.length}',
          style: context.text.labelLarge!.copyWith(
            color: context.colors.inkMuted,
          ),
        ),
        children: [
          SurfaceCard(
            children: [
              for (final item in items)
                Row(
                  children: [
                    Opacity(opacity: 0.6, child: item.badge),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(item.name, style: context.text.bodyMedium),
                    ),
                    TextButton(
                      onPressed: item.onRestore,
                      child: Text(l.restore),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ArchivedItem {
  const ArchivedItem({
    required this.badge,
    required this.name,
    required this.onRestore,
  });

  final Widget badge;
  final String name;
  final VoidCallback onRestore;
}

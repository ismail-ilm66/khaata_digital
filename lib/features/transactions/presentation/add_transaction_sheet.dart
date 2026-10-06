import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/empty_state.dart';

/// The Add tab opens this modal sheet rather than a full screen (spec 3.2 #3).
/// The real entry form lands in M2.
class AddTransactionSheet extends StatelessWidget {
  const AddTransactionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: Column(
        children: [
          Text(
            l10n.addTransactionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.add_circle_outline,
              message: l10n.comingSoon,
            ),
          ),
        ],
      ),
    );
  }
}

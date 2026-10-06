import 'package:flutter/material.dart';

import '../../../core/theme/context_x.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_icons.dart';

/// The Add tab opens this modal sheet rather than a full screen (spec 3.2 #3).
/// The real entry form lands in M2.
class AddTransactionSheet extends StatelessWidget {
  const AddTransactionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: Column(
        children: [
          Text(
            context.l10n.addTransactionTitle,
            style: context.text.titleLarge,
          ),
          Expanded(
            child: EmptyState(
              icon: AppIcons.quickAdd.filled,
              title: context.l10n.comingSoon,
              message: context.l10n.addEmpty,
            ),
          ),
        ],
      ),
    );
  }
}

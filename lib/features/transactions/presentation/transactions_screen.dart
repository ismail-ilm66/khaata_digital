import 'package:flutter/material.dart';

import '../../../core/theme/context_x.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../core/widgets/app_icons.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: context.l10n.navTransactions,
    icon: AppIcons.transactions.filled,
    message: context.l10n.transactionsEmpty,
  );
}

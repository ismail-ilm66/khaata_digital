import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/transactions/presentation/add_transaction_sheet.dart';
import '../theme/context_x.dart';
import '../widgets/ambient_background.dart';
import '../widgets/app_icons.dart';
import '../widgets/glass_nav_bar.dart';

/// Tab shell: Home · Transactions · (+) · Reports · More.
///
/// Pages draw over a shared [AmbientBackground] and scroll under the
/// floating [GlassNavBar]. The centre "+" is not a tab — it opens
/// [AddTransactionSheet] over whichever tab is showing.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      extendBody: true,
      backgroundColor: context.colors.paper,
      body: AmbientBackground(child: shell),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: shell.currentIndex,
        onSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        actionLabel: l10n.navAdd,
        onAction: () => AddTransactionSheet.show(context),
        items: [
          GlassNavItem(icon: AppIcons.home, label: l10n.navHome),
          GlassNavItem(
            icon: AppIcons.transactions,
            label: l10n.navTransactions,
          ),
          GlassNavItem(icon: AppIcons.reports, label: l10n.navReports),
          GlassNavItem(icon: AppIcons.more, label: l10n.navMore),
        ],
      ),
    );
  }
}

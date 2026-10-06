import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/transactions/presentation/add_transaction_sheet.dart';
import '../l10n/gen/app_localizations.dart';

/// Bottom-nav shell: Home · Transactions · (+) Add · Reports · More.
///
/// The Add tab is not a branch — it opens [AddTransactionSheet] over the
/// current tab, so nav index 2 is skipped when mapping to shell branches.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const int _addIndex = 2;

  int get _navIndex => shell.currentIndex >= _addIndex
      ? shell.currentIndex + 1
      : shell.currentIndex;

  void _onTap(BuildContext context, int navIndex) {
    if (navIndex == _addIndex) {
      AddTransactionSheet.show(context);
      return;
    }
    final branch = navIndex > _addIndex ? navIndex - 1 : navIndex;
    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.navTransactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle, size: 36),
            label: l10n.navAdd,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: l10n.navReports,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}

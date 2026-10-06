import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/transactions/presentation/form/entry_editor_screen.dart';
import '../theme/context_x.dart';
import '../widgets/app_icons.dart';
import '../widgets/glass_nav_bar.dart';

/// Tab shell: Home · Transactions · (+) · Reports · More.
///
/// Tab pages scroll under the floating [GlassNavBar]; sub-pages are pushed
/// full-screen on the root navigator (see `app_router.dart`). The centre "+" is not a tab — it opens
/// [EntryEditorScreen] over whichever tab is showing.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      extendBody: true,
      backgroundColor: context.colors.paper,
      body: GlassNavBarScope(child: shell),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: shell.currentIndex,
        onSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        actionLabel: l10n.navAdd,
        onAction: () => EntryEditor.open(context),
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

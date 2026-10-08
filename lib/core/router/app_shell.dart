import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/security/presentation/lock_cubit.dart';
import '../di/injection.dart';

import '../../features/onboarding/presentation/home_tour.dart';
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
    // Android back: another tab → Home; Home → leave the app, locked, so
    // reopening it always asks (Android 12+ only backgrounds the app).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (shell.currentIndex != 0) {
          shell.goBranch(0);
          return;
        }
        getIt<LockCubit>().lockNow();
        SystemNavigator.pop();
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: context.colors.paper,
        // Each tab's own navigator reports "nothing to go back to" at its
        // root, and Android then closes the app itself, never asking
        // Flutter. In the shell back always does something (Home, or lock
        // and leave), so tell Android that Flutter handles it.
        body: NotificationListener<NavigationNotification>(
          onNotification: (n) {
            if (n.canHandlePop) return false;
            const NavigationNotification(canHandlePop: true).dispatch(context);
            return true;
          },
          child: GlassNavBarScope(child: shell),
        ),
        bottomNavigationBar: GlassNavBar(
          selectedIndex: shell.currentIndex,
          onSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          actionLabel: l10n.navAdd,
          onAction: () => EntryEditor.open(context),
          actionKey: TourTargets.add,
          tabKeys: TourTargets.tabs,
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
      ),
    );
  }
}

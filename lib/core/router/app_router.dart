import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/account_form_screen.dart';
import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/backup/presentation/restore_screen.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/import_export/presentation/import_screen.dart';
import '../../features/people/presentation/people_screen.dart';
import '../../features/people/presentation/person_screen.dart';
import '../../features/recurring/presentation/recurring_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/more_screen.dart';
import '../../features/transactions/presentation/entries_screen.dart';
import '../../features/transactions/presentation/entry_detail_screen.dart';
import '../../features/transactions/presentation/form/entry_editor_screen.dart';
import '../../features/transactions/presentation/search_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../files/file_gateway.dart';
import 'app_shell.dart';
import 'routes.dart';
import '../../features/security/presentation/lock_settings_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/settings/presentation/about_screen.dart';
import '../../features/settings/presentation/privacy_screen.dart';

/// Builds a fresh router.
///
/// The four tabs are branches of a [StatefulShellRoute] (order must match
/// [AppShell]). Every other page is a top-level route on the root
/// navigator: it slides in over the whole app — glass nav bar included —
/// from any tab, without switching tabs underneath.
GoRouter createRouter({String initialLocation = Routes.home}) {
  final root = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: root,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.transactions,
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.reports,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.more,
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
      // Add / edit slides up as a full-screen task.
      GoRoute(
        path: Routes.addEntry,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: EntryEditorScreen(args: state.extra as EntryEditorArgs?),
        ),
      ),
      GoRoute(
        path: Routes.editEntryPattern,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: EntryEditorScreen(editId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: Routes.entries,
        builder: (context, state) =>
            EntriesScreen(args: state.extra! as EntriesArgs),
      ),
      GoRoute(
        path: Routes.budgets,
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: Routes.people,
        builder: (context, state) => const PeopleScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                PersonScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.recurring,
        builder: (context, state) => const RecurringScreen(),
      ),
      GoRoute(
        path: Routes.backup,
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: Routes.restore,
        builder: (context, state) =>
            RestoreScreen(file: state.extra! as PickedFile),
      ),
      GoRoute(
        path: Routes.importData,
        builder: (context, state) => const ImportScreen(),
      ),
      GoRoute(
        path: Routes.privacy,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: Routes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: Routes.categories,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.appLock,
        builder: (context, state) => const LockSettingsScreen(),
      ),
      GoRoute(
        path: Routes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: Routes.entryPattern,
        builder: (context, state) =>
            EntryDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.accounts,
        builder: (context, state) => const AccountsScreen(),
        routes: [
          GoRoute(
            path: 'form',
            builder: (context, state) => AccountFormScreen(
              args: state.extra as AccountFormArgs? ?? const AccountFormArgs(),
            ),
          ),
        ],
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/coach_tour.dart';
import '../../settings/domain/setting_key.dart';
import '../../settings/domain/settings_repository.dart';

/// What the how-to tour points at, attached by Home and the tab bar.
abstract final class TourTargets {
  static final add = GlobalKey(debugLabel: 'tour-add');
  static final netWorth = GlobalKey(debugLabel: 'tour-net-worth');
  static final eye = GlobalKey(debugLabel: 'tour-eye');
  static final thisMonth = GlobalKey(debugLabel: 'tour-this-month');
  static final accounts = GlobalKey(debugLabel: 'tour-accounts');

  /// Home, Transactions, Reports, More.
  static final tabs = List.generate(
    4,
    (i) => GlobalKey(debugLabel: 'tour-tab-$i'),
  );
}

bool _running = false;

/// First visit to Home: the tour, once (finished or skipped), whether or
/// not the welcome was skipped.
Future<void> maybeStartHomeTour(BuildContext context) async {
  final settings = getIt<SettingsRepository>();
  if (await settings.read(SettingKey.tourDone) == 'true') return;
  if (context.mounted) await startHomeTour(context);
}

/// More → How to use Kharcha: back to Home, then the tour.
Future<void> replayHomeTour(BuildContext context) async {
  context.go(Routes.home);
  // Wait for Home to be laid out with its data.
  for (var i = 0; i < 60 && TourTargets.netWorth.currentContext == null; i++) {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
  final home = TourTargets.netWorth.currentContext;
  if (home != null && home.mounted) await startHomeTour(home);
}

Future<void> startHomeTour(BuildContext context) async {
  if (_running) return;
  _running = true;
  try {
    final l = context.l10n;
    await showCoachTour(
      context,
      labels: CoachLabels(
        next: l.next,
        done: l.gotIt,
        skip: l.skip,
        progress: l.tourProgress,
      ),
      steps: [
        CoachStep(
          target: TourTargets.add,
          title: l.tourAddTitle,
          body: l.tourAddBody,
        ),
        CoachStep(
          target: TourTargets.netWorth,
          title: l.tourNetWorthTitle,
          body: l.tourNetWorthBody,
        ),
        CoachStep(
          target: TourTargets.eye,
          title: l.tourEyeTitle,
          body: l.tourEyeBody,
        ),
        CoachStep(
          target: TourTargets.thisMonth,
          title: l.tourMonthTitle,
          body: l.tourMonthBody,
        ),
        CoachStep(
          target: TourTargets.accounts,
          title: l.tourAccountsTitle,
          body: l.tourAccountsBody,
        ),
        CoachStep(
          target: TourTargets.tabs[1],
          title: l.navTransactions,
          body: l.tourTransactionsBody,
        ),
        CoachStep(
          target: TourTargets.tabs[2],
          title: l.navReports,
          body: l.tourReportsBody,
        ),
        CoachStep(
          target: TourTargets.tabs[3],
          title: l.navMore,
          body: l.tourMoreBody,
        ),
      ],
    );
    await getIt<SettingsRepository>().write(SettingKey.tourDone, 'true');
    // Back to the top of Home, where the tour began.
    final top = TourTargets.eye.currentContext;
    if (top != null && top.mounted) {
      await Scrollable.ensureVisible(
        top,
        duration: AppMotion.slow,
        curve: AppMotion.out,
      );
    }
  } finally {
    _running = false;
  }
}

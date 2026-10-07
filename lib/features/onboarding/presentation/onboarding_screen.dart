import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/money/currency.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/dates/budget_cycle.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../../security/presentation/lock_cubit.dart';
import '../../security/presentation/lock_settings_screen.dart';
import '../../settings/presentation/month_start_label.dart';
import 'onboarding_cubit.dart';
import '../../security/presentation/biometric_offer.dart';

/// First run: three short, skippable pages, then Home.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<OnboardingCubit>(),
    child: const _OnboardingView(),
  );
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<OnboardingCubit>().finish();
    if (mounted) context.go(Routes.home);
  }

  void _next(int page) {
    Haptics.tap();
    if (page == OnboardingState.pages - 1) {
      _finish();
      return;
    }
    _pages.animateToPage(
      page + 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final page = context.select((OnboardingCubit b) => b.state.page);
    final last = page == OnboardingState.pages - 1;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s),
                  child: AnimatedOpacity(
                    opacity: last ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      key: const Key('onboardingSkip'),
                      onPressed: last ? null : _finish,
                      child: Text(l.skip),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: context.read<OnboardingCubit>().goTo,
                  children: const [_Promise(), _Setup(), _Extras()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.s,
                  AppSpacing.page,
                  AppSpacing.l,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < OnboardingState.pages; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == page ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == page ? c.brand : c.line,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    FilledButton(
                      key: const Key('onboardingNext'),
                      onPressed: () => _next(page),
                      child: Text(last ? l.startUsing : l.next),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A page: headline, a quiet line under it, then its content.
class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.body,
    required this.children,
    this.top,
  });

  final String title;
  final String body;
  final Widget? top;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.page,
      vertical: AppSpacing.l,
    ),
    children: [
      ?top,
      Text(title, style: context.text.headlineMedium),
      const SizedBox(height: AppSpacing.s),
      Text(
        body,
        style: context.text.bodyLarge!.copyWith(color: context.colors.inkMuted),
      ),
      const SizedBox(height: AppSpacing.xl),
      ...children,
    ],
  );
}

class _Promise extends StatelessWidget {
  const _Promise();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget point(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Row(
        children: [
          TintedBadge(icon: icon, size: 40),
          const SizedBox(width: AppSpacing.m),
          Expanded(child: Text(text, style: context.text.titleSmall)),
        ],
      ),
    );
    return _Page(
      top: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Image.asset('assets/splash/mark.png', width: 64, height: 64),
        ),
      ),
      title: l.welcomeTitle,
      body: l.welcomeBody,
      children: [
        point(AppIcons.device, l.promiseOffline),
        point(AppIcons.backup.regular, l.promiseBackup),
        point(AppIcons.monthStart.regular, l.promisePayday),
        point(AppIcons.shield, l.promiseFree),
      ],
    );
  }
}

class _Setup extends StatelessWidget {
  const _Setup();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.watch<OnboardingCubit>().state;
    final cubit = context.read<OnboardingCubit>();
    return _Page(
      title: l.setupTitle,
      body: l.setupBody,
      children: [
        SurfaceCard(
          children: [
            SettingTile(
              key: const Key('onboardingCurrency'),
              icon: AppIcons.accounts.regular,
              title: l.homeCurrency,
              subtitle: l.homeCurrencyHint,
              trailing: Text(s.currency.code, style: context.text.titleSmall),
              onTap: () async {
                final c = await pickOne<Currency>(
                  context,
                  title: l.homeCurrency,
                  selected: s.currency,
                  items: [
                    for (final c in Currency.known)
                      PickItem(
                        value: c,
                        title: c.code,
                        subtitle: c.symbol == c.code ? null : c.symbol,
                      ),
                  ],
                );
                if (c != null) await cubit.setCurrency(c);
              },
            ),
            SettingTile(
              key: const Key('onboardingMonthStart'),
              icon: AppIcons.monthStart.regular,
              title: l.monthStart,
              subtitle: l.monthStartHint,
              trailing: Text(
                monthStartLabel(context, s.cycle),
                style: context.text.titleSmall,
              ),
              onTap: () async {
                final c = await pickOne<BudgetCycle>(
                  context,
                  title: l.monthStart,
                  selected: s.cycle,
                  items: [
                    for (final c in BudgetCycle.choices)
                      PickItem(value: c, title: monthStartLabel(context, c)),
                  ],
                );
                if (c != null) await cubit.setCycle(c);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Extras extends StatelessWidget {
  const _Extras();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.watch<OnboardingCubit>().state;
    final cubit = context.read<OnboardingCubit>();
    final lock = getIt<LockCubit>();
    Widget done() => Icon(AppIcons.check, color: context.colors.brand);
    return _Page(
      title: l.extrasTitle,
      body: l.extrasBody,
      children: [
        SurfaceCard(
          children: [
            SettingTile(
              key: const Key('onboardingImport'),
              icon: AppIcons.importFile,
              title: l.extrasImport,
              subtitle: l.extrasImportHint,
              trailing: s.imported ? done() : null,
              onTap: () async {
                await context.push(Routes.importData);
                cubit.imported();
              },
            ),
            BlocBuilder<LockCubit, AppLockState>(
              bloc: lock,
              builder: (context, ls) => SettingTile(
                key: const Key('onboardingLock'),
                icon: AppIcons.lock,
                title: l.extrasLock,
                subtitle: l.extrasLockHint,
                trailing: ls.enabled ? done() : null,
                onTap: ls.enabled
                    ? null
                    : () async {
                        final pin = await askNewPin(context);
                        if (pin == null) return;
                        await lock.setPin(pin);
                        if (context.mounted) await offerBiometrics(context);
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

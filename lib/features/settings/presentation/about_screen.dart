import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/lifecycle/system_screens.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/headline_card.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/watch.dart';
import '../data/diagnostics.dart';
import '../domain/changelog.dart';

/// More → About (spec 3.2 #10): version, changelog, contact us with a
/// prefilled diagnostics email, and the "No ads, ever" promise.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _contact(BuildContext context) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final report = await getIt<Diagnostics>().report();
    final to = Diagnostics.supportEmail;
    if (to.isNotEmpty) {
      final mail = Uri(
        scheme: 'mailto',
        path: to,
        query: _query({
          'subject': l.supportSubject,
          'body': '\n\n---\n$report',
        }),
      );
      try {
        if (await SystemScreens.show(() => launchUrl(mail))) return;
      } catch (_) {
        // No mail app: fall through to copying.
      }
    }
    await Clipboard.setData(ClipboardData(text: report));
    messenger.toast(l.diagnosticsCopied);
  }

  /// mailto wants %20, not "+", for spaces.
  static String _query(Map<String, String> params) => params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PageScaffold(
      title: l.about,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          sliver: SliverList.list(
            children: [
              Watch<String>(
                () => Stream.fromFuture(getIt<Diagnostics>().appVersion()),
                builder: (context, version) => HeadlineCard(
                  key: const Key('aboutHeadline'),
                  icon: AppIcons.shield,
                  title: 'Kharcha',
                  subtitle: version == null ? null : l.version(version),
                  footer: Text(l.noAds, style: context.text.bodyMedium),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SurfaceCard(
                children: [
                  SettingTile(
                    key: const Key('contactUs'),
                    icon: AppIcons.note,
                    title: Diagnostics.supportEmail.isEmpty
                        ? l.copyDiagnostics
                        : l.contactUs,
                    subtitle: Diagnostics.supportEmail.isEmpty
                        ? l.copyDiagnosticsHint
                        : l.contactUsHint,
                    onTap: () => _contact(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Section(
                title: l.whatsNew,
                child: SurfaceCard(
                  children: [
                    for (final release in changelog)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${release.version} · ${release.date}',
                            style: context.text.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          for (final note in release.notes)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('•  ', style: context.text.bodySmall),
                                  Expanded(
                                    child: Text(
                                      note,
                                      style: context.text.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

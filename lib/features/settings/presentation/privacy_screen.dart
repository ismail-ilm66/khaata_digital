import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/simple_markdown.dart';
import '../../../core/widgets/watch.dart';

/// The privacy policy, from the same file that's published for Google
/// Play (`docs/privacy-policy.md`), so the two can't drift apart.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const String asset = 'docs/privacy-policy.md';

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: context.l10n.privacyPolicy,
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        sliver: SliverToBoxAdapter(
          child: Watch<String>(
            () => Stream.fromFuture(rootBundle.loadString(asset)),
            builder: (context, text) => text == null
                ? const SizedBox.shrink()
                // The page title is already the heading.
                : SimpleMarkdown(text.replaceFirst(RegExp(r'^# .*\n'), '')),
          ),
        ),
      ),
    ],
  );
}

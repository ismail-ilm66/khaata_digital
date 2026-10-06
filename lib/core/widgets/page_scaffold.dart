import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';
import 'glass_nav_bar.dart';

/// The layout every tab uses: a large title that scrolls away with the
/// content, a transparent background (so the shell's ambient glow shows),
/// and bottom padding that clears the floating glass nav bar.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Action shown beside the title (e.g. a search or settings button).
  final Widget? trailing;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PageHeader(
                  title: title,
                  subtitle: subtitle,
                  trailing: trailing,
                ),
              ),
              ...slivers,
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: GlassNavBar.clearance(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page + AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.page,
        AppSpacing.l,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(subtitle!, style: context.text.bodySmall),
                  ),
                Text(title, style: context.text.headlineLarge),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';
import 'ambient_background.dart';
import 'app_icons.dart';
import 'glass_nav_bar.dart';

/// The layout every page uses: a large title that scrolls away with the
/// content over the ambient background, and bottom padding that clears the
/// floating glass nav bar when the page sits under it.
///
/// Pages are opaque so push/pop transitions never show the page beneath.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String? subtitle;

  /// Action shown beside the title (e.g. a search or settings button).
  final Widget? trailing;
  final List<Widget> slivers;

  /// Pinned under the content (a page's main action, e.g. "Import").
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scroll = CustomScrollView(
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
            bottom: bottom == null
                ? GlassNavBar.clearance(context)
                : AppSpacing.l,
          ),
        ),
      ],
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: AmbientBackground(
          child: SafeArea(
            bottom: bottom != null,
            child: bottom == null
                ? scroll
                : Column(
                    children: [
                      Expanded(child: scroll),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          AppSpacing.s,
                          AppSpacing.page,
                          AppSpacing.l,
                        ),
                        child: bottom,
                      ),
                    ],
                  ),
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
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page + AppSpacing.xs,
        canPop ? AppSpacing.xs : AppSpacing.xl,
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
                if (canPop)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.maybePop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.surface,
                      ),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      icon: DirectionalIcon(
                        AppIcons.back,
                        size: 18,
                        color: context.colors.ink,
                      ),
                    ),
                  ),
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

import 'package:flutter/material.dart';

import '../theme/context_x.dart';
import 'empty_state.dart';
import 'page_scaffold.dart';

/// A tab whose feature lands in a later milestone: real page chrome with an
/// empty state that says what will live here.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: title,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: icon,
            title: context.l10n.comingSoon,
            message: message,
          ),
        ),
      ],
    );
  }
}

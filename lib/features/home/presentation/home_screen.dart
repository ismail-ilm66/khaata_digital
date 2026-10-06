import 'package:flutter/material.dart';

import '../../../core/theme/context_x.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../core/widgets/app_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: context.l10n.appTitle,
    icon: AppIcons.home.filled,
    message: context.l10n.homeEmpty,
  );
}

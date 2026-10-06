import 'package:flutter/material.dart';

import '../../../core/theme/context_x.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../core/widgets/app_icons.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: context.l10n.navReports,
    icon: AppIcons.reports.filled,
    message: context.l10n.reportsEmpty,
  );
}

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import 'app_colors.dart';

/// Shortcuts so widgets don't repeat `Theme.of(context)…` boilerplate.
extension AppContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

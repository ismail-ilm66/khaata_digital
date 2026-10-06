// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kharcha';

  @override
  String get navHome => 'Home';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navAdd => 'Add';

  @override
  String get navReports => 'Reports';

  @override
  String get navMore => 'More';

  @override
  String get addTransactionTitle => 'Add transaction';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUrdu => 'اردو';

  @override
  String get homeEmpty =>
      'Your month at a glance: balance, budgets and recent spending.';

  @override
  String get transactionsEmpty =>
      'Every expense, income and transfer, grouped by day.';

  @override
  String get reportsEmpty =>
      'Charts for any date range, with your full history.';

  @override
  String get addEmpty => 'Log an expense in three taps.';

  @override
  String get settingsAppearance => 'Appearance';
}

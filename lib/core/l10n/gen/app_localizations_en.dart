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

  @override
  String get typeExpense => 'Expense';

  @override
  String get typeIncome => 'Income';

  @override
  String get typeTransfer => 'Transfer';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get clear => 'Clear';

  @override
  String get cancel => 'Cancel';

  @override
  String get undo => 'Undo';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get saved => 'Saved';

  @override
  String get deleted => 'Transaction deleted';

  @override
  String get noCategory => 'No category';

  @override
  String get category => 'Category';

  @override
  String get account => 'Account';

  @override
  String get fromAccount => 'From';

  @override
  String get toAccount => 'To';

  @override
  String get date => 'Date';

  @override
  String get note => 'Note';

  @override
  String get notePlaceholder => 'Add a note';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint => 'Comma separated, e.g. office, lunch';

  @override
  String get receipts => 'Receipts';

  @override
  String get addReceipt => 'Add receipt';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get receives => 'Receives';

  @override
  String rateLabel(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get problemAmount => 'Enter an amount';

  @override
  String get problemAccount => 'Choose an account';

  @override
  String get problemDestination => 'Choose where the money goes';

  @override
  String get problemSameAccount => 'Pick two different accounts';

  @override
  String get problemConversion => 'Enter the amount received';

  @override
  String get receiptFailed => 'Couldn\'t attach that image. Try another photo.';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Note, amount, category or tag';

  @override
  String get filterType => 'Type';

  @override
  String get filterAccount => 'Account';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterTag => 'Tag';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noTransactionsBody => 'Tap + to log your first expense.';

  @override
  String get noMatches => 'Nothing matches';

  @override
  String get noMatchesBody => 'Try a different search or clear the filters.';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get transferTitle => 'Transfer';

  @override
  String get exchangeRate => 'Exchange rate';

  @override
  String get accounts => 'Accounts';

  @override
  String get addAccount => 'Add account';

  @override
  String get newAccount => 'New account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get accountName => 'Name';

  @override
  String get accountType => 'Type';

  @override
  String get currency => 'Currency';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get excludeFromTotal => 'Exclude from net worth';

  @override
  String get excludeFromTotalHint =>
      'For savings or money you don\'t spend from';

  @override
  String get archive => 'Archive';

  @override
  String get archived => 'Archived';

  @override
  String get restore => 'Restore';

  @override
  String get netWorth => 'Net worth';

  @override
  String get custom => 'Custom';

  @override
  String get customHint => 'Any other bank, wallet or cash';

  @override
  String duplicateAccountName(String name) {
    return 'You already have an account called $name';
  }

  @override
  String get nameRequired => 'Give it a name';

  @override
  String get invalidAmount => 'Enter a valid amount';

  @override
  String get notInTotal => 'Not in total';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeWallet => 'Wallet';

  @override
  String get accountTypeCard => 'Card';

  @override
  String get accountTypeSavings => 'Savings';

  @override
  String get chooseAccount => 'Choose an account';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get thisCycle => 'This month';

  @override
  String get income => 'Income';

  @override
  String get spent => 'Spent';

  @override
  String get left => 'Left';

  @override
  String get recent => 'Recent';

  @override
  String get seeAll => 'See all';

  @override
  String get manage => 'Manage';

  @override
  String get hideBalances => 'Hide balances';

  @override
  String get showBalances => 'Show balances';

  @override
  String get yourMoney => 'Your money';

  @override
  String get accountsSubtitle => 'Banks, wallets and cash';

  @override
  String get accountArchived => 'Account archived';

  @override
  String get saveExpense => 'Save expense';

  @override
  String get saveIncome => 'Save income';

  @override
  String get saveTransfer => 'Save transfer';

  @override
  String get allCategories => 'All';

  @override
  String get swapAccounts => 'Swap accounts';

  @override
  String tagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return '$_temp0';
  }

  @override
  String receiptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count receipts',
      one: '1 receipt',
    );
    return '$_temp0';
  }

  @override
  String get receipt => 'Receipt';
}

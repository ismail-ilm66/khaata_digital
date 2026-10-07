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

  @override
  String get budgets => 'Budgets';

  @override
  String get budgetsSubtitle => 'Limits for each month';

  @override
  String get overallBudget => 'Overall';

  @override
  String get overallBudgetHint => 'Everything you spend this month';

  @override
  String get addBudget => 'Add budget';

  @override
  String get editBudget => 'Edit budget';

  @override
  String get removeBudget => 'Remove budget';

  @override
  String get copyLastMonth => 'Copy last month';

  @override
  String copiedBudgets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count budgets',
      one: 'Copied 1 budget',
      zero: 'Nothing to copy from last month',
    );
    return '$_temp0';
  }

  @override
  String get noBudgets => 'No budgets yet';

  @override
  String get noBudgetsBody =>
      'Set a limit for the month or for a category, and watch it fill as you spend.';

  @override
  String budgetLeft(String amount) {
    return '$amount left';
  }

  @override
  String budgetOver(String amount) {
    return '$amount over';
  }

  @override
  String get budgetLimit => 'Monthly limit';

  @override
  String get previousCycle => 'Previous month';

  @override
  String get nextCycle => 'Next month';

  @override
  String get people => 'People';

  @override
  String get peopleSubtitle => 'Udhaar: who owes whom';

  @override
  String get youllReceive => 'You\'ll receive';

  @override
  String get youOwe => 'You owe';

  @override
  String get addPerson => 'Add person';

  @override
  String get personName => 'Name';

  @override
  String get person => 'Person';

  @override
  String get choosePerson => 'Choose a person';

  @override
  String get noPeople => 'No udhaar yet';

  @override
  String get noPeopleBody => 'Add someone you lend to or borrow from.';

  @override
  String get owesYou => 'Owes you';

  @override
  String get youOweThem => 'You owe';

  @override
  String get settled => 'Settled';

  @override
  String get iGave => 'I gave';

  @override
  String get iReceived => 'I received';

  @override
  String get settleUp => 'Settle up';

  @override
  String get typeUdhaar => 'Udhaar';

  @override
  String get saveUdhaar => 'Save udhaar';

  @override
  String duplicatePersonName(String name) {
    return '$name is already in your people';
  }

  @override
  String get removePerson => 'Remove person';

  @override
  String get personRemoved => 'Person removed';

  @override
  String get noLedger => 'No entries yet';

  @override
  String get noLedgerBody => 'Record money you gave or received.';

  @override
  String get problemPerson => 'Choose a person';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatNever => 'Never';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get repeatYearly => 'Yearly';

  @override
  String get remindMe => 'Remind me';

  @override
  String get remindMeHint => 'A notification on the due date';

  @override
  String get recurring => 'Recurring';

  @override
  String get recurringSubtitle => 'Bills and payments that repeat';

  @override
  String get noRecurring => 'Nothing repeating yet';

  @override
  String get noRecurringBody =>
      'When adding an entry, tap Repeat to make it recur.';

  @override
  String nextOn(String date) {
    return 'Next: $date';
  }

  @override
  String get stopRepeating => 'Stop repeating';

  @override
  String get stoppedRepeating => 'Stopped repeating';

  @override
  String get reminderTitle => 'Due today';

  @override
  String reminderBody(String what, String amount) {
    return '$what · $amount';
  }

  @override
  String get recurringEntry => 'Repeating payment';

  @override
  String get monthStart => 'Month starts on';

  @override
  String monthStartDay(int day) {
    return 'Day $day';
  }

  @override
  String get monthStartHint =>
      'When your month begins: a date, or the last working day';

  @override
  String get settingsGeneral => 'General';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get periodCustom => 'Custom';

  @override
  String get periodAll => 'All';

  @override
  String get allTime => 'All time';

  @override
  String get previousPeriod => 'Previous';

  @override
  String get nextPeriod => 'Next';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get incomeByCategory => 'Income by category';

  @override
  String get incomeVsSpending => 'Income vs spending';

  @override
  String get balanceTrend => 'Balance';

  @override
  String get net => 'Net';

  @override
  String get other => 'Other';

  @override
  String get noActivity => 'No activity in this period';

  @override
  String get noActivityBody => 'Try another period or clear the filters.';

  @override
  String get export => 'Export';

  @override
  String get exportScope => 'What to export';

  @override
  String get exportView => 'This view';

  @override
  String get exportAll => 'Everything';

  @override
  String get exportFormat => 'Format';

  @override
  String get formatExcel => 'Excel';

  @override
  String get formatCsv => 'CSV';

  @override
  String get share => 'Share';

  @override
  String get saveToDevice => 'Save to device';

  @override
  String savedFile(String name) {
    return 'Saved $name';
  }

  @override
  String get exportFailed => 'Couldn\'t create the file. Try again.';

  @override
  String get exportHint =>
      'Same columns as Hysab Kytab, so you can import it back anytime.';

  @override
  String get exportAllSubtitle => 'Your full history as Excel or CSV';

  @override
  String ofTotal(int percent) {
    return '$percent% of total';
  }

  @override
  String get settingsData => 'Data';

  @override
  String get exportEverything => 'Export everything';

  @override
  String get backupTitle => 'Backup & restore';

  @override
  String get backupTileHint =>
      'Keep your records safe on your phone and in your Drive';

  @override
  String get lastBackup => 'Last backup';

  @override
  String lastBackupAt(String date, String place) {
    return '$date · $place';
  }

  @override
  String get noBackupYet => 'No backup yet';

  @override
  String get noBackupBody =>
      'Back up now so a lost or reset phone never costs you your records.';

  @override
  String get placeFile => 'File';

  @override
  String get placeDrive => 'Google Drive';

  @override
  String get placeDevice => 'This phone';

  @override
  String get backupNow => 'Back up now';

  @override
  String get backupToFile => 'Save backup to a file';

  @override
  String get backupToFileHint =>
      'Keep it anywhere: Downloads, a USB drive, email';

  @override
  String get backupToDrive => 'Back up to Google Drive';

  @override
  String get backupToDriveHint =>
      'Into a “Kharcha Backups” folder in your own Drive';

  @override
  String get encryptBackup => 'Protect with a passphrase';

  @override
  String get encryptHint =>
      'AES-256. A forgotten passphrase can\'t be recovered.';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get passphraseHint => 'At least 6 characters';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String get backupUploaded => 'Backed up to Google Drive';

  @override
  String get backupFailed =>
      'The backup didn\'t finish. Your data is unchanged; try again.';

  @override
  String get autoBackupSection => 'Automatic';

  @override
  String get autoBackup => 'Weekly backup';

  @override
  String get autoBackupHint =>
      'To Google Drive when connected, plus a copy on this phone';

  @override
  String get wifiOnly => 'Wi-Fi only';

  @override
  String get wifiOnlyHint => 'Don\'t use mobile data for Drive backups';

  @override
  String get driveConnect => 'Connect Google Drive';

  @override
  String get driveConnectHint => 'Kharcha can only see the backups it creates';

  @override
  String get driveDisconnect => 'Disconnect';

  @override
  String get driveUnavailable =>
      'Google Drive isn\'t set up in this build. File backups work everywhere.';

  @override
  String get driveFailed =>
      'Couldn\'t reach Google Drive. Check your connection and try again.';

  @override
  String get restoreSection => 'Restore';

  @override
  String get restoreFromFile => 'Restore from a file';

  @override
  String get restoreFromDrive => 'Restore from Google Drive';

  @override
  String get restoreFromDevice => 'Copies on this phone';

  @override
  String get restoreFromDeviceHint =>
      'Made automatically each week and before imports and restores';

  @override
  String get noBackupsFound => 'No backups found';

  @override
  String get restoreTitle => 'Restore';

  @override
  String get restoreMade => 'Made';

  @override
  String get restoreEntries => 'Entries';

  @override
  String get restoreDates => 'Dates';

  @override
  String get restoreApp => 'App version';

  @override
  String get encryptedBackup => 'Passphrase protected';

  @override
  String get restoreMode => 'How to restore';

  @override
  String get modeReplace => 'Replace';

  @override
  String get modeReplaceHint => 'This phone\'s data is replaced by the backup.';

  @override
  String get modeMerge => 'Merge';

  @override
  String get modeMergeHint =>
      'Keep this phone\'s data and add what\'s missing from the backup. Where both have the same entry, the newer edit wins.';

  @override
  String get restoreReplaceButton => 'Replace my data';

  @override
  String get restoreMergeButton => 'Merge into my data';

  @override
  String get safetyCopyNote =>
      'A copy of your current data is kept on this phone first.';

  @override
  String get restoring => 'Restoring…';

  @override
  String get restoreDone => 'Restore complete';

  @override
  String get restoreVerified =>
      'Every file matched its checksum and the database passed its integrity check.';

  @override
  String restoreSummary(int accounts, int entries, int receipts) {
    return '$accounts accounts · $entries entries · $receipts receipts';
  }

  @override
  String get failNotBackup => 'This isn\'t a Kharcha backup file.';

  @override
  String get failNewer =>
      'This backup is from a newer Kharcha. Update the app, then try again.';

  @override
  String get failPassphrase => 'That passphrase doesn\'t open this backup.';

  @override
  String get failDamaged =>
      'This backup is damaged: a checksum doesn\'t match. Your data is unchanged.';

  @override
  String get failIntegrity =>
      'The database in this backup is damaged. Your data is unchanged.';

  @override
  String get failConflict =>
      'Couldn\'t merge this backup. Your data is unchanged; try Replace instead.';

  @override
  String get importTitle => 'Import';

  @override
  String get importTile => 'Import from Hysab Kytab';

  @override
  String get importTileHint => 'Also Kharcha exports and other CSV files';

  @override
  String get importIntro =>
      'In Hysab Kytab, open More → Export → Export All, then choose that file here. Kharcha exports and CSV files from other apps work too.';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get reading => 'Reading…';

  @override
  String get importUnreadable =>
      'Couldn\'t read this file. Choose an Excel (.xls, .xlsx) or CSV file.';

  @override
  String get importEmpty => 'No entries found in this file.';

  @override
  String get mapColumns => 'Match the columns';

  @override
  String get mapColumnsHint =>
      'Tell Kharcha which column holds what. Negative amounts are expenses unless there\'s a type column.';

  @override
  String get colAmount => 'Amount';

  @override
  String get colType => 'Type';

  @override
  String get notInFile => 'Not in file';

  @override
  String get dateOrder => 'Date order';

  @override
  String get defaultAccount => 'Account for rows without one';

  @override
  String get continueLabel => 'Continue';

  @override
  String get importReady => 'Ready to import';

  @override
  String importNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new entries',
      one: '1 new entry',
      zero: 'No new entries',
    );
    return '$_temp0';
  }

  @override
  String importAlready(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already imported',
      one: '1 already imported',
    );
    return '$_temp0';
  }

  @override
  String importWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows need a look',
      one: '1 row needs a look',
    );
    return '$_temp0';
  }

  @override
  String warnUnreadable(int row) {
    return 'Row $row: couldn\'t read the date or amount, so it\'s skipped';
  }

  @override
  String warnUnpaired(int row, String account) {
    return 'Row $row: a transfer with no matching row, kept as an adjustment on $account';
  }

  @override
  String get namesTitle => 'Accounts and people';

  @override
  String get namesHint =>
      'Hysab Kytab keeps people as accounts. Mark who\'s a person and their transfers become udhaar.';

  @override
  String get roleAccount => 'Account';

  @override
  String get rolePerson => 'Person';

  @override
  String get nameExisting => 'Already in Kharcha';

  @override
  String nameEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'Opening balance only',
    );
    return '$_temp0';
  }

  @override
  String get importButton => 'Import';

  @override
  String get importing => 'Importing…';

  @override
  String get importDone => 'Import complete';

  @override
  String get reportImported => 'Imported';

  @override
  String get reportDuplicates => 'Already there';

  @override
  String get reportSkipped => 'Not imported';

  @override
  String get reportAccounts => 'New accounts';

  @override
  String get reportPeople => 'New people';

  @override
  String get reportCategories => 'New categories';

  @override
  String skipBetweenPeople(int row) {
    return 'Row $row: a transfer between two people isn\'t imported';
  }

  @override
  String skipPersonAdjustment(int row) {
    return 'Row $row: an unpaired transfer on a person isn\'t imported';
  }

  @override
  String get importNothingNew =>
      'Everything in this file is already in Kharcha.';

  @override
  String get importFailed =>
      'The import didn\'t finish. Nothing was changed; try again.';

  @override
  String get backupNudgeTitle => 'Back up your data';

  @override
  String get backupNudgeNever => 'You haven\'t made a backup yet.';

  @override
  String backupNudgeDays(int days) {
    return 'Last backup $days days ago.';
  }

  @override
  String get integrityTitle => 'Your data needs attention';

  @override
  String get integrityBody =>
      'A safety check found damage. Restore from a backup to be safe.';

  @override
  String get monthStartLastWorking => 'Last working day';

  @override
  String get haptics => 'Haptics';

  @override
  String get hapticsHint => 'Gentle taps when you choose, save or delete';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockHint =>
      'A PIN, or your fingerprint or face, to open Kharcha';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get turnOnLock => 'Turn on app lock';

  @override
  String get choosePin => 'Choose a 4-digit PIN';

  @override
  String get confirmPin => 'Enter it again';

  @override
  String get pinMismatch => 'Those didn\'t match. Try again.';

  @override
  String get enterPin => 'Enter your PIN';

  @override
  String get currentPin => 'Enter your current PIN';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String pinPaused(String time) {
    return 'Too many tries. Try again in $time.';
  }

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get forgotPinReason => 'Confirm it\'s you to turn off Kharcha\'s lock';

  @override
  String get lockTurnedOff =>
      'App lock is off. You can set a new PIN in More → App lock.';

  @override
  String get unlockReason => 'Unlock Kharcha';

  @override
  String get useBiometrics => 'Fingerprint or face';

  @override
  String get useBiometricsHint => 'Unlock without typing your PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get turnOffLock => 'Turn off app lock';

  @override
  String get lockAfter => 'Lock after';

  @override
  String get lockAfterHint => 'How long Kharcha can be in the background';

  @override
  String get lockImmediately => 'Immediately';

  @override
  String lockSeconds(int n) {
    return '$n seconds';
  }

  @override
  String lockMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get lockIsOn => 'App lock is on';

  @override
  String get pinChanged => 'PIN changed';

  @override
  String get welcomeTitle => 'Know where your money goes';

  @override
  String get welcomeBody =>
      'Add an expense in seconds. Kharcha keeps the totals, budgets and reports.';

  @override
  String get promiseOffline => 'Works offline. No sign-up, ever.';

  @override
  String get promiseBackup => 'Backups to your phone or your own Google Drive';

  @override
  String get promisePayday => 'Budgets that follow your payday';

  @override
  String get promiseFree => 'Free, with no ads, ever';

  @override
  String get setupTitle => 'Make it yours';

  @override
  String get setupBody => 'You can change these anytime in More.';

  @override
  String get homeCurrency => 'Currency';

  @override
  String get homeCurrencyHint => 'For totals and new accounts';

  @override
  String get extrasTitle => 'A couple of extras';

  @override
  String get extrasBody => 'Both are optional.';

  @override
  String get extrasImport => 'Coming from Hysab Kytab?';

  @override
  String get extrasImportHint => 'Bring your history in one go';

  @override
  String get extrasLock => 'Lock Kharcha with a PIN';

  @override
  String get extrasLockHint => 'Or your fingerprint or face';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get startUsing => 'Start using Kharcha';

  @override
  String get categories => 'Categories';

  @override
  String get categoriesHint => 'Add, rename, reorder or archive';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryName => 'Name';

  @override
  String get categoryIcon => 'Icon';

  @override
  String get categoryArchived => 'Category archived';

  @override
  String duplicateCategoryName(String name) {
    return 'You already have a category called $name';
  }

  @override
  String get noCategories => 'No categories here yet';

  @override
  String get about => 'About';

  @override
  String get aboutHint => 'Version, what\'s new and contact';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get noAds =>
      'No ads, ever. Your data stays on your phone unless you back it up.';

  @override
  String get whatsNew => 'What\'s new';

  @override
  String get contactUs => 'Contact us';

  @override
  String get contactUsHint =>
      'Email us, with a short technical report attached';

  @override
  String get copyDiagnostics => 'Copy diagnostics';

  @override
  String get diagnosticsCopied =>
      'Diagnostics copied. Paste them into your message.';

  @override
  String get supportSubject => 'Kharcha support';

  @override
  String get hideBalancesHint => 'Hide totals and balances behind dots';

  @override
  String get copyDiagnosticsHint =>
      'A short technical report to paste into a message to us';

  @override
  String get noAccounts => 'No accounts yet. Add one to start recording.';

  @override
  String get bioFaceId => 'Face ID';

  @override
  String get bioTouchId => 'Touch ID';

  @override
  String get bioFace => 'Face unlock';

  @override
  String get bioFingerprint => 'Fingerprint';

  @override
  String offerBiometricTitle(String name) {
    return 'Use $name to unlock?';
  }

  @override
  String get offerBiometricBody =>
      'Quicker than typing your PIN. Your PIN still works.';

  @override
  String useBiometricNamed(String name) {
    return 'Use $name';
  }

  @override
  String get notNow => 'Not now';

  @override
  String enableBiometricReason(String name) {
    return 'Confirm to turn on $name for Kharcha';
  }
}

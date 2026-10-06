import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kharcha'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get navAdd;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @addTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransactionTitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'اردو'**
  String get languageUrdu;

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your month at a glance: balance, budgets and recent spending.'**
  String get homeEmpty;

  /// No description provided for @transactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Every expense, income and transfer, grouped by day.'**
  String get transactionsEmpty;

  /// No description provided for @reportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Charts for any date range, with your full history.'**
  String get reportsEmpty;

  /// No description provided for @addEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log an expense in three taps.'**
  String get addEmpty;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @typeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get typeExpense;

  /// No description provided for @typeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get typeIncome;

  /// No description provided for @typeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get typeTransfer;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get deleted;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get noCategory;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromAccount;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toAccount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @notePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get notePlaceholder;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, e.g. office, lunch'**
  String get tagsHint;

  /// No description provided for @receipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receipts;

  /// No description provided for @addReceipt.
  ///
  /// In en, this message translates to:
  /// **'Add receipt'**
  String get addReceipt;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @receives.
  ///
  /// In en, this message translates to:
  /// **'Receives'**
  String get receives;

  /// No description provided for @rateLabel.
  ///
  /// In en, this message translates to:
  /// **'1 {from} = {rate} {to}'**
  String rateLabel(String from, String rate, String to);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @problemAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get problemAmount;

  /// No description provided for @problemAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose an account'**
  String get problemAccount;

  /// No description provided for @problemDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose where the money goes'**
  String get problemDestination;

  /// No description provided for @problemSameAccount.
  ///
  /// In en, this message translates to:
  /// **'Pick two different accounts'**
  String get problemSameAccount;

  /// No description provided for @problemConversion.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount received'**
  String get problemConversion;

  /// No description provided for @receiptFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t attach that image. Try another photo.'**
  String get receiptFailed;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Note, amount, category or tag'**
  String get searchHint;

  /// No description provided for @filterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filterType;

  /// No description provided for @filterAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get filterAccount;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @filterTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get filterTag;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noTransactionsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap + to log your first expense.'**
  String get noTransactionsBody;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get noMatches;

  /// No description provided for @noMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or clear the filters.'**
  String get noMatchesBody;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @transferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferTitle;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get exchangeRate;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @newAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get newAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountName;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountType;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @excludeFromTotal.
  ///
  /// In en, this message translates to:
  /// **'Exclude from net worth'**
  String get excludeFromTotal;

  /// No description provided for @excludeFromTotalHint.
  ///
  /// In en, this message translates to:
  /// **'For savings or money you don\'t spend from'**
  String get excludeFromTotalHint;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @netWorth.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get netWorth;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @customHint.
  ///
  /// In en, this message translates to:
  /// **'Any other bank, wallet or cash'**
  String get customHint;

  /// No description provided for @duplicateAccountName.
  ///
  /// In en, this message translates to:
  /// **'You already have an account called {name}'**
  String duplicateAccountName(String name);

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give it a name'**
  String get nameRequired;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @notInTotal.
  ///
  /// In en, this message translates to:
  /// **'Not in total'**
  String get notInTotal;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountTypeBank;

  /// No description provided for @accountTypeWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get accountTypeWallet;

  /// No description provided for @accountTypeCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get accountTypeCard;

  /// No description provided for @accountTypeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get accountTypeSavings;

  /// No description provided for @chooseAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose an account'**
  String get chooseAccount;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @thisCycle.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisCycle;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @hideBalances.
  ///
  /// In en, this message translates to:
  /// **'Hide balances'**
  String get hideBalances;

  /// No description provided for @showBalances.
  ///
  /// In en, this message translates to:
  /// **'Show balances'**
  String get showBalances;

  /// No description provided for @yourMoney.
  ///
  /// In en, this message translates to:
  /// **'Your money'**
  String get yourMoney;

  /// No description provided for @accountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Banks, wallets and cash'**
  String get accountsSubtitle;

  /// No description provided for @accountArchived.
  ///
  /// In en, this message translates to:
  /// **'Account archived'**
  String get accountArchived;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get saveExpense;

  /// No description provided for @saveIncome.
  ///
  /// In en, this message translates to:
  /// **'Save income'**
  String get saveIncome;

  /// No description provided for @saveTransfer.
  ///
  /// In en, this message translates to:
  /// **'Save transfer'**
  String get saveTransfer;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @swapAccounts.
  ///
  /// In en, this message translates to:
  /// **'Swap accounts'**
  String get swapAccounts;

  /// No description provided for @tagCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tag} other{{count} tags}}'**
  String tagCount(int count);

  /// No description provided for @receiptCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 receipt} other{{count} receipts}}'**
  String receiptCount(int count);

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @budgetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Limits for each month'**
  String get budgetsSubtitle;

  /// No description provided for @overallBudget.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overallBudget;

  /// No description provided for @overallBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'Everything you spend this month'**
  String get overallBudgetHint;

  /// No description provided for @addBudget.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get addBudget;

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get editBudget;

  /// No description provided for @removeBudget.
  ///
  /// In en, this message translates to:
  /// **'Remove budget'**
  String get removeBudget;

  /// No description provided for @copyLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Copy last month'**
  String get copyLastMonth;

  /// No description provided for @copiedBudgets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to copy from last month} =1{Copied 1 budget} other{Copied {count} budgets}}'**
  String copiedBudgets(int count);

  /// No description provided for @noBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get noBudgets;

  /// No description provided for @noBudgetsBody.
  ///
  /// In en, this message translates to:
  /// **'Set a limit for the month or for a category, and watch it fill as you spend.'**
  String get noBudgetsBody;

  /// No description provided for @budgetLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String budgetLeft(String amount);

  /// No description provided for @budgetOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String budgetOver(String amount);

  /// No description provided for @budgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get budgetLimit;

  /// No description provided for @previousCycle.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousCycle;

  /// No description provided for @nextCycle.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextCycle;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @peopleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Udhaar: who owes whom'**
  String get peopleSubtitle;

  /// No description provided for @youllReceive.
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive'**
  String get youllReceive;

  /// No description provided for @youOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get youOwe;

  /// No description provided for @addPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get addPerson;

  /// No description provided for @personName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get personName;

  /// No description provided for @person.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get person;

  /// No description provided for @choosePerson.
  ///
  /// In en, this message translates to:
  /// **'Choose a person'**
  String get choosePerson;

  /// No description provided for @noPeople.
  ///
  /// In en, this message translates to:
  /// **'No udhaar yet'**
  String get noPeople;

  /// No description provided for @noPeopleBody.
  ///
  /// In en, this message translates to:
  /// **'Add someone you lend to or borrow from.'**
  String get noPeopleBody;

  /// No description provided for @owesYou.
  ///
  /// In en, this message translates to:
  /// **'Owes you'**
  String get owesYou;

  /// No description provided for @youOweThem.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get youOweThem;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @iGave.
  ///
  /// In en, this message translates to:
  /// **'I gave'**
  String get iGave;

  /// No description provided for @iReceived.
  ///
  /// In en, this message translates to:
  /// **'I received'**
  String get iReceived;

  /// No description provided for @settleUp.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get settleUp;

  /// No description provided for @typeUdhaar.
  ///
  /// In en, this message translates to:
  /// **'Udhaar'**
  String get typeUdhaar;

  /// No description provided for @saveUdhaar.
  ///
  /// In en, this message translates to:
  /// **'Save udhaar'**
  String get saveUdhaar;

  /// No description provided for @duplicatePersonName.
  ///
  /// In en, this message translates to:
  /// **'{name} is already in your people'**
  String duplicatePersonName(String name);

  /// No description provided for @removePerson.
  ///
  /// In en, this message translates to:
  /// **'Remove person'**
  String get removePerson;

  /// No description provided for @personRemoved.
  ///
  /// In en, this message translates to:
  /// **'Person removed'**
  String get personRemoved;

  /// No description provided for @noLedger.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noLedger;

  /// No description provided for @noLedgerBody.
  ///
  /// In en, this message translates to:
  /// **'Record money you gave or received.'**
  String get noLedgerBody;

  /// No description provided for @problemPerson.
  ///
  /// In en, this message translates to:
  /// **'Choose a person'**
  String get problemPerson;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNever;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get repeatYearly;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMe;

  /// No description provided for @remindMeHint.
  ///
  /// In en, this message translates to:
  /// **'A notification on the due date'**
  String get remindMeHint;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @recurringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bills and payments that repeat'**
  String get recurringSubtitle;

  /// No description provided for @noRecurring.
  ///
  /// In en, this message translates to:
  /// **'Nothing repeating yet'**
  String get noRecurring;

  /// No description provided for @noRecurringBody.
  ///
  /// In en, this message translates to:
  /// **'When adding an entry, tap Repeat to make it recur.'**
  String get noRecurringBody;

  /// No description provided for @nextOn.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String nextOn(String date);

  /// No description provided for @stopRepeating.
  ///
  /// In en, this message translates to:
  /// **'Stop repeating'**
  String get stopRepeating;

  /// No description provided for @stoppedRepeating.
  ///
  /// In en, this message translates to:
  /// **'Stopped repeating'**
  String get stoppedRepeating;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'{what} · {amount}'**
  String reminderBody(String what, String amount);

  /// No description provided for @recurringEntry.
  ///
  /// In en, this message translates to:
  /// **'Repeating payment'**
  String get recurringEntry;

  /// No description provided for @monthStart.
  ///
  /// In en, this message translates to:
  /// **'Month starts on'**
  String get monthStart;

  /// No description provided for @monthStartDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String monthStartDay(int day);

  /// No description provided for @monthStartHint.
  ///
  /// In en, this message translates to:
  /// **'For salaries paid on a set date, e.g. the 25th'**
  String get monthStartHint;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @periodDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get periodCustom;

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get periodAll;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @previousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextPeriod;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get spendingByCategory;

  /// No description provided for @incomeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Income by category'**
  String get incomeByCategory;

  /// No description provided for @incomeVsSpending.
  ///
  /// In en, this message translates to:
  /// **'Income vs spending'**
  String get incomeVsSpending;

  /// No description provided for @balanceTrend.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceTrend;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity in this period'**
  String get noActivity;

  /// No description provided for @noActivityBody.
  ///
  /// In en, this message translates to:
  /// **'Try another period or clear the filters.'**
  String get noActivityBody;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportScope.
  ///
  /// In en, this message translates to:
  /// **'What to export'**
  String get exportScope;

  /// No description provided for @exportView.
  ///
  /// In en, this message translates to:
  /// **'This view'**
  String get exportView;

  /// No description provided for @exportAll.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get exportAll;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get exportFormat;

  /// No description provided for @formatExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get formatExcel;

  /// No description provided for @formatCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get formatCsv;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @saveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get saveToDevice;

  /// No description provided for @savedFile.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String savedFile(String name);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the file. Try again.'**
  String get exportFailed;

  /// No description provided for @exportHint.
  ///
  /// In en, this message translates to:
  /// **'Same columns as Hysab Kytab, so you can import it back anytime.'**
  String get exportHint;

  /// No description provided for @exportAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your full history as Excel or CSV'**
  String get exportAllSubtitle;

  /// No description provided for @ofTotal.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of total'**
  String ofTotal(int percent);

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @exportEverything.
  ///
  /// In en, this message translates to:
  /// **'Export everything'**
  String get exportEverything;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupTitle;

  /// No description provided for @backupTileHint.
  ///
  /// In en, this message translates to:
  /// **'Keep your records safe on your phone and in your Drive'**
  String get backupTileHint;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get lastBackup;

  /// No description provided for @lastBackupAt.
  ///
  /// In en, this message translates to:
  /// **'{date} · {place}'**
  String lastBackupAt(String date, String place);

  /// No description provided for @noBackupYet.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get noBackupYet;

  /// No description provided for @noBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Back up now so a lost or reset phone never costs you your records.'**
  String get noBackupBody;

  /// No description provided for @placeFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get placeFile;

  /// No description provided for @placeDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get placeDrive;

  /// No description provided for @placeDevice.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get placeDevice;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// No description provided for @backupToFile.
  ///
  /// In en, this message translates to:
  /// **'Save backup to a file'**
  String get backupToFile;

  /// No description provided for @backupToFileHint.
  ///
  /// In en, this message translates to:
  /// **'Keep it anywhere: Downloads, a USB drive, email'**
  String get backupToFileHint;

  /// No description provided for @backupToDrive.
  ///
  /// In en, this message translates to:
  /// **'Back up to Google Drive'**
  String get backupToDrive;

  /// No description provided for @backupToDriveHint.
  ///
  /// In en, this message translates to:
  /// **'Into a “Kharcha Backups” folder in your own Drive'**
  String get backupToDriveHint;

  /// No description provided for @encryptBackup.
  ///
  /// In en, this message translates to:
  /// **'Protect with a passphrase'**
  String get encryptBackup;

  /// No description provided for @encryptHint.
  ///
  /// In en, this message translates to:
  /// **'AES-256. A forgotten passphrase can\'t be recovered.'**
  String get encryptHint;

  /// No description provided for @passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphrase;

  /// No description provided for @passphraseHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passphraseHint;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @backupUploaded.
  ///
  /// In en, this message translates to:
  /// **'Backed up to Google Drive'**
  String get backupUploaded;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'The backup didn\'t finish. Your data is unchanged; try again.'**
  String get backupFailed;

  /// No description provided for @autoBackupSection.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get autoBackupSection;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Weekly backup'**
  String get autoBackup;

  /// No description provided for @autoBackupHint.
  ///
  /// In en, this message translates to:
  /// **'To Google Drive when connected, plus a copy on this phone'**
  String get autoBackupHint;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get wifiOnly;

  /// No description provided for @wifiOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Don\'t use mobile data for Drive backups'**
  String get wifiOnlyHint;

  /// No description provided for @driveConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive'**
  String get driveConnect;

  /// No description provided for @driveConnectHint.
  ///
  /// In en, this message translates to:
  /// **'Kharcha can only see the backups it creates'**
  String get driveConnectHint;

  /// No description provided for @driveDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get driveDisconnect;

  /// No description provided for @driveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Drive isn\'t set up in this build. File backups work everywhere.'**
  String get driveUnavailable;

  /// No description provided for @driveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach Google Drive. Check your connection and try again.'**
  String get driveFailed;

  /// No description provided for @restoreSection.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreSection;

  /// No description provided for @restoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from a file'**
  String get restoreFromFile;

  /// No description provided for @restoreFromDrive.
  ///
  /// In en, this message translates to:
  /// **'Restore from Google Drive'**
  String get restoreFromDrive;

  /// No description provided for @restoreFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Copies on this phone'**
  String get restoreFromDevice;

  /// No description provided for @restoreFromDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'Made automatically each week and before imports and restores'**
  String get restoreFromDeviceHint;

  /// No description provided for @noBackupsFound.
  ///
  /// In en, this message translates to:
  /// **'No backups found'**
  String get noBackupsFound;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreTitle;

  /// No description provided for @restoreMade.
  ///
  /// In en, this message translates to:
  /// **'Made'**
  String get restoreMade;

  /// No description provided for @restoreEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get restoreEntries;

  /// No description provided for @restoreDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get restoreDates;

  /// No description provided for @restoreApp.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get restoreApp;

  /// No description provided for @encryptedBackup.
  ///
  /// In en, this message translates to:
  /// **'Passphrase protected'**
  String get encryptedBackup;

  /// No description provided for @restoreMode.
  ///
  /// In en, this message translates to:
  /// **'How to restore'**
  String get restoreMode;

  /// No description provided for @modeReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get modeReplace;

  /// No description provided for @modeReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'This phone\'s data is replaced by the backup.'**
  String get modeReplaceHint;

  /// No description provided for @modeMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get modeMerge;

  /// No description provided for @modeMergeHint.
  ///
  /// In en, this message translates to:
  /// **'Keep this phone\'s data and add what\'s missing from the backup. Where both have the same entry, the newer edit wins.'**
  String get modeMergeHint;

  /// No description provided for @restoreReplaceButton.
  ///
  /// In en, this message translates to:
  /// **'Replace my data'**
  String get restoreReplaceButton;

  /// No description provided for @restoreMergeButton.
  ///
  /// In en, this message translates to:
  /// **'Merge into my data'**
  String get restoreMergeButton;

  /// No description provided for @safetyCopyNote.
  ///
  /// In en, this message translates to:
  /// **'A copy of your current data is kept on this phone first.'**
  String get safetyCopyNote;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get restoring;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get restoreDone;

  /// No description provided for @restoreVerified.
  ///
  /// In en, this message translates to:
  /// **'Every file matched its checksum and the database passed its integrity check.'**
  String get restoreVerified;

  /// No description provided for @restoreSummary.
  ///
  /// In en, this message translates to:
  /// **'{accounts} accounts · {entries} entries · {receipts} receipts'**
  String restoreSummary(int accounts, int entries, int receipts);

  /// No description provided for @failNotBackup.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a Kharcha backup file.'**
  String get failNotBackup;

  /// No description provided for @failNewer.
  ///
  /// In en, this message translates to:
  /// **'This backup is from a newer Kharcha. Update the app, then try again.'**
  String get failNewer;

  /// No description provided for @failPassphrase.
  ///
  /// In en, this message translates to:
  /// **'That passphrase doesn\'t open this backup.'**
  String get failPassphrase;

  /// No description provided for @failDamaged.
  ///
  /// In en, this message translates to:
  /// **'This backup is damaged: a checksum doesn\'t match. Your data is unchanged.'**
  String get failDamaged;

  /// No description provided for @failIntegrity.
  ///
  /// In en, this message translates to:
  /// **'The database in this backup is damaged. Your data is unchanged.'**
  String get failIntegrity;

  /// No description provided for @failConflict.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t merge this backup. Your data is unchanged; try Replace instead.'**
  String get failConflict;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @importTile.
  ///
  /// In en, this message translates to:
  /// **'Import from Hysab Kytab'**
  String get importTile;

  /// No description provided for @importTileHint.
  ///
  /// In en, this message translates to:
  /// **'Also Kharcha exports and other CSV files'**
  String get importTileHint;

  /// No description provided for @importIntro.
  ///
  /// In en, this message translates to:
  /// **'In Hysab Kytab, open More → Export → Export All, then choose that file here. Kharcha exports and CSV files from other apps work too.'**
  String get importIntro;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get reading;

  /// No description provided for @importUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this file. Choose an Excel (.xls, .xlsx) or CSV file.'**
  String get importUnreadable;

  /// No description provided for @importEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries found in this file.'**
  String get importEmpty;

  /// No description provided for @mapColumns.
  ///
  /// In en, this message translates to:
  /// **'Match the columns'**
  String get mapColumns;

  /// No description provided for @mapColumnsHint.
  ///
  /// In en, this message translates to:
  /// **'Tell Kharcha which column holds what. Negative amounts are expenses unless there\'s a type column.'**
  String get mapColumnsHint;

  /// No description provided for @colAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get colAmount;

  /// No description provided for @colType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get colType;

  /// No description provided for @notInFile.
  ///
  /// In en, this message translates to:
  /// **'Not in file'**
  String get notInFile;

  /// No description provided for @dateOrder.
  ///
  /// In en, this message translates to:
  /// **'Date order'**
  String get dateOrder;

  /// No description provided for @defaultAccount.
  ///
  /// In en, this message translates to:
  /// **'Account for rows without one'**
  String get defaultAccount;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @importReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to import'**
  String get importReady;

  /// No description provided for @importNew.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new entries} =1{1 new entry} other{{count} new entries}}'**
  String importNew(int count);

  /// No description provided for @importAlready.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 already imported} other{{count} already imported}}'**
  String importAlready(int count);

  /// No description provided for @importWarnings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row needs a look} other{{count} rows need a look}}'**
  String importWarnings(int count);

  /// No description provided for @warnUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: couldn\'t read the date or amount, so it\'s skipped'**
  String warnUnreadable(int row);

  /// No description provided for @warnUnpaired.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: a transfer with no matching row, kept as an adjustment on {account}'**
  String warnUnpaired(int row, String account);

  /// No description provided for @namesTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts and people'**
  String get namesTitle;

  /// No description provided for @namesHint.
  ///
  /// In en, this message translates to:
  /// **'Hysab Kytab keeps people as accounts. Mark who\'s a person and their transfers become udhaar.'**
  String get namesHint;

  /// No description provided for @roleAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get roleAccount;

  /// No description provided for @rolePerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get rolePerson;

  /// No description provided for @nameExisting.
  ///
  /// In en, this message translates to:
  /// **'Already in Kharcha'**
  String get nameExisting;

  /// No description provided for @nameEntries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Opening balance only} =1{1 entry} other{{count} entries}}'**
  String nameEntries(int count);

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importing;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get importDone;

  /// No description provided for @reportImported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get reportImported;

  /// No description provided for @reportDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Already there'**
  String get reportDuplicates;

  /// No description provided for @reportSkipped.
  ///
  /// In en, this message translates to:
  /// **'Not imported'**
  String get reportSkipped;

  /// No description provided for @reportAccounts.
  ///
  /// In en, this message translates to:
  /// **'New accounts'**
  String get reportAccounts;

  /// No description provided for @reportPeople.
  ///
  /// In en, this message translates to:
  /// **'New people'**
  String get reportPeople;

  /// No description provided for @reportCategories.
  ///
  /// In en, this message translates to:
  /// **'New categories'**
  String get reportCategories;

  /// No description provided for @skipBetweenPeople.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: a transfer between two people isn\'t imported'**
  String skipBetweenPeople(int row);

  /// No description provided for @skipPersonAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: an unpaired transfer on a person isn\'t imported'**
  String skipPersonAdjustment(int row);

  /// No description provided for @importNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Everything in this file is already in Kharcha.'**
  String get importNothingNew;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'The import didn\'t finish. Nothing was changed; try again.'**
  String get importFailed;

  /// No description provided for @backupNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up your data'**
  String get backupNudgeTitle;

  /// No description provided for @backupNudgeNever.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t made a backup yet.'**
  String get backupNudgeNever;

  /// No description provided for @backupNudgeDays.
  ///
  /// In en, this message translates to:
  /// **'Last backup {days} days ago.'**
  String backupNudgeDays(int days);

  /// No description provided for @integrityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data needs attention'**
  String get integrityTitle;

  /// No description provided for @integrityBody.
  ///
  /// In en, this message translates to:
  /// **'A safety check found damage. Restore from a backup to be safe.'**
  String get integrityBody;

  /// No description provided for @monthStartLastWorking.
  ///
  /// In en, this message translates to:
  /// **'Last working day'**
  String get monthStartLastWorking;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @hapticsHint.
  ///
  /// In en, this message translates to:
  /// **'Gentle taps when you choose, save or delete'**
  String get hapticsHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'خرچہ';

  @override
  String get navHome => 'ہوم';

  @override
  String get navTransactions => 'لین دین';

  @override
  String get navAdd => 'شامل کریں';

  @override
  String get navReports => 'رپورٹس';

  @override
  String get navMore => 'مزید';

  @override
  String get addTransactionTitle => 'لین دین شامل کریں';

  @override
  String get comingSoon => 'جلد آ رہا ہے';

  @override
  String get settingsTheme => 'تھیم';

  @override
  String get themeSystem => 'سسٹم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تاریک';

  @override
  String get settingsLanguage => 'زبان';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUrdu => 'اردو';

  @override
  String get homeEmpty => 'آپ کا مہینہ ایک نظر میں: بیلنس، بجٹ اور حالیہ خرچ۔';

  @override
  String get transactionsEmpty => 'ہر خرچ، آمدنی اور منتقلی، دن کے حساب سے۔';

  @override
  String get reportsEmpty =>
      'کسی بھی تاریخ کی حد کے چارٹس، پوری ہسٹری کے ساتھ۔';

  @override
  String get addEmpty => 'تین ٹیپ میں خرچ درج کریں۔';

  @override
  String get settingsAppearance => 'ظاہری شکل';

  @override
  String get typeExpense => 'خرچ';

  @override
  String get typeIncome => 'آمدنی';

  @override
  String get typeTransfer => 'منتقلی';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get done => 'مکمل';

  @override
  String get clear => 'صاف کریں';

  @override
  String get cancel => 'منسوخ';

  @override
  String get undo => 'واپس لیں';

  @override
  String get edit => 'ترمیم';

  @override
  String get delete => 'حذف کریں';

  @override
  String get saved => 'محفوظ ہو گیا';

  @override
  String get deleted => 'لین دین حذف ہو گیا';

  @override
  String get noCategory => 'کوئی زمرہ نہیں';

  @override
  String get category => 'زمرہ';

  @override
  String get account => 'اکاؤنٹ';

  @override
  String get fromAccount => 'سے';

  @override
  String get toAccount => 'کو';

  @override
  String get date => 'تاریخ';

  @override
  String get note => 'نوٹ';

  @override
  String get notePlaceholder => 'نوٹ لکھیں';

  @override
  String get tags => 'ٹیگز';

  @override
  String get tagsHint => 'کوما سے الگ کریں، مثلاً دفتر، کھانا';

  @override
  String get receipts => 'رسیدیں';

  @override
  String get addReceipt => 'رسید شامل کریں';

  @override
  String get takePhoto => 'تصویر لیں';

  @override
  String get chooseFromGallery => 'گیلری سے منتخب کریں';

  @override
  String get receives => 'وصول';

  @override
  String rateLabel(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String get today => 'آج';

  @override
  String get yesterday => 'کل';

  @override
  String get problemAmount => 'رقم درج کریں';

  @override
  String get problemAccount => 'اکاؤنٹ منتخب کریں';

  @override
  String get problemDestination => 'منتخب کریں کہ رقم کہاں جائے';

  @override
  String get problemSameAccount => 'دو مختلف اکاؤنٹ منتخب کریں';

  @override
  String get problemConversion => 'وصول ہونے والی رقم درج کریں';

  @override
  String get receiptFailed =>
      'یہ تصویر شامل نہیں ہو سکی۔ کوئی اور تصویر آزمائیں۔';

  @override
  String get search => 'تلاش';

  @override
  String get searchHint => 'نوٹ، رقم، زمرہ یا ٹیگ';

  @override
  String get filterType => 'قسم';

  @override
  String get filterAccount => 'اکاؤنٹ';

  @override
  String get filterCategory => 'زمرہ';

  @override
  String get filterTag => 'ٹیگ';

  @override
  String get noTransactions => 'ابھی کوئی لین دین نہیں';

  @override
  String get noTransactionsBody => 'اپنا پہلا خرچ درج کرنے کے لیے + دبائیں۔';

  @override
  String get noMatches => 'کچھ نہیں ملا';

  @override
  String get noMatchesBody => 'کوئی اور تلاش آزمائیں یا فلٹر صاف کریں۔';

  @override
  String get addTransaction => 'لین دین شامل کریں';

  @override
  String get editTransaction => 'لین دین میں ترمیم';

  @override
  String get transferTitle => 'منتقلی';

  @override
  String get exchangeRate => 'شرح تبادلہ';

  @override
  String get accounts => 'اکاؤنٹس';

  @override
  String get addAccount => 'اکاؤنٹ شامل کریں';

  @override
  String get newAccount => 'نیا اکاؤنٹ';

  @override
  String get editAccount => 'اکاؤنٹ میں ترمیم';

  @override
  String get accountName => 'نام';

  @override
  String get accountType => 'قسم';

  @override
  String get currency => 'کرنسی';

  @override
  String get openingBalance => 'ابتدائی بیلنس';

  @override
  String get excludeFromTotal => 'کل مالیت میں شامل نہ کریں';

  @override
  String get excludeFromTotalHint => 'بچت یا وہ رقم جس سے آپ خرچ نہیں کرتے';

  @override
  String get archive => 'آرکائیو کریں';

  @override
  String get archived => 'آرکائیو';

  @override
  String get restore => 'بحال کریں';

  @override
  String get netWorth => 'کل مالیت';

  @override
  String get custom => 'اپنی مرضی کا';

  @override
  String get customHint => 'کوئی اور بینک، والیٹ یا نقد';

  @override
  String duplicateAccountName(String name) {
    return '$name نام کا اکاؤنٹ پہلے سے موجود ہے';
  }

  @override
  String get nameRequired => 'نام درج کریں';

  @override
  String get invalidAmount => 'درست رقم درج کریں';

  @override
  String get notInTotal => 'کل میں شامل نہیں';

  @override
  String get accountTypeCash => 'نقد';

  @override
  String get accountTypeBank => 'بینک';

  @override
  String get accountTypeWallet => 'والیٹ';

  @override
  String get accountTypeCard => 'کارڈ';

  @override
  String get accountTypeSavings => 'بچت';

  @override
  String get chooseAccount => 'اکاؤنٹ منتخب کریں';

  @override
  String get chooseCategory => 'زمرہ منتخب کریں';

  @override
  String get thisCycle => 'یہ مہینہ';

  @override
  String get income => 'آمدنی';

  @override
  String get spent => 'خرچ';

  @override
  String get left => 'باقی';

  @override
  String get recent => 'حالیہ';

  @override
  String get seeAll => 'سب دیکھیں';

  @override
  String get manage => 'انتظام';

  @override
  String get hideBalances => 'بیلنس چھپائیں';

  @override
  String get showBalances => 'بیلنس دکھائیں';

  @override
  String get yourMoney => 'آپ کا پیسہ';

  @override
  String get accountsSubtitle => 'بینک، والیٹ اور نقد';

  @override
  String get accountArchived => 'اکاؤنٹ آرکائیو ہو گیا';

  @override
  String get saveExpense => 'خرچ محفوظ کریں';

  @override
  String get saveIncome => 'آمدنی محفوظ کریں';

  @override
  String get saveTransfer => 'منتقلی محفوظ کریں';

  @override
  String get allCategories => 'سب';

  @override
  String get swapAccounts => 'اکاؤنٹ بدلیں';

  @override
  String tagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ٹیگز',
      one: '1 ٹیگ',
    );
    return '$_temp0';
  }

  @override
  String receiptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رسیدیں',
      one: '1 رسید',
    );
    return '$_temp0';
  }

  @override
  String get receipt => 'رسید';

  @override
  String get budgets => 'بجٹ';

  @override
  String get budgetsSubtitle => 'ہر مہینے کی حد';

  @override
  String get overallBudget => 'مجموعی';

  @override
  String get overallBudgetHint => 'اس مہینے کا سارا خرچ';

  @override
  String get addBudget => 'بجٹ شامل کریں';

  @override
  String get editBudget => 'بجٹ میں ترمیم';

  @override
  String get removeBudget => 'بجٹ ہٹائیں';

  @override
  String get copyLastMonth => 'پچھلے مہینے سے نقل کریں';

  @override
  String copiedBudgets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بجٹ نقل ہو گئے',
      one: '1 بجٹ نقل ہو گیا',
      zero: 'پچھلے مہینے کوئی بجٹ نہیں تھا',
    );
    return '$_temp0';
  }

  @override
  String get noBudgets => 'ابھی کوئی بجٹ نہیں';

  @override
  String get noBudgetsBody =>
      'مہینے یا کسی زمرے کی حد مقرر کریں اور خرچ کے ساتھ اسے بھرتے دیکھیں۔';

  @override
  String budgetLeft(String amount) {
    return '$amount باقی';
  }

  @override
  String budgetOver(String amount) {
    return '$amount زیادہ';
  }

  @override
  String get budgetLimit => 'ماہانہ حد';

  @override
  String get previousCycle => 'پچھلا مہینہ';

  @override
  String get nextCycle => 'اگلا مہینہ';

  @override
  String get people => 'لوگ';

  @override
  String get peopleSubtitle => 'ادھار: کس نے کس کو دینا ہے';

  @override
  String get youllReceive => 'آپ کو ملنے ہیں';

  @override
  String get youOwe => 'آپ نے دینے ہیں';

  @override
  String get addPerson => 'شخص شامل کریں';

  @override
  String get personName => 'نام';

  @override
  String get person => 'شخص';

  @override
  String get choosePerson => 'شخص منتخب کریں';

  @override
  String get noPeople => 'ابھی کوئی ادھار نہیں';

  @override
  String get noPeopleBody =>
      'کسی ایسے شخص کو شامل کریں جسے آپ ادھار دیتے یا جس سے لیتے ہیں۔';

  @override
  String get owesYou => 'آپ کو دینے ہیں';

  @override
  String get youOweThem => 'آپ نے دینے ہیں';

  @override
  String get settled => 'حساب برابر';

  @override
  String get iGave => 'میں نے دیے';

  @override
  String get iReceived => 'میں نے لیے';

  @override
  String get settleUp => 'حساب برابر کریں';

  @override
  String get typeUdhaar => 'ادھار';

  @override
  String get saveUdhaar => 'ادھار محفوظ کریں';

  @override
  String duplicatePersonName(String name) {
    return '$name پہلے سے آپ کے لوگوں میں ہے';
  }

  @override
  String get removePerson => 'شخص ہٹائیں';

  @override
  String get personRemoved => 'شخص ہٹا دیا گیا';

  @override
  String get noLedger => 'ابھی کوئی اندراج نہیں';

  @override
  String get noLedgerBody => 'دی یا لی گئی رقم درج کریں۔';

  @override
  String get problemPerson => 'شخص منتخب کریں';

  @override
  String get problemCategory => 'زمرہ منتخب کریں';

  @override
  String get repeat => 'دہرائیں';

  @override
  String get repeatNever => 'کبھی نہیں';

  @override
  String get repeatDaily => 'روزانہ';

  @override
  String get repeatWeekly => 'ہفتہ وار';

  @override
  String get repeatMonthly => 'ماہانہ';

  @override
  String get repeatYearly => 'سالانہ';

  @override
  String get remindMe => 'یاد دہانی';

  @override
  String get remindMeHint => 'مقررہ تاریخ پر اطلاع';

  @override
  String get recurring => 'بار بار';

  @override
  String get recurringSubtitle => 'دہرائے جانے والے بل اور ادائیگیاں';

  @override
  String get noRecurring => 'ابھی کچھ نہیں دہرایا جا رہا';

  @override
  String get noRecurringBody => 'اندراج کرتے وقت دہرائیں دبائیں۔';

  @override
  String nextOn(String date) {
    return 'اگلا: $date';
  }

  @override
  String get stopRepeating => 'دہرانا بند کریں';

  @override
  String get stoppedRepeating => 'دہرانا بند ہو گیا';

  @override
  String get reminderTitle => 'آج واجب الادا';

  @override
  String reminderBody(String what, String amount) {
    return '$what · $amount';
  }

  @override
  String get recurringEntry => 'دہرائی جانے والی ادائیگی';

  @override
  String get monthStart => 'مہینہ شروع ہوتا ہے';

  @override
  String monthStartDay(int day) {
    return '$day تاریخ';
  }

  @override
  String get monthStartHint =>
      'آپ کا مہینہ کب شروع ہو: کوئی تاریخ یا آخری کاروباری دن';

  @override
  String get settingsGeneral => 'عمومی';

  @override
  String get periodDay => 'دن';

  @override
  String get periodWeek => 'ہفتہ';

  @override
  String get periodMonth => 'مہینہ';

  @override
  String get periodYear => 'سال';

  @override
  String get periodCustom => 'اپنی مرضی';

  @override
  String get periodAll => 'سب';

  @override
  String get allTime => 'تمام وقت';

  @override
  String get previousPeriod => 'پچھلا';

  @override
  String get nextPeriod => 'اگلا';

  @override
  String get spendingByCategory => 'زمرہ وار خرچ';

  @override
  String get incomeByCategory => 'زمرہ وار آمدنی';

  @override
  String get incomeVsSpending => 'آمدنی بمقابلہ خرچ';

  @override
  String get balanceTrend => 'بیلنس';

  @override
  String get net => 'خالص';

  @override
  String get other => 'دیگر';

  @override
  String get noActivity => 'اس مدت میں کوئی لین دین نہیں';

  @override
  String get noActivityBody => 'کوئی اور مدت آزمائیں یا فلٹر صاف کریں۔';

  @override
  String get export => 'برآمد';

  @override
  String get exportScope => 'کیا برآمد کرنا ہے';

  @override
  String get exportView => 'یہ منظر';

  @override
  String get exportAll => 'سب کچھ';

  @override
  String get exportFormat => 'فارمیٹ';

  @override
  String get formatExcel => 'Excel';

  @override
  String get formatCsv => 'CSV';

  @override
  String get share => 'شیئر کریں';

  @override
  String get saveToDevice => 'فون میں محفوظ کریں';

  @override
  String savedFile(String name) {
    return '$name محفوظ ہو گئی';
  }

  @override
  String get exportFailed => 'فائل نہیں بن سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get exportHint =>
      'Hysab Kytab جیسے کالم، تاکہ آپ کبھی بھی واپس درآمد کر سکیں۔';

  @override
  String get exportAllSubtitle => 'آپ کی پوری تاریخ Excel یا CSV میں';

  @override
  String ofTotal(int percent) {
    return 'کل کا $percent%';
  }

  @override
  String get settingsData => 'ڈیٹا';

  @override
  String get exportEverything => 'سب کچھ برآمد کریں';

  @override
  String get backupTitle => 'بیک اپ اور بحالی';

  @override
  String get backupTileHint => 'اپنا ریکارڈ فون اور ڈرائیو میں محفوظ رکھیں';

  @override
  String get lastBackup => 'آخری بیک اپ';

  @override
  String lastBackupAt(String date, String place) {
    return '$date · $place';
  }

  @override
  String get noBackupYet => 'ابھی کوئی بیک اپ نہیں';

  @override
  String get noBackupBody =>
      'ابھی بیک اپ بنائیں تاکہ فون گم یا ری سیٹ ہونے پر بھی ریکارڈ محفوظ رہے۔';

  @override
  String get placeFile => 'فائل';

  @override
  String get placeDrive => 'گوگل ڈرائیو';

  @override
  String get placeDevice => 'یہ فون';

  @override
  String get backupNow => 'ابھی بیک اپ بنائیں';

  @override
  String get backupToFile => 'بیک اپ فائل میں محفوظ کریں';

  @override
  String get backupToFileHint => 'کہیں بھی رکھیں: ڈاؤن لوڈز، یو ایس بی، ای میل';

  @override
  String get backupToDrive => 'گوگل ڈرائیو پر بیک اپ';

  @override
  String get backupToDriveHint =>
      'آپ کی اپنی ڈرائیو میں “Kharcha Backups” فولڈر میں';

  @override
  String get encryptBackup => 'پاس فریز سے محفوظ کریں';

  @override
  String get encryptHint => 'AES-256۔ بھولا ہوا پاس فریز واپس نہیں مل سکتا۔';

  @override
  String get passphrase => 'پاس فریز';

  @override
  String get passphraseHint => 'کم از کم 6 حروف';

  @override
  String get backupSaved => 'بیک اپ محفوظ ہو گیا';

  @override
  String get backupUploaded => 'گوگل ڈرائیو پر بیک اپ ہو گیا';

  @override
  String get backupFailed =>
      'بیک اپ مکمل نہیں ہوا۔ آپ کا ڈیٹا محفوظ ہے، دوبارہ کوشش کریں۔';

  @override
  String get autoBackupSection => 'خودکار';

  @override
  String get autoBackup => 'ہفتہ وار بیک اپ';

  @override
  String get autoBackupHint =>
      'ڈرائیو منسلک ہو تو وہاں، اور ایک کاپی اس فون پر';

  @override
  String get wifiOnly => 'صرف وائی فائی';

  @override
  String get wifiOnlyHint => 'ڈرائیو بیک اپ کے لیے موبائل ڈیٹا استعمال نہ کریں';

  @override
  String get driveConnect => 'گوگل ڈرائیو منسلک کریں';

  @override
  String get driveConnectHint => 'خرچہ صرف اپنے بنائے ہوئے بیک اپ دیکھ سکتا ہے';

  @override
  String get driveDisconnect => 'منقطع کریں';

  @override
  String get driveUnavailable =>
      'اس ورژن میں گوگل ڈرائیو دستیاب نہیں۔ فائل بیک اپ ہر جگہ کام کرتا ہے۔';

  @override
  String get driveFailed =>
      'گوگل ڈرائیو تک رسائی نہیں ہوئی۔ انٹرنیٹ چیک کر کے دوبارہ کوشش کریں۔';

  @override
  String get restoreSection => 'بحالی';

  @override
  String get restoreFromFile => 'فائل سے بحال کریں';

  @override
  String get restoreFromDrive => 'گوگل ڈرائیو سے بحال کریں';

  @override
  String get restoreFromDevice => 'اس فون پر موجود کاپیاں';

  @override
  String get restoreFromDeviceHint =>
      'ہر ہفتے اور امپورٹ یا بحالی سے پہلے خود بنتی ہیں';

  @override
  String get noBackupsFound => 'کوئی بیک اپ نہیں ملا';

  @override
  String get restoreTitle => 'بحالی';

  @override
  String get restoreMade => 'بنایا گیا';

  @override
  String get restoreEntries => 'اندراجات';

  @override
  String get restoreDates => 'تاریخیں';

  @override
  String get restoreApp => 'ایپ ورژن';

  @override
  String get encryptedBackup => 'پاس فریز سے محفوظ';

  @override
  String get restoreMode => 'کیسے بحال کریں';

  @override
  String get modeReplace => 'تبدیل کریں';

  @override
  String get modeReplaceHint => 'اس فون کا ڈیٹا بیک اپ سے بدل دیا جائے گا۔';

  @override
  String get modeMerge => 'ملائیں';

  @override
  String get modeMergeHint =>
      'اس فون کا ڈیٹا رکھیں اور بیک اپ سے جو نہیں ہے وہ شامل کریں۔ ایک جیسے اندراج میں نئی تبدیلی رہے گی۔';

  @override
  String get restoreReplaceButton => 'میرا ڈیٹا تبدیل کریں';

  @override
  String get restoreMergeButton => 'میرے ڈیٹا میں ملائیں';

  @override
  String get safetyCopyNote =>
      'پہلے آپ کے موجودہ ڈیٹا کی ایک کاپی اس فون پر رکھی جاتی ہے۔';

  @override
  String get restoring => 'بحال ہو رہا ہے…';

  @override
  String get restoreDone => 'بحالی مکمل';

  @override
  String get restoreVerified =>
      'ہر فائل کا چیک سم درست نکلا اور ڈیٹا بیس کی جانچ کامیاب رہی۔';

  @override
  String restoreSummary(int accounts, int entries, int receipts) {
    return '$accounts اکاؤنٹس · $entries اندراجات · $receipts رسیدیں';
  }

  @override
  String get failNotBackup => 'یہ خرچہ بیک اپ فائل نہیں ہے۔';

  @override
  String get failNewer =>
      'یہ بیک اپ نئے خرچہ ورژن کا ہے۔ ایپ اپ ڈیٹ کر کے دوبارہ کوشش کریں۔';

  @override
  String get failPassphrase => 'اس پاس فریز سے یہ بیک اپ نہیں کھلا۔';

  @override
  String get failDamaged =>
      'یہ بیک اپ خراب ہے: چیک سم میل نہیں کھاتا۔ آپ کا ڈیٹا محفوظ ہے۔';

  @override
  String get failIntegrity =>
      'اس بیک اپ کا ڈیٹا بیس خراب ہے۔ آپ کا ڈیٹا محفوظ ہے۔';

  @override
  String get failConflict =>
      'یہ بیک اپ ملایا نہیں جا سکا۔ آپ کا ڈیٹا محفوظ ہے؛ تبدیل کریں آزمائیں۔';

  @override
  String get importTitle => 'امپورٹ';

  @override
  String get importTile => 'حساب کتاب سے امپورٹ';

  @override
  String get importTileHint => 'خرچہ ایکسپورٹ اور دوسری CSV فائلیں بھی';

  @override
  String get importIntro =>
      'حساب کتاب میں More → Export → Export All کھولیں، پھر وہ فائل یہاں منتخب کریں۔ خرچہ ایکسپورٹ اور دوسری ایپس کی CSV فائلیں بھی چلتی ہیں۔';

  @override
  String get chooseFile => 'فائل منتخب کریں';

  @override
  String get reading => 'پڑھا جا رہا ہے…';

  @override
  String get importUnreadable =>
      'یہ فائل نہیں پڑھی جا سکی۔ ایکسل (.xls, .xlsx) یا CSV فائل منتخب کریں۔';

  @override
  String get importEmpty => 'اس فائل میں کوئی اندراج نہیں ملا۔';

  @override
  String get mapColumns => 'کالم ملائیں';

  @override
  String get mapColumnsHint =>
      'بتائیں کون سا کالم کیا ہے۔ ٹائپ کالم نہ ہو تو منفی رقم خرچ سمجھی جائے گی۔';

  @override
  String get colAmount => 'رقم';

  @override
  String get colType => 'قسم';

  @override
  String get notInFile => 'فائل میں نہیں';

  @override
  String get dateOrder => 'تاریخ کی ترتیب';

  @override
  String get defaultAccount => 'بغیر اکاؤنٹ والی قطاروں کا اکاؤنٹ';

  @override
  String get continueLabel => 'جاری رکھیں';

  @override
  String get importReady => 'امپورٹ کے لیے تیار';

  @override
  String importNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نئے اندراجات',
      one: '1 نیا اندراج',
      zero: 'کوئی نیا اندراج نہیں',
    );
    return '$_temp0';
  }

  @override
  String importAlready(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count پہلے سے موجود',
      one: '1 پہلے سے موجود',
    );
    return '$_temp0';
  }

  @override
  String importWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قطاریں دیکھ لیں',
      one: '1 قطار دیکھ لیں',
    );
    return '$_temp0';
  }

  @override
  String warnUnreadable(int row) {
    return 'قطار $row: تاریخ یا رقم نہیں پڑھی جا سکی، چھوڑ دی گئی';
  }

  @override
  String warnUnpaired(int row, String account) {
    return 'قطار $row: بغیر جوڑ کی منتقلی، $account پر ایڈجسٹمنٹ کے طور پر رکھی گئی';
  }

  @override
  String get namesTitle => 'اکاؤنٹس اور لوگ';

  @override
  String get namesHint =>
      'حساب کتاب لوگوں کو اکاؤنٹ کے طور پر رکھتا ہے۔ جو شخص ہے اسے نشان زد کریں، اس کی منتقلیاں ادھار بن جائیں گی۔';

  @override
  String get roleAccount => 'اکاؤنٹ';

  @override
  String get rolePerson => 'شخص';

  @override
  String get nameExisting => 'پہلے سے خرچہ میں';

  @override
  String nameEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اندراجات',
      one: '1 اندراج',
      zero: 'صرف ابتدائی بیلنس',
    );
    return '$_temp0';
  }

  @override
  String get importButton => 'امپورٹ کریں';

  @override
  String get importing => 'امپورٹ ہو رہا ہے…';

  @override
  String get importDone => 'امپورٹ مکمل';

  @override
  String get reportImported => 'امپورٹ ہوئے';

  @override
  String get reportDuplicates => 'پہلے سے موجود';

  @override
  String get reportSkipped => 'امپورٹ نہیں ہوئے';

  @override
  String get reportAccounts => 'نئے اکاؤنٹس';

  @override
  String get reportPeople => 'نئے لوگ';

  @override
  String get reportCategories => 'نئی کیٹیگریز';

  @override
  String skipBetweenPeople(int row) {
    return 'قطار $row: دو لوگوں کے درمیان منتقلی امپورٹ نہیں ہوئی';
  }

  @override
  String skipPersonAdjustment(int row) {
    return 'قطار $row: کسی شخص پر بغیر جوڑ کی منتقلی امپورٹ نہیں ہوئی';
  }

  @override
  String get importNothingNew => 'اس فائل کا سب کچھ پہلے سے خرچہ میں ہے۔';

  @override
  String get importFailed =>
      'امپورٹ مکمل نہیں ہوا۔ کچھ تبدیل نہیں ہوا، دوبارہ کوشش کریں۔';

  @override
  String get backupNudgeTitle => 'اپنے ڈیٹا کا بیک اپ بنائیں';

  @override
  String get backupNudgeNever => 'آپ نے ابھی تک بیک اپ نہیں بنایا۔';

  @override
  String backupNudgeDays(int days) {
    return 'آخری بیک اپ $days دن پہلے۔';
  }

  @override
  String get integrityTitle => 'آپ کے ڈیٹا پر توجہ درکار ہے';

  @override
  String get integrityBody =>
      'حفاظتی جانچ میں خرابی ملی۔ احتیاطاً بیک اپ سے بحال کریں۔';

  @override
  String get monthStartLastWorking => 'آخری کاروباری دن';

  @override
  String get haptics => 'ہلکی وائبریشن';

  @override
  String get hapticsHint => 'انتخاب، محفوظ یا حذف کرنے پر ہلکا سا احساس';

  @override
  String get appLock => 'ایپ لاک';

  @override
  String get appLockHint => 'خرچہ کھولنے کے لیے پن، فنگر پرنٹ یا چہرہ';

  @override
  String get on => 'آن';

  @override
  String get off => 'آف';

  @override
  String get turnOnLock => 'ایپ لاک آن کریں';

  @override
  String get choosePin => '4 ہندسوں کا پن چنیں';

  @override
  String get confirmPin => 'دوبارہ درج کریں';

  @override
  String get pinMismatch => 'دونوں ایک جیسے نہیں تھے۔ دوبارہ کوشش کریں۔';

  @override
  String get enterPin => 'اپنا پن درج کریں';

  @override
  String get currentPin => 'اپنا موجودہ پن درج کریں';

  @override
  String get wrongPin => 'غلط پن';

  @override
  String pinPaused(String time) {
    return 'بہت زیادہ کوششیں۔ $time بعد دوبارہ کوشش کریں۔';
  }

  @override
  String get forgotPin => 'پن بھول گئے؟';

  @override
  String get forgotPinReason => 'خرچہ کا لاک بند کرنے کے لیے تصدیق کریں';

  @override
  String get lockTurnedOff =>
      'ایپ لاک بند ہے۔ نیا پن مزید → ایپ لاک میں رکھیں۔';

  @override
  String get unlockReason => 'خرچہ ان لاک کریں';

  @override
  String get useBiometrics => 'فنگر پرنٹ یا چہرہ';

  @override
  String get useBiometricsHint => 'پن لکھے بغیر کھولیں';

  @override
  String get changePin => 'پن تبدیل کریں';

  @override
  String get turnOffLock => 'ایپ لاک بند کریں';

  @override
  String get lockAfter => 'کب لاک ہو';

  @override
  String get lockAfterHint => 'خرچہ کتنی دیر پس منظر میں رہ سکتا ہے';

  @override
  String get lockImmediately => 'فوراً';

  @override
  String lockSeconds(int n) {
    return '$n سیکنڈ';
  }

  @override
  String lockMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n منٹ',
      one: '1 منٹ',
    );
    return '$_temp0';
  }

  @override
  String get lockIsOn => 'ایپ لاک آن ہے';

  @override
  String get pinChanged => 'پن تبدیل ہو گیا';

  @override
  String get welcomeTitle => 'جانیں آپ کا پیسہ کہاں جاتا ہے';

  @override
  String get welcomeBody =>
      'چند سیکنڈ میں خرچ لکھیں۔ باقی حساب، بجٹ اور رپورٹس خرچہ سنبھالتا ہے۔';

  @override
  String get promiseOffline => 'آف لائن چلتا ہے۔ کبھی سائن اپ نہیں۔';

  @override
  String get promiseBackup => 'بیک اپ آپ کے فون یا آپ کی اپنی گوگل ڈرائیو میں';

  @override
  String get promisePayday => 'بجٹ جو آپ کی تنخواہ کی تاریخ کے ساتھ چلیں';

  @override
  String get promiseFree => 'مفت، اور کبھی کوئی اشتہار نہیں';

  @override
  String get setupTitle => 'اسے اپنا بنائیں';

  @override
  String get setupBody => 'یہ سب بعد میں مزید میں بدل سکتے ہیں۔';

  @override
  String get homeCurrency => 'کرنسی';

  @override
  String get homeCurrencyHint => 'کل رقم اور نئے اکاؤنٹس کے لیے';

  @override
  String get extrasTitle => 'کچھ اضافی چیزیں';

  @override
  String get extrasBody => 'دونوں اختیاری ہیں۔';

  @override
  String get extrasImport => 'حساب کتاب سے آ رہے ہیں؟';

  @override
  String get extrasImportHint => 'اپنا پرانا ریکارڈ ایک ساتھ لے آئیں';

  @override
  String get extrasLock => 'خرچہ کو پن سے لاک کریں';

  @override
  String get extrasLockHint => 'یا فنگر پرنٹ یا چہرے سے';

  @override
  String get skip => 'چھوڑیں';

  @override
  String get next => 'آگے';

  @override
  String get startUsing => 'خرچہ شروع کریں';

  @override
  String get categories => 'کیٹیگریز';

  @override
  String get categoriesHint =>
      'شامل کریں، نام بدلیں، ترتیب دیں یا آرکائیو کریں';

  @override
  String get addCategory => 'کیٹیگری شامل کریں';

  @override
  String get editCategory => 'کیٹیگری میں ترمیم';

  @override
  String get categoryName => 'نام';

  @override
  String get categoryIcon => 'آئیکن';

  @override
  String get categoryArchived => 'کیٹیگری آرکائیو ہو گئی';

  @override
  String duplicateCategoryName(String name) {
    return '$name نام کی کیٹیگری پہلے سے موجود ہے';
  }

  @override
  String get noCategories => 'یہاں ابھی کوئی کیٹیگری نہیں';

  @override
  String get about => 'تعارف';

  @override
  String get aboutHint => 'ورژن، نیا کیا ہے اور رابطہ';

  @override
  String version(String version) {
    return 'ورژن $version';
  }

  @override
  String get noAds =>
      'کبھی اشتہار نہیں۔ آپ کا ڈیٹا آپ کے فون پر رہتا ہے، جب تک آپ خود بیک اپ نہ کریں۔';

  @override
  String get whatsNew => 'نیا کیا ہے';

  @override
  String get contactUs => 'ہم سے رابطہ';

  @override
  String get contactUsHint => 'ہمیں ای میل کریں، ساتھ ایک مختصر تکنیکی رپورٹ';

  @override
  String get copyDiagnostics => 'تشخیصی معلومات کاپی کریں';

  @override
  String get diagnosticsCopied =>
      'معلومات کاپی ہو گئیں۔ اپنے پیغام میں پیسٹ کریں۔';

  @override
  String get supportSubject => 'خرچہ سپورٹ';

  @override
  String get hideBalancesHint => 'کل رقم اور بیلنس نقطوں کے پیچھے چھپائیں';

  @override
  String get copyDiagnosticsHint =>
      'ایک مختصر تکنیکی رپورٹ، ہمیں پیغام میں پیسٹ کرنے کے لیے';

  @override
  String get noAccounts =>
      'ابھی کوئی اکاؤنٹ نہیں۔ لکھنا شروع کرنے کے لیے ایک شامل کریں۔';

  @override
  String get bioFaceId => 'فیس آئی ڈی';

  @override
  String get bioTouchId => 'ٹچ آئی ڈی';

  @override
  String get bioFace => 'چہرے سے ان لاک';

  @override
  String get bioFingerprint => 'فنگر پرنٹ';

  @override
  String offerBiometricTitle(String name) {
    return '$name سے ان لاک کریں؟';
  }

  @override
  String get offerBiometricBody =>
      'پن لکھنے سے تیز۔ آپ کا پن بھی کام کرتا رہے گا۔';

  @override
  String useBiometricNamed(String name) {
    return '$name استعمال کریں';
  }

  @override
  String get notNow => 'ابھی نہیں';

  @override
  String enableBiometricReason(String name) {
    return 'خرچہ کے لیے $name آن کرنے کی تصدیق کریں';
  }

  @override
  String get privacyPolicy => 'پرائیویسی پالیسی';

  @override
  String get privacyPolicyHint => 'خرچہ کیا محفوظ کرتا ہے اور کہاں';

  @override
  String get showBalancesReason => 'اپنے بیلنس دکھائیں';

  @override
  String get deleteEntryTitle => 'یہ اندراج حذف کریں؟';

  @override
  String get deleteEntryBody =>
      'یہ آپ کے بیلنس اور رپورٹس سے ہٹ جائے گا۔ فوراً بعد واپس لا سکتے ہیں۔';

  @override
  String get searchPeople => 'لوگ تلاش کریں';

  @override
  String get sortLargest => 'سب سے بڑی رقم پہلے';

  @override
  String get sortSmallest => 'سب سے چھوٹی رقم پہلے';

  @override
  String get sortName => 'نام کے حساب سے';

  @override
  String get sortBy => 'ترتیب';

  @override
  String get nobodyOwesYou => 'ابھی کسی نے آپ کو کچھ نہیں دینا۔';

  @override
  String get youOweNobody => 'ابھی آپ نے کسی کو کچھ نہیں دینا۔';

  @override
  String get noneSettled => 'ابھی کوئی حساب برابر نہیں ہوا۔';

  @override
  String noPeopleMatch(String query) {
    return '“$query” سے کوئی نہیں ملا';
  }

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لوگ',
      one: '1 شخص',
    );
    return '$_temp0';
  }
}

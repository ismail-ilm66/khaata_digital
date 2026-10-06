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
}

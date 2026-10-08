import 'package:meta/meta.dart';

import 'account_type.dart';

/// A curated bank / wallet for the add-account picker (spec 3.1 #2), listed
/// per country.
@immutable
class AccountPreset {
  const AccountPreset({
    required this.key,
    required this.name,
    required this.type,
    required this.color,
    required this.monogram,
    this.aliases = const [],
  });

  /// Stable id stored as the account's `icon`.
  final String key;
  final String name;
  final AccountType type;

  /// Brand-adjacent ARGB colour for the monogram badge.
  final int color;
  final String monogram;

  /// Other spellings seen in the wild (e.g. Hysab Kytab exports).
  final List<String> aliases;

  bool matches(String accountName) {
    final n = _norm(accountName);
    return _norm(name) == n || aliases.any((a) => _norm(a) == n);
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

abstract final class AccountPresets {
  static const cash = AccountPreset(
    key: 'cash',
    name: 'Cash',
    type: AccountType.cash,
    color: 0xFF5F6B7A,
    monogram: 'Rs',
  );

  /// Pakistan.
  static const List<AccountPreset> pakistan = [
    AccountPreset(
      key: 'easypaisa',
      name: 'Easypaisa',
      type: AccountType.wallet,
      color: 0xFF1FA84F,
      monogram: 'EP',
    ),
    AccountPreset(
      key: 'jazzcash',
      name: 'JazzCash',
      type: AccountType.wallet,
      color: 0xFFC8102E,
      monogram: 'JC',
    ),
    AccountPreset(
      key: 'sadapay',
      name: 'SadaPay',
      type: AccountType.wallet,
      color: 0xFF00A88F,
      monogram: 'SP',
    ),
    AccountPreset(
      key: 'nayapay',
      name: 'NayaPay',
      type: AccountType.wallet,
      color: 0xFFE8641B,
      monogram: 'NP',
    ),
    AccountPreset(
      key: 'meezan',
      name: 'Meezan Bank',
      type: AccountType.bank,
      color: 0xFF6A1B6E,
      monogram: 'MB',
      aliases: ['Meezan'],
    ),
    AccountPreset(
      key: 'hbl',
      name: 'HBL',
      type: AccountType.bank,
      color: 0xFF00836B,
      monogram: 'HBL',
      aliases: ['Habib Bank', 'Habib Bank Limited'],
    ),
    AccountPreset(
      key: 'ubl',
      name: 'UBL',
      type: AccountType.bank,
      color: 0xFF0055A5,
      monogram: 'UBL',
      aliases: ['United Bank', 'United Bank Limited'],
    ),
    AccountPreset(
      key: 'mcb',
      name: 'MCB',
      type: AccountType.bank,
      color: 0xFF0B7A4B,
      monogram: 'MCB',
      aliases: ['MCB Bank', 'Muslim Commercial Bank'],
    ),
    AccountPreset(
      key: 'allied',
      name: 'Allied Bank',
      type: AccountType.bank,
      color: 0xFF0F4C81,
      monogram: 'ABL',
      aliases: ['ABL', 'Allied Bank Limited'],
    ),
    AccountPreset(
      key: 'alfalah',
      name: 'Bank Alfalah',
      type: AccountType.bank,
      color: 0xFFB01E23,
      monogram: 'BAF',
      aliases: ['Alfalah'],
    ),
    AccountPreset(
      key: 'askari',
      name: 'Askari Bank',
      type: AccountType.bank,
      color: 0xFF0067B1,
      monogram: 'AKB',
      aliases: ['Askari'],
    ),
    AccountPreset(
      key: 'scb',
      name: 'Standard Chartered',
      type: AccountType.bank,
      color: 0xFF0473EA,
      monogram: 'SC',
      aliases: ['Standard Chartered Bank', 'SCB'],
    ),
  ];

  /// Offered in every country (freelancers, remittances).
  static const List<AccountPreset> international = [
    AccountPreset(
      key: 'paypal',
      name: 'PayPal',
      type: AccountType.wallet,
      color: 0xFF003087,
      monogram: 'PP',
    ),
    AccountPreset(
      key: 'wise',
      name: 'Wise',
      type: AccountType.wallet,
      color: 0xFF163300,
      monogram: 'W',
      aliases: ['TransferWise'],
    ),
    AccountPreset(
      key: 'payoneer',
      name: 'Payoneer',
      type: AccountType.wallet,
      color: 0xFFFF4800,
      monogram: 'PO',
    ),
  ];

  /// India.
  static const List<AccountPreset> _in = [
    AccountPreset(
      key: 'paytm',
      name: 'Paytm',
      type: AccountType.wallet,
      color: 0xFF00BAF2,
      monogram: 'PTM',
    ),
    AccountPreset(
      key: 'phonepe',
      name: 'PhonePe',
      type: AccountType.wallet,
      color: 0xFF5F259F,
      monogram: 'PP',
    ),
    AccountPreset(
      key: 'gpay_in',
      name: 'Google Pay',
      type: AccountType.wallet,
      color: 0xFF4285F4,
      monogram: 'GP',
      aliases: ['GPay'],
    ),
    AccountPreset(
      key: 'sbi',
      name: 'SBI',
      type: AccountType.bank,
      color: 0xFF2D6EB5,
      monogram: 'SBI',
      aliases: ['State Bank of India'],
    ),
    AccountPreset(
      key: 'hdfc',
      name: 'HDFC Bank',
      type: AccountType.bank,
      color: 0xFF004C8F,
      monogram: 'HDF',
      aliases: ['HDFC'],
    ),
    AccountPreset(
      key: 'icici',
      name: 'ICICI Bank',
      type: AccountType.bank,
      color: 0xFFB02A30,
      monogram: 'ICI',
      aliases: ['ICICI'],
    ),
    AccountPreset(
      key: 'axis',
      name: 'Axis Bank',
      type: AccountType.bank,
      color: 0xFF97144D,
      monogram: 'AX',
      aliases: ['Axis'],
    ),
    AccountPreset(
      key: 'kotak',
      name: 'Kotak Mahindra Bank',
      type: AccountType.bank,
      color: 0xFFED1C24,
      monogram: 'KMB',
      aliases: ['Kotak'],
    ),
  ];

  /// United Arab Emirates.
  static const List<AccountPreset> _ae = [
    AccountPreset(
      key: 'enbd',
      name: 'Emirates NBD',
      type: AccountType.bank,
      color: 0xFF072F5F,
      monogram: 'ENB',
      aliases: ['ENBD'],
    ),
    AccountPreset(
      key: 'fab',
      name: 'First Abu Dhabi Bank',
      type: AccountType.bank,
      color: 0xFF00205B,
      monogram: 'FAB',
      aliases: ['FAB'],
    ),
    AccountPreset(
      key: 'adcb',
      name: 'ADCB',
      type: AccountType.bank,
      color: 0xFFC8102E,
      monogram: 'ADC',
      aliases: ['Abu Dhabi Commercial Bank'],
    ),
    AccountPreset(
      key: 'mashreq',
      name: 'Mashreq',
      type: AccountType.bank,
      color: 0xFFF15A22,
      monogram: 'MQ',
      aliases: ['Mashreq Bank'],
    ),
    AccountPreset(
      key: 'dib',
      name: 'Dubai Islamic Bank',
      type: AccountType.bank,
      color: 0xFF00573F,
      monogram: 'DIB',
      aliases: ['DIB'],
    ),
    AccountPreset(
      key: 'careempay',
      name: 'Careem Pay',
      type: AccountType.wallet,
      color: 0xFF2D7A4F,
      monogram: 'CP',
    ),
  ];

  /// Saudi Arabia.
  static const List<AccountPreset> _sa = [
    AccountPreset(
      key: 'alrajhi',
      name: 'Al Rajhi Bank',
      type: AccountType.bank,
      color: 0xFF1F3C88,
      monogram: 'AR',
      aliases: ['Al Rajhi'],
    ),
    AccountPreset(
      key: 'snb',
      name: 'SNB',
      type: AccountType.bank,
      color: 0xFF00704A,
      monogram: 'SNB',
      aliases: ['Saudi National Bank', 'AlAhli'],
    ),
    AccountPreset(
      key: 'riyad',
      name: 'Riyad Bank',
      type: AccountType.bank,
      color: 0xFF005BAA,
      monogram: 'RB',
    ),
    AccountPreset(
      key: 'sab',
      name: 'SAB',
      type: AccountType.bank,
      color: 0xFFDB0011,
      monogram: 'SAB',
      aliases: ['Saudi Awwal Bank', 'SABB'],
    ),
    AccountPreset(
      key: 'alinma',
      name: 'Alinma Bank',
      type: AccountType.bank,
      color: 0xFF7A5C2E,
      monogram: 'AIB',
      aliases: ['Alinma'],
    ),
    AccountPreset(
      key: 'stcpay',
      name: 'stc pay',
      type: AccountType.wallet,
      color: 0xFF4F008C,
      monogram: 'STC',
      aliases: ['STC Bank'],
    ),
  ];

  /// Qatar.
  static const List<AccountPreset> _qa = [
    AccountPreset(
      key: 'qnb',
      name: 'QNB',
      type: AccountType.bank,
      color: 0xFF5C2D91,
      monogram: 'QNB',
      aliases: ['Qatar National Bank'],
    ),
    AccountPreset(
      key: 'cbq',
      name: 'Commercial Bank',
      type: AccountType.bank,
      color: 0xFFC8102E,
      monogram: 'CBQ',
    ),
    AccountPreset(
      key: 'qib',
      name: 'QIB',
      type: AccountType.bank,
      color: 0xFF8B6D2F,
      monogram: 'QIB',
      aliases: ['Qatar Islamic Bank'],
    ),
    AccountPreset(
      key: 'dohabank',
      name: 'Doha Bank',
      type: AccountType.bank,
      color: 0xFF0055A4,
      monogram: 'DB',
    ),
  ];

  /// Oman.
  static const List<AccountPreset> _om = [
    AccountPreset(
      key: 'bankmuscat',
      name: 'Bank Muscat',
      type: AccountType.bank,
      color: 0xFF00A3E0,
      monogram: 'BM',
    ),
    AccountPreset(
      key: 'nbo',
      name: 'NBO',
      type: AccountType.bank,
      color: 0xFF005EB8,
      monogram: 'NBO',
      aliases: ['National Bank of Oman'],
    ),
    AccountPreset(
      key: 'dhofar',
      name: 'Bank Dhofar',
      type: AccountType.bank,
      color: 0xFF00704A,
      monogram: 'BD',
    ),
    AccountPreset(
      key: 'sohar',
      name: 'Sohar International',
      type: AccountType.bank,
      color: 0xFF1C2F5E,
      monogram: 'SI',
    ),
  ];

  /// Kuwait.
  static const List<AccountPreset> _kw = [
    AccountPreset(
      key: 'nbk',
      name: 'NBK',
      type: AccountType.bank,
      color: 0xFF003DA5,
      monogram: 'NBK',
      aliases: ['National Bank of Kuwait'],
    ),
    AccountPreset(
      key: 'kfh',
      name: 'KFH',
      type: AccountType.bank,
      color: 0xFF00843D,
      monogram: 'KFH',
      aliases: ['Kuwait Finance House'],
    ),
    AccountPreset(
      key: 'gulfbank',
      name: 'Gulf Bank',
      type: AccountType.bank,
      color: 0xFF0071BC,
      monogram: 'GB',
    ),
    AccountPreset(
      key: 'burgan',
      name: 'Burgan Bank',
      type: AccountType.bank,
      color: 0xFF003B71,
      monogram: 'BB',
    ),
  ];

  /// Bahrain.
  static const List<AccountPreset> _bh = [
    AccountPreset(
      key: 'nbb',
      name: 'NBB',
      type: AccountType.bank,
      color: 0xFFB2142E,
      monogram: 'NBB',
      aliases: ['National Bank of Bahrain'],
    ),
    AccountPreset(
      key: 'bbk',
      name: 'BBK',
      type: AccountType.bank,
      color: 0xFF003A70,
      monogram: 'BBK',
      aliases: ['Bank of Bahrain and Kuwait'],
    ),
    AccountPreset(
      key: 'benefitpay',
      name: 'BenefitPay',
      type: AccountType.wallet,
      color: 0xFFD71920,
      monogram: 'BP',
    ),
  ];

  /// United Kingdom.
  static const List<AccountPreset> _gb = [
    AccountPreset(
      key: 'barclays',
      name: 'Barclays',
      type: AccountType.bank,
      color: 0xFF00AEEF,
      monogram: 'BAR',
    ),
    AccountPreset(
      key: 'hsbcuk',
      name: 'HSBC UK',
      type: AccountType.bank,
      color: 0xFFDB0011,
      monogram: 'HS',
      aliases: ['HSBC'],
    ),
    AccountPreset(
      key: 'lloyds',
      name: 'Lloyds Bank',
      type: AccountType.bank,
      color: 0xFF006A4D,
      monogram: 'LB',
      aliases: ['Lloyds'],
    ),
    AccountPreset(
      key: 'natwest',
      name: 'NatWest',
      type: AccountType.bank,
      color: 0xFF5A287D,
      monogram: 'NW',
    ),
    AccountPreset(
      key: 'santanderuk',
      name: 'Santander UK',
      type: AccountType.bank,
      color: 0xFFEC0000,
      monogram: 'SAN',
      aliases: ['Santander'],
    ),
    AccountPreset(
      key: 'monzo',
      name: 'Monzo',
      type: AccountType.bank,
      color: 0xFFFF4F40,
      monogram: 'MZ',
    ),
    AccountPreset(
      key: 'starling',
      name: 'Starling Bank',
      type: AccountType.bank,
      color: 0xFF6935D3,
      monogram: 'SB',
      aliases: ['Starling'],
    ),
    AccountPreset(
      key: 'revolut',
      name: 'Revolut',
      type: AccountType.wallet,
      color: 0xFF191C1F,
      monogram: 'R',
    ),
  ];

  /// United States.
  static const List<AccountPreset> _us = [
    AccountPreset(
      key: 'chase',
      name: 'Chase',
      type: AccountType.bank,
      color: 0xFF117ACA,
      monogram: 'CH',
      aliases: ['JPMorgan Chase'],
    ),
    AccountPreset(
      key: 'bofa',
      name: 'Bank of America',
      type: AccountType.bank,
      color: 0xFFE31837,
      monogram: 'BoA',
      aliases: ['BofA'],
    ),
    AccountPreset(
      key: 'wellsfargo',
      name: 'Wells Fargo',
      type: AccountType.bank,
      color: 0xFFD71E28,
      monogram: 'WF',
    ),
    AccountPreset(
      key: 'citi',
      name: 'Citi',
      type: AccountType.bank,
      color: 0xFF056DAE,
      monogram: 'C',
      aliases: ['Citibank'],
    ),
    AccountPreset(
      key: 'capitalone',
      name: 'Capital One',
      type: AccountType.bank,
      color: 0xFF004977,
      monogram: 'C1',
    ),
    AccountPreset(
      key: 'venmo',
      name: 'Venmo',
      type: AccountType.wallet,
      color: 0xFF3D95CE,
      monogram: 'V',
    ),
    AccountPreset(
      key: 'cashapp',
      name: 'Cash App',
      type: AccountType.wallet,
      color: 0xFF00C244,
      monogram: 'CA',
    ),
  ];

  /// Canada.
  static const List<AccountPreset> _ca = [
    AccountPreset(
      key: 'rbc',
      name: 'RBC',
      type: AccountType.bank,
      color: 0xFF005DAA,
      monogram: 'RBC',
      aliases: ['Royal Bank of Canada'],
    ),
    AccountPreset(
      key: 'td',
      name: 'TD',
      type: AccountType.bank,
      color: 0xFF2E8B26,
      monogram: 'TD',
      aliases: ['TD Bank', 'TD Canada Trust'],
    ),
    AccountPreset(
      key: 'scotiabank',
      name: 'Scotiabank',
      type: AccountType.bank,
      color: 0xFFEC111A,
      monogram: 'SB',
    ),
    AccountPreset(
      key: 'bmo',
      name: 'BMO',
      type: AccountType.bank,
      color: 0xFF0079C1,
      monogram: 'BMO',
      aliases: ['Bank of Montreal'],
    ),
    AccountPreset(
      key: 'cibc',
      name: 'CIBC',
      type: AccountType.bank,
      color: 0xFFC41F3E,
      monogram: 'CI',
    ),
  ];

  /// Australia.
  static const List<AccountPreset> _au = [
    AccountPreset(
      key: 'commbank',
      name: 'CommBank',
      type: AccountType.bank,
      color: 0xFFC69214,
      monogram: 'CBA',
      aliases: ['Commonwealth Bank'],
    ),
    AccountPreset(
      key: 'westpac',
      name: 'Westpac',
      type: AccountType.bank,
      color: 0xFFDA1710,
      monogram: 'WP',
    ),
    AccountPreset(
      key: 'nab',
      name: 'NAB',
      type: AccountType.bank,
      color: 0xFF000000,
      monogram: 'NAB',
      aliases: ['National Australia Bank'],
    ),
    AccountPreset(
      key: 'anz',
      name: 'ANZ',
      type: AccountType.bank,
      color: 0xFF007DBA,
      monogram: 'ANZ',
    ),
  ];

  /// Malaysia.
  static const List<AccountPreset> _my = [
    AccountPreset(
      key: 'maybank',
      name: 'Maybank',
      type: AccountType.bank,
      color: 0xFFC29A1D,
      monogram: 'MB',
    ),
    AccountPreset(
      key: 'cimb',
      name: 'CIMB',
      type: AccountType.bank,
      color: 0xFFEC1C24,
      monogram: 'CI',
      aliases: ['CIMB Bank'],
    ),
    AccountPreset(
      key: 'publicbank',
      name: 'Public Bank',
      type: AccountType.bank,
      color: 0xFFD71920,
      monogram: 'PB',
    ),
    AccountPreset(
      key: 'rhb',
      name: 'RHB',
      type: AccountType.bank,
      color: 0xFF0067B1,
      monogram: 'RHB',
      aliases: ['RHB Bank'],
    ),
    AccountPreset(
      key: 'tng',
      name: 'Touch \'n Go eWallet',
      type: AccountType.wallet,
      color: 0xFF005ABB,
      monogram: 'TNG',
      aliases: ['TNG', 'Touch n Go'],
    ),
    AccountPreset(
      key: 'grabpay',
      name: 'GrabPay',
      type: AccountType.wallet,
      color: 0xFF00B14F,
      monogram: 'GP',
    ),
  ];

  /// Turkey.
  static const List<AccountPreset> _tr = [
    AccountPreset(
      key: 'ziraat',
      name: 'Ziraat Bankası',
      type: AccountType.bank,
      color: 0xFFE30A17,
      monogram: 'ZB',
      aliases: ['Ziraat'],
    ),
    AccountPreset(
      key: 'isbank',
      name: 'İş Bankası',
      type: AccountType.bank,
      color: 0xFF0C3C7C,
      monogram: 'İŞ',
      aliases: ['Is Bankasi', 'Isbank'],
    ),
    AccountPreset(
      key: 'garanti',
      name: 'Garanti BBVA',
      type: AccountType.bank,
      color: 0xFF1C8A43,
      monogram: 'GB',
      aliases: ['Garanti'],
    ),
    AccountPreset(
      key: 'akbank',
      name: 'Akbank',
      type: AccountType.bank,
      color: 0xFFE2001A,
      monogram: 'AK',
    ),
    AccountPreset(
      key: 'yapikredi',
      name: 'Yapı Kredi',
      type: AccountType.bank,
      color: 0xFF004990,
      monogram: 'YK',
      aliases: ['Yapi Kredi'],
    ),
    AccountPreset(
      key: 'papara',
      name: 'Papara',
      type: AccountType.wallet,
      color: 0xFF000000,
      monogram: 'PA',
    ),
  ];

  /// China.
  static const List<AccountPreset> _cn = [
    AccountPreset(
      key: 'alipay',
      name: 'Alipay',
      type: AccountType.wallet,
      color: 0xFF1677FF,
      monogram: '支',
      aliases: ['Zhifubao'],
    ),
    AccountPreset(
      key: 'wechatpay',
      name: 'WeChat Pay',
      type: AccountType.wallet,
      color: 0xFF07C160,
      monogram: '微',
      aliases: ['WeChat'],
    ),
    AccountPreset(
      key: 'icbc',
      name: 'ICBC',
      type: AccountType.bank,
      color: 0xFFC7000B,
      monogram: '工',
    ),
    AccountPreset(
      key: 'ccb',
      name: 'China Construction Bank',
      type: AccountType.bank,
      color: 0xFF0066B3,
      monogram: '建',
      aliases: ['CCB'],
    ),
    AccountPreset(
      key: 'boc',
      name: 'Bank of China',
      type: AccountType.bank,
      color: 0xFFB81C22,
      monogram: '中',
      aliases: ['BOC'],
    ),
    AccountPreset(
      key: 'abc',
      name: 'Agricultural Bank of China',
      type: AccountType.bank,
      color: 0xFF009882,
      monogram: '农',
      aliases: ['ABC'],
    ),
  ];

  /// Euro area.
  static const List<AccountPreset> _eu = [
    AccountPreset(
      key: 'revolut',
      name: 'Revolut',
      type: AccountType.wallet,
      color: 0xFF191C1F,
      monogram: 'R',
    ),
    AccountPreset(
      key: 'n26',
      name: 'N26',
      type: AccountType.bank,
      color: 0xFF36A18B,
      monogram: 'N26',
    ),
    AccountPreset(
      key: 'bunq',
      name: 'bunq',
      type: AccountType.bank,
      color: 0xFF2D8C4E,
      monogram: 'bq',
    ),
  ];

  static const Map<String, List<AccountPreset>> _byCountry = {
    'PK': pakistan,
    'IN': _in,
    'AE': _ae,
    'SA': _sa,
    'QA': _qa,
    'OM': _om,
    'KW': _kw,
    'BH': _bh,
    'GB': _gb,
    'US': _us,
    'CA': _ca,
    'AU': _au,
    'MY': _my,
    'TR': _tr,
    'CN': _cn,
    'EU': _eu,
  };

  /// What the add-account picker offers for [countryCode]: Cash, that
  /// country's banks and wallets, then the international ones.
  static List<AccountPreset> forCountry(String countryCode) => [
    cash,
    ...?_byCountry[countryCode],
    ...international,
  ];

  /// Every preset once, for badges and for matching imported names.
  static final List<AccountPreset> all = [
    cash,
    ...{
      for (final list in [..._byCountry.values, international])
        for (final p in list) p.key: p,
    }.values,
  ];

  static AccountPreset? byKey(String? key) {
    for (final p in all) {
      if (p.key == key) return p;
    }
    return null;
  }

  static AccountPreset? match(String accountName) {
    for (final p in all) {
      if (p.matches(accountName)) return p;
    }
    return null;
  }

  static final _wallet = RegExp(
    r'easy\s?paisa|jazz\s?cash|sada\s?pay|naya\s?pay|upaisa|payoneer|paypal|'
    r'wallet|zindigi|keenu',
    caseSensitive: false,
  );
  static final _bank = RegExp(
    r'\bbank|\bhbl\b|\bubl\b|\bmcb\b|\babl\b|\bnbp\b|\bbop\b|meezan|'
    r'alfalah|askari|faysal|habib|allied|islami|soneri|summit|silk|'
    r'chartered|al\s?baraka|\bjs\b|limited|\bltd\b',
    caseSensitive: false,
  );
  static final _card = RegExp(
    r'\bcard\b|credit|visa|master',
    caseSensitive: false,
  );
  static final _savings = RegExp(
    r'saving|committee|\bbc\b|invest|fund|deposit',
    caseSensitive: false,
  );
  static final _cash = RegExp(
    r'\bcash\b|account|purse|pocket',
    caseSensitive: false,
  );

  /// Best-guess account type from a free-text name (spec 3.3 import rule):
  /// a known preset's type; else wallet brands → wallet, bank words and
  /// Pakistani bank names → bank, card → card, savings / committee →
  /// savings, otherwise cash.
  static AccountType guessType(String accountName) {
    final preset = match(accountName);
    if (preset != null) return preset.type;
    if (_wallet.hasMatch(accountName)) return AccountType.wallet;
    if (_bank.hasMatch(accountName)) return AccountType.bank;
    if (_card.hasMatch(accountName)) return AccountType.card;
    if (_savings.hasMatch(accountName)) return AccountType.savings;
    return AccountType.cash;
  }

  /// Whether a name sounds like a money account at all — used to tell
  /// Hysab Kytab's person "accounts" (Mudassir Bhai) from real ones.
  static bool looksLikeAccount(String name) =>
      match(name) != null ||
      [_wallet, _bank, _card, _savings, _cash].any((r) => r.hasMatch(name));
}

/// Every route path in one place.
///
/// Tabs live in the shell; everything else is a full-screen page pushed on
/// the root navigator over the shell, so it animates the same from any tab.
abstract final class Routes {
  // Tabs
  static const home = '/home';
  static const transactions = '/transactions';
  static const reports = '/reports';
  static const more = '/more';

  // Full-screen pages
  static const search = '/search';
  static const accounts = '/accounts';
  static const accountForm = '/accounts/form';
  static const entryPattern = '/entry/:id';
  static const entries = '/entries';
  static const budgets = '/budgets';
  static const people = '/people';
  static const personPattern = '/people/:id';
  static const recurring = '/recurring';
  static const addEntry = '/add';
  static const editEntryPattern = '/edit/:id';
  static const backup = '/backup';
  static const restore = '/restore';
  static const importData = '/import';
  static const appLock = '/app-lock';
  static const welcome = '/welcome';
  static const categories = '/categories';
  static const about = '/about';
  static const privacy = '/privacy';

  static String entry(String id) => '/entry/$id';
  static String editEntry(String id) => '/edit/$id';
  static String person(String id) => '/people/$id';

  /// People on a given tab (`receive`, `owe`, `settled`).
  static String peopleTab(String tab) => '/people?tab=$tab';
}

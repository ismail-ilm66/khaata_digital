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
  static const addEntry = '/add';
  static const editEntryPattern = '/edit/:id';

  static String entry(String id) => '/entry/$id';
  static String editEntry(String id) => '/edit/$id';
}

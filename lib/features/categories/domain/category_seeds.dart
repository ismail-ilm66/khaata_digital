import 'package:meta/meta.dart';

import 'category_kind.dart';

@immutable
class CategorySeed {
  const CategorySeed(this.name, this.kind, this.icon);

  final String name;
  final CategoryKind kind;

  /// Icon key resolved by the presentation layer's icon registry.
  final String icon;
}

/// Seed categories, copied verbatim (names and order) from the CATEGORY
/// sheet of a real Hysab Kytab export so imports match without remapping.
///
/// "No Category" is deliberately not seeded: it means `category_id IS NULL`
/// and is rendered/exported under that label.
abstract final class CategorySeeds {
  static const String noCategoryLabel = 'No Category';

  /// Muted hues that hold up in light and dark themes; assigned in order.
  static const List<int> palette = [
    0xFF2F7D5B, // green
    0xFF3A6EA5, // blue
    0xFF8A5BA8, // purple
    0xFFC0703A, // orange
    0xFFB5475A, // rose
    0xFF3D8C8C, // teal
    0xFF9C8A2E, // olive
    0xFF5F6B7A, // slate
  ];

  static int colorAt(int index) => palette[index % palette.length];

  static const List<CategorySeed> all = [
    CategorySeed('Salary', CategoryKind.income, 'payments'),
    CategorySeed('Business Income/Profit', CategoryKind.income, 'storefront'),
    CategorySeed('Investment', CategoryKind.income, 'trending_up'),
    CategorySeed('Commission', CategoryKind.income, 'percent'),
    CategorySeed('Pension', CategoryKind.income, 'elderly'),
    CategorySeed('Allowance', CategoryKind.income, 'wallet'),
    CategorySeed('Bonus', CategoryKind.income, 'redeem'),
    CategorySeed('Transport Income', CategoryKind.income, 'local_taxi'),
    CategorySeed('Pocket Money', CategoryKind.income, 'toll'),
    CategorySeed('Freelance', CategoryKind.income, 'laptop'),
    CategorySeed('Tutoring Income', CategoryKind.income, 'menu_book'),
    CategorySeed('Gifts Received', CategoryKind.income, 'card_giftcard'),
    CategorySeed('Rent Received', CategoryKind.income, 'key'),
    CategorySeed('Loan Received', CategoryKind.income, 'call_received'),
    CategorySeed('Other Income', CategoryKind.income, 'add_circle'),
    CategorySeed('Savings', CategoryKind.income, 'savings'),
    CategorySeed('Personal', CategoryKind.expense, 'person'),
    CategorySeed('Food & Drink', CategoryKind.expense, 'restaurant'),
    CategorySeed('Transport', CategoryKind.expense, 'directions_bus'),
    CategorySeed('Grocery', CategoryKind.expense, 'shopping_basket'),
    CategorySeed('Travel', CategoryKind.expense, 'flight'),
    CategorySeed('Entertainment', CategoryKind.expense, 'movie'),
    CategorySeed(
      'Fuel & Maintenance',
      CategoryKind.expense,
      'local_gas_station',
    ),
    CategorySeed('Bills & Utilities', CategoryKind.expense, 'receipt'),
    CategorySeed('Medical', CategoryKind.expense, 'medical_services'),
    CategorySeed('Shopping', CategoryKind.expense, 'shopping_bag'),
    CategorySeed('Education', CategoryKind.expense, 'school'),
    CategorySeed('Office', CategoryKind.expense, 'work'),
    CategorySeed('Home', CategoryKind.expense, 'home'),
    CategorySeed('Rent Paid', CategoryKind.expense, 'house'),
    CategorySeed('Loan Paid', CategoryKind.expense, 'call_made'),
    CategorySeed(
      'Donations/Charity',
      CategoryKind.expense,
      'volunteer_activism',
    ),
    CategorySeed('Gifts', CategoryKind.expense, 'card_giftcard'),
    CategorySeed('Family', CategoryKind.expense, 'family_restroom'),
    CategorySeed('Health & Fitness', CategoryKind.expense, 'fitness_center'),
    CategorySeed('Wedding', CategoryKind.expense, 'celebration'),
    CategorySeed('Mobile', CategoryKind.expense, 'smartphone'),
    CategorySeed('Electronics', CategoryKind.expense, 'devices'),
    CategorySeed('Insurance', CategoryKind.expense, 'shield'),
    CategorySeed('Committee', CategoryKind.expense, 'groups'),
    CategorySeed('Installment', CategoryKind.expense, 'event_repeat'),
    CategorySeed('Other Expenses', CategoryKind.expense, 'more_horiz'),
  ];
}

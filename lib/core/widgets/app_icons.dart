import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// An icon in its two weights: [regular] for resting states and lists,
/// [filled] for selected states and tinted badges.
@immutable
class AppIcon {
  const AppIcon(this.regular, this.filled);

  final IconData regular;
  final IconData filled;
}

/// Every icon the app draws, by meaning. Screens never reference an icon
/// font directly, so the whole app keeps one visual language (Phosphor).
abstract final class AppIcons {
  // Navigation
  static const home = AppIcon(
    PhosphorIconsRegular.house,
    PhosphorIconsFill.house,
  );
  static const transactions = AppIcon(
    PhosphorIconsRegular.receipt,
    PhosphorIconsFill.receipt,
  );
  static const reports = AppIcon(
    PhosphorIconsRegular.chartDonut,
    PhosphorIconsFill.chartDonut,
  );
  static const more = AppIcon(
    PhosphorIconsRegular.squaresFour,
    PhosphorIconsFill.squaresFour,
  );
  static const IconData add = PhosphorIconsBold.plus;

  // Settings & states
  static const theme = AppIcon(
    PhosphorIconsRegular.circleHalf,
    PhosphorIconsFill.circleHalf,
  );
  static const language = AppIcon(
    PhosphorIconsRegular.translate,
    PhosphorIconsFill.translate,
  );
  static const quickAdd = AppIcon(
    PhosphorIconsRegular.lightning,
    PhosphorIconsFill.lightning,
  );

  // Categories — keys are the stable values stored in `categories.icon`.
  static const fallback = AppIcon(
    PhosphorIconsRegular.tag,
    PhosphorIconsFill.tag,
  );

  static const Map<String, AppIcon> byKey = {
    'payments': AppIcon(PhosphorIconsRegular.money, PhosphorIconsFill.money),
    'storefront': AppIcon(
      PhosphorIconsRegular.storefront,
      PhosphorIconsFill.storefront,
    ),
    'trending_up': AppIcon(
      PhosphorIconsRegular.trendUp,
      PhosphorIconsFill.trendUp,
    ),
    'percent': AppIcon(PhosphorIconsRegular.percent, PhosphorIconsFill.percent),
    'elderly': AppIcon(
      PhosphorIconsRegular.armchair,
      PhosphorIconsFill.armchair,
    ),
    'wallet': AppIcon(PhosphorIconsRegular.wallet, PhosphorIconsFill.wallet),
    'redeem': AppIcon(PhosphorIconsRegular.sparkle, PhosphorIconsFill.sparkle),
    'local_taxi': AppIcon(PhosphorIconsRegular.taxi, PhosphorIconsFill.taxi),
    'toll': AppIcon(PhosphorIconsRegular.coins, PhosphorIconsFill.coins),
    'laptop': AppIcon(PhosphorIconsRegular.laptop, PhosphorIconsFill.laptop),
    'menu_book': AppIcon(
      PhosphorIconsRegular.chalkboardTeacher,
      PhosphorIconsFill.chalkboardTeacher,
    ),
    'card_giftcard': AppIcon(PhosphorIconsRegular.gift, PhosphorIconsFill.gift),
    'key': AppIcon(PhosphorIconsRegular.key, PhosphorIconsFill.key),
    'call_received': AppIcon(
      PhosphorIconsRegular.handCoins,
      PhosphorIconsFill.handCoins,
    ),
    'add_circle': AppIcon(
      PhosphorIconsRegular.plusCircle,
      PhosphorIconsFill.plusCircle,
    ),
    'savings': AppIcon(
      PhosphorIconsRegular.piggyBank,
      PhosphorIconsFill.piggyBank,
    ),
    'person': AppIcon(PhosphorIconsRegular.user, PhosphorIconsFill.user),
    'restaurant': AppIcon(
      PhosphorIconsRegular.forkKnife,
      PhosphorIconsFill.forkKnife,
    ),
    'directions_bus': AppIcon(PhosphorIconsRegular.bus, PhosphorIconsFill.bus),
    'shopping_basket': AppIcon(
      PhosphorIconsRegular.basket,
      PhosphorIconsFill.basket,
    ),
    'flight': AppIcon(
      PhosphorIconsRegular.airplaneTilt,
      PhosphorIconsFill.airplaneTilt,
    ),
    'movie': AppIcon(PhosphorIconsRegular.popcorn, PhosphorIconsFill.popcorn),
    'local_gas_station': AppIcon(
      PhosphorIconsRegular.gasPump,
      PhosphorIconsFill.gasPump,
    ),
    'receipt': AppIcon(
      PhosphorIconsRegular.lightbulb,
      PhosphorIconsFill.lightbulb,
    ),
    'medical_services': AppIcon(
      PhosphorIconsRegular.firstAidKit,
      PhosphorIconsFill.firstAidKit,
    ),
    'shopping_bag': AppIcon(
      PhosphorIconsRegular.shoppingBag,
      PhosphorIconsFill.shoppingBag,
    ),
    'school': AppIcon(
      PhosphorIconsRegular.graduationCap,
      PhosphorIconsFill.graduationCap,
    ),
    'work': AppIcon(
      PhosphorIconsRegular.briefcase,
      PhosphorIconsFill.briefcase,
    ),
    'home': AppIcon(PhosphorIconsRegular.house, PhosphorIconsFill.house),
    'house': AppIcon(
      PhosphorIconsRegular.buildings,
      PhosphorIconsFill.buildings,
    ),
    'call_made': AppIcon(
      PhosphorIconsRegular.arrowUpRight,
      PhosphorIconsFill.arrowUpRight,
    ),
    'volunteer_activism': AppIcon(
      PhosphorIconsRegular.handHeart,
      PhosphorIconsFill.handHeart,
    ),
    'family_restroom': AppIcon(
      PhosphorIconsRegular.usersThree,
      PhosphorIconsFill.usersThree,
    ),
    'fitness_center': AppIcon(
      PhosphorIconsRegular.barbell,
      PhosphorIconsFill.barbell,
    ),
    'celebration': AppIcon(
      PhosphorIconsRegular.confetti,
      PhosphorIconsFill.confetti,
    ),
    'smartphone': AppIcon(
      PhosphorIconsRegular.deviceMobile,
      PhosphorIconsFill.deviceMobile,
    ),
    'devices': AppIcon(PhosphorIconsRegular.monitor, PhosphorIconsFill.monitor),
    'shield': AppIcon(
      PhosphorIconsRegular.shieldCheck,
      PhosphorIconsFill.shieldCheck,
    ),
    'groups': AppIcon(
      PhosphorIconsRegular.usersFour,
      PhosphorIconsFill.usersFour,
    ),
    'event_repeat': AppIcon(
      PhosphorIconsRegular.calendarCheck,
      PhosphorIconsFill.calendarCheck,
    ),
    'more_horiz': AppIcon(
      PhosphorIconsRegular.dotsThreeCircle,
      PhosphorIconsFill.dotsThreeCircle,
    ),
  };

  static AppIcon of(String? key) => byKey[key] ?? fallback;
}

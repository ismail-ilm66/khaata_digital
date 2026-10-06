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

  // Actions & chrome
  static const IconData chevronDown = PhosphorIconsBold.caretDown;
  static const IconData chevronRight = PhosphorIconsBold.caretRight;
  static const IconData back = PhosphorIconsBold.arrowLeft;
  static const IconData close = PhosphorIconsBold.x;
  static const IconData check = PhosphorIconsBold.check;
  static const IconData backspace = PhosphorIconsRegular.backspace;
  static const IconData dragHandle = PhosphorIconsBold.dotsSixVertical;
  static const IconData arrowRight = PhosphorIconsBold.arrowRight;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData filter = PhosphorIconsRegular.faders;
  static const IconData calendar = PhosphorIconsRegular.calendarBlank;
  static const IconData note = PhosphorIconsRegular.notePencil;
  static const IconData camera = PhosphorIconsRegular.camera;
  static const IconData gallery = PhosphorIconsRegular.images;
  static const IconData receipt = PhosphorIconsRegular.receipt;
  static const IconData edit = PhosphorIconsRegular.pencilSimple;
  static const IconData delete = PhosphorIconsRegular.trash;
  static const IconData archive = PhosphorIconsRegular.archive;
  static const IconData restore = PhosphorIconsRegular.arrowCounterClockwise;
  static const IconData show = PhosphorIconsRegular.eye;
  static const IconData hide = PhosphorIconsRegular.eyeSlash;
  static const IconData plus = PhosphorIconsBold.plus;
  static const IconData tag = PhosphorIconsRegular.tag;
  static const IconData transfer = PhosphorIconsBold.arrowsLeftRight;
  static const accounts = AppIcon(
    PhosphorIconsRegular.wallet,
    PhosphorIconsFill.wallet,
  );

  /// Account types → icon, for accounts without a preset monogram.
  static const Map<String, AppIcon> accountTypes = {
    'cash': AppIcon(PhosphorIconsRegular.money, PhosphorIconsFill.money),
    'bank': AppIcon(PhosphorIconsRegular.bank, PhosphorIconsFill.bank),
    'wallet': AppIcon(PhosphorIconsRegular.wallet, PhosphorIconsFill.wallet),
    'card': AppIcon(
      PhosphorIconsRegular.creditCard,
      PhosphorIconsFill.creditCard,
    ),
    'savings': AppIcon(PhosphorIconsRegular.vault, PhosphorIconsFill.vault),
  };

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

/// An arrow/chevron that points the right way in both LTR and RTL layouts.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(this.icon, {super.key, this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(
      flipX: rtl,
      child: Icon(icon, size: size, color: color),
    );
  }
}

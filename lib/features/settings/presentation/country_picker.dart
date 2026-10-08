import 'package:flutter/material.dart';

import '../../../core/region/country.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_sheet.dart';

/// The country's display name ("Other" is translated; real names stay as
/// written, like bank names).
String countryName(BuildContext context, Country c) =>
    c == Countries.other ? context.l10n.countryOther : c.name;

/// Its flag, sized for a list row or a pill.
class CountryFlag extends StatelessWidget {
  const CountryFlag(this.country, {super.key, this.size = 22});

  final Country country;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Text(country.flag, style: TextStyle(fontSize: size, height: 1.1));
}

/// A sheet of every country with its own bank list.
Future<Country?> pickCountry(BuildContext context, Country selected) =>
    pickOne<Country>(
      context,
      title: context.l10n.country,
      selected: selected,
      items: [
        for (final c in Countries.all)
          PickItem(
            value: c,
            title: countryName(context, c),
            leading: CountryFlag(c, size: 26),
          ),
      ],
    );

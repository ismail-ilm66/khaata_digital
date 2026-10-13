import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/watch.dart';
import '../domain/planned_payment.dart';
import 'to_pay_screen.dart';
import 'to_pay_widgets.dart';

/// Home: what's still to pay, soonest first, while there's anything.
class ToPayHomeSection extends StatelessWidget {
  const ToPayHomeSection({super.key});

  static const int shown = 3;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Watch<List<PlannedPayment>>(
      getIt<ToPayRepository>().watchOpen,
      builder: (context, open) {
        if (open == null || open.isEmpty) return const SizedBox.shrink();
        return ExpenseCategories(
          builder: (context, categories) => Section(
            key: const Key('homeToPay'),
            title: l.toPay,
            trailing: TextButton(
              onPressed: () => context.push(Routes.toPay),
              child: Text(open.length > shown ? l.seeAll : l.manage),
            ),
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.l,
                    AppSpacing.l,
                    AppSpacing.s,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ToPayTotal(items: open),
                  ),
                ),
                for (final item in open.take(shown))
                  ToPayRow(
                    item: item,
                    category: categories[item.categoryId],
                    onTap: () => ToPayScreen.edit(
                      context,
                      item,
                      categories.values.toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

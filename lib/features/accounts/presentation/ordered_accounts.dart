import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/ordering/by_use.dart';
import '../../../core/widgets/watch.dart';
import '../../settings/presentation/cubit/preference_cubits.dart';
import '../../transactions/domain/transactions_repository.dart';
import '../domain/account.dart';

/// [accounts] in the order chosen on the Accounts screen: most used first
/// (kept up to date as entries are added), or the user's drag order.
class OrderedAccounts extends StatelessWidget {
  const OrderedAccounts({
    super.key,
    required this.accounts,
    required this.builder,
  });

  /// In the user's own order.
  final List<AccountSummary> accounts;
  final Widget Function(BuildContext context, List<AccountSummary> ordered)
  builder;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AccountsByUseCubit>().state) {
      return builder(context, accounts);
    }
    return Watch<List<String>>(
      () => getIt<TransactionsRepository>().watchFrequentAccountIds(),
      builder: (context, used) => builder(
        context,
        sortByUse(accounts, (s) => s.account.id, used ?? const []),
      ),
    );
  }
}

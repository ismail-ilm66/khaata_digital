import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/paged_scroll_listener.dart';
import '../domain/entry_query.dart';
import 'list/entry_list.dart';
import 'list/transaction_list_bloc.dart';

/// Route argument for [EntriesScreen].
@immutable
class EntriesArgs {
  const EntriesArgs({required this.title, required this.query, this.subtitle});

  final String title;
  final String? subtitle;
  final EntryQuery query;
}

/// A titled, pre-filtered transactions list — e.g. a budget's category in
/// one cycle. Same rows and gestures as the Transactions tab.
class EntriesScreen extends StatelessWidget {
  const EntriesScreen({super.key, required this.args});

  final EntriesArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionListBloc>()..add(ListStarted(args.query)),
      child: Builder(
        builder: (context) {
          final state = context.watch<TransactionListBloc>().state;
          return PagedScrollListener(
            onNearEnd: () =>
                context.read<TransactionListBloc>().add(const MoreRequested()),
            child: PageScaffold(
              title: args.title,
              subtitle: args.subtitle,
              slivers: [
                if (state.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: AppIcons.transactions.filled,
                      title: context.l10n.noTransactions,
                      message: context.l10n.noMatchesBody,
                    ),
                  )
                else
                  EntryListSlivers(days: state.days),
              ],
            ),
          );
        },
      ),
    );
  }
}

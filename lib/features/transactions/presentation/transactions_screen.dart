import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/paged_scroll_listener.dart';
import 'form/entry_editor_screen.dart';
import 'list/entry_list.dart';
import 'list/filter_bar.dart';
import 'list/transaction_list_bloc.dart';

/// Transactions tab (spec 3.2 #4).
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionListBloc>()..add(const ListStarted()),
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionListBloc>().state;
    final l = context.l10n;
    return PagedScrollListener(
      onNearEnd: () =>
          context.read<TransactionListBloc>().add(const MoreRequested()),
      child: PageScaffold(
        title: l.navTransactions,
        trailing: IconButton.filledTonal(
          key: const Key('searchButton'),
          tooltip: l.search,
          onPressed: () => context.push(Routes.search),
          style: IconButton.styleFrom(backgroundColor: context.colors.surface),
          icon: Icon(AppIcons.search, color: context.colors.ink),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: FilterBar(
              query: state.query,
              onChanged: (q) =>
                  context.read<TransactionListBloc>().add(FiltersChanged(q)),
            ),
          ),
          if (state.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: state.query.hasFilters
                  ? EmptyState(
                      icon: AppIcons.filter,
                      title: l.noMatches,
                      message: l.noMatchesBody,
                    )
                  : EmptyState(
                      icon: AppIcons.transactions.filled,
                      title: l.noTransactions,
                      message: l.noTransactionsBody,
                      action: FilledButton(
                        onPressed: () => EntryEditor.open(context),
                        child: Text(l.addTransaction),
                      ),
                    ),
            )
          else
            EntryListSlivers(days: state.days),
          if (state.hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.l),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/paged_scroll_listener.dart';
import '../domain/entry_query.dart';
import 'list/entry_list.dart';
import 'list/transaction_list_bloc.dart';

/// Full-text search over note, amount, category, account and tags.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionListBloc>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  Timer? _debounce;
  bool _started = false;

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final bloc = context.read<TransactionListBloc>();
      if (text.trim().isEmpty) return;
      if (!_started) {
        _started = true;
        bloc.add(ListStarted(EntryQuery(search: text)));
      } else {
        bloc.add(SearchChanged(text));
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<TransactionListBloc>().state;
    return PagedScrollListener(
      onNearEnd: () =>
          context.read<TransactionListBloc>().add(const MoreRequested()),
      child: PageScaffold(
        title: l.search,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.s,
              ),
              child: TextField(
                key: const Key('searchField'),
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  prefixIcon: const Icon(AppIcons.search),
                ),
              ),
            ),
          ),
          if (!_started)
            const SliverToBoxAdapter(child: SizedBox.shrink())
          else if (state.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: AppIcons.search,
                title: l.noMatches,
                message: l.noMatchesBody,
              ),
            )
          else
            EntryListSlivers(days: state.days),
        ],
      ),
    );
  }
}

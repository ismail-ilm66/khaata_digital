import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/archived_section.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/segmented_picker.dart';
import '../../../core/widgets/tinted_badge.dart';
import '../domain/category.dart';
import '../domain/category_kind.dart';
import 'categories_cubit.dart';
import 'category_badge.dart';

/// More → Categories.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CategoriesCubit>(),
    child: const _CategoriesView(),
  );
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  Future<void> _edit(BuildContext context, [Category? existing]) async {
    final cubit = context.read<CategoriesCubit>();
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await showAppSheet<_SheetResult>(
      context,
      title: existing == null ? l.addCategory : l.editCategory,
      expand: true,
      builder: (_) => _CategorySheet(existing: existing),
    );
    switch (result) {
      case null:
        return;
      case _Archive():
        await cubit.archive(existing!);
        messenger.undo(
          message: l.categoryArchived,
          undoLabel: l.undo,
          onUndo: () => cubit.restore(existing),
        );
      case _Save(:final name, :final iconKey):
        final ok = existing == null
            ? await cubit.add(name, iconKey)
            : await cubit.edit(existing, name, iconKey);
        if (ok) {
          await Haptics.success();
          messenger.toast(l.saved);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return BlocConsumer<CategoriesCubit, CategoriesState>(
      listenWhen: (a, b) => a.duplicateId != b.duplicateId,
      listener: (context, s) {
        Haptics.warning();
        showToast(context, l.duplicateCategoryName(s.duplicate!));
      },
      builder: (context, s) {
        final cubit = context.read<CategoriesCubit>();
        return PageScaffold(
          title: l.categories,
          trailing: IconButton.filled(
            key: const Key('addCategory'),
            tooltip: l.addCategory,
            onPressed: () => _edit(context),
            icon: const Icon(AppIcons.plus),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.l,
              ),
              sliver: SliverToBoxAdapter(
                child: SegmentedPicker<CategoryKind>(
                  key: const Key('categoryKind'),
                  value: s.kind,
                  onChanged: cubit.showKind,
                  options: [
                    PickerOption(CategoryKind.expense, l.typeExpense),
                    PickerOption(CategoryKind.income, l.typeIncome),
                  ],
                ),
              ),
            ),
            if (s.active.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: AppIcons.tag,
                  message: l.noCategories,
                  action: FilledButton(
                    onPressed: () => _edit(context),
                    child: Text(l.addCategory),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                sliver: SliverReorderableList(
                  itemCount: s.active.length,
                  onReorder: cubit.reorder,
                  proxyDecorator: (child, _, _) =>
                      Material(color: Colors.transparent, child: child),
                  itemBuilder: (context, i) {
                    final cat = s.active[i];
                    return Padding(
                      key: ValueKey(cat.id),
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: Material(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(AppRadii.l),
                        child: InkWell(
                          key: Key('category-row-${cat.name}'),
                          borderRadius: BorderRadius.circular(AppRadii.l),
                          onTap: () => _edit(context, cat),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                              vertical: AppSpacing.m,
                            ),
                            child: Row(
                              children: [
                                CategoryBadge(cat, size: 36),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: context.text.titleSmall,
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: i,
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.s),
                                    child: Icon(
                                      AppIcons.dragHandle,
                                      size: 18,
                                      color: c.inkMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (s.archived.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.l,
                  AppSpacing.page,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ArchivedSection(
                    items: [
                      for (final a in s.archived)
                        ArchivedItem(
                          badge: CategoryBadge(a, size: 32),
                          name: a.name,
                          onRestore: () => cubit.restore(a),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

sealed class _SheetResult {}

class _Save extends _SheetResult {
  _Save(this.name, this.iconKey);
  final String name;
  final String? iconKey;
}

class _Archive extends _SheetResult {}

/// Name, icon grid, and (for an existing one) Archive.
class _CategorySheet extends StatefulWidget {
  const _CategorySheet({this.existing});

  final Category? existing;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late String? _icon = widget.existing?.iconKey;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('categoryNameField'),
            controller: _name,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.words,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: l.categoryName,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(l.categoryIcon, style: context.text.labelLarge),
          const SizedBox(height: AppSpacing.s),
          Expanded(
            child: GridView.count(
              crossAxisCount: 6,
              mainAxisSpacing: AppSpacing.s,
              crossAxisSpacing: AppSpacing.s,
              children: [
                for (final MapEntry(:key, :value) in AppIcons.byKey.entries)
                  InkResponse(
                    key: Key('icon-$key'),
                    onTap: () {
                      Haptics.selection();
                      setState(() => _icon = key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        // Same shape as the badge inside it.
                        borderRadius: BorderRadius.circular(AppRadii.m),
                        border: Border.all(
                          color: _icon == key ? c.brand : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: TintedBadge(icon: value.filled, size: 40),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) => FilledButton(
              key: const Key('saveCategory'),
              onPressed: _name.text.trim().isEmpty
                  ? null
                  : () =>
                        Navigator.pop(context, _Save(_name.text.trim(), _icon)),
              child: Text(l.save),
            ),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: AppSpacing.s),
            TextButton(
              key: const Key('archiveCategory'),
              onPressed: () => Navigator.pop(context, _Archive()),
              style: TextButton.styleFrom(foregroundColor: c.danger),
              child: Text(l.archive),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';
import 'app_icons.dart';
import '../feedback/haptics.dart';

/// Opens a modal bottom sheet with the app's standard chrome: drag handle,
/// optional [title], safe-area padding, and keyboard avoidance.
///
/// Sheets always open on the root navigator so they cover the floating
/// glass nav bar, whichever tab they're opened from.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  String? title,
  required WidgetBuilder builder,
  bool expand = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.m,
              ),
              child: Text(title, style: sheetContext.text.titleLarge),
            ),
          Flexible(child: builder(sheetContext)),
        ],
      );
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: expand
            ? SizedBox(height: media.size.height * 0.92, child: body)
            : ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: media.size.height * 0.85,
                ),
                child: body,
              ),
      );
    },
  );
}

/// One row in a pick sheet.
@immutable
class PickItem<T> {
  const PickItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final T value;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
}

/// A sheet listing [items]; returns the tapped value.
Future<T?> pickOne<T>(
  BuildContext context, {
  required String title,
  required List<PickItem<T>> items,
  T? selected,
}) {
  return showAppSheet<T>(
    context,
    title: title,
    builder: (context) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      children: [
        for (final item in items)
          _PickRow(
            item: item,
            selected: item.value == selected,
            onTap: () => Navigator.pop(context, item.value),
          ),
      ],
    ),
  );
}

/// A sheet with checkable [items]; returns the chosen set, or null if
/// dismissed. An empty result means "no filter".
Future<Set<T>?> pickMany<T>(
  BuildContext context, {
  required String title,
  required List<PickItem<T>> items,
  required Set<T> selected,
  required String doneLabel,
  required String clearLabel,
}) {
  return showAppSheet<Set<T>>(
    context,
    title: title,
    builder: (context) {
      var chosen = {...selected};
      return StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in items)
                    _PickRow(
                      item: item,
                      selected: chosen.contains(item.value),
                      onTap: () => setState(() {
                        chosen = chosen.contains(item.value)
                            ? ({...chosen}..remove(item.value))
                            : {...chosen, item.value};
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, <T>{}),
                    child: Text(clearLabel),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, chosen),
                      child: Text(doneLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PickRow<T> extends StatelessWidget {
  const _PickRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PickItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      selected: selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      leading: item.leading,
      title: Text(item.title, style: context.text.titleSmall),
      subtitle: item.subtitle == null ? null : Text(item.subtitle!),
      trailing:
          item.trailing ??
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: Icon(AppIcons.check, color: c.brand, size: 20),
          ),
    );
  }
}

/// A sheet with one text field and a Done button; returns the trimmed text,
/// or null if dismissed. For short inputs (a note, tags) that would
/// otherwise crowd a screen.
Future<String?> editTextSheet(
  BuildContext context, {
  required String title,
  required String initial,
  required String doneLabel,
  String? hint,
  IconData? icon,
  int maxLines = 1,
  bool secret = false,
  int minLength = 0,
}) {
  return showAppSheet<String>(
    context,
    title: title,
    builder: (_) => _TextSheet(
      initial: initial,
      doneLabel: doneLabel,
      hint: hint,
      icon: icon,
      maxLines: secret ? 1 : maxLines,
      secret: secret,
      minLength: minLength,
    ),
  );
}

class _TextSheet extends StatefulWidget {
  const _TextSheet({
    required this.initial,
    required this.doneLabel,
    required this.maxLines,
    required this.secret,
    required this.minLength,
    this.hint,
    this.icon,
  });

  final String initial;
  final String doneLabel;
  final String? hint;
  final IconData? icon;
  final int maxLines;

  /// Passphrases: hidden, never trimmed or auto-corrected.
  final bool secret;

  /// Done stays disabled until the text is at least this long.
  final int minLength;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _value =>
      widget.secret ? _controller.text : _controller.text.trim();

  bool get _valid => _value.length >= widget.minLength;

  void _done() {
    if (_valid) Navigator.pop(context, _value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('sheetTextField'),
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: widget.maxLines,
            obscureText: widget.secret,
            autocorrect: !widget.secret,
            enableSuggestions: !widget.secret,
            textCapitalization: widget.secret
                ? TextCapitalization.none
                : TextCapitalization.sentences,
            textInputAction: widget.maxLines == 1
                ? TextInputAction.done
                : TextInputAction.newline,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.icon == null ? null : Icon(widget.icon),
            ),
            onSubmitted: (_) => _done(),
          ),
          const SizedBox(height: AppSpacing.l),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => FilledButton(
              key: const Key('sheetDone'),
              onPressed: _valid ? _done : null,
              child: Text(widget.doneLabel),
            ),
          ),
        ],
      ),
    );
  }
}

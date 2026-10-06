import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/injection.dart';
import '../../../core/files/file_gateway.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_x.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/section.dart';
import '../../../core/widgets/segmented_picker.dart';
import '../../transactions/domain/entry_query.dart';
import '../domain/exporter.dart';

/// Export to Excel / CSV in Hysab Kytab's layout, then share or save.
/// With [view], offers "This view" (its filters and period) or everything.
Future<void> showExportSheet(
  BuildContext context, {
  EntryQuery? view,
  String viewLabel = '',
}) => showAppSheet<void>(
  context,
  title: context.l10n.export,
  builder: (_) => _ExportSheet(view: view, viewLabel: viewLabel),
);

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.view, required this.viewLabel});

  final EntryQuery? view;
  final String viewLabel;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  late bool _onlyView = widget.view != null;
  ExportFormat _format = ExportFormat.xlsx;
  bool _busy = false;

  Future<ExportFile> _build() => getIt<Exporter>().export(
    _onlyView ? widget.view! : const EntryQuery(),
    _format,
    label: _onlyView ? widget.viewLabel : 'All',
  );

  Future<void> _run(Future<void> Function(ExportFile file) action) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await action(await _build());
    } catch (_) {
      messenger.toast(l.exportFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(ExportFile file) async {
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, file.name);
    await File(path).writeAsBytes(file.bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: file.mime)],
        subject: file.name,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save(ExportFile file) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final saved = await getIt<FileGateway>().save(
      name: file.name,
      bytes: file.bytes,
      mime: file.mime,
    );
    if (!saved) return; // cancelled
    if (mounted) Navigator.pop(context);
    messenger.toast(l.savedFile(file.name));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
          if (widget.view != null)
            Section(
              title: l.exportScope,
              child: SegmentedPicker<bool>(
                key: const Key('exportScope'),
                value: _onlyView,
                onChanged: (v) => setState(() => _onlyView = v),
                options: [
                  PickerOption(true, l.exportView),
                  PickerOption(false, l.exportAll),
                ],
              ),
            ),
          Section(
            title: l.exportFormat,
            child: SegmentedPicker<ExportFormat>(
              key: const Key('exportFormat'),
              value: _format,
              onChanged: (f) => setState(() => _format = f),
              options: [
                PickerOption(ExportFormat.xlsx, l.formatExcel),
                PickerOption(ExportFormat.csv, l.formatCsv),
              ],
            ),
          ),
          Text(
            l.exportHint,
            style: context.text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton.icon(
            key: const Key('exportShare'),
            onPressed: _busy ? null : () => _run(_share),
            icon: const Icon(AppIcons.share, size: 18),
            label: Text(l.share),
          ),
          const SizedBox(height: AppSpacing.s),
          OutlinedButton.icon(
            key: const Key('exportSave'),
            onPressed: _busy ? null : () => _run(_save),
            icon: const Icon(AppIcons.download, size: 18),
            label: Text(l.saveToDevice),
          ),
        ],
      ),
    );
  }
}

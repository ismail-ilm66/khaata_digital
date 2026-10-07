import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/context_x.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../domain/ledger_entry.dart';
import '../../domain/transactions_repository.dart';
import '../../../../core/widgets/watch.dart';
import '../../../../core/lifecycle/system_screens.dart';

/// A receipt to show: either already stored ([attachment]) or just picked
/// and not yet saved ([path]).
@immutable
class ReceiptRef {
  const ReceiptRef.stored(Attachment this.attachment) : path = null;
  const ReceiptRef.picked(String this.path) : attachment = null;

  final Attachment? attachment;
  final String? path;
}

/// Renders a receipt from disk, resolving stored files through the
/// repository.
class ReceiptImage extends StatelessWidget {
  const ReceiptImage(this.receipt, {super.key, this.fit = BoxFit.cover});

  final ReceiptRef receipt;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = receipt.path;
    if (path != null) return Image.file(File(path), fit: fit);
    final attachment = receipt.attachment!;
    return Watch<String>(
      () => Stream.fromFuture(
        getIt<TransactionsRepository>().receiptPath(attachment),
      ),
      sourceKey: attachment.id,
      builder: (context, file) => file != null
          ? Image.file(File(file), fit: fit, gaplessPlayback: true)
          : ColoredBox(color: context.colors.surfaceMuted),
    );
  }
}

/// Full-screen, pinch-to-zoom receipt viewer.
class ReceiptViewer extends StatelessWidget {
  const ReceiptViewer({super.key, required this.receipts, this.initial = 0});

  final List<ReceiptRef> receipts;
  final int initial;

  static Future<void> open(
    BuildContext context,
    List<ReceiptRef> receipts,
    int index,
  ) => Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ReceiptViewer(receipts: receipts, initial: index),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: PageController(initialPage: initial),
            children: [
              for (final r in receipts)
                InteractiveViewer(
                  maxScale: 5,
                  child: Center(child: ReceiptImage(r, fit: BoxFit.contain)),
                ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s),
              child: IconButton.filledTonal(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(AppIcons.close),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal row of receipt thumbnails; opens the viewer on tap. With
/// [onAdd]/[onRemove] it becomes editable (the transaction form).
class ReceiptStrip extends StatelessWidget {
  const ReceiptStrip({
    super.key,
    required this.receipts,
    this.onAdd,
    this.onRemove,
  });

  final List<ReceiptRef> receipts;
  final ValueChanged<String>? onAdd;
  final ValueChanged<ReceiptRef>? onRemove;

  static const double size = 72;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(AppRadii.s);
    return SizedBox(
      height: size,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < receipts.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.s),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => ReceiptViewer.open(context, receipts, i),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: SizedBox.square(
                        dimension: size,
                        child: ReceiptImage(receipts[i]),
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    PositionedDirectional(
                      top: 2,
                      end: 2,
                      child: GestureDetector(
                        onTap: () => onRemove!(receipts[i]),
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.black54,
                          child: const Icon(
                            AppIcons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (onAdd != null)
            InkWell(
              onTap: () async {
                final path = await pickReceiptImage(context);
                if (path != null) onAdd?.call(path);
              },
              borderRadius: radius,
              child: Container(
                width: size,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: c.line, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.camera, color: c.brand),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.addReceipt,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Asks camera or gallery, then returns the picked image path (or null).
Future<String?> pickReceiptImage(BuildContext context) async {
  final source = await pickOne<ImageSource>(
    context,
    title: context.l10n.addReceipt,
    items: [
      PickItem(
        value: ImageSource.camera,
        title: context.l10n.takePhoto,
        leading: const Icon(AppIcons.camera),
        trailing: const SizedBox.shrink(),
      ),
      PickItem(
        value: ImageSource.gallery,
        title: context.l10n.chooseFromGallery,
        leading: const Icon(AppIcons.gallery),
        trailing: const SizedBox.shrink(),
      ),
    ],
  );
  if (source == null) return null;
  final file = await SystemScreens.show(
    () => ImagePicker().pickImage(source: source),
  );
  return file?.path;
}

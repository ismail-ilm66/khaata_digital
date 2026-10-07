import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_x.dart';

/// Renders the small Markdown subset our bundled documents use: `#` and
/// `##` headings, `- ` bullets, paragraphs and `**bold**`. No package, no
/// links, no HTML — the privacy policy is plain by design.
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.source, {super.key});

  final String source;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    for (final raw in source.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      if (line.startsWith('# ')) {
        blocks.add(_gap(AppSpacing.l));
        blocks.add(Text(line.substring(2), style: context.text.headlineSmall));
      } else if (line.startsWith('## ')) {
        blocks.add(_gap(AppSpacing.xl));
        blocks.add(Text(line.substring(3), style: context.text.titleMedium));
      } else if (line.startsWith('- ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: context.text.bodyMedium),
                Expanded(child: _rich(context, line.substring(2))),
              ],
            ),
          ),
        );
      } else {
        blocks.add(_gap(AppSpacing.s));
        blocks.add(_rich(context, line));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  static Widget _gap(double h) => SizedBox(height: h);

  /// `**bold**` spans inside a line.
  static Widget _rich(BuildContext context, String line) {
    final style = context.text.bodyMedium!;
    final spans = <TextSpan>[];
    final parts = line.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null,
        ),
      );
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }
}

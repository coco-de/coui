import 'package:coui_flutter/coui_flutter.dart';
import 'package:markdown/markdown.dart' as md;

import 'native_docs_document.dart';
import 'native_inline_renderer.dart';

Widget buildNativeDocsParagraph(
  BuildContext context,
  List<md.Node> children,
  DocsInternalLinkCallback? onInternalLink,
) {
  return DocsRichText(
    nodes: children,
    onInternalLink: onInternalLink,
  ).bodyMedium.onSurface;
}

List<Widget> withNativeDocsBlockSpacing(List<Widget> blocks) => [
  for (final (index, block) in blocks.indexed)
    if (index == 0)
      block
    else
      Padding(
        padding: const .only(top: CoreSpace.space16),
        child: block,
      ),
];

/// The same block column used by the application's DocsMarkdown renderer.
Widget buildNativeDocsBlockColumn(List<Widget> blocks) => Column(
  crossAxisAlignment: .start,
  children: blocks,
);

/// Uses the original Native document parser, paragraph and inline renderer.
/// Other blocks must gain a shared real renderer before this scene supports them.
class FlutterDocsParagraphBody extends StatelessWidget {
  const FlutterDocsParagraphBody({required this.markdown, this.onInternalLink, super.key});

  final String markdown;
  final DocsInternalLinkCallback? onInternalLink;

  @override
  Widget build(BuildContext context) {
    final nodes = parseDocsMarkdownNodes(markdown);
    final blocks = <Widget>[];
    for (final node in nodes) {
      if (node is! md.Element || node.tag != 'p') {
        throw UnsupportedError(
          'Native Card scene body requires a shared renderer for ${node is md.Element ? node.tag : node.runtimeType}',
        );
      }
      blocks.add(buildNativeDocsParagraph(context, node.children ?? const <md.Node>[], onInternalLink));
    }
    return buildNativeDocsBlockColumn(withNativeDocsBlockSpacing(blocks));
  }
}

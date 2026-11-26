import 'package:jaspr_content/jaspr_content.dart';

/// Points a body link that names only a heading (`#id`) at the page it is on.
///
/// The document sets `<base href="/">`, so a bare `#id` resolves against the
/// site root and opens the home page. Authors write the bare form — it is what
/// markdown means by a link within the page — and this gives it the page's
/// path, the form the table of contents and the heading anchors already use.
class DocsFragmentLinksExtension implements PageExtension {
  const DocsFragmentLinksExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async => [
    for (final node in nodes) _anchor(page.url, node),
  ];

  Node _anchor(String path, Node node) {
    if (node is! ElementNode) return node;
    final href = node.tag == 'a' ? node.attributes['href'] : null;
    return ElementNode(
      node.tag,
      href != null && href.startsWith('#') ? {...node.attributes, 'href': '$path$href'} : node.attributes,
      node.children?.map((child) => _anchor(path, child)).toList(),
    );
  }
}

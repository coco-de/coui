import 'package:docs_site/components/docs_fragment_links.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:test/test.dart';

void main() {
  final page = Page(
    path: 'components/card.md',
    url: '/components/card',
    content: '',
    config: const PageConfig(),
    loader: MemoryLoader(pages: const []),
  );

  Future<List<String?>> hrefs(List<Node> nodes) async {
    final result = await const DocsFragmentLinksExtension().apply(page, nodes);
    Iterable<String?> walk(Node node) sync* {
      if (node is! ElementNode) return;
      if (node.tag == 'a') yield node.attributes['href'];
      for (final child in node.children ?? const <Node>[]) {
        yield* walk(child);
      }
    }

    return [for (final node in result) ...walk(node)];
  }

  test(
    'a heading-only link gets the page path, however deep it sits',
    () async {
      expect(
        await hrefs([
          ElementNode('p', const {}, [
            ElementNode('a', const {'href': '#알려진-제약'}, [TextNode('제약')]),
          ]),
          ElementNode('Callout', const {}, [
            ElementNode('table', const {}, [
              ElementNode('a', const {'href': '#api'}, const []),
            ]),
          ]),
        ]),
        ['/components/card#알려진-제약', '/components/card#api'],
      );
    },
  );

  test('every other link is left as written', () async {
    const written = [
      '/components/button#api',
      'button.md',
      'https://example.com/#a',
    ];
    expect(
      await hrefs([
        for (final href in written) ElementNode('a', {'href': href}, const []),
        ElementNode('a', const {'id': 'old-anchor'}, const []),
      ]),
      [...written, null],
    );
  });
}

@TestOn('vm')
library;

import 'package:docs_site/layouts/manual_layout.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:test/test.dart';

Page page({String title = '테마', String? layout, String url = '/guides/theming'}) => Page(
  path: 'guides/theming.md',
  url: url,
  content: '',
  initialData: {
    'page': {'title': title, 'layout': ?layout},
  },
  config: const PageConfig(),
  loader: MemoryLoader(pages: []),
);

void main() {
  const extension = ManualTitleExtension();

  test('one visible title retains the original Korean fragment', () async {
    final doc = page();
    final title = ElementNode('h1', {'id': '테마'}, [TextNode('테마')]);
    final section = ElementNode('h2', {'id': 'flutter-테마'}, [TextNode('Flutter 테마')]);
    final nodes = [title, section];
    final result = await extension.apply(doc, nodes);
    expect(result, [section]);
    expect(doc.data['docsTitleId'], '테마');
    expect(nodes, [title, section], reason: 'do not mutate shared Markdown nodes');
  });

  test('a different heading is still content', () async {
    final nodes = [
      ElementNode('h1', {}, [TextNode('다른 제목')]),
    ];
    expect(await extension.apply(page(), nodes), nodes);
  });

  test('landing and pages without a leading title remain intact', () async {
    final nodes = [
      ElementNode('h1', {}, [TextNode('테마')]),
    ];
    expect(await extension.apply(page(layout: 'landing'), nodes), nodes);
    final body = [
      ElementNode('p', {}, [TextNode('본문')]),
      ...nodes,
    ];
    expect(await extension.apply(page(), body), body);
    expect(await extension.apply(page(), []), isEmpty);
  });
  test('basic usage moves before the gallery without losing fragments or content', () async {
    final preview = ElementNode('h2', {'id': 'live-preview'}, [TextNode('Live Preview')]);
    final usage = ElementNode('h2', {'id': '기본-사용법'}, [TextNode('기본 사용법 (Basic Usage)')]);
    final api = ElementNode('h2', {'id': 'props'}, [TextNode('Props / Parameters')]);
    final example = ElementNode('p', {}, [TextNode('runnable example')]);
    final nodes = [preview, ElementNode('LivePreview', {}, []), usage, example, api];
    final result = await const ManualReadingOrderExtension().apply(page(url: '/components/button'), nodes);
    expect(result, [usage, example, preview, nodes[1], api]);
    expect((result.first as ElementNode).attributes['id'], '기본-사용법');
    expect(nodes.first, preview, reason: 'shared content nodes must not be reordered in place');
    expect(await const ManualReadingOrderExtension().apply(page(), nodes), nodes);
  });
}

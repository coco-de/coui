// Pins the Web `RichEditor`'s Markdown codec — the part of the editor that
// runs without a browser. Markdown parses into the editor's document, the
// document renders as the editing surface's markup, and the document a
// browser leaves in the surface serialises back to Markdown.

import 'package:coui_web/src/components/form/rich_editor/rich_editor_markdown.dart';
import 'package:test/test.dart';

/// Markdown → document → Markdown.
String _roundTrip(String markdown) =>
    serializeRichEditorMarkdown(parseRichEditorMarkdown(markdown));

RichEditorNode _el(String tag, [List<RichEditorNode> children = const []]) =>
    RichEditorNode(tag, children: children);

RichEditorNode _t(String text) => RichEditorNode.text(text);

void main() {
  group('round trip — Markdown the editor writes reads back unchanged', () {
    const cases = <String, String>{
      'inline marks': '**bold**, *italic*, ~~gone~~ and `code`',
      'a link': 'see [the docs](https://example.com/docs) now',
      'a bare link': 'visit https://example.com',
      'headings': '# One\n\n## Two\n\n### Three',
      'a bulleted list': '- one\n- two\n  - nested',
      'a numbered list': '1. one\n2. two',
      'a list from 3': '3. three\n4. four',
      'a task list': '- [ ] open\n- [x] done',
      'a quote': '> quoted *text*',
      'a rule': 'above\n\n---\n\nbelow',
      'a code block': '```dart\nfinal x = 1;\n```',
      'a hard break':
          r'line one\'
          '\nline two',
      'escaped specials': r'2 \* 3 \_not\_ \[x\] \`y\`',
      'a line that looks like a heading': r'\# not a heading',
      'a line that looks like a list': r'\- not a list',
      'nested marks': '***both*** and **bold *and italic***',
      'an image': '![a cat](https://x.test/cat.png)',
      'an image between paragraphs':
          'before\n\n![a cat](https://x.test/cat.png)\n\nafter',
      'two images in a row':
          '![one](https://x.test/1.png)\n\n![two](https://x.test/2.png)',
      'an image in a sentence': 'see ![icon](/icon.png) here',
      'an image in a list item': '- ![icon](/icon.png) first\n- second',
      "a path on the page's own server": '![local](/uploads/a.png)',
      'a data image': '![dot](data:image/png;base64,iVBORw0KGgo=)',
      'an image with no label': '![](https://x.test/cat.png)',
      'an image with brackets in its label': r'![a \[b\] c](/a.png)',
      'an image with an encoded parenthesis':
          '![x](https://x.test/a_%281%29.png)',
    };
    cases.forEach((name, markdown) {
      test(name, () => expect(_roundTrip(markdown), markdown));
    });
  });

  group('parse — the document the surface shows', () {
    test('a task item carries its checkbox first, then its text', () {
      final nodes = parseRichEditorMarkdown('- [x] done');
      final item = nodes.single.children.single;
      expect(item.tag, 'li');
      expect(item.children.first.tag, 'input');
      expect(item.children.first.attributes.containsKey('checked'), isTrue);
      expect(item.children.last.text, 'done');
    });

    test('an unsafe link keeps its text and loses the link', () {
      final nodes = parseRichEditorMarkdown('[click](javascript:alert(1))');
      final html = renderRichEditorHtml(nodes);
      expect(html, isNot(contains('href')));
      expect(html, contains('click'));
    });

    test('a bare domain link is normalised to https', () {
      final nodes = parseRichEditorMarkdown('[site](example.com)');
      expect(
        renderRichEditorHtml(nodes),
        contains('href="https://example.com"'),
      );
    });

    test('raw HTML is shown as text, never injected', () {
      final html = renderRichEditorHtml(
        parseRichEditorMarkdown('<script>alert(1)</script>\n\nhi <b>x</b>'),
      );
      expect(html, isNot(contains('<script')));
      expect(html, isNot(contains('<b>')));
      expect(html, contains('&lt;script&gt;'));
    });

    test('an image stays an image, alone in its paragraph', () {
      final nodes = parseRichEditorMarkdown('![a cat](https://x.com/c.png)');
      expect(nodes.single.tag, 'p');
      final image = nodes.single.children.single;
      expect(image.tag, 'img');
      expect(image.attributes, {'src': 'https://x.com/c.png', 'alt': 'a cat'});
      expect(
        renderRichEditorHtml(nodes),
        '<p><img src="https://x.com/c.png" alt="a cat"></p>',
      );
    });

    test('an image in a sentence stays on its line', () {
      final html = renderRichEditorHtml(
        parseRichEditorMarkdown('see ![i](/i.png) here'),
      );
      expect(html, '<p>see <img src="/i.png" alt="i"> here</p>');
    });

    test('a data image is shown, an SVG one is its alt text', () {
      expect(
        renderRichEditorHtml(
          parseRichEditorMarkdown('![d](data:image/png;base64,iVBORw0KGgo=)'),
        ),
        '<p><img src="data:image/png;base64,iVBORw0KGgo=" alt="d"></p>',
      );
      expect(
        renderRichEditorHtml(
          parseRichEditorMarkdown('![d](data:image/svg+xml;base64,PHN2Zz4=)'),
        ),
        '<p>d</p>',
      );
    });

    test('an unsafe image address leaves its alt text, no element', () {
      for (final bad in const [
        'javascript:alert(1)',
        'file:///etc/passwd',
        'vbscript:x',
      ]) {
        final html = renderRichEditorHtml(
          parseRichEditorMarkdown('![a cat]($bad)'),
        );
        expect(html, '<p>a cat</p>', reason: bad);
      }
    });

    test('an unsafe image with no alt text leaves nothing', () {
      final nodes = parseRichEditorMarkdown('![](javascript:alert(1))');
      expect(renderRichEditorHtml(nodes), '<p></p>');
      expect(serializeRichEditorMarkdown(nodes), '');
    });

    test('a reference image resolves to its address', () {
      final html = renderRichEditorHtml(
        parseRichEditorMarkdown('![ref][r]\n\n[r]: https://x.com/r.png'),
      );
      expect(html, contains('<img src="https://x.com/r.png" alt="ref">'));
    });

    test('a soft line break reads as a space', () {
      final nodes = parseRichEditorMarkdown('one\ntwo');
      expect(renderRichEditorHtml(nodes), '<p>one two</p>');
    });

    test('empty Markdown is an empty document', () {
      expect(parseRichEditorMarkdown('  \n '), isEmpty);
      expect(serializeRichEditorMarkdown(const []), '');
    });
  });

  group('render — the editing surface markup', () {
    test("an image's label is escaped in its attribute", () {
      final html = renderRichEditorHtml([
        _el('p', [
          const RichEditorNode(
            'img',
            attributes: {'src': 'https://x.test/a.png', 'alt': 'say "hi" <b>'},
          ),
        ]),
      ]);
      expect(
        html,
        '<p><img src="https://x.test/a.png" '
        'alt="say &quot;hi&quot; &lt;b&gt;"></p>',
      );
    });

    test('an image whose address is unsafe is not written, only its label', () {
      final html = renderRichEditorHtml([
        _el('p', [
          const RichEditorNode(
            'img',
            attributes: {'src': 'javascript:alert(1)', 'alt': 'a cat'},
          ),
          const RichEditorNode(
            'img',
            attributes: {'src': 'https://x.test/"onerror="x', 'alt': 'b'},
          ),
        ]),
      ]);
      expect(html, '<p>a catb</p>');
      expect(html, isNot(contains('<img')));
    });

    test('a task checkbox is not editable text and takes no tab stop', () {
      final html = renderRichEditorHtml(parseRichEditorMarkdown('- [ ] a'));
      expect(
        html,
        '<ul><li><input type="checkbox" contenteditable="false" '
        'tabindex="-1">a</li></ul>',
      );
    });

    test('text and attributes are escaped', () {
      final html = renderRichEditorHtml([
        _el('p', [
          _t('a < b & "c"'),
          RichEditorNode(
            'a',
            attributes: const {'href': 'https://x.com/?a="b"'},
            children: [_t('x')],
          ),
        ]),
      ]);
      expect(html, contains('a &lt; b &amp; &quot;c&quot;'));
      expect(html, contains('href="https://x.com/?a=&quot;b&quot;"'));
    });
  });

  group('serialise — normalising what a browser writes', () {
    test('div lines are paragraphs', () {
      final markdown = serializeRichEditorMarkdown([
        _el('div', [_t('one')]),
        _el('div', [_t('two')]),
      ]);
      expect(markdown, 'one\n\ntwo');
    });

    test('loose text at the top level is a paragraph', () {
      final markdown = serializeRichEditorMarkdown([
        _t('typed '),
        _el('b', [_t('straight')]),
        _t(' in'),
        _el('p', [_t('next')]),
      ]);
      expect(markdown, 'typed **straight** in\n\nnext');
    });

    test('b / i / strike are strong / emphasis / strikethrough', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          _el('b', [_t('b')]),
          _t(' '),
          _el('i', [_t('i')]),
          _t(' '),
          _el('strike', [_t('s')]),
        ]),
      ]);
      expect(markdown, '**b** *i* ~~s~~');
    });

    test('styling spans are unwrapped', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          _el('span', [
            _el('span', [_t('plain')]),
          ]),
        ]),
      ]);
      expect(markdown, 'plain');
    });

    test('adjacent marks of one kind join into one', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          _el('b', [_t('ab')]),
          _el('strong', [_t('cd')]),
        ]),
      ]);
      expect(markdown, '**abcd**');
    });

    test('a mark keeps its outer spaces outside the markers', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          _t('a'),
          _el('b', [_t(' bold ')]),
          _t('b'),
        ]),
      ]);
      expect(markdown, 'a **bold** b');
    });

    test('an empty mark writes nothing', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          _t('a'),
          _el('b', [_t('​')]),
        ]),
      ]);
      expect(markdown, 'a');
    });

    test('caret holders and non-breaking spaces are not part of the value', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          _el('code', [_t('x')]),
          _t('​ after'),
        ]),
      ]);
      expect(markdown, '`x` after');
    });

    test('a trailing br placeholder and empty lines are dropped', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [_t('text'), _el('br')]),
        _el('p', [_el('br')]),
        _el('div', [_el('br')]),
      ]);
      expect(markdown, 'text');
    });

    test('a pasted list inside a div keeps its blocks', () {
      final markdown = serializeRichEditorMarkdown([
        _el('div', [
          _el('ul', [
            _el('li', [_t('a')]),
            _el('li', [_t('b')]),
          ]),
        ]),
      ]);
      expect(markdown, '- a\n- b');
    });

    test('a checked task reads from the checkbox', () {
      final markdown = serializeRichEditorMarkdown([
        _el('ul', [
          _el('li', [
            const RichEditorNode(
              'input',
              attributes: {'type': 'checkbox', 'checked': ''},
            ),
            _t('done'),
          ]),
          _el('li', [
            const RichEditorNode('input', attributes: {'type': 'checkbox'}),
            _t('open'),
          ]),
        ]),
      ]);
      expect(markdown, '- [x] done\n- [ ] open');
    });

    test('an unsafe href is dropped on the way out too', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          RichEditorNode(
            'a',
            attributes: const {'href': 'javascript:alert(1)'},
            children: [_t('x')],
          ),
        ]),
      ]);
      expect(markdown, 'x');
    });

    test("a paragraph that is only an image is that image's line", () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [_t('before')]),
        _el('p', [
          const RichEditorNode(
            'img',
            attributes: {'src': 'https://x.test/a.png', 'alt': 'a'},
          ),
          _el('br'),
        ]),
        _el('div', [_t('after')]),
      ]);
      expect(markdown, 'before\n\n![a](https://x.test/a.png)\n\nafter');
    });

    test('an image the browser left in the surface keeps a relative path', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          const RichEditorNode(
            'img',
            attributes: {'src': '/uploads/a.png', 'alt': 'a'},
          ),
        ]),
      ]);
      expect(markdown, '![a](/uploads/a.png)');
    });

    test('an image with an unsafe address is dropped on the way out', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          _t('a'),
          const RichEditorNode(
            'img',
            attributes: {'src': 'javascript:alert(1)', 'alt': 'x'},
          ),
          _t('b'),
        ]),
        _el('p', [
          const RichEditorNode(
            'img',
            attributes: {'src': 'file:///etc/passwd', 'alt': 'y'},
          ),
        ]),
        _el('p', [const RichEditorNode('img')]),
      ]);
      expect(markdown, 'ab');
    });

    test(
      "an image's label loses the caret holder and non-breaking spaces",
      () {
        final markdown = serializeRichEditorMarkdown([
          _el('p', [
            const RichEditorNode(
              'img',
              attributes: {'src': '/a.png', 'alt': 'a\u200b\u00a0b'},
            ),
          ]),
        ]);
        expect(markdown, '![a b](/a.png)');
      },
    );

    test('a raw parenthesis in the address is written out', () {
      final markdown = serializeRichEditorMarkdown(
        parseRichEditorMarkdown('![x](https://x.test/a_(1).png)'),
      );
      expect(markdown, '![x](https://x.test/a_%281%29.png)');
    });

    test('images on neighbouring lines share one paragraph', () {
      final markdown = _roundTrip('![a](/a.png)\n![b](/b.png)');
      expect(markdown, '![a](/a.png) ![b](/b.png)');
    });

    test('a title is not kept', () {
      expect(
        _roundTrip('![a](https://x.test/a.png "A title")'),
        '![a](https://x.test/a.png)',
      );
    });

    test('code holding backticks gets a longer fence', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          _el('code', [_t('a`b')]),
        ]),
      ]);
      expect(markdown, '``a`b``');
      expect(_roundTrip(markdown), markdown);
    });

    test('a link target with parentheses stays one target', () {
      final markdown = serializeRichEditorMarkdown([
        _el('p', [
          RichEditorNode(
            'a',
            attributes: const {'href': 'https://x.com/a_(b)'},
            children: [_t('wiki')],
          ),
        ]),
      ]);
      expect(markdown, '[wiki](https://x.com/a_%28b%29)');
    });
  });

  group('richEditorImageUrls', () {
    test('collects every image the document shows, wherever it is', () {
      final urls = richEditorImageUrls(
        parseRichEditorMarkdown(
          '![a](https://x.test/a.png)\n\n'
          '> ![b](https://x.test/b.png)\n\n'
          '- item ![c](/c.png)\n\n'
          'text ![a again](https://x.test/a.png)',
        ),
      );
      expect(urls, {
        'https://x.test/a.png',
        'https://x.test/b.png',
        '/c.png',
      });
    });

    test('skips an image the editor would not show', () {
      final urls = richEditorImageUrls([
        _el('p', [
          const RichEditorNode(
            'img',
            attributes: {'src': 'javascript:alert(1)', 'alt': 'x'},
          ),
          const RichEditorNode('img'),
          const RichEditorNode(
            'img',
            attributes: {'src': 'https://x.test/ok.png', 'alt': 'ok'},
          ),
        ]),
      ]);
      expect(urls, {'https://x.test/ok.png'});
    });

    test('an empty document has none', () {
      expect(richEditorImageUrls(const []), isEmpty);
    });
  });
}

@TestOn('vm')
library;

import 'package:coui_web/coui_web.dart' show CoUIWeb, ThemeData;
import 'package:docs_site/components/docs_blocks.dart';
import 'package:docs_site/components/docs_code.dart';
import 'package:docs_site/components/safe_code_block.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_test/server_test.dart';

/// 본문의 블록(코드 · 카드 묶음 · 단계 · 표)이 **서버 렌더에서** 무엇을
/// 내는지 본다.
///
/// 이 블록들은 정적으로 생성되는 본문 안에 있어 브라우저에서 깨어나지
/// 않는다. 그래서 동작(복사 · 등장)은 정적 스크립트가 마크업의 표시를
/// 읽어서 한다 — 표시가 빠지면 블록은 **에러 없이** 그려지고 버튼만 아무
/// 일도 하지 않는다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  /// 마크다운이 낸 노드를 사이트가 등록한 컴포넌트로 그린다.
  Component render(List<Node> nodes) => CoUIWeb(
    theme: ThemeData.coui,
    child: NodesBuilder([DocsBlocks(), SafeCodeBlock()]).build(nodes),
  );

  /// 코드 펜스가 파서에서 나오는 모양.
  Node fence(String source, {String? language}) => ElementNode('pre', const {}, [
    ElementNode('code', {'class': ?language == null ? null : 'language-$language'}, [TextNode(source)]),
  ]);

  group('코드', () {
    testServer('이름표와 복사 버튼, 그 아래 코드', (tester) async {
      tester.pumpComponent(render([fence("final answer = 42;\n", language: 'dart')]));
      final document = (await tester.request('/')).document!;

      final block = document.querySelector('figure.docs-code')!;
      expect(block.attributes.containsKey('data-docs-code'), isTrue);
      expect(block.attributes['data-language'], 'dart');
      expect(block.querySelector('.docs-code-label')!.text.trim(), 'Dart');
      // 본문의 산문 규칙이 이 안을 다시 꾸미지 않는다.
      expect(block.classes, contains('not-content'));
      expect(block.querySelector('code')!.text, 'final answer = 42;');
    });

    testServer('복사 버튼은 켜져 있고, 스크립트가 읽을 표시와 문구를 갖는다', (tester) async {
      tester.pumpComponent(render([fence('flutter pub get\n', language: 'bash')]));
      final document = (await tester.request('/')).document!;

      final button = document.querySelector('[data-docs-copy]')!;
      expect(button.localName, 'button');
      // 서버의 핸들러가 없는 버튼을 킷은 끈 채로 그린다 — 꺼진 버튼은 정적
      // 스크립트에 눌림을 보내지 않는다.
      expect(button.attributes.containsKey('disabled'), isFalse);
      expect(button.attributes['data-copy-label'], kDocsCopyLabel);
      expect(button.attributes['data-copied-label'], kDocsCopiedLabel);
      expect(button.attributes['data-failed-label'], kDocsCopyFailedLabel);
      expect(button.attributes['aria-label'], contains('Terminal'));

      final label = button.querySelector('[data-copy-label]')!;
      expect(label.text.trim(), kDocsCopyLabel);
      expect(label.attributes['aria-live'], 'polite');
      // 킷 자신의 복사 버튼은 나가지 않는다 — 깨어나야 동작하는 버튼이다.
      expect(document.querySelectorAll('figure.docs-code button'), hasLength(1));
    });

    testServer('Dart 는 킷의 구문 색으로 칠한다', (tester) async {
      tester.pumpComponent(render([fence("final answer = 42;\n", language: 'dart')]));
      final document = (await tester.request('/')).document!;

      final colors = document
          .querySelectorAll('figure.docs-code code span[style]')
          .map((span) => span.attributes['style']!)
          .toList();
      expect(colors, isNotEmpty);
      // 색은 리터럴이 아니라 킷의 변수다 — 밝기를 바꾸면 코드도 바뀐다.
      for (final style in colors) {
        expect(style, matches(RegExp(r'color:\s*rgb\(var\(--coui-[a-z-]+\)\)')));
      }
      expect(colors.join(), contains('--coui-syntax-keyword'));
    });

    for (final language in const ['bash', 'html', 'text']) {
      testServer('$language 는 다른 언어의 문법으로 칠하지 않는다', (tester) async {
        // 킷이 문법을 갖지 않은 언어다. Dart 문법은 URL 의 `//` 를 주석으로
        // 읽는다 — 빌려 칠하면 덜 칠해지는 것이 아니라 틀리게 칠해진다.
        const source = 'url: https://github.com/coco-de/coui.git';
        tester.pumpComponent(render([fence('$source\n', language: language)]));
        final document = (await tester.request('/')).document!;

        final code = document.querySelector('figure.docs-code code')!;
        expect(code.text, source);
        expect(code.querySelectorAll('span[style*="color"]'), isEmpty);
      });
    }

    testServer('yaml 은 자기 문법으로 칠한다 — URL 의 `//` 는 값이다', (tester) async {
      const source = 'url: https://github.com/coco-de/coui.git';
      tester.pumpComponent(render([fence('$source\n', language: 'yaml')]));
      final document = (await tester.request('/')).document!;

      final code = document.querySelector('figure.docs-code code')!;
      expect(code.text, source);
      final painted = {
        for (final span in code.querySelectorAll('span[style*="color"]')) span.text: span.attributes['style']!,
      };
      // 키가 칠해지고, `//…` 는 어느 색에도 들지 않는다.
      expect(painted['url'], contains('--coui-syntax-function'));
      expect(painted.keys.where((text) => text.contains('//')), isEmpty);
    });

    testServer('json 은 자기 문법으로 칠한다', (tester) async {
      const source = '{"name": "coui", "private": true}';
      tester.pumpComponent(render([fence('$source\n', language: 'json')]));
      final document = (await tester.request('/')).document!;

      final code = document.querySelector('figure.docs-code code')!;
      expect(code.text, source);
      // 한 색의 글자를 이어 읽는다 — 따옴표와 그 안의 글자가 따로 나올 수 있다.
      String paintedIn(String variable) => [
        for (final span in code.querySelectorAll('span[style*="$variable"]')) span.text,
      ].join();
      expect(paintedIn('--coui-syntax-function'), '"name""private"');
      expect(paintedIn('--coui-syntax-string'), '"coui"');
      expect(paintedIn('--coui-syntax-keyword'), 'true');
    });

    test('이름표는 코드를 어디에 넣는지 말한다', () {
      expect(docsCodeLabel('dart'), 'Dart');
      expect(docsCodeLabel('yaml'), 'YAML');
      expect(docsCodeLabel('yml'), 'YAML');
      expect(docsCodeLabel('bash'), 'Terminal');
      expect(docsCodeLabel('sh'), 'Terminal');
      // 언어를 적지 않은 펜스와 `text` 는 이름표가 없다.
      expect(docsCodeLabel(null), isNull);
      expect(docsCodeLabel('text'), isNull);
      // 모르는 언어는 적힌 그대로.
      expect(docsCodeLabel('kotlin'), 'kotlin');
    });

    testServer('언어를 적지 않은 펜스는 이름표 없이, 한 색으로 그린다', (tester) async {
      tester.pumpComponent(render([fence('a → b\n')]));
      final document = (await tester.request('/')).document!;

      expect(document.querySelector('.docs-code-label'), isNull);
      expect(document.querySelector('[data-docs-copy]')!.attributes['aria-label'], '코드 복사');
      expect(document.querySelectorAll('figure.docs-code code span[style*="color"]'), isEmpty);
    });

    testServer('태그로 쓰면 이름표를 직접 정한다', (tester) async {
      tester.pumpComponent(
        render([
          ElementNode('Code', const {'language': 'dart', 'title': 'main.dart'}, [const TextNode('void main() {}')]),
        ]),
      );
      final document = (await tester.request('/')).document!;

      expect(document.querySelector('.docs-code-label')!.text.trim(), 'main.dart');
    });
  });

  group('카드 묶음', () {
    Node cards(Map<String, String> attributes, List<Map<String, String>> items) => ElementNode('Cards', attributes, [
      for (final item in items) ...[
        const TextNode('\n'),
        ElementNode('Card', item, [
          const ElementNode('p', {}, [TextNode('본문')]),
        ]),
      ],
    ]);

    testServer('카드마다 순번을 갖고, 묶음은 등장의 표시를 갖는다', (tester) async {
      tester.pumpComponent(
        render([
          cards(
            const {'columns': '3'},
            const [
              {'eyebrow': '01', 'title': '하나'},
              {'eyebrow': '02', 'title': '둘'},
              {'eyebrow': '03', 'title': '셋'},
            ],
          ),
        ]),
      );
      final document = (await tester.request('/')).document!;

      final group = document.querySelector('.docs-cards')!;
      expect(group.attributes.containsKey('data-docs-reveal'), isTrue);
      expect(group.attributes['style'], contains('--docs-cards-columns: 3'));
      expect(group.classes, contains('not-content'));

      final items = group.querySelectorAll('.docs-card');
      expect(items, hasLength(3));
      expect(items.map((card) => card.attributes['style']), ['--i: 0', '--i: 1', '--i: 2']);
      expect(items.first.querySelector('.docs-card-eyebrow')!.text.trim(), '01');
      expect(items.first.querySelector('.docs-card-body')!.text.trim(), '본문');
    });

    testServer('링크가 있으면 카드 전체가 링크다', (tester) async {
      tester.pumpComponent(
        render([
          cards(const {}, const [
            {'title': '빠른 시작', 'href': '/getting-started', 'more': '빠른 시작'},
            {'title': '링크 없음'},
          ]),
        ]),
      );
      final document = (await tester.request('/')).document!;
      final items = document.querySelectorAll('.docs-card');

      expect(items.first.localName, 'a');
      expect(items.first.attributes['href'], '/getting-started');
      expect(items.first.querySelector('.docs-card-more')!.text, '빠른 시작');
      // 문서 페이지의 카드는 밑줄 글자가 링크를 말한다 — 화살표를 덧붙이지
      // 않는다(Figma 개요의 다음 단계 카드). 화살표는 미리보기 카드만 단다.
      expect(items.first.querySelector('.site-arrow'), isNull);
      expect(items.last.localName, 'div');
      expect(items.last.querySelector('.docs-card-more'), isNull);
    });

    testServer('열 수는 적지 않으면 카드 수, 그리고 상한을 넘지 않는다', (tester) async {
      tester.pumpComponent(
        render([
          cards(const {}, const [
            {'title': 'a'},
            {'title': 'b'},
          ]),
          cards(
            const {'columns': '9'},
            const [
              {'title': 'a'},
            ],
          ),
        ]),
      );
      final document = (await tester.request('/')).document!;
      final groups = document.querySelectorAll('.docs-cards');

      expect(groups.first.attributes['style'], contains('--docs-cards-columns: 2'));
      expect(groups.last.attributes['style'], contains('--docs-cards-columns: $kDocsCardsMaxColumns'));
    });

    testServer('권장 · 금지는 색만이 아니라 글자로 말한다', (tester) async {
      tester.pumpComponent(
        render([
          cards(
            const {'columns': '2'},
            const [
              {'eyebrow': '권장', 'title': '토큰으로', 'tone': 'do'},
              {'eyebrow': '금지', 'title': '리터럴로', 'tone': 'dont'},
            ],
          ),
        ]),
      );
      final document = (await tester.request('/')).document!;

      expect(document.querySelector('.docs-card--do .docs-card-eyebrow')!.text.trim(), '권장');
      expect(document.querySelector('.docs-card--dont .docs-card-eyebrow')!.text.trim(), '금지');
      // 종류를 말하는 이름표는 본문 서체다 — 고정폭은 순번 같은 짧은 표시의 것이다.
      expect(document.querySelector('.docs-card--do .docs-card-eyebrow .text-code-sm'), isNull);
    });

    testServer('모양은 묶음이 정하고 카드가 덮을 수 있다 — 모르는 이름은 면 카드다', (tester) async {
      tester.pumpComponent(
        render([
          cards(const {}, const [
            {'title': '기본'},
          ]),
          cards(
            const {'variant': 'outlined'},
            const [
              {'title': '선'},
              {'title': '면', 'variant': 'filled'},
            ],
          ),
          cards(
            const {'variant': 'outline'},
            const [
              {'title': '오타'},
            ],
          ),
        ]),
      );
      final document = (await tester.request('/')).document!;

      String shape(String title) => document
          .querySelectorAll('.docs-card')
          .firstWhere((card) => card.querySelector('.docs-card-head')!.text.trim() == title)
          .classes
          .firstWhere((name) => name == 'docs-card--filled' || name == 'docs-card--outlined');

      expect(kDocsCardDefaultVariant, 'filled');
      expect(kDocsCardVariants, {'filled', 'outlined'});
      expect(shape('기본'), 'docs-card--filled');
      expect(shape('선'), 'docs-card--outlined');
      expect(shape('면'), 'docs-card--filled');
      expect(shape('오타'), 'docs-card--filled');
    });

    testServer('제목의 역할은 모양이 정한다 — 면 카드는 한 단 크다', (tester) async {
      tester.pumpComponent(
        render([
          cards(const {}, const [
            {'eyebrow': '01', 'title': '면'},
          ]),
          cards(
            const {'variant': 'outlined'},
            const [
              {'title': '선'},
            ],
          ),
        ]),
      );
      final document = (await tester.request('/')).document!;

      final filled = document.querySelector('.docs-card--filled')!;
      final outlined = document.querySelector('.docs-card--outlined')!;
      expect(filled.querySelector('.docs-card-head .text-title-medium'), isNotNull);
      expect(outlined.querySelector('.docs-card-head .text-label-xl'), isNotNull);
      // 순번은 고정폭 글자다.
      expect(filled.querySelector('.docs-card-eyebrow .text-code-sm'), isNotNull);
    });

    testServer('숫자 카드 — 큰 숫자가 이름 위에 놓인다', (tester) async {
      tester.pumpComponent(
        render([
          cards(
            const {'variant': 'outlined'},
            const [
              {'value': '34', 'title': '명세'},
            ],
          ),
        ]),
      );
      final document = (await tester.request('/')).document!;

      final card = document.querySelector('.docs-card')!;
      expect(card.classes, containsAll(['docs-card--outlined', 'docs-card--stat']));
      final value = card.querySelector('.docs-card-value')!;
      expect(value.text.trim(), '34');
      expect(value.querySelector('.text-headline-medium'), isNotNull);
      // 숫자가 먼저, 이름이 그다음이다.
      final order = card.children.map((child) => child.classes.first).toList();
      expect(order.indexOf('docs-card-value'), lessThan(order.indexOf('docs-card-head')));
    });

    testServer('카드 안의 코드 펜스는 맨 코드다 — 이름표 · 복사 · 면이 없다', (tester) async {
      tester.pumpComponent(
        render([
          ElementNode(
            'Cards',
            const {'variant': 'outlined'},
            [
              ElementNode(
                'Card',
                const {'tone': 'do', 'eyebrow': '권장', 'title': '테마를 따르는 방법'},
                [
                  fence('Card(cardStyle: CoreCardStyle())\n', language: 'dart'),
                ],
              ),
            ],
          ),
          fence('final a = 1;\n', language: 'dart'),
        ]),
      );
      final document = (await tester.request('/')).document!;

      final plain = document.querySelector('.docs-card-body figure.docs-code')!;
      expect(plain.classes, contains('docs-code--plain'));
      expect(plain.querySelector('.docs-code-head'), isNull);
      expect(plain.querySelector('[data-docs-copy]'), isNull);
      expect(plain.text, contains('Card(cardStyle: CoreCardStyle())'));
      // 카드 밖의 펜스는 그대로 이름표와 복사를 단 어두운 코드다.
      final outside = document.querySelectorAll('figure.docs-code').last;
      expect(outside.classes, isNot(contains('docs-code--plain')));
      expect(outside.querySelector('[data-docs-copy]'), isNotNull);
    });
  });

  group('노트', () {
    testServer('제목 · 본문 · 모양 — 모르는 모양은 기본 노트다', (tester) async {
      tester.pumpComponent(
        render([
          const ElementNode(
            'DesignNote',
            {'title': '우회하면 조용히 깨집니다'},
            [
              ElementNode('p', {}, [TextNode('리터럴 색은 CSS 변수를 거치지 않습니다.')]),
            ],
          ),
          const ElementNode('DesignNote', {'variant': 'warning', 'title': '확인합니다'}, [TextNode('경고')]),
          const ElementNode('DesignNote', {'variant': 'outlined'}, [TextNode('아직 정하지 않았습니다.')]),
          const ElementNode('DesignNote', {'variant': 'danger'}, [TextNode('오타')]),
        ]),
      );
      final document = (await tester.request('/')).document!;

      final notes = document.querySelectorAll('.design-note');
      expect(notes, hasLength(4));
      expect(notes.map((note) => note.attributes['role']).toSet(), {'note'});
      expect(notes.first.querySelector('.design-note-title')!.text.trim(), '우회하면 조용히 깨집니다');
      expect(notes.first.querySelector('.design-note-title .text-label-xl'), isNotNull);
      expect(notes.first.querySelector('.design-note-body')!.text.trim(), '리터럴 색은 CSS 변수를 거치지 않습니다.');
      expect(notes[1].classes, contains('design-note-warning'));
      expect(notes[2].classes, contains('design-note-outlined'));
      // 제목을 적지 않으면 제목 줄이 없다.
      expect(notes[2].querySelector('.design-note-title'), isNull);
      expect(notes[3].classes.where((name) => name.startsWith('design-note-')), isEmpty);
      expect(kDocsNoteVariants, {'warning', 'outlined'});
    });
  });

  group('단계', () {
    testServer('순서대로 번호가 붙고, 본문의 코드가 그대로 들어간다', (tester) async {
      tester.pumpComponent(
        render([
          ElementNode('Steps', const {}, [
            const TextNode('\n'),
            ElementNode('Step', const {'title': '패키지 추가'}, [fence('dependencies:\n', language: 'yaml')]),
            const TextNode('\n'),
            const ElementNode(
              'Step',
              {'title': '앱 감싸기'},
              [
                ElementNode('p', {}, [TextNode('루트를 바꾼다.')]),
              ],
            ),
          ]),
        ]),
      );
      final document = (await tester.request('/')).document!;

      final group = document.querySelector('.docs-steps')!;
      expect(group.attributes['role'], 'list');
      expect(group.attributes.containsKey('data-docs-reveal'), isTrue);

      final steps = group.querySelectorAll('.docs-step');
      expect(steps, hasLength(2));
      expect(steps.map((step) => step.attributes['role']).toSet(), {'listitem'});
      expect(steps.map((step) => step.querySelector('.docs-step-number')!.text.trim()), ['1', '2']);
      expect(steps.map((step) => step.querySelector('.docs-step-title')!.text.trim()), ['패키지 추가', '앱 감싸기']);
      expect(steps.first.querySelector('figure.docs-code'), isNotNull);
      expect(steps.last.querySelector('.docs-step-body')!.text.trim(), '루트를 바꾼다.');
      // 짧은 절차의 제목은 한 단 작다.
      expect(group.classes, isNot(contains('docs-steps--large')));
      expect(steps.first.querySelector('.docs-step-title .text-title-small'), isNotNull);
    });

    testServer('따라 하기(`size="large"`)는 넉넉하고 제목이 한 단 크다', (tester) async {
      tester.pumpComponent(
        render([
          const ElementNode(
            'Steps',
            {'size': kDocsStepsLargeSize},
            [
              ElementNode('Step', {'title': '기준 문서를 엽니다'}, [TextNode('본문')]),
            ],
          ),
          const ElementNode(
            'Steps',
            {'size': 'huge'},
            [
              ElementNode('Step', {'title': '모르는 크기'}, [TextNode('본문')]),
            ],
          ),
        ]),
      );
      final document = (await tester.request('/')).document!;

      final groups = document.querySelectorAll('.docs-steps');
      expect(groups.first.classes, contains('docs-steps--large'));
      expect(groups.first.querySelector('.docs-step-title .text-title-medium'), isNotNull);
      expect(groups.last.classes, isNot(contains('docs-steps--large')));
    });

    testServer('묶음 밖에 홀로 놓인 것도 사라지지 않는다', (tester) async {
      tester.pumpComponent(
        render([
          const ElementNode('Step', {'title': '혼자'}, [TextNode('본문')]),
          const ElementNode('Card', {'title': '혼자'}, [TextNode('본문')]),
        ]),
      );
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll('.docs-steps .docs-step'), hasLength(1));
      expect(document.querySelectorAll('.docs-cards .docs-card'), hasLength(1));
    });
  });

  group('표', () {
    test('옆으로 스크롤하는 상자에 담긴다 — 표 자신은 폭을 채운다', () async {
      const table = ElementNode('table', {}, []);
      const paragraph = ElementNode('p', {}, [TextNode('문단')]);
      final page = Page(
        path: 'overview.md',
        url: '/overview',
        content: '',
        initialData: const {},
        config: const PageConfig(),
        loader: MemoryLoader(pages: []),
      );

      final nodes = await const DocsTableExtension().apply(page, [paragraph, table]);

      expect(nodes.first, same(paragraph));
      final wrapper = nodes.last as ElementNode;
      expect(wrapper.tag, 'div');
      expect(wrapper.attributes['class'], 'docs-table');
      expect(wrapper.children, [same(table)]);
    });

    test('머리줄이 빈 표는 이름 · 값 표다 — 빈 머리줄을 걷어 낸다', () async {
      ElementNode row(String tag, List<String> cells) => ElementNode('tr', const {}, [
        for (final cell in cells) ElementNode(tag, const {}, [if (cell.isNotEmpty) TextNode(cell)]),
      ]);
      final plain = ElementNode('table', const {}, [
        ElementNode('thead', const {}, [
          row('th', ['', '']),
        ]),
        ElementNode('tbody', const {}, [
          row('td', ['식별자', 'coui-component-library']),
        ]),
      ]);
      final headed = ElementNode('table', const {}, [
        ElementNode('thead', const {}, [
          row('th', ['이름', '값']),
        ]),
        ElementNode('tbody', const {}, [
          row('td', ['a', 'b']),
        ]),
      ]);
      final page = Page(
        path: 'overview.md',
        url: '/overview',
        content: '',
        initialData: const {},
        config: const PageConfig(),
        loader: MemoryLoader(pages: []),
      );

      final nodes = await const DocsTableExtension().apply(page, [plain, headed]);

      final plainWrapper = nodes.first as ElementNode;
      expect(plainWrapper.attributes['class'], 'docs-table docs-table--plain');
      final plainTable = plainWrapper.children!.single as ElementNode;
      expect(plainTable.children!.whereType<ElementNode>().map((child) => child.tag), ['tbody']);

      final headedWrapper = nodes.last as ElementNode;
      expect(headedWrapper.attributes['class'], 'docs-table');
      expect(headedWrapper.children, [same(headed)]);
    });
  });
}

@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/markdown/code_tag_block_syntax.dart';
import 'package:coui_web/coui_web.dart' show CoUIWeb, ThemeData;
import 'package:docs_core/markdown/heading_slug.dart';
import 'package:docs_site/components/docs_tabs.dart';
import 'package:docs_site/components/safe_code_block.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:markdown/markdown.dart' as md;

/// 본문의 탭이 **서버 렌더에서** 무엇을 내는지, 그리고 그것을 바꾸는
/// 스크립트와 시트가 같은 속성을 읽는지 본다.
///
/// 본문은 브라우저에서 깨어나지 않는다. 탭 막대 · 선택 · 보이는 패널은
/// 서버가 낸 속성이고 정적 스크립트가 그 속성을 고친다 — 그래서 세 파일이
/// 같은 이름을 말하지 않으면 탭은 **에러 없이** 그려지고 눌러도 바뀌지
/// 않는다. 눌렀을 때의 결과는 브라우저에서 확인한다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  /// 마크다운 원문을 사이트의 파서로 읽어, 사이트가 등록한 컴포넌트로
  /// 그린다.
  ///
  /// 노드를 손으로 짓지 않는다 — 파서는 속성 이름을 소문자로 넘기므로
  /// (`groupId` → `groupid`), 손으로 지은 노드는 콘텐츠가 실제로 내는 것과
  /// 다른 이름을 갖는다.
  Component render(String source) {
    final document = md.Document(
      blockSyntaxes: kDocsBlockSyntaxes,
      extensionSet: docsHeadingAwareExtensionSet,
    );
    final nodes = MarkdownParser.buildNodes(document.parse(source));

    return CoUIWeb(
      theme: ThemeData.coui,
      child: NodesBuilder([DocsTabs(), SafeCodeBlock()]).build(nodes),
    );
  }

  String item(String label, String value, String body) =>
      '  <TabItem label="$label" value="$value">\n\n$body\n\n  </TabItem>\n';

  String tabs(String children, {String attributes = ''}) =>
      '<Tabs${attributes.isEmpty ? '' : ' $attributes'}>\n$children</Tabs>\n';

  final platform = item('Flutter', 'flutter', '위젯') + item('Web', 'web', '컴포넌트');

  group('서버가 낸 탭', () {
    testServer('탭 막대 · 탭 · 패널이 역할을 갖는다', (tester) async {
      tester.pumpComponent(render(tabs(platform)));
      final document = (await tester.request('/')).document!;

      final root = document.querySelector('[$kDocsTabsAttribute]')!;
      final list = root.querySelector('[role="tablist"]')!;
      final buttons = list.querySelectorAll('[role="tab"]');
      final panels = root.querySelectorAll('[role="tabpanel"]');

      expect(buttons.map((tab) => tab.text.trim()), ['Flutter', 'Web']);
      expect(buttons.map((tab) => tab.localName).toSet(), {'button'});
      // 폼 안에 놓여도 제출하지 않는다.
      expect(buttons.map((tab) => tab.attributes['type']).toSet(), {'button'});
      expect(panels.map((panel) => panel.text.trim()), ['위젯', '컴포넌트']);
      // 탭과 패널은 탭 막대의 형제다 — 스크립트가 묶음의 직계에서 찾는다.
      expect(list.parent, root);
      expect(panels.map((panel) => panel.parent).toSet(), {root});
      // 본문의 산문 규칙이 탭 막대를 다시 꾸미지 않는다.
      expect(list.classes, contains('not-content'));
    });

    testServer('첫 탭이 선택되고, 그 패널만 보인다', (tester) async {
      tester.pumpComponent(render(tabs(platform)));
      final document = (await tester.request('/')).document!;

      final buttons = document.querySelectorAll('[role="tab"]');
      final panels = document.querySelectorAll('[role="tabpanel"]');

      expect(buttons.map((tab) => tab.attributes['aria-selected']), ['true', 'false']);
      // 탭 막대는 탭 정지점 하나다 — 선택된 탭.
      expect(buttons.map((tab) => tab.attributes['tabindex']), ['0', '-1']);
      expect(panels.map((panel) => panel.attributes.containsKey('hidden')), [false, true]);
    });

    testServer('탭과 패널은 같은 값으로 짝지어지고, 패널의 이름은 탭의 이름이다', (tester) async {
      tester.pumpComponent(render(tabs(platform)));
      final document = (await tester.request('/')).document!;

      final buttons = document.querySelectorAll('[role="tab"]');
      final panels = document.querySelectorAll('[role="tabpanel"]');

      expect(buttons.map((tab) => tab.attributes[kDocsTabValueAttribute]), ['flutter', 'web']);
      expect(panels.map((panel) => panel.attributes[kDocsTabValueAttribute]), ['flutter', 'web']);
      expect(panels.map((panel) => panel.attributes['aria-label']), ['Flutter', 'Web']);
    });

    testServer('`defaultValue` 가 처음 보이는 탭을 정한다', (tester) async {
      tester.pumpComponent(render(tabs(platform, attributes: 'defaultValue="web"')));
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll('[role="tab"]').map((tab) => tab.attributes['aria-selected']), [
        'false',
        'true',
      ]);
      expect(document.querySelectorAll('[role="tab"]').map((tab) => tab.attributes['tabindex']), ['-1', '0']);
      expect(
        document.querySelectorAll('[role="tabpanel"]').map((panel) => panel.attributes.containsKey('hidden')),
        [true, false],
      );
    });

    testServer('어느 탭의 것도 아닌 `defaultValue` 는 첫 탭으로 간다', (tester) async {
      tester.pumpComponent(render(tabs(platform, attributes: 'defaultValue="android"')));
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll('[role="tab"]').map((tab) => tab.attributes['aria-selected']), [
        'true',
        'false',
      ]);
    });

    testServer('`groupId` 는 함께 바뀌는 묶음의 이름으로 나간다', (tester) async {
      tester.pumpComponent(render('${tabs(platform, attributes: 'groupId="platform"')}\n${tabs(platform)}'));
      final document = (await tester.request('/')).document!;

      final roots = document.querySelectorAll('[$kDocsTabsAttribute]');
      expect(roots, hasLength(2));
      expect(roots.first.attributes[kDocsTabsGroupAttribute], 'platform');
      // 이름을 적지 않은 묶음은 혼자 바뀐다.
      expect(roots.last.attributes.containsKey(kDocsTabsGroupAttribute), isFalse);
    });

    testServer('`label` 은 탭 막대의 이름이고, 적지 않으면 붙지 않는다', (tester) async {
      tester.pumpComponent(render('${tabs(platform, attributes: 'label="플랫폼"')}\n${tabs(platform)}'));
      final document = (await tester.request('/')).document!;

      final lists = document.querySelectorAll('[role="tablist"]');
      expect(lists.first.attributes['aria-label'], '플랫폼');
      expect(lists.last.attributes.containsKey('aria-label'), isFalse);
    });

    testServer('탭의 글자는 킷의 역할이다', (tester) async {
      tester.pumpComponent(render(tabs(platform)));
      final document = (await tester.request('/')).document!;

      final label = document.querySelector('[role="tab"]')!.children.single;
      expect(label.classes, contains('text-label-large'));
    });

    testServer('값이 겹친 탭은 하나만 선택된다', (tester) async {
      // 값을 적지 않은 탭들이다. 콘텐츠 검사가 막지만, 지나가더라도 두 탭이
      // 함께 선택된 탭 막대를 내지 않는다.
      tester.pumpComponent(render(tabs(item('Flutter', '', '위젯') + item('Web', '', '컴포넌트'))));
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll('[role="tab"]').map((tab) => tab.attributes['aria-selected']), [
        'true',
        'false',
      ]);
      expect(
        document.querySelectorAll('[role="tabpanel"]').map((panel) => panel.attributes.containsKey('hidden')),
        [false, true],
      );
    });

    testServer('묶음 밖에 홀로 놓인 `TabItem` 은 탭 하나짜리 묶음이다', (tester) async {
      tester.pumpComponent(render(item('Flutter', 'flutter', '위젯')));
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll('[role="tab"]'), hasLength(1));
      expect(document.querySelector('[role="tabpanel"]')!.text.trim(), '위젯');
      expect(document.querySelector('[role="tabpanel"]')!.attributes.containsKey('hidden'), isFalse);
    });

    testServer('탭이 하나도 없는 묶음은 안에 적힌 것을 그대로 둔다', (tester) async {
      tester.pumpComponent(render(tabs('\n탭 없이 적은 글\n\n')));
      final document = (await tester.request('/')).document!;

      expect(document.querySelector('[role="tablist"]'), isNull);
      expect(document.body!.text, contains('탭 없이 적은 글'));
    });
  });

  group('배선', () {
    final script = File('web/docs-shell.js').readAsStringSync();
    final sheet = File('web/docs-shell.css').readAsStringSync();

    test('서버 엔트리포인트는 이 탭을 등록한다', () {
      final source = File('lib/main.server.dart').readAsStringSync();

      expect(source, contains('DocsTabs(),'));
      // 대신하던 컴포넌트는 탭 막대를 브라우저에서 깨어나는 섬으로 그린다 —
      // 둘이 함께 등록되면 먼저 온 쪽이 `<Tabs>` 를 가져간다.
      expect(source, isNot(contains('package:jaspr_content/components/tabs.dart')));
    });

    test('탭 막대를 깨우는 섬이 클라이언트 묶음에 없다', () {
      for (final path in const ['lib/main.client.options.dart', 'lib/main.server.options.dart']) {
        expect(File(path).readAsStringSync(), isNot(contains('tab_bar')), reason: path);
      }
    });

    test('스크립트는 서버가 낸 속성 이름으로 묶음과 값을 찾는다', () {
      expect(script, contains('[$kDocsTabsAttribute]'));
      // `data-group` · `data-value` 를 `dataset` 으로 읽는다.
      expect(kDocsTabsGroupAttribute, 'data-group');
      expect(kDocsTabValueAttribute, 'data-value');
      expect(script, contains('dataset.group'));
      expect(script, contains('dataset.value'));
    });

    test('스크립트는 선택 · 탭 정지점 · 보이는 패널을 함께 고친다', () {
      final body = script.substring(script.indexOf('const showTab'), script.indexOf('const markPanels'));

      expect(body, contains("setAttribute('aria-selected'"));
      expect(body, contains('tabIndex'));
      expect(body, contains('panel.hidden'));
    });

    test('스크립트는 화살표 · Home · End 로 초점을 옮긴다', () {
      for (final key in const ['ArrowRight', 'ArrowLeft', 'Home', 'End']) {
        expect(script, contains(key), reason: key);
      }
    });

    test('탭의 키는 창의 캡처 단계에서 듣는다', () {
      // 페이지에 놓인 Flutter 프리뷰가 창의 캡처 단계에서 키를 듣고, 자기가
      // 처리한 키(화살표)의 전파를 멈춘다. 문서나 그 아래에 건 리스너는 그
      // 키를 받지 못한다 — 에러 없이, 프리뷰가 있는 페이지에서만.
      final start = script.indexOf('const tab = event.target instanceof Element ? event.target.closest(tabSelector)');
      final keys = script.substring(script.lastIndexOf('addEventListener(', script.indexOf('to.focus();')));
      expect(start, isNot(-1));
      expect(keys, startsWith("addEventListener('keydown', event => {"));
      expect(keys.substring(0, keys.indexOf('// ── Scroll reveals')).trimRight(), endsWith('}, true);'));
      // 문서에 건 것이 아니다.
      expect(script, isNot(contains("document.addEventListener('keydown'")));
    });

    test('시트는 선택된 탭과 숨은 패널을 속성으로 읽는다', () {
      expect(sheet, contains('[role="tab"][aria-selected="true"]'));
      expect(sheet, contains('.docs-tabs > [role="tabpanel"][hidden] { display: none; }'));
      // 대신하던 컴포넌트의 클래스에 건 규칙은 남지 않는다.
      expect(sheet, isNot(contains('.tab-bar')));
      expect(sheet, isNot(contains('.tab-content')));
    });

    test('스크립트가 없는 문서에서는 모든 패널이 이름을 달고 보인다', () {
      final start = sheet.indexOf('@media (scripting: none)');
      expect(start, isNot(-1));
      final block = sheet.substring(start, sheet.indexOf('\n}\n', start));

      expect(block, contains('[role="tablist"] { display: none; }'));
      expect(block, contains('[role="tabpanel"][hidden] { display: block; }'));
      expect(block, contains('content: attr(aria-label);'));
    });
  });
}

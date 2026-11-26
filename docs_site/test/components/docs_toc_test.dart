@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_site/components/docs_toc.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart' show TocEntry;
import 'package:jaspr_test/server_test.dart';

/// "이 문서의 목차" 가 **렌더된 HTML 로** 무엇을 내는지, 그리고 그 마크업을 읽는
/// 스크립트·스타일과 이름이 맞는지 본다.
///
/// 읽는 쪽(`docs-toc.js`)은 서버가 쓴 속성 이름에 기대고, 스타일은 서버가 쓴 클래스
/// 이름에 기댄다. 한쪽 이름만 바뀌면 목차는 **에러 없이** 활성 표시와 진행선을
/// 잃는다 — 마크업은 멀쩡히 렌더되기 때문에 눈에 안 띈다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  final entries = [
    TocEntry('개요', 'overview', []),
    TocEntry('사용법', 'usage', [
      TocEntry('옵션', 'options', []),
    ]),
    TocEntry('접근성', 'a11y', []),
  ];

  group('DocsTocList 서버 렌더', () {
    testServer('항목마다 페이지 경로 + 조각 앵커로 나간다', (tester) async {
      tester.pumpComponent(DocsTocList(path: '/components/sortable', entries: entries));
      final response = await tester.request('/');

      // 문서에 `<base href="/">` 가 있어 `#id` 만 쓰면 홈으로 풀린다.
      final hrefs = response.document!.querySelectorAll('a.toc-link').map((a) => a.attributes['href']).toList();
      expect(hrefs, [
        '/components/sortable#overview',
        '/components/sortable#usage',
        '/components/sortable#options',
        '/components/sortable#a11y',
      ]);
    });

    testServer('하위 제목은 부모 항목 안의 중첩 목록이다', (tester) async {
      tester.pumpComponent(DocsTocList(path: '/p', entries: entries));
      final response = await tester.request('/');
      final doc = response.document!;

      expect(doc.querySelectorAll('ul.toc-list'), hasLength(1));
      expect(doc.querySelectorAll('ul.toc-sub'), hasLength(1));

      final usage = doc.querySelector('a[href="/p#usage"]')!.parent!;
      expect(usage.querySelector('ul.toc-sub a')!.attributes['href'], '/p#options');
    });

    testServer('깊이는 링크의 들여쓰기로 가고, 최상위 링크는 인라인 스타일이 없다', (tester) async {
      tester.pumpComponent(DocsTocList(path: '/p', entries: entries));
      final response = await tester.request('/');
      final doc = response.document!;

      // 마커는 링크 자신의 가장자리에서 위치를 잡는다 — 깊이가 링크를 옮기면 레일에서
      // 떨어진다. 그래서 깊이는 링크 안쪽 여백(`--toc-depth`)으로만 간다.
      final sub = doc.querySelector('a[href="/p#options"]')!;
      expect(sub.classes, containsAll(['toc-link', 'toc-link--sub']));
      expect(sub.attributes['style'], contains('--toc-depth: 1'));

      final top = doc.querySelector('a[href="/p#overview"]')!;
      expect(top.classes, ['toc-link']);
      expect(top.attributes.containsKey('style'), isFalse);
    });
  });

  // 서버가 쓰는 이름과 읽는 쪽이 읽는 이름이 갈리지 않게 소스에서 맞춘다.
  group('목차 마크업 · 스크립트 · 스타일 계약', () {
    late String layout;
    late String script;
    late String css;
    late String chrome;

    setUpAll(() {
      layout = File('lib/layouts/manual_layout.dart').readAsStringSync();
      script = File('web/docs-toc.js').readAsStringSync();
      css = File('web/docs-shell.css').readAsStringSync();
      chrome = File('lib/layouts/site_chrome.dart').readAsStringSync();
    });

    test('레이아웃이 쓰는 속성을 스크립트가 읽는다', () {
      expect(layout, contains("'data-toc'"), reason: '레이아웃이 data-toc 를 쓰지 않는다');
      expect(script, contains('[data-toc]'));
    });

    test('모바일 목록도 같은 스크립트가 다룬다', () {
      // 모바일 목록의 클릭도 페이지 안에서 스크롤해야 한다 — 경로에 끝 슬래시가 없는
      // href 는 다른 문서라 따라가면 페이지를 다시 연다.
      final markers = RegExp(r"'data-toc': ''").allMatches(layout);
      expect(markers.length, 2, reason: '데스크톱 레일과 모바일 목록 둘 다 data-toc 를 달아야 한다');
    });

    test('스크립트가 켜고 끄는 클래스를 스타일이 안다', () {
      expect(script, contains("'is-active'"));
      expect(css, contains('.toc-link.is-active'));
      // 읽고 있는 줄의 표지는 그 줄의 눈금 위로 자란다.
      expect(css, contains('.toc-link.is-active::after'));
    });

    test('레이아웃이 내는 클래스마다 스타일이 있다', () {
      for (final selector in const ['.toc-rail', '.toc-title', '.toc-link', '.toc-link--sub', '.docs-mobile-toc']) {
        expect(css, contains(selector), reason: '$selector 규칙이 없다');
      }
    });

    test('두 레이아웃의 머리가 스크립트를 싣고 파일이 있다', () {
      expect(chrome, contains("kDocsTocScript = '/docs-toc.js'"));
      expect(chrome, contains('script(src: kDocsTocScript'));
      expect(File('web/docs-toc.js').existsSync(), isTrue);
    });

    test('표지의 전환은 모션 변수를 거친다 — 움직임 줄이기가 닿는다', () {
      // 시간을 적은 전환은 OS 의 움직임 줄이기 설정을 지나친다.
      final marker = RegExp(r'^\.toc-link::after \{([^}]*)\}', multiLine: true).firstMatch(css)!.group(1)!;

      expect(marker, contains('transition: transform var(--site-duration-normal) var(--site-easing-move)'));
    });

    test('스크립트는 시간을 적지 않는다', () {
      final code = script.split('\n').where((line) => !line.trimLeft().startsWith('//')).join('\n');

      expect(code, isNot(matches(RegExp(r'\b\d+\s*m?s\b'))));
      for (final timer in RegExp(r'setTimeout\(([\s\S]*?)\);').allMatches(code)) {
        expect(timer.group(1), matches(RegExp(r'\bwait\s*$')));
      }
    });
  });
}

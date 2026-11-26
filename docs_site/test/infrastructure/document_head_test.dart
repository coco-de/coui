@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/site_head.dart';
import 'package:docs_site/components/site_footer.dart';
import 'package:docs_site/layouts/landing_layout.dart';
import 'package:docs_site/layouts/manual_layout.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_test/server_test.dart';

/// 문서의 머리가 싣는 것이 어느 경로의 페이지에서나 같은 곳을 가리키는지,
/// 그리고 페이지에 든 것이 그 페이지의 제목을 지우지 않는지 본다.
///
/// 둘 다 홈에서는 보이지 않는다. 홈은 루트에 있어서 상대 주소가 우연히
/// 맞고, Flutter 프리뷰가 없어서 제목을 건드릴 것이 없다. 그래서 홈만 보고
/// 있으면 나머지 페이지 전부에서 틀린 채로 지나간다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  group('문서의 뼈대', () {
    final page = Page(
      path: 'overview.md',
      url: '/overview',
      content: '',
      initialData: {
        'page': {'title': '개요', 'description': '문서를 읽는 순서'},
      },
      config: const PageConfig(),
      loader: MemoryLoader(pages: []),
    );

    const layouts = <String, PageLayoutBase>{
      '문서': ManualLayout(),
      '랜딩': LandingLayout(footer: SiteFooter()),
    };

    for (final MapEntry(key: name, value: layout) in layouts.entries) {
      testServer('$name 레이아웃 — 문서는 하나이고 제목 · 설명 · base 가 그 머리에 있다', (tester) async {
        tester.pumpComponent(layout.buildLayout(page, Component.text('본문')));
        final html = (await tester.request('/')).body;

        // 문서 위에 상자를 그리는 것이 놓이면 jaspr 가 바깥에 문서를 하나 더
        // 세우고, 레이아웃의 `<html><head>` 는 본문 안에 남는다.
        expect('<html'.allMatches(html), hasLength(1));
        expect(RegExp('<head[ >]').allMatches(html), hasLength(1));
        expect(RegExp('<body[ >]').allMatches(html), hasLength(1));

        final head = html.substring(html.indexOf('<head'), html.indexOf('</head>'));
        expect(head, contains('<title>개요</title>'));
        expect(head, contains('<base href="/"'));
        expect(head, contains('name="description"'));
        // 화면 전환은 앱 루트가 머리에 싣는다 — 사이트 시트는 다시 적지 않는다.
        expect(head, contains('id="coui-page-transition"'));

        // 앱 루트는 본문 안에 있고, 머리의 것은 본문에 다시 나오지 않는다.
        final body = html.substring(html.indexOf('</head>'));
        expect(body, contains('class="coui-root'));
        expect(body, isNot(contains('<title')));
        expect(body, isNot(contains('<base')));
      });
    }

    test('서버 엔트리포인트는 문서 위에 앱 루트를 놓지 않는다', () {
      final source = File('lib/main.server.dart').readAsStringSync();
      final code = source.split('\n').where((line) => !line.trimLeft().startsWith('//')).join('\n');

      // `runApp` 이 받는 것이 곧 렌더 트리의 맨 위다.
      expect(code, matches(RegExp(r'runApp\(\s*ContentApp\.custom\(')));
      // 문서를 스스로 세우지 않는 라우트는 라우터가 앱 루트로 감싼다.
      expect(RegExp(r'siteAppRoot\(\s*child: (DocsPathRedirect|EmbedPage)\(').allMatches(code), hasLength(3));
    });
  });

  group('공유 머리의 주소', () {
    testServer('같은 출처의 자산은 사이트 루트에서 부른다', (tester) async {
      tester.pumpComponent(
        Component.element(tag: 'div', id: 'shared-head', children: docsSharedHead()),
      );
      final document = (await tester.request('/')).document!;
      final urls = [
        for (final element in document.querySelectorAll('#shared-head script[src]')) element.attributes['src']!,
        for (final element in document.querySelectorAll('#shared-head link[href]')) element.attributes['href']!,
      ];

      // 페이지는 중첩된 경로(`/components/button`)에 있고, 상대 주소를 루트에
      // 붙여 줄 `<base href>` 는 이 스크립트들보다 문서에서 뒤에 온다. 그래서
      // 상대 주소는 페이지 경로에 붙어 아무것도 받지 못한다.
      expect(urls, isNotEmpty);
      for (final url in urls) {
        expect(url, anyOf(startsWith('/'), startsWith('https://')), reason: '`$url` 은 페이지 경로에 붙는다');
      }
      expect(urls, contains(kDocsIconStrokeScript));
    });
  });

  group('Flutter 프리뷰', () {
    test('페이지의 제목을 그대로 돌려준다', () {
      // `CoUIApp` 의 `title` 은 Flutter 의 `Title` 로 가고, Web 에서 그 위젯은
      // 그릴 때마다 `document.title` 을 쓴다. 기본값(빈 문자열)으로 두면
      // 프리뷰가 뜨는 순간 그 페이지의 탭 제목이 빈다.
      //
      // 소스를 읽는다 — 이 앱은 브라우저에서만 문서를 읽으므로 VM 에서
      // 그려서는 제목이 오가는 것을 볼 수 없다. 브라우저에서의 결과는 배포용
      // 빌드로 확인한다.
      final source = File('lib/widgets/preview_app.dart').readAsStringSync();
      final app = source.substring(source.indexOf('return coui.CoUIApp('));

      expect(source, contains("_jsEvalString('document.title')"));
      expect(app.substring(0, app.indexOf('home:')), contains('title: _documentTitle()'));
    });

    test('앱을 초점 문 뒤에 세운다', () {
      // 앱은 뜨면서 첫 라우트에 초점을 주고, 뷰는 그 초점을 보고 페이지의
      // DOM 초점을 가져간다. 문이 없으면 페이지를 열 때와 변형을 고를 때마다
      // 독자의 초점이 프리뷰로 옮겨지고, 화살표와 Tab 이 페이지에 닿지 않는다.
      //
      // 문이 하는 일은 docs_core 의 위젯 테스트가 본다
      // (`preview_focus_gate_test.dart`). 여기서 보는 것은 임베드가 그 문
      // 뒤에 앱을 세우는지다 — 소스를 읽는 이유는 위의 테스트와 같다.
      final source = File('lib/widgets/preview_app.dart').readAsStringSync();

      expect(source, contains('Widget build(BuildContext context) => PreviewFocusGate(child: _app());'));
      // 문 밖에 서는 두 번째 앱 루트는 없다.
      expect('CoUIApp('.allMatches(source), hasLength(1));
      expect(source.indexOf('Widget _app() {'), lessThan(source.indexOf('return coui.CoUIApp(')));
    });
  });
}

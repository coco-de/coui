@TestOn('vm')
library;

import 'package:docs_site/layouts/manual_layout.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_test/server_test.dart';

/// 시안 페이지의 그림은 그 페이지들만 싣는 시트(`docs-designed-pages.css`)에
/// 있다. 그 시트를 받는 길은 셋이고(frontmatter `design: true`, 사이트 전용
/// 시안판, 컴포넌트 v2 템플릿), 나머지 페이지는 받지 않는다.
///
/// 본문을 공유 문서(`docs_core/content`)로 옮긴 시안 페이지는 첫 번째 길만
/// 남는다. 그 판정이 빠지면 페이지는 에러 없이 그려지고 그림만 맨 마크업으로
/// 남는다 — 화면을 열어 보기 전에는 보이지 않는다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  Page pageWith({Map<String, Object?> frontmatter = const {}, Map<String, Object?> data = const {}}) => Page(
    path: 'guides/sample.md',
    url: '/guides/sample',
    content: '',
    initialData: {
      'page': {'title': '견본', 'description': '시안 판정', ...frontmatter},
      ...data,
    },
    config: const PageConfig(),
    loader: MemoryLoader(pages: []),
  );

  final cases = <String, (Page, bool)>{
    'frontmatter design: true': (pageWith(frontmatter: {kDocsDesignKey: true}), true),
    '사이트 전용 시안판(docsDesign)': (pageWith(data: {'docsDesign': true}), true),
    '컴포넌트 v2 템플릿': (pageWith(frontmatter: {'template': 'v2'}), true),
    '아무 표시도 없는 페이지': (pageWith(), false),
    'design: false': (pageWith(frontmatter: {kDocsDesignKey: false}), false),
    '문자열 "true" 는 표시가 아니다': (pageWith(frontmatter: {kDocsDesignKey: 'true'}), false),
  };

  for (final MapEntry(key: name, value: (page, designed)) in cases.entries) {
    test('$name — 판정은 ${designed ? '시안' : '일반'}', () {
      expect(docsUsesDesignedLayout(page), designed);
    });

    testServer('$name — 시트와 셸 표시가 판정을 따른다', (tester) async {
      tester.pumpComponent(const ManualLayout().buildLayout(page, Component.text('본문')));
      final html = (await tester.request('/')).body;
      final head = html.substring(html.indexOf('<head'), html.indexOf('</head>'));
      final body = html.substring(html.indexOf('</head>'));

      expect(head.contains('href="/docs-designed-pages.css"'), designed);
      expect(body.contains('data-docs-design'), designed);
    });
  }
}

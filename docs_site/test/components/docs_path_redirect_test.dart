@TestOn('vm')
library;

import 'package:docs_site/components/docs_path_redirect.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

/// `/components/footer` 가 정적 빌드에서도 `/blocks/footer` 로 이어지는지.
///
/// jaspr 정적 호스트는 HTTP 301 을 내지 않는다. 페이지가 refresh 와
/// `location.replace` 를 함께 실어야 북마크가 새 문서로 간다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  testServer('푸터 블록으로 옮긴다', (tester) async {
    tester.pumpComponent(const DocsPathRedirect(to: '/blocks/footer'));
    final body = (await tester.request('/')).body;

    expect(body, contains('http-equiv="refresh"'));
    expect(body, contains('content="0;url=/blocks/footer"'));
    expect(body, contains("location.replace('/blocks/footer')"));
    expect(body, contains('href="/blocks/footer"'));
  });
}

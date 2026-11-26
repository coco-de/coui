import 'package:docs_app/src/content/docs_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveDocsRoute', () {
    test('컴포넌트 페이지가 /components/<slug> 로 매핑된다', () {
      final route = resolveDocsRoute('$kDocsContentRoot/components/button.md');
      expect(route?.path, '/components/button');
    });

    test('index.md 가 부모 디렉터리로 접힌다', () {
      expect(resolveDocsRoute('$kDocsContentRoot/index.md')?.path, '/');
    });

    test('중첩 디렉터리가 1:1 로 매핑된다', () {
      expect(
        resolveDocsRoute('$kDocsContentRoot/guides/theming.md')?.path,
        '/guides/theming',
      );
    });

    test('루트 레벨 페이지가 매핑된다', () {
      expect(
        resolveDocsRoute('$kDocsContentRoot/getting-started.md')?.path,
        '/getting-started',
      );
    });

    test('토큰 개요가 /tokens/overview 로 매핑된다', () {
      expect(
        resolveDocsRoute('$kDocsContentRoot/tokens/overview.md')?.path,
        '/tokens/overview',
      );
    });

    test('밑줄로 시작하는 세그먼트는 private — 라우트가 아니다', () {
      // jaspr 쪽 규칙과 동일: `_templates` 는 라우트가 아니라 저작 도구다.
      expect(
        resolveDocsRoute('$kDocsContentRoot/_templates/component.md'),
        isNull,
      );
      expect(resolveDocsRoute('$kDocsContentRoot/_data/site.md'), isNull);
    });

    test('md 가 아닌 asset 과 콘텐츠 밖 asset 은 무시한다', () {
      expect(resolveDocsRoute('$kDocsContentRoot/_data/site.yaml'), isNull);
      expect(resolveDocsRoute('packages/other/content/x.md'), isNull);
      expect(resolveDocsRoute('assets/images/logo.svg'), isNull);
    });
  });
}

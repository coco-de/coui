import 'package:docs_app/src/content/content_repository.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_core/shared/docs_navigation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// 실제 번들된 `docs_site` 콘텐츠에 대해 로더를 검증한다.
///
/// 이 테스트는 asset 배선 전체를 실측한다: docs_site 의 pubspec 이 콘텐츠를
/// 노출하는지, 매니페스트에 잡히는지, 라우트 해석이 진짜 파일에서 도는지.
/// 이게 깨지면 docs_app 은 빈 사이트를 띄운다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DocsContentRepository repo;

  setUpAll(() async {
    repo = DocsContentRepository(rootBundle);
    await repo.load();
  });

  test('번들된 docs_site 콘텐츠에서 라우트를 찾는다', () {
    expect(repo.routes, isNotEmpty, reason: 'asset 배선이 끊겼다');
  });

  test('문서화된 138개 컴포넌트 전부에 라우트가 있다', () {
    final missing = [
      for (final entry in kDocsComponentEntries)
        if (!repo.hasRoute('/components/${entry.slug}')) entry.slug,
    ];
    expect(missing, isEmpty, reason: '카탈로그에 있는데 페이지가 안 잡힌다');
  });

  test('사이트 구조의 모든 페이지가 번들에 있다', () {
    // 앱의 사이드바는 구조(kDocsNavLocations)에서 나오고, 그 링크가 여는
    // 페이지는 docs_core 의 asset 이다. asset 목록은 디렉터리를 재귀하지
    // 않아 새 디렉터리(`content/<dir>/`)를 만들면서 한 줄을 빠뜨리면 그
    // 디렉터리의 페이지가 앱에서만 조용히 빈다.
    final missing = [
      for (final location in kDocsNavLocations)
        if (!repo.hasRoute(location.page.path)) location.page.path,
    ];
    expect(
      missing,
      isEmpty,
      reason: '구조에 있는데 앱 번들에 없다 — docs_core/pubspec.yaml 의 assets',
    );
  });

  test('루트 · 가이드 · 개요 라우트가 존재한다', () {
    expect(repo.hasRoute('/'), isTrue);
    expect(repo.hasRoute('/getting-started'), isTrue);
    expect(repo.hasRoute('/components-overview'), isTrue);
    expect(repo.hasRoute('/guides/theming'), isTrue);
    expect(repo.hasRoute('/tokens/overview'), isTrue);
    // PoC 는 소비자 내비에서 뺐지만, LivePreview 하네스가 이 라우트에
    // 남아 있다 — 지워지면 북마크·내부 검증이 404 가 된다.
    expect(repo.hasRoute('/live-preview-poc'), isTrue);
  });

  test('private 콘텐츠는 라우트로 노출되지 않는다', () {
    final private = repo.routes.where(
      (r) => r.path.contains('_templates') || r.path.contains('_data'),
    );
    expect(private, isEmpty);
  });

  test('모든 라우트가 예외 없이 파싱된다', () async {
    for (final route in repo.routes) {
      final page = await repo.page(route.path);
      expect(page, isNotNull, reason: '${route.path} 로드 실패');
      expect(page!.body, isNotEmpty, reason: '${route.path} 본문이 비었다');
    }
  });

  test('컴포넌트 페이지가 frontmatter title 을 들고 있다', () async {
    final page = await repo.page('/components/button');
    expect(page?.title, 'Button');
    expect(page?.category, 'control');
  });
}

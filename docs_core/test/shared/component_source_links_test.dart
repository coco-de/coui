@TestOn('vm')
library;

import 'package:docs_core/shared/component_source_links.dart';
import 'package:test/test.dart';

void main() {
  test('카탈로그 실재 슬러그는 raw/github/claude 링크를 만든다', () {
    final links = docsComponentSourceLinksForSlug('button');
    expect(links, isNotNull);
    expect(
      links!.rawMarkdownUrl,
      'https://raw.githubusercontent.com/coco-de/coui/main/'
      'docs_core/content/components/button.md',
    );
    expect(
      links.githubUrl,
      'https://github.com/coco-de/coui/blob/main/'
      'docs_core/content/components/button.md',
    );
    expect(links.openInClaudeUrl, startsWith('https://claude.ai/new?q='));
    expect(links.openInClaudeUrl, contains('Button'));
  });

  test('카탈로그 밖 슬러그는 null', () {
    expect(docsComponentSourceLinksForSlug('does-not-exist'), isNull);
  });

  test('라우트 경로에서 슬러그를 뽑는다', () {
    expect(docsComponentSlugFromRoutePath('/components/button'), 'button');
    expect(docsComponentSlugFromRoutePath('/components/text-field'), 'text-field');
  });

  test('컴포넌트 경로가 아니면 null', () {
    expect(docsComponentSlugFromRoutePath('/getting-started'), isNull);
    expect(docsComponentSlugFromRoutePath('/tokens/overview'), isNull);
    expect(docsComponentSlugFromRoutePath('/components/'), isNull);
    expect(
      docsComponentSlugFromRoutePath('/components/button/extra'),
      isNull,
    );
    expect(docsComponentSlugFromRoutePath('components/button'), isNull);
  });
}

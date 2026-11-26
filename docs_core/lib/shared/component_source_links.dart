/// 컴포넌트 문서 페이지 상단에 붙는 소스 링크 — raw `.md` 직링크 + AI 딥링크.
///
/// daisyUI/Astryx 패턴(`docs/docs-benchmark-2026-08-01.md` 4장): 사람은
/// GitHub 에서 원문을 바로 보고, AI 에이전트는 한 번의 클릭으로 그 원문을
/// 읽은 채 대화를 시작한다. 순수 Dart 다(`component_catalog.dart` 와 같은
/// 이유로 jaspr/Flutter 어느 쪽도 import 하지 않는다) — docs_site 와
/// docs_app 이 같은 URL 을 만들어야 두 표면이 갈라지지 않는다. #3579.
library;

import 'component_catalog.dart';

/// `coui_core/coui` 저장소의 GitHub owner/repo — 이 카탈로그가 속한 문서
/// 저장소의 유일한 출처. raw/blob URL 모두 이 상수를 경유한다.
const String kDocsGithubRepo = 'coco-de/coui';

/// 링크가 가리키는 브랜치. 저장소의 GitHub 표시 기본 브랜치(`main`)와
/// 같다 — 커밋마다 바뀌는 SHA 를 박지 않아 raw 링크가 항상 최신 문서를
/// 가리킨다.
const String kDocsGithubBranch = 'main';

/// 컴포넌트 문서 페이지 하나의 소스 링크 묶음.
class DocsComponentSourceLinks {
  /// 링크 묶음을 만든다.
  const DocsComponentSourceLinks({
    required this.rawMarkdownUrl,
    required this.githubUrl,
    required this.openInClaudeUrl,
  });

  /// `raw.githubusercontent.com` 직링크 — AI 에이전트가 그대로 fetch 할
  /// 수 있는 순수 텍스트.
  final String rawMarkdownUrl;

  /// `github.com/.../blob/...` 사람이 읽는 소스 링크(구문 강조·기록 포함).
  final String githubUrl;

  /// `claude.ai/new?q=...` — [rawMarkdownUrl] 을 읽으라는 프롬프트를 미리
  /// 채운 새 대화 딥링크.
  final String openInClaudeUrl;
}

/// [slug] 가 카탈로그의 실재 컴포넌트를 가리킬 때만 그 문서 페이지의 소스
/// 링크를 만든다. 카탈로그 밖의 페이지(가이드·개요 등)는 raw `.md` 대상이
/// 정의돼 있지 않으므로 null.
DocsComponentSourceLinks? docsComponentSourceLinksForSlug(String slug) {
  final entry = docsComponentBySlug(slug);
  if (entry == null) return null;

  final path = 'docs_core/content/components/$slug.md';
  final rawMarkdownUrl = 'https://raw.githubusercontent.com/$kDocsGithubRepo/$kDocsGithubBranch/$path';
  final githubUrl = 'https://github.com/$kDocsGithubRepo/blob/$kDocsGithubBranch/$path';
  final prompt =
      "I'm using the CoUI ${entry.name} component. Read $rawMarkdownUrl "
      'for its full API and usage guidelines, then help me use it.';
  final openInClaudeUrl = 'https://claude.ai/new?q=${Uri.encodeComponent(prompt)}';

  return DocsComponentSourceLinks(
    rawMarkdownUrl: rawMarkdownUrl,
    githubUrl: githubUrl,
    openInClaudeUrl: openInClaudeUrl,
  );
}

/// 라우트 경로(`/components/button`)에서 카탈로그 슬러그(`button`)를
/// 뽑는다. 컴포넌트 경로가 아니면 null — docs_site(파일 경로
/// `components/button.md`)와 docs_app(라우트 경로 `/components/button`)이
/// 서로 다른 표기를 쓰므로 각자 호출 전에 자기 표기에서 슬러그만 뽑아
/// 넘긴다(이 함수는 라우트 경로 표기 하나만 안다).
String? docsComponentSlugFromRoutePath(String path) {
  const prefix = '/components/';
  if (!path.startsWith(prefix)) return null;
  final slug = path.substring(prefix.length);
  if (slug.isEmpty || slug.contains('/')) return null;
  return slug;
}

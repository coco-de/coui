/// CoUI 문서의 가이드 카탈로그 — **단일 출처**.
///
/// 컴포넌트 카탈로그와 같은 이유로 존재한다. 순수 Dart 이므로 jaspr 사이트
/// (`docs_site`) 와 네이티브 Flutter 쌍둥이 (`docs_app`) 가 **같은 목록**을
/// 읽는다.
///
/// 이 파일이 생기기 전 두 사이드바는 손으로 관리되는 사본 2벌이었고, 이미
/// 갈라져 있었다 — 사이트는 11개, 앱은 9개였다(`figma-library` ·
/// `design-sources` 누락). 그 차이는 화면에서 "네이티브 앱에는 그 가이드가
/// 없다" 로 나타나고, 어느 쪽이 옳은지는 코드만 봐선 알 수 없다.
///
/// 순서는 의미가 있다 — 알파벳이 아니라 읽는 순서다. 같은 [DocsGuideGroup]
/// 안에서 이 목록의 순서가 곧 사이드바와 이전 · 다음 페이저의 순서다.
///
/// 가이드가 어느 탭의 어느 그룹에 놓이는지도 여기서 정한다
/// ([DocsGuideEntry.group]). 그 값이 required 인 이유는 가이드를 추가하면서
/// 자리를 빠뜨릴 수 없게 하려는 것이다 — 자리 없는 가이드는 파일은 있는데
/// 어느 내비게이션에도 나오지 않는 페이지가 된다.
library;

/// 가이드가 놓이는 자리 — 사이트 구조(`docs_navigation.dart`)의 그룹 하나.
enum DocsGuideGroup {
  /// Getting Started 탭의 "개념".
  concepts,

  /// Foundations 탭의 "파운데이션".
  foundations,

  /// Resources 탭의 "도구".
  tools,

  /// Resources 탭의 "기준".
  standards,
}

/// 카탈로그의 한 가이드.
class DocsGuideEntry {
  /// 이 가이드를 만든다.
  const DocsGuideEntry({
    required this.slug,
    required this.label,
    required this.englishLabel,
    required this.group,
  });

  /// 문서 URL 세그먼트이자 `content/guides/<slug>.md` 파일명.
  final String slug;

  /// 사이드바에 보이는 이름.
  final String label;

  /// AI 표면(`llms.txt`)에 싣는 영문 이름.
  ///
  /// 문서 사이트는 한국어가 primary 지만 AI 소비 표면은 영문이다
  /// (`process/docs-site.md` "언어 정책"). 사이드바 [label] 은 한국어라
  /// 따로 둔다 — required 라서 가이드를 추가하면서 빠뜨릴 수 없다.
  final String englishLabel;

  /// 이 가이드가 놓이는 그룹.
  final DocsGuideGroup group;

  /// 사이트와 앱이 함께 쓰는 경로.
  String get path => '/guides/$slug';
}

/// 모든 가이드, 읽는 순서대로.
const List<DocsGuideEntry> kDocsGuides = [
  // ── 개념 ─────────────────────────────────────────────────────
  DocsGuideEntry(
    slug: 'theming',
    label: '테마',
    englishLabel: 'Theming',
    group: DocsGuideGroup.concepts,
  ),
  DocsGuideEntry(
    slug: 'surface-styles',
    label: '서페이스 스타일',
    englishLabel: 'Surface styles',
    group: DocsGuideGroup.concepts,
  ),
  DocsGuideEntry(
    slug: 'cross-platform',
    label: '크로스 플랫폼',
    englishLabel: 'Cross-platform',
    group: DocsGuideGroup.concepts,
  ),
  DocsGuideEntry(
    slug: 'state',
    label: '상태 제어',
    englishLabel: 'State control',
    group: DocsGuideGroup.concepts,
  ),
  DocsGuideEntry(
    slug: 'glossary',
    label: '용어 풀이',
    englishLabel: 'Glossary',
    group: DocsGuideGroup.concepts,
  ),
  // ── 파운데이션 ───────────────────────────────────────────────
  DocsGuideEntry(
    slug: 'colors',
    label: '색상',
    englishLabel: 'Colors',
    group: DocsGuideGroup.foundations,
  ),
  DocsGuideEntry(
    slug: 'typography',
    label: '타이포그래피',
    englishLabel: 'Typography',
    group: DocsGuideGroup.foundations,
  ),
  DocsGuideEntry(
    slug: 'icons',
    label: '아이콘',
    englishLabel: 'Icons',
    group: DocsGuideGroup.foundations,
  ),
  DocsGuideEntry(
    slug: 'layout',
    label: '레이아웃',
    englishLabel: 'Layout',
    group: DocsGuideGroup.foundations,
  ),
  DocsGuideEntry(
    slug: 'shape',
    label: '모양',
    englishLabel: 'Shape',
    group: DocsGuideGroup.foundations,
  ),
  DocsGuideEntry(
    slug: 'effect',
    label: '그림자와 효과',
    englishLabel: 'Shadows and effects',
    group: DocsGuideGroup.foundations,
  ),
  DocsGuideEntry(
    slug: 'animation',
    label: '모션',
    englishLabel: 'Motion',
    group: DocsGuideGroup.foundations,
  ),
  DocsGuideEntry(
    slug: 'layering',
    label: '레이어',
    englishLabel: 'Layers',
    group: DocsGuideGroup.foundations,
  ),
  // ── 도구 ─────────────────────────────────────────────────────
  DocsGuideEntry(
    slug: 'figma-library',
    label: 'Figma 라이브러리',
    englishLabel: 'Figma library',
    group: DocsGuideGroup.tools,
  ),
  DocsGuideEntry(
    slug: 'mcp',
    label: 'AI · MCP',
    englishLabel: 'MCP server',
    group: DocsGuideGroup.tools,
  ),
  // ── 기준 ─────────────────────────────────────────────────────
  DocsGuideEntry(
    slug: 'design-sources',
    label: '설계 문서 기준',
    englishLabel: 'Design sources',
    group: DocsGuideGroup.standards,
  ),
];

/// 가이드였다가 다른 페이지로 합쳐진 경로.
///
/// 키는 옛 URL, 값은 그 내용을 넘겨받은 페이지다. 설치 가이드는 빠른 시작에
/// 합쳐졌다 — 밖에 퍼진 링크가 죽지 않게 옛 주소를 새 주소에 붙인다.
const Map<String, String> kDocsMovedGuidePaths = {
  '/guides/installation': '/getting-started',
};

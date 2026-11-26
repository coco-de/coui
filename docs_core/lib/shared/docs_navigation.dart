/// 문서 사이트의 구조 — 탭 다섯과 그 아래 그룹 · 페이지. **단일 출처**.
///
/// 헤더의 탭, 탭마다 다른 사이드바, 페이지 머리의 경로 표시, 이전 · 다음
/// 페이저, 검색 인덱스, `llms.txt`, 네이티브 문서 앱의 사이드바가 전부 이
/// 파일 하나에서 나온다. 순수 Dart 라(jaspr · Flutter import 없음) jaspr
/// 사이트와 네이티브 앱이 같은 구조를 읽는다.
///
/// ## 왜 한 곳인가
///
/// 이 표면들은 같은 목록의 사본이 아니라 하나의 구조를 다르게 그린 것이다.
/// 사본으로 두면 페이지 하나를 옮길 때 손 편집이 표면 수만큼 필요하고,
/// 언젠가는 한 곳을 빠뜨려 "사이드바에는 있는데 페이저는 건너뛰는" 페이지가
/// 생긴다.
///
/// ## 무엇이 여기 적히고 무엇이 파생되나
///
/// 탭과 그룹의 이름 · 순서, 그리고 카탈로그에 없는 최상위 페이지(개요 ·
/// 빠른 시작 · 디자인 토큰 …)는 여기 적는다. 가이드 · 블록 · 컴포넌트는
/// 각자의 카탈로그에서 읽는다 — 가이드가 어느 그룹에 놓이는지도 가이드
/// 카탈로그가 말한다([DocsGuideEntry.group]).
///
/// 순서는 의미가 있다. 탭 → 그룹 → 페이지를 차례로 편 순서가 곧 페이저의
/// 이전 · 다음이다.
library;

import 'block_catalog.dart';
import 'component_catalog.dart';
import 'guide_catalog.dart';

/// 구조 안의 한 페이지.
class DocsNavPage {
  /// 페이지 하나를 만든다.
  const DocsNavPage({
    required this.label,
    required this.path,
    required this.englishLabel,
    this.englishDescription,
    this.searchLabel,
    this.keywords = const [],
    this.deprecated = false,
  });

  /// 사이드바 · 페이저에 보이는 이름.
  final String label;

  /// 검색 결과에 보이는 이름. 없으면 [label].
  ///
  /// 사이드바에서는 탭이 문맥을 주므로 "전체 보기" 로 충분하지만, 검색
  /// 결과는 탭 밖에서 읽힌다 — 같은 이름이 둘이면 서로를 가릴 수 없다.
  final String? searchLabel;

  /// 사이트와 앱이 함께 쓰는 경로.
  final String path;

  /// AI 표면(`llms.txt`)에 싣는 영문 이름.
  final String englishLabel;

  /// AI 표면에 싣는 영문 한 줄 요약. 없으면 이름만 나간다.
  final String? englishDescription;

  /// 검색에서 이 페이지를 찾게 하는 낱말 — 화면에는 나오지 않는다.
  final List<String> keywords;

  /// 문서화된 대상이 deprecated 인가 — 컴포넌트 카탈로그에서 온다.
  final bool deprecated;
}

/// 사이드바의 한 묶음 — 제목과 그 아래 페이지들.
class DocsNavGroup {
  /// 그룹 하나를 만든다.
  const DocsNavGroup({required this.title, required this.pages});

  /// 사이드바에 보이는 그룹 제목.
  final String title;

  /// 이 그룹의 페이지, 읽는 순서대로.
  final List<DocsNavPage> pages;
}

/// 헤더의 탭 하나 — 사이드바가 보여 주는 범위.
class DocsNavTab {
  /// 탭 하나를 만든다.
  const DocsNavTab({
    required this.id,
    required this.label,
    required this.koreanLabel,
    required this.summary,
    required this.groups,
  });

  /// 마크업과 스타일이 이 탭을 집는 이름 (예: `getting-started`).
  final String id;

  /// 헤더에 보이는 이름.
  final String label;

  /// 이 탭의 한국어 이름.
  ///
  /// 그룹 제목이 이 이름과 같으면 그 그룹은 탭 자신을 대표하는 묶음이다 —
  /// 페이지 머리의 경로 표시가 탭 이름만 적고 그룹을 다시 적지 않는다
  /// ([DocsNavLocation.trail]).
  final String koreanLabel;

  /// 이 탭이 무엇을 담는지 한 줄.
  final String summary;

  /// 사이드바의 그룹들.
  final List<DocsNavGroup> groups;

  /// 탭을 눌렀을 때 가는 곳 — 첫 그룹의 첫 페이지.
  String get path => groups.first.pages.first.path;

  /// 이 탭의 모든 페이지, 읽는 순서대로.
  Iterable<DocsNavPage> get pages => groups.expand((group) => group.pages);
}

/// 한 경로가 구조 안에서 놓인 자리.
class DocsNavLocation {
  /// 자리 하나를 만든다.
  const DocsNavLocation({
    required this.tab,
    required this.group,
    required this.page,
    this.previous,
    this.next,
  });

  /// 이 페이지가 속한 탭.
  final DocsNavTab tab;

  /// 이 페이지가 속한 그룹.
  final DocsNavGroup group;

  /// 페이지 자신.
  final DocsNavPage page;

  /// 읽는 순서로 바로 앞 페이지. 첫 페이지면 없다.
  final DocsNavPage? previous;

  /// 읽는 순서로 바로 다음 페이지. 마지막 페이지면 없다.
  final DocsNavPage? next;

  /// 페이지 머리에 적는 경로 — 탭, 그리고 탭을 대표하지 않는 그룹이면 그룹.
  ///
  /// `Getting Started` 탭의 "시작하기" 그룹은 탭 자신이라 `Getting Started`
  /// 로 끝나고, "개념" 그룹은 `Getting Started / 개념` 이 된다.
  List<String> get trail => [
    tab.label,
    if (group.title != tab.koreanLabel) group.title,
  ];
}

// ── 카탈로그에 없는 최상위 페이지 ────────────────────────────────

/// 개요 — 문서의 첫 페이지.
const DocsNavPage kDocsOverviewPage = DocsNavPage(
  label: '개요',
  path: '/overview',
  englishLabel: 'Overview',
  englishDescription: 'What CoUI does and how these docs are organized',
  keywords: ['소개', '문서 구성', 'overview', 'introduction'],
);

/// 빠른 시작 — 설치부터 첫 컴포넌트까지.
const DocsNavPage kDocsQuickStartPage = DocsNavPage(
  label: '빠른 시작',
  path: '/getting-started',
  englishLabel: 'Quick start',
  englishDescription: 'Install CoUI, wrap the app root and render a first component',
  keywords: [
    '설치',
    '시작',
    '시작하기',
    'getting started',
    'installation',
    'install',
    'quick start',
  ],
);

/// 설계 원칙.
const DocsNavPage kDocsPrinciplesPage = DocsNavPage(
  label: '설계 원칙',
  path: '/principles',
  englishLabel: 'Design principles',
  englishDescription: 'Why the API is shaped the way it is, and what that changes in your code',
  keywords: ['원칙', 'principles', 'api'],
);

/// 접근성.
const DocsNavPage kDocsAccessibilityPage = DocsNavPage(
  label: '접근성',
  path: '/accessibility',
  englishLabel: 'Accessibility',
  englishDescription:
      'What CoUI guarantees across every component, and where each '
      'component documents its own behavior',
  keywords: ['키보드', '스크린 리더', 'accessibility', 'a11y'],
);

/// 디자인 토큰 — 파운데이션의 입구.
const DocsNavPage kDocsTokensPage = DocsNavPage(
  label: '디자인 토큰',
  path: '/tokens/overview',
  englishLabel: 'Design tokens',
  englishDescription:
      'Shared coui_core tokens: color, typography, spacing, shape, '
      'effects, layering and motion',
  keywords: ['색상', '간격', '타이포그래피', 'design tokens', 'tokens'],
);

/// 컴포넌트 전체 보기.
const DocsNavPage kDocsComponentsOverviewPage = DocsNavPage(
  label: '전체 보기',
  path: '/components-overview',
  englishLabel: 'All components',
  englishDescription: 'Every component, grouped by category',
  searchLabel: '컴포넌트 전체 보기',
  keywords: ['컴포넌트', '카탈로그', 'components', 'catalog'],
);

/// 블록 전체 보기.
const DocsNavPage kDocsBlocksOverviewPage = DocsNavPage(
  label: '전체 보기',
  path: '/blocks',
  englishLabel: 'All blocks',
  englishDescription: 'Page-section shells composed from components',
  searchLabel: '블록 전체 보기',
  keywords: ['블록', 'blocks'],
);

/// 기여 가이드.
const DocsNavPage kDocsContributingPage = DocsNavPage(
  label: '기여 가이드',
  path: '/contributing',
  englishLabel: 'Contributing',
  englishDescription: 'How to propose and land a change',
  keywords: ['기여', 'contributing', 'pull request'],
);

/// Changelog.
const DocsNavPage kDocsChangelogPage = DocsNavPage(
  label: 'Changelog',
  path: '/changelog',
  englishLabel: 'Changelog',
  englishDescription: 'Release notes for each package',
  keywords: ['변경 내역', '릴리스', 'release notes', 'version'],
);

// ── 구조 ─────────────────────────────────────────────────────────

/// 한 그룹에 놓인 가이드들 — 카탈로그 순서대로.
List<DocsNavPage> _guides(DocsGuideGroup group) => [
  for (final guide in kDocsGuides)
    if (guide.group == group)
      DocsNavPage(
        label: guide.label,
        path: guide.path,
        englishLabel: guide.englishLabel,
        keywords: [guide.englishLabel, guide.slug],
      ),
];

/// 사이트의 탭 다섯, 헤더에 놓이는 순서대로.
final List<DocsNavTab> kDocsNavTabs = List.unmodifiable([
  DocsNavTab(
    id: 'getting-started',
    label: 'Getting Started',
    koreanLabel: '시작하기',
    summary: '사용 준비와 개념',
    groups: [
      const DocsNavGroup(
        title: '시작하기',
        pages: [
          kDocsOverviewPage,
          kDocsQuickStartPage,
          kDocsPrinciplesPage,
          kDocsAccessibilityPage,
        ],
      ),
      DocsNavGroup(title: '개념', pages: _guides(DocsGuideGroup.concepts)),
    ],
  ),
  DocsNavTab(
    id: 'foundations',
    label: 'Foundations',
    koreanLabel: '파운데이션',
    summary: '값의 정의',
    groups: [
      DocsNavGroup(
        title: '파운데이션',
        pages: [kDocsTokensPage, ..._guides(DocsGuideGroup.foundations)],
      ),
    ],
  ),
  DocsNavTab(
    id: 'components',
    label: 'Components',
    koreanLabel: '컴포넌트',
    summary: '카테고리별 문서',
    groups: [
      const DocsNavGroup(title: '컴포넌트', pages: [kDocsComponentsOverviewPage]),
      for (final group in kDocsComponentGroups)
        DocsNavGroup(
          title: group.title,
          pages: [
            for (final entry in group.items)
              DocsNavPage(
                label: entry.name,
                path: '/components/${entry.slug}',
                englishLabel: entry.name,
                englishDescription: entry.llmsSummary,
                deprecated: entry.isDeprecated,
              ),
          ],
        ),
    ],
  ),
  DocsNavTab(
    id: 'blocks',
    label: 'Blocks',
    koreanLabel: '블록',
    summary: '조합 단위',
    groups: [
      DocsNavGroup(
        title: '블록',
        pages: [
          kDocsBlocksOverviewPage,
          for (final block in kDocsBlocks)
            DocsNavPage(
              label: block.name,
              path: block.path,
              englishLabel: block.name,
              englishDescription: block.llmsSummary,
              keywords: [block.description, block.slug],
            ),
        ],
      ),
    ],
  ),
  DocsNavTab(
    id: 'resources',
    label: 'Resources',
    koreanLabel: '리소스',
    summary: '도구와 기준, 업데이트',
    groups: [
      DocsNavGroup(title: '도구', pages: _guides(DocsGuideGroup.tools)),
      DocsNavGroup(
        title: '기준',
        pages: [..._guides(DocsGuideGroup.standards), kDocsContributingPage],
      ),
      const DocsNavGroup(title: '업데이트', pages: [kDocsChangelogPage]),
    ],
  ),
]);

/// 다른 페이지로 옮겨진 경로 — 옛 URL → 지금의 URL.
///
/// 사이트와 앱이 이 맵으로 옛 주소를 새 주소에 붙인다.
const Map<String, String> kDocsMovedPaths = {
  ...kDocsMovedBlockPaths,
  ...kDocsMovedGuidePaths,
};

/// 끝의 `/` 를 뗀 경로. 루트(`/`)는 그대로 둔다.
String _normalized(String path) => path.length > 1 && path.endsWith('/') ? path.substring(0, path.length - 1) : path;

/// 모든 페이지를 읽는 순서로 편 것 — 자리 정보와 함께.
final List<DocsNavLocation> kDocsNavLocations = _locations();

List<DocsNavLocation> _locations() {
  final flat = <({DocsNavTab tab, DocsNavGroup group, DocsNavPage page})>[
    for (final tab in kDocsNavTabs)
      for (final group in tab.groups)
        for (final page in group.pages) (tab: tab, group: group, page: page),
  ];

  return List.unmodifiable([
    for (final (index, entry) in flat.indexed)
      DocsNavLocation(
        tab: entry.tab,
        group: entry.group,
        page: entry.page,
        previous: index == 0 ? null : flat[index - 1].page,
        next: index == flat.length - 1 ? null : flat[index + 1].page,
      ),
  ]);
}

/// [path] 가 구조 안에서 놓인 자리. 구조에 없는 경로면 `null`.
DocsNavLocation? docsNavLocate(String path) {
  final target = _normalized(path);
  for (final location in kDocsNavLocations) {
    if (location.page.path == target) return location;
  }

  return null;
}

/// [path] 가 속한 탭. 구조에 없는 경로는 경로의 머리로 짐작한다.
///
/// 구조에 없는 페이지(실험 페이지 · 옛 주소)도 사이드바는 그려야 한다.
/// 그때는 같은 디렉터리의 페이지들이 사는 탭을 고르고, 그것도 없으면 첫
/// 탭이다.
DocsNavTab docsNavTabFor(String path) {
  final located = docsNavLocate(path);
  if (located != null) return located.tab;

  final target = _normalized(path);
  final head = target.split('/').where((segment) => segment.isNotEmpty).firstOrNull;
  if (head != null) {
    for (final tab in kDocsNavTabs) {
      if (tab.pages.any((page) => page.path.startsWith('/$head/') || page.path == '/$head')) return tab;
    }
  }

  return kDocsNavTabs.first;
}

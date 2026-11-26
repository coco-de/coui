/// 문서 검색 팔레트가 쓰는 인덱스 — **단일 출처**.
///
/// docs_app(Flutter, `app/docs_app/lib/src/search/docs_search.dart`)의
/// `CoreCommandGroup`/`CoreCommandItem` 구성 로직을 여기로 끌어올렸다. 순수
/// Dart 다(jaspr/Flutter 어느 쪽도 import 하지 않는다) — `component_catalog.dart`
/// 와 마찬가지로 docs_site 와 docs_app 양쪽이 같은 인덱스를 읽어야, 검색
/// 결과 목록이 갈라지지 않는다.
///
/// `CoreCommandGroup<W>`/`CoreCommandItem<W>` 로 바로 만들지 않는 이유:
/// 그 타입들의 `W`(위젯 타입, Flutter `Widget` / Web `Component`)는
/// 플랫폼마다 다르다. 이 파일은 플랫폼-무관 중간 표현만 만들고, 각 플랫폼
/// 위젯이 `CoreCommandItem<W>(value: item.value, label: item.label)` 로
/// 감싼다.
library;

import 'block_catalog.dart';
import 'component_catalog.dart';
import 'docs_navigation.dart';

/// 검색 결과 한 줄.
class DocsSearchItem {
  /// 항목을 만든다.
  const DocsSearchItem({required this.value, required this.label, this.keywords = const []});

  /// 선택 시 `onSelect` 로 보고되는 값 — 카탈로그 슬러그 또는 가이드 경로.
  final String value;

  /// 표시 라벨. deprecated 항목은 사이드바(#3580)와 같은 형식
  /// (`'$name · Deprecated'`)으로 시각적으로 분리된다 — 검색 결과에서도
  /// Active/Deprecated 가 구분돼야 사용자가 대체품을 찾아 헤매지 않는다.
  final String label;

  /// Searchable descriptions and aliases, not displayed in the result.
  final List<String> keywords;
}

/// 이름(제목) + [DocsSearchItem] 묶음.
class DocsSearchGroup {
  /// 그룹을 만든다.
  const DocsSearchGroup({required this.heading, required this.items});

  /// 그룹 제목 (컴포넌트 카탈로그 그룹의 [DocsComponentGroup.title]).
  final String heading;

  /// 이 그룹에 속한 검색 결과.
  final List<DocsSearchItem> items;
}

/// 검색에서 고른 슬러그의 문서 경로.
///
/// 가이드 경로는 그대로, 블록은 `/blocks/<slug>`, 컴포넌트는
/// `/components/<slug>`. 선택 값이
/// 슬러그로 남는 이유: 두 사이트의 `Command.onSelect` 가 문자열 하나만
/// 받고, 블록과 컴포넌트가 같은 슬러그를 쓰지 않는다.
String docsSearchPath(String slug) {
  if (slug.startsWith('/')) return slug;
  for (final block in kDocsBlocks) {
    if (block.slug == slug) return block.path;
  }
  return '/components/$slug';
}

/// 사이트 구조([kDocsNavTabs])에서 검색 인덱스를 만든다.
///
/// 그룹은 탭 하나씩이다 — 컴포넌트 탭만 카테고리마다 그룹으로 편다. 블록과
/// 컴포넌트의 값은 슬러그이고([docsSearchPath] 가 경로로 바꾼다), 그 밖의
/// 페이지는 경로 그대로다.
///
/// 매 호출마다 구조를 다시 읽는다 — 캐싱하지 않는다. 카탈로그는 컴파일타임
/// 상수라 재계산 비용이 무의미하고, 캐싱은 (아직 없는) 런타임 카탈로그
/// 변경 시나리오를 위한 조기 최적화일 뿐이다.
List<DocsSearchGroup> buildDocsSearchIndex() {
  final blockPaths = {for (final block in kDocsBlocks) block.path: block};

  return [
    for (final tab in kDocsNavTabs)
      if (tab.id == 'components') ...[
        DocsSearchGroup(
          heading: tab.label,
          items: [_pageItem(kDocsComponentsOverviewPage)],
        ),
        for (final group in kDocsComponentGroups)
          DocsSearchGroup(
            heading: group.title,
            items: [
              for (final entry in group.items)
                DocsSearchItem(
                  value: entry.slug,
                  label: entry.isDeprecated ? '${entry.name} · Deprecated' : entry.name,
                  keywords: docsComponentSearchTerms(entry),
                ),
            ],
          ),
      ] else
        DocsSearchGroup(
          heading: tab.label,
          items: [
            for (final page in tab.pages)
              if (blockPaths[page.path] case final block?)
                DocsSearchItem(value: block.slug, label: block.name, keywords: [block.description, block.slug])
              else
                _pageItem(page),
          ],
        ),
  ];
}

/// 구조의 한 페이지 → 검색 결과 한 줄. 값은 경로다.
DocsSearchItem _pageItem(DocsNavPage page) => DocsSearchItem(
  value: page.path,
  label: page.searchLabel ?? page.label,
  keywords: [page.englishLabel, ...page.keywords],
);

/// Shared vocabulary for the command palette and the catalog filter.
List<String> docsComponentSearchTerms(DocsComponentEntry entry) => [
  entry.slug,
  entry.description,
  entry.name.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}'),
  ...entry.searchKeywords,
];

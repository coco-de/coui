/// CoUI 문서의 블록 카탈로그 — 마케팅 레이아웃 셸.
///
/// 컴포넌트 카탈로그와 분리한다. 블록은 프리미티브가 아니라 페이지 구간의
/// 껍질이다. 순수 Dart 라 jaspr 사이트와 네이티브 문서 앱이 같은 목록을 읽는다.
library;

/// 카탈로그의 한 블록.
class DocsBlockEntry {
  /// 이 블록을 만든다.
  const DocsBlockEntry({
    required this.slug,
    required this.name,
    required this.description,
    required this.layouts,
    this.layoutEnum,
    this.englishDescription,
  });

  /// 문서 URL 세그먼트이자 `content/blocks/<slug>.md` 파일명.
  final String slug;

  /// 사이드바에 보이는 이름.
  final String name;

  /// 개요 카드의 한 줄 설명.
  final String description;

  /// 블록의 `Layout` 축 값, 읽는 순서대로 — 코드의 레이아웃 enum 멤버 이름과
  /// 같다(Hero 는 `CoreHeroLayout`, Footer 는 `CoreFooterLayout`).
  ///
  /// 개요의 이름표와 블록 페이지의 레이아웃 그림 · 목록이 이 목록을 읽는다 —
  /// 사이트와 앱이 같은 값을 그린다.
  final List<String> layouts;

  /// 레이아웃 이름 앞에 붙여 부르는 enum 이름 — 있으면 블록 페이지의 레이아웃
  /// 이름표가 `CoreHeroLayout.center` 처럼 적힌다. 없으면 값만 적는다.
  final String? layoutEnum;

  /// AI 표면(`llms.txt`)용 영문 한 줄. [description] 이 한글일 때만 둔다.
  final String? englishDescription;

  /// 사이트와 앱이 함께 쓰는 경로.
  String get path => '/blocks/$slug';

  /// AI 표면이 쓰는 영문 한 줄 — [englishDescription] 이 있으면 그것.
  String get llmsSummary => englishDescription ?? description;

  /// 레이아웃 [layout] 의 이름표 — [layoutEnum] 이 있으면 그 이름을 앞에 붙인다.
  String layoutLabel(String layout) => layoutEnum == null ? layout : '$layoutEnum.$layout';
}

/// Footer 구조 그림의 범례 — 세로로 쌓이는 세 블록과 그 블록을 채우는 속성.
const List<({String label, String slots})> kDocsFooterStructure = [
  (label: '상단 구분선', slots: 'showDivider'),
  (label: '내비게이션 밴드', slots: 'aside + sections'),
  (label: '법적 고지', slots: 'company, links, copyright'),
];

/// 문서화된 블록, 읽는 순서대로.
///
/// [Hero] 다음이 [Footer] 다. 다른 마케팅 셸(프루프 스트립 등)은 후속이다.
const List<DocsBlockEntry> kDocsBlocks = [
  DocsBlockEntry(
    slug: 'hero',
    name: 'Hero',
    description: '페이지 맨 위의 히어로. 카피와 미디어를 배치합니다.',
    layouts: ['center', 'split'],
    layoutEnum: 'CoreHeroLayout',
    englishDescription: 'The hero at the top of a page. Centered copy, or copy and media side by side.',
  ),
  DocsBlockEntry(
    slug: 'footer',
    name: 'Footer',
    description: '페이지 맨 아래의 푸터입니다.',
    layouts: ['horizontal', 'vertical', 'center'],
    englishDescription: 'The footer at the bottom of a page, with nav sections & a legal block',
  ),
];

/// 컴포넌트 문서에 있다가 블록으로 옮겨진 경로.
///
/// 키는 옛 URL, 값은 블록 페이지다. 클래스 이름은 그대로다 — 주소만
/// 바뀐다. docs_site 와 docs_app 이 이 맵으로 `/components/footer` 를
/// `/blocks/footer` 에 붙인다.
const Map<String, String> kDocsMovedBlockPaths = {
  '/components/footer': '/blocks/footer',
};

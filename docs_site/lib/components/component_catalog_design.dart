import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_core/shared/component_source_links.dart';
import 'package:docs_core/shared/docs_navigation.dart';

// Family names, previews, and utility rows follow the DocSite Figma catalog.
const _families = {
  "control": (
    description: "버튼, 토글처럼 누르고 바꾸는 컨트롤",
    cards: [
      (slug: "button", description: "행동을 실행하는 버튼과 떠 있는 버튼", stage: "fit", children: <String>["fab"]),
      (slug: "command", description: "명령을 검색하고 실행하는 목록", stage: "bleed", children: <String>["command-search"]),
      (slug: "theme-controller", description: "라이트, 다크 테마 전환", stage: "fit", children: <String>[]),
      (slug: "filter", description: "조건을 골라 목록을 거르는 칩", stage: "fit", children: <String>[]),
      (slug: "toggle-group", description: "여러 토글을 하나로 묶은 그룹", stage: "fit", children: <String>[]),
    ],
  ),
  "form": (
    description: "값을 입력하고 고르고 검증하는 요소",
    cards: [
      (
        slug: "text-field",
        description: "텍스트와 형식이 정해진 값을 입력하는 필드",
        stage: "fit",
        children: <String>[
          "text-area",
          "formatted-input",
          "phone-input",
          "number-input",
          "object-input",
          "chip-input",
          "input-otp",
        ],
      ),
      (slug: "rich-editor", description: "서식을 넣을 수 있는 편집기", stage: "bleed", children: <String>[]),
      (
        slug: "select",
        description: "목록에서 값을 찾아 고르는 입력",
        stage: "fit",
        children: <String>["autocomplete", "item-picker"],
      ),
      (
        slug: "checkbox",
        description: "켜고 끄거나 하나를 고르는 선택",
        stage: "fit",
        children: <String>["radio-group", "toggle", "switch-field"],
      ),
      (slug: "slider", description: "막대를 끌어 값이나 범위 선택", stage: "fit", children: <String>["range"]),
      (slug: "date-picker", description: "날짜와 시간 선택", stage: "fit", children: <String>["time-picker"]),
      (slug: "color-picker", description: "색을 고르는 팔레트", stage: "fit", children: <String>[]),
      (slug: "multiple-choice", description: "보기 중에서 답 고르기", stage: "fit", children: <String>["multi-answer-card"]),
      (slug: "star-rating", description: "별점으로 평가", stage: "fit", children: <String>[]),
      (slug: "option-list", description: "선택 항목을 모은 목록", stage: "bleed", children: <String>["option-item"]),
      (slug: "bottom-sheet", description: "아래에서 올라오는 시트", stage: "edge", children: <String>[]),
      (slug: "sortable", description: "끌어서 순서 바꾸기", stage: "fit", children: <String>[]),
      (slug: "file-input", description: "파일을 끌어 놓거나 골라 올리기", stage: "fit", children: <String>[]),
      (
        slug: "form",
        description: "입력 항목을 묶고 라벨, 도움말, 검증을 붙이는 폼",
        stage: "fit",
        children: <String>["form-field", "form-label", "fieldset", "validator-hint"],
      ),
    ],
  ),
  "display": (
    description: "정보와 상태를 보여 주는 요소",
    cards: [
      (slug: "avatar", description: "사람이나 팀을 나타내는 이미지", stage: "fit", children: <String>[]),
      (
        slug: "badge",
        description: "개수, 상태, 검사 결과를 알리는 표시",
        stage: "fit",
        children: <String>["disclosure-badge", "validation-badge", "indicator"],
      ),
      (slug: "tag", description: "분류나 속성을 붙이는 라벨", stage: "fit", children: <String>["label"]),
      (slug: "progress", description: "진행 정도를 보여 주는 막대", stage: "fit", children: <String>[]),
      (slug: "calendar", description: "날짜를 한눈에 보는 달력", stage: "bleed", children: <String>[]),
      (slug: "banner", description: "화면 위쪽의 안내 띠", stage: "fit", children: <String>[]),
      (
        slug: "carousel",
        description: "여러 콘텐츠를 넘기거나 펼쳐 보는 영역",
        stage: "fit",
        children: <String>["carousel-banner", "hover-gallery"],
      ),
      (slug: "chat", description: "대화 말풍선 목록", stage: "fit", children: <String>[]),
      (slug: "chip", description: "값이나 필터를 나타내는 칩", stage: "fit", children: <String>["chip-group"]),
      (slug: "code-snippet", description: "코드 한 줄부터 변경 비교까지", stage: "fit", children: <String>["code-diff", "diff"]),
      (slug: "divider", description: "영역을 나누는 선", stage: "fit", children: <String>[]),
      (slug: "dot-indicator", description: "현재 위치를 점으로 표시", stage: "fit", children: <String>[]),
      (slug: "empty-state", description: "내용이 없을 때의 안내", stage: "fit", children: <String>[]),
      (slug: "kbd", description: "키보드 단축키 표시", stage: "fit", children: <String>[]),
      (slug: "number-ticker", description: "바뀌는 숫자와 남은 시간 표시", stage: "fit", children: <String>["countdown"]),
      (
        slug: "stat",
        description: "수치, 추이, 비율을 보여 주는 데이터 표시",
        stage: "fit",
        children: <String>["trend-chart", "category-breakdown", "tracker"],
      ),
      (slug: "status", description: "진행 상태를 알리는 라벨", stage: "fit", children: <String>[]),
      (slug: "description-card", description: "이름과 값을 나란히 보여 주는 요약 카드", stage: "fit", children: <String>[]),
      (
        slug: "loading",
        description: "불러오는 중 표시와 자리 표시",
        stage: "fit",
        children: <String>["loading-region", "skeleton"],
      ),
      (
        slug: "mockup",
        description: "브라우저, 코드, 기기 목업",
        stage: "fit",
        children: <String>["mockup-browser", "mockup-code", "mockup-device", "mockup-foldable"],
      ),
      (slug: "timeline", description: "시간 순서로 놓인 기록", stage: "fit", children: <String>[]),
    ],
  ),
  "layout": (
    description: "화면을 나누고 쌓고 펼치는 구조",
    cards: [
      (slug: "accordion", description: "내용을 접고 펴는 영역", stage: "bleed", children: <String>["collapsible", "disclosure"]),
      (slug: "card", description: "관련 내용을 묶은 카드", stage: "fit", children: <String>["card-image"]),
      (slug: "table", description: "행과 열로 정리한 데이터", stage: "bleed", children: <String>[]),
      (slug: "stepper", description: "단계 진행을 가로, 세로로 표시", stage: "fit", children: <String>["steps", "step-item"]),
      (slug: "tree", description: "계층 구조를 펼쳐 보는 목록", stage: "fit", children: <String>[]),
      (slug: "resizable", description: "경계를 끌어 크기 조절", stage: "fit", children: <String>[]),
      (slug: "overflow-marquee", description: "넘치는 글을 흘려 보여 주기", stage: "fit", children: <String>[]),
      (
        slug: "window",
        description: "제목 막대가 있는 창과 떠 있는 패널",
        stage: "fit",
        children: <String>["window-panel", "draggable-panel"],
      ),
      (slug: "join", description: "입력과 버튼을 붙인 묶음", stage: "fit", children: <String>[]),
      (slug: "listing", description: "김하나", stage: "fit", children: <String>["basic", "swipe-actions"]),
      (slug: "page-header", description: "페이지와 패널의 제목, 동작", stage: "fit", children: <String>["panel-header"]),
      (slug: "bottom-action-bar", description: "화면 아래 고정된 동작 막대", stage: "edge", children: <String>[]),
    ],
  ),
  "navigation": (
    description: "화면 사이를 오가는 길잡이",
    cards: [
      (slug: "app-bar", description: "화면 위 제목과 동작 막대", stage: "fit", children: <String>[]),
      (slug: "dock", description: "자주 쓰는 앱을 모은 막대", stage: "fit", children: <String>[]),
      (slug: "tabs", description: "같은 층의 화면 전환", stage: "fit", children: <String>["tab-pane"]),
      (slug: "navigation-bar", description: "화면 아래 주요 메뉴", stage: "edge", children: <String>["navigation-bar-item"]),
      (slug: "sidebar", description: "옆에 놓인 메뉴 목록", stage: "bleed", children: <String>[]),
      (slug: "breadcrumb", description: "현재 위치까지의 경로", stage: "fit", children: <String>[]),
      (slug: "pagination", description: "페이지 번호 이동", stage: "fit", children: <String>[]),
      (slug: "switcher", description: "작업 공간이나 계정 전환", stage: "fit", children: <String>["indexed-switcher"]),
    ],
  ),
  "menu": (
    description: "명령과 선택지를 모아 여는 목록",
    cards: [
      (
        slug: "menu",
        description: "명령을 모은 목록과 여는 방식",
        stage: "bleed",
        children: <String>["menu-item", "context-menu", "dropdown-menu"],
      ),
      (slug: "menubar", description: "앱 위쪽 메뉴 막대", stage: "bleed", children: <String>[]),
      (slug: "toolbar-group", description: "도구 버튼 묶음", stage: "fit", children: <String>[]),
      (slug: "navigation-menu", description: "큰 패널을 여는 상단 메뉴", stage: "fit", children: <String>[]),
    ],
  ),
  "overlay": (
    description: "화면 위에 잠깐 떠오르는 레이어",
    cards: [
      (slug: "dialog", description: "확인이 필요한 대화 상자", stage: "fit", children: <String>[]),
      (slug: "drawer", description: "옆에서 밀려 나오는 패널", stage: "edge", children: <String>[]),
      (slug: "popover", description: "요소에 붙어 뜨는 작은 창과 말풍선", stage: "fit", children: <String>["hover-card", "tooltip"]),
      (slug: "toast", description: "잠깐 떴다 사라지는 알림", stage: "fit", children: <String>[]),
      (slug: "swiper", description: "넘겨서 고르는 카드", stage: "fit", children: <String>[]),
      (slug: "refresh-trigger", description: "당겨서 새로고침", stage: "fit", children: <String>[]),
      (slug: "alert", description: "주의가 필요한 안내 상자", stage: "fit", children: <String>[]),
    ],
  ),
  "icon": (
    description: "Lucide 기반 아이콘",
    cards: [
      (slug: "icon", description: "Lucide 기반 아이콘 세트", stage: "fit", children: <String>[]),
    ],
  ),
  "text": (
    description: "글을 보여 주고 고르는 요소",
    cards: [
      (slug: "text-block", description: "제목과 문단, 고를 수 있는 텍스트", stage: "fit", children: <String>["selectable-text"]),
      (slug: "link", description: "다른 곳으로 이동하는 글자", stage: "fit", children: <String>[]),
      (slug: "definition-list", description: "이름과 값 목록", stage: "fit", children: <String>[]),
    ],
  ),
};

const _utilities = {
  "레이아웃 보조": {
    "stack-layout": "가로, 세로로 쌓는 배치",
    "gap": "요소 사이 간격",
    "frame": "여백과 모서리를 주는 틀",
    "stage-container": "가운데에 놓는 콘텐츠 틀",
    "scaffold": "앱 화면의 기본 뼈대",
    "aspect-ratio-box": "비율을 지키는 상자",
    "mask": "모양대로 잘라 보여 주기",
    "hidden": "조건에 따라 숨기기",
    "responsive-container": "화면 너비에 맞추는 틀",
    "responsive-grid": "너비에 따라 열 수가 바뀌는 격자",
    "responsive-row-column": "좁으면 세로로 바뀌는 행",
    "media-query": "화면 크기에 따라 다르게 그리기",
    "breakpoint": "화면 너비 구간 정의",
  },
  "상호작용": {
    "hover": "포인터를 올린 상태 감지",
    "drag": "끌어서 옮기는 기본 동작",
    "clickable": "누를 수 있는 영역",
    "swap": "두 상태를 바꿔 보여 주기",
  },
  "입력 처리": {
    "formatter": "입력 값을 형식에 맞게 변환",
    "validated": "규칙에 맞는지 검사하는 입력",
  },
  "포커스 · 스크롤 · 레이어": {
    "focus-outline": "키보드 포커스 표시",
    "subfocus": "안쪽 항목 간 포커스 이동",
    "outlined-container": "상태별 테두리 상자",
    "popup": "기준 요소에 붙어 뜨는 레이어",
    "scrollbar": "스크롤 위치 표시 막대",
    "scroll-area": "스크롤바가 붙은 영역",
    "fade-scroll": "끝이 흐려지는 스크롤 영역",
    "scrollable-client": "가로로 넘겨 보는 영역",
    "scrollview": "겹친 스크롤 제어",
  },
  "텍스트": {
    "text": "글자 스타일이 적용된 텍스트",
  },
};

typedef CatalogCard = ({
  DocsComponentEntry item,
  String description,
  String stage,
  List<DocsComponentEntry> children,
});

typedef CatalogGroup = ({String id, String title, String description, List<CatalogCard> cards});
typedef CatalogUtility = ({DocsComponentEntry item, String description});

final _components = {
  for (final group in kDocsComponentGroups)
    for (final item in group.items) item.slug: item,
};

final catalogUtilities = [
  for (final group in _utilities.entries)
    (
      title: group.key,
      items: [
        for (final row in group.value.entries)
          if (_components[row.key] case final item?) (item: item, description: row.value),
      ],
    ),
];

final _coveredSlugs = {
  for (final group in _families.values)
    for (final card in group.cards) ...[card.slug, ...card.children],
  for (final group in _utilities.values) ...group.keys,
};

/// Entries added to CoUI before they get a designed card use their catalog group.
final List<CatalogGroup> catalogGroups = [
  for (final group in kDocsComponentGroups)
    if (group.id != 'infra')
      (
        id: group.id,
        title: group.title,
        description: _families[group.id]?.description ?? group.description ?? '',
        cards: [
          for (final card in _families[group.id]?.cards ?? const [])
            if (_components[card.slug] case final item?)
              (
                item: item,
                description: card.description,
                stage: card.stage,
                children: [
                  for (final slug in card.children) ?_components[slug],
                ],
              ),
          for (final item in group.items)
            if (!_coveredSlugs.contains(item.slug))
              (item: item, description: item.description, stage: 'fit', children: <DocsComponentEntry>[]),
        ],
      ),
  (
    id: 'infra',
    title: 'Utilities',
    description: '화면 배치, 입력 제어, 포커스 이동에 쓰는 유틸리티입니다.',
    cards: [
      for (final item in kDocsComponentGroups.firstWhere((group) => group.id == 'infra').items)
        if (!_coveredSlugs.contains(item.slug))
          (item: item, description: item.description, stage: 'fit', children: <DocsComponentEntry>[]),
    ],
  ),
];

/// The two detail templates link to the catalog and to the examples shown next in Figma.
({DocsNavPage previous, DocsNavPage? next})? componentTemplatePager(DocsNavLocation location) {
  final slug = docsComponentSlugFromRoutePath(location.page.path);
  final nextSlug = switch (slug) {
    'button' => 'fab',
    'text-field' => 'select',
    _ => null,
  };
  if (nextSlug == null) return null;

  final catalog = kDocsComponentsOverviewPage;
  final previous = slug == 'text-field'
      ? DocsNavPage(
          label: '${location.group.title} ${catalog.label}',
          path: '${catalog.path}#form',
          englishLabel: 'All Form components',
        )
      : catalog;

  return (
    previous: previous,
    next: location.tab.pages.where((page) => docsComponentSlugFromRoutePath(page.path) == nextSlug).firstOrNull,
  );
}

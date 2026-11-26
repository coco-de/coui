/// CoUI 문서의 컴포넌트 카탈로그 — **단일 출처**.
///
/// 순수 Dart 다: jaspr 도 Flutter 도 import 하지 않는다. 그래서 jaspr 사이트
/// (`docs_site`) 와 네이티브 Flutter 쌍둥이 (`docs_app`) 가 **같은 목록**을
/// 읽는다. 이 파일이 생기기 전에는 같은 138개 컴포넌트가 손으로 관리되는
/// 사본 3벌 (사이드바 · 그리드 · 검색 인덱스) 로 존재했고, 컴포넌트 하나를
/// 추가할 때마다 편집이 3곳에서 필요했다.
///
/// 순서는 의미가 있다 — 알파벳이 아니라 사이드바와 개요 그리드가 보여주는
/// 큐레이션된 순서다. 재정렬하면 양쪽 UI 가 같이 바뀐다.
library;

// Deprecation 상태(`DocsDeprecationStatus`)와 그걸 담는 생성 맵
// (`kDocsDeprecationStatus`)를 여기서 재노출한다 — 이 파일을 이미 import 하는
// 모든 소비자(사이드바 · 그리드 · 검색)가 `entry.isDeprecated` 를 바로 쓸 수
// 있도록. 소스는 `component_deprecation_status.g.dart` 하나뿐이다(손 관리
// 아님 — `tool/gen_deprecation_status.dart` 가 생성).
export 'component_deprecation.dart';
export 'component_deprecation_status.g.dart';

import 'component_deprecation.dart';
import 'component_deprecation_status.g.dart';

/// 카탈로그의 한 컴포넌트.
class DocsComponentEntry {
  /// 문서 URL 세그먼트와 `content/components/<slug>.md` 파일명, 그리고 모든
  /// 프리뷰/코드 레지스트리의 키. 클래스 이름과 항상 같지는 않다 — 예를 들어
  /// `text-field` 는 `TextField`, `radio-group` 은 `RadioGroup` 이다.
  final String slug;

  /// 사람이 읽는 표시 이름 (예: `TextField`).
  final String name;

  /// 카드/검색 결과에 쓰는 한 줄 요약.
  final String description;

  /// Additional search terms, including Korean names.
  final List<String> searchKeywords;

  /// AI 표면(`llms.txt`)에 싣는 영문 한 줄 요약 — [description] 이 한글을
  /// 담을 때만 둔다.
  ///
  /// 문서 사이트는 한국어가 primary 지만 AI 소비 표면은 영문이다
  /// (`process/docs-site.md` "언어 정책"). [description] 이 이미 영문이면
  /// null 로 둔다 — 영문 요약이 두 벌이면 한쪽만 고쳐져 갈라진다.
  /// 둘 중 어느 쪽을 쓰는지는 [llmsSummary] 한 곳이 정하고,
  /// `test/registry/llms_txt_sync_test.dart` 가 한글이 섞인 [description] 에
  /// 이 필드가 빠졌거나 영문 [description] 에 중복으로 붙었는지 게이트한다.
  final String? englishDescription;

  /// 그리드 카드의 글리프. 이모지 문자열 — Web/Flutter 양쪽이 같은 문자를
  /// 그리도록 타입 있는 아이콘이 아니라 문자를 유지한다.
  final String icon;

  /// 카탈로그 엔트리를 만든다.
  const DocsComponentEntry({
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    this.englishDescription,
    this.searchKeywords = const [],
  });

  /// AI 표면이 쓰는 영문 한 줄 요약 — [englishDescription] 이 있으면 그것,
  /// 없으면 (이미 영문인) [description].
  String get llmsSummary => englishDescription ?? description;
}

/// [DocsComponentEntry] 에 deprecation 상태를 얹는다.
///
/// 필드가 아니라 extension 인 이유: `kDocsComponentGroups` 는 위 4 필드만
/// 손으로 큐레이션한 `const` 목록이고, deprecation 은 그와 별개로 소스에서
/// **파싱**된다(`kDocsDeprecationStatus`, `tool/gen_deprecation_status.dart`
/// 가 생성). 두 출처를 한 `const` 값으로 합칠 수 없으므로 — 그리고 합쳐도 안
/// 된다, 손 관리 필드와 파싱된 필드가 한 클래스에 섞이면 "이 필드는 어디서
/// 오나"가 필드마다 달라진다 — 조회 시점에 합성한다.
extension DocsComponentEntryDeprecation on DocsComponentEntry {
  /// 이 컴포넌트의 파싱된 deprecation 상태. 없으면 active.
  DocsDeprecationStatus? get deprecation => kDocsDeprecationStatus[slug];

  /// `deprecation != null` 의 sugar.
  bool get isDeprecated => deprecation != null;
}

/// 사이드바와 개요 그리드가 함께 쓰는 컴포넌트 그룹.
class DocsComponentGroup {
  /// 개요 페이지가 딥링크하는 앵커 id (예: `control`).
  final String id;

  /// 표시 제목 (예: `Control`).
  final String title;

  /// 개요 그리드에만 쓰는 선택적 그룹 설명.
  final String? description;

  /// 이 그룹의 컴포넌트들 (큐레이션된 순서).
  final List<DocsComponentEntry> items;

  /// 그룹을 만든다.
  const DocsComponentGroup({
    required this.id,
    required this.title,
    required this.items,
    this.description,
  });
}

/// 문서화된 모든 컴포넌트, 표시 순서대로 그룹핑.
const List<DocsComponentGroup> kDocsComponentGroups = [
  DocsComponentGroup(
    id: 'control',
    title: 'Control',
    description: 'Buttons, toggles, and interactive controls.',
    items: [
      DocsComponentEntry(
        name: 'Button',
        slug: 'button',
        searchKeywords: ['버튼 동작 액션 클릭'],
        description: 'Clickable button',
        icon: '\u{1F518}',
      ),
      DocsComponentEntry(
        name: 'Command',
        slug: 'command',
        searchKeywords: ['명령 명령어 검색 팔레트'],
        description: 'Command palette',
        icon: '\u{2328}',
      ),
      DocsComponentEntry(
        name: 'FAB',
        slug: 'fab',
        searchKeywords: ['플로팅 버튼 떠있는 버튼'],
        description: 'Floating action button',
        icon: '\u{2795}',
      ),
      DocsComponentEntry(
        name: 'Hover',
        slug: 'hover',
        searchKeywords: ['호버 마우스'],
        description: 'Hover effect wrapper',
        icon: '\u{1F5B1}',
      ),
      DocsComponentEntry(
        name: 'ThemeController',
        slug: 'theme-controller',
        searchKeywords: ['테마 다크 모드 라이트'],
        description: 'Theme picker swatches',
        icon: '\u{1F3A8}',
      ),
      DocsComponentEntry(
        name: 'Filter',
        slug: 'filter',
        searchKeywords: ['필터 검색 조건'],
        description: 'Segmented filter control',
        icon: '\u{1F50D}',
      ),
      DocsComponentEntry(
        name: 'ToggleGroup',
        slug: 'toggle-group',
        description: 'Grouped toggle with a raised chosen segment',
        icon: '\u{1F532}',
      ),
      DocsComponentEntry(
        name: 'CommandSearch',
        slug: 'command-search',
        description: 'Command palette trigger',
        icon: '\u{1F50E}',
      ),
    ],
  ),
  DocsComponentGroup(
    id: 'form',
    title: 'Form',
    description: 'Form inputs and data entry components.',
    items: [
      DocsComponentEntry(
        name: 'TextField',
        slug: 'text-field',
        searchKeywords: ['입력 텍스트 필드 인풋'],
        description: 'Text input field',
        icon: '\u{270F}',
      ),
      DocsComponentEntry(
        name: 'TextArea',
        slug: 'text-area',
        searchKeywords: ['여러줄 입력 텍스트 영역'],
        description: 'Multi-line text',
        icon: '\u{1F4DD}',
      ),
      DocsComponentEntry(
        name: 'RichEditor',
        slug: 'rich-editor',
        searchKeywords: ['편집기 에디터 서식 문서'],
        description: 'Markdown post / comment composer',
        icon: '\u{1F58B}',
      ),
      DocsComponentEntry(
        name: 'Select',
        slug: 'select',
        searchKeywords: ['선택 셀렉트 드롭다운'],
        description: 'Dropdown select',
        icon: '\u{1F53D}',
      ),
      DocsComponentEntry(
        name: 'Checkbox',
        slug: 'checkbox',
        searchKeywords: ['체크박스 체크 선택'],
        description: '하나 이상 선택 · 불확정 상태',
        englishDescription: 'Select one or more options, with an indeterminate state',
        icon: '\u{2611}',
      ),
      DocsComponentEntry(
        name: 'Toggle',
        slug: 'toggle',
        searchKeywords: ['토글 스위치 켜기 끄기'],
        description: 'On/off toggle',
        icon: '\u{1F504}',
      ),
      DocsComponentEntry(
        name: 'Slider',
        slug: 'slider',
        searchKeywords: ['슬라이더 범위 조절'],
        description: 'Range slider',
        icon: '\u{1F39A}',
      ),
      DocsComponentEntry(
        name: 'DatePicker',
        slug: 'date-picker',
        searchKeywords: ['날짜 선택 달력'],
        description: 'Date selector',
        icon: '\u{1F4C5}',
      ),
      DocsComponentEntry(
        name: 'TimePicker',
        slug: 'time-picker',
        searchKeywords: ['시간 선택'],
        description: '시·분·초 선택',
        englishDescription: 'Hour, minute, and second picker',
        icon: '\u{1F552}',
      ),
      DocsComponentEntry(
        name: 'ColorPicker',
        slug: 'color-picker',
        searchKeywords: ['색상 선택 컬러'],
        description: '색상 선택 · 편집',
        englishDescription: 'Pick and edit a color',
        icon: '\u{1F3A8}',
      ),
      DocsComponentEntry(
        name: 'AutoComplete',
        slug: 'autocomplete',
        searchKeywords: ['자동완성 검색'],
        description: 'Auto-suggestions',
        icon: '\u{1F50D}',
      ),
      DocsComponentEntry(
        name: 'InputOtp',
        slug: 'input-otp',
        searchKeywords: ['인증번호 일회용 비밀번호'],
        description: 'OTP input',
        icon: '\u{1F510}',
      ),
      DocsComponentEntry(
        name: 'RadioGroup',
        slug: 'radio-group',
        searchKeywords: ['라디오 단일 선택'],
        description: 'Radio selection',
        icon: '\u{1F518}',
      ),
      DocsComponentEntry(
        name: 'MultipleChoice',
        slug: 'multiple-choice',
        searchKeywords: ['객관식 다중 선택'],
        description: 'Single-select option group',
        icon: '\u{1F518}',
      ),
      DocsComponentEntry(
        name: 'StarRating',
        slug: 'star-rating',
        searchKeywords: ['별점 평점'],
        description: 'Star rating',
        icon: '\u{2B50}',
      ),
      DocsComponentEntry(
        name: 'Range',
        slug: 'range',
        searchKeywords: ['범위 구간'],
        description: 'Dual-handle range slider',
        icon: '\u{2194}',
      ),
      DocsComponentEntry(
        name: 'ItemPicker',
        slug: 'item-picker',
        searchKeywords: ['항목 선택'],
        description: 'Searchable item picker',
        icon: '\u{1F50D}',
      ),
      DocsComponentEntry(
        name: 'MultiAnswerCard',
        slug: 'multi-answer-card',
        searchKeywords: ['다중 답변 카드'],
        description: 'Selectable answer card',
        icon: '\u{2705}',
      ),
      DocsComponentEntry(
        name: 'OptionItem',
        slug: 'option-item',
        description: '선택지 한 줄 — 단일 선택은 체크, 다중 선택은 체크박스',
        englishDescription: 'One choosable row of a list of options — a check for single, a checkbox for multiple',
        icon: '\u{2611}',
      ),
      DocsComponentEntry(
        name: 'OptionList',
        slug: 'option-list',
        description: '선택지 목록 — OptionItem 을 세로로 쌓는 묶음',
        englishDescription: 'Option list — OptionItems stacked in one column',
        icon: '\u{1F4CB}',
      ),
      DocsComponentEntry(
        name: 'BottomSheet',
        slug: 'bottom-sheet',
        description: '모바일 화면 아래에서 올라오는 패널 — 손잡이 · 제목 · 내용 · 하단 바',
        englishDescription:
            'Bottom sheet — the panel that rises from the bottom of a phone screen: handle, title, content and a bottom bar',
        icon: '\u{1F4F1}',
      ),
      DocsComponentEntry(
        name: 'FormattedInput',
        slug: 'formatted-input',
        searchKeywords: ['형식 입력 마스크'],
        description: 'Masked / segmented input',
        icon: '\u{1F522}',
      ),
      DocsComponentEntry(
        name: 'NumberInput',
        slug: 'number-input',
        searchKeywords: ['숫자 입력'],
        description: 'Stepper-style number field',
        icon: '\u{2795}',
      ),
      DocsComponentEntry(
        name: 'ObjectInput',
        slug: 'object-input',
        searchKeywords: ['객체 입력'],
        description: 'Key-value field input',
        icon: '\u{1F5C2}',
      ),
      DocsComponentEntry(
        name: 'PhoneInput',
        slug: 'phone-input',
        searchKeywords: ['전화번호 국가'],
        description: 'Phone number',
        icon: '\u{1F4DE}',
      ),
      DocsComponentEntry(
        name: 'ChipInput',
        slug: 'chip-input',
        searchKeywords: ['태그 칩 입력'],
        description: 'Tag input',
        icon: '\u{1F3F7}',
      ),
      DocsComponentEntry(
        name: 'SwitchField',
        slug: 'switch-field',
        searchKeywords: ['스위치 필드'],
        description: 'Switch toggle',
        icon: '\u{1F4A1}',
      ),
      DocsComponentEntry(
        name: 'Drag',
        slug: 'drag',
        searchKeywords: ['드래그 끌기'],
        description: 'Drag, drop and reorder primitives',
        icon: '\u{1F91A}',
      ),
      DocsComponentEntry(
        name: 'Sortable',
        slug: 'sortable',
        searchKeywords: ['정렬 순서 드래그'],
        description: 'Drag to reorder',
        icon: '\u{2195}',
      ),
      DocsComponentEntry(
        name: 'Fieldset',
        slug: 'fieldset',
        searchKeywords: ['필드셋 입력 그룹'],
        description: 'Field grouping',
        icon: '\u{1F4CB}',
      ),
      DocsComponentEntry(
        name: 'FileInput',
        slug: 'file-input',
        searchKeywords: ['파일 업로드 첨부'],
        description: 'File upload',
        icon: '\u{1F4C1}',
      ),
      DocsComponentEntry(
        name: 'Form',
        slug: 'form',
        searchKeywords: ['폼 양식 제출'],
        description: 'Form container',
        icon: '\u{1F4C4}',
      ),
      DocsComponentEntry(
        name: 'FormLabel',
        slug: 'form-label',
        searchKeywords: ['폼 라벨 레이블'],
        description: 'Form field label',
        icon: '\u{1F3F7}',
      ),
      DocsComponentEntry(
        name: 'FormField',
        slug: 'form-field',
        searchKeywords: ['폼 필드 입력'],
        description: 'Form field wrapper (Form 내부)',
        englishDescription: 'Form field wrapper (used inside Form)',
        icon: '\u{1F4DD}',
      ),
      DocsComponentEntry(
        name: 'Formatter',
        slug: 'formatter',
        searchKeywords: ['포맷 입력 형식'],
        description: 'Input formatter factories',
        icon: '\u{1F524}',
      ),
      DocsComponentEntry(
        name: 'Validated',
        slug: 'validated',
        searchKeywords: ['유효성 검증'],
        description: 'Validation ring wrapper',
        icon: '\u{2705}',
      ),
      DocsComponentEntry(
        name: 'ValidatorHint',
        slug: 'validator-hint',
        searchKeywords: ['유효성 검증 힌트'],
        description: 'Validation message',
        icon: '\u{26A0}',
      ),
    ],
  ),
  DocsComponentGroup(
    id: 'display',
    title: 'Display',
    description: 'Content and data display components.',
    items: [
      DocsComponentEntry(
        name: 'Avatar',
        slug: 'avatar',
        searchKeywords: ['아바타 프로필'],
        description: 'User avatar',
        icon: '\u{1F464}',
      ),
      DocsComponentEntry(
        name: 'Badge',
        slug: 'badge',
        searchKeywords: ['배지 뱃지 상태'],
        description: 'Status badge',
        icon: '\u{1F3F7}',
      ),
      DocsComponentEntry(
        name: 'Tag',
        slug: 'tag',
        description: 'Category tag',
        icon: '\u{1F516}',
      ),
      DocsComponentEntry(
        name: 'Progress',
        slug: 'progress',
        searchKeywords: ['진행 진행률 로딩'],
        description: 'Progress bar',
        icon: '\u{1F4CA}',
      ),
      DocsComponentEntry(
        name: 'Calendar',
        slug: 'calendar',
        searchKeywords: ['달력 캘린더 일정'],
        description: 'Calendar view',
        icon: '\u{1F4C6}',
      ),
      DocsComponentEntry(
        name: 'Banner',
        slug: 'banner',
        searchKeywords: ['배너 알림'],
        description: 'Banner message',
        icon: '\u{1F4E2}',
      ),
      DocsComponentEntry(
        name: 'Carousel',
        slug: 'carousel',
        searchKeywords: ['캐러셀 슬라이드 이미지'],
        description: 'Image carousel',
        icon: '\u{1F3A0}',
      ),
      DocsComponentEntry(
        name: 'CarouselBanner',
        slug: 'carousel-banner',
        searchKeywords: ['슬라이드 배너'],
        description: 'Promotional strip for a banner carousel',
        icon: '\u{1F39F}',
      ),
      DocsComponentEntry(
        name: 'Chat',
        slug: 'chat',
        searchKeywords: ['채팅 대화 메시지'],
        description: 'Chat bubbles',
        icon: '\u{1F4AC}',
      ),
      DocsComponentEntry(
        name: 'Chip',
        slug: 'chip',
        searchKeywords: ['칩 태그'],
        description: 'Info chip',
        icon: '\u{1F3F7}',
      ),
      DocsComponentEntry(
        name: 'ChipGroup',
        slug: 'chip-group',
        searchKeywords: ['칩 그룹 태그'],
        description: 'Selectable chip group',
        icon: '\u{1F3F7}',
      ),
      DocsComponentEntry(
        name: 'CodeDiff',
        slug: 'code-diff',
        searchKeywords: ['코드 차이 비교'],
        description: 'Line-by-line code diff',
        icon: '\u{1F4DD}',
      ),
      DocsComponentEntry(
        name: 'Diff',
        slug: 'diff',
        searchKeywords: ['차이 비교 변경'],
        description: 'Before/after split-view',
        icon: '\u{1F500}',
      ),
      DocsComponentEntry(
        name: 'CodeSnippet',
        slug: 'code-snippet',
        searchKeywords: ['코드 예제 복사'],
        description: 'Code display',
        icon: '\u{1F4BB}',
      ),
      DocsComponentEntry(
        name: 'Divider',
        slug: 'divider',
        searchKeywords: ['구분선 나누기'],
        description: 'Content divider',
        icon: '\u{2796}',
      ),
      DocsComponentEntry(
        name: 'DotIndicator',
        slug: 'dot-indicator',
        searchKeywords: ['점 표시 인디케이터'],
        description: 'Dot indicator',
        icon: '\u{25CF}',
      ),
      DocsComponentEntry(
        name: 'EmptyState',
        slug: 'empty-state',
        searchKeywords: ['빈 상태 데이터 없음'],
        description: 'Empty placeholder',
        icon: '\u{1F4ED}',
      ),
      DocsComponentEntry(
        name: 'Indicator',
        slug: 'indicator',
        searchKeywords: ['표시 상태'],
        description: 'Corner badge wrapper',
        icon: '\u{1F4CC}',
      ),
      DocsComponentEntry(
        name: 'Kbd',
        slug: 'kbd',
        searchKeywords: ['키보드 단축키'],
        description: 'Keyboard key',
        icon: '\u{2328}',
      ),
      DocsComponentEntry(
        name: 'Label',
        slug: 'label',
        searchKeywords: ['라벨 레이블'],
        description: 'Form field label',
        icon: '\u{1F3F7}',
      ),
      DocsComponentEntry(
        name: 'NumberTicker',
        slug: 'number-ticker',
        searchKeywords: ['숫자 카운터'],
        description: 'Animated number',
        icon: '\u{1F522}',
      ),
      DocsComponentEntry(
        name: 'AspectRatioBox',
        slug: 'aspect-ratio-box',
        searchKeywords: ['화면 비율 종횡비'],
        description: 'Fixed width:height container',
        icon: '\u{1F5BC}',
      ),
      DocsComponentEntry(
        name: 'Skeleton',
        slug: 'skeleton',
        searchKeywords: ['스켈레톤 로딩'],
        description: 'Loading skeleton',
        icon: '\u{1F480}',
      ),
      DocsComponentEntry(
        name: 'LoadingRegion',
        slug: 'loading-region',
        description: 'Announces loading once for an area',
        icon: '\u{1F50A}',
      ),
      DocsComponentEntry(
        name: 'Stat',
        slug: 'stat',
        searchKeywords: ['통계 지표 수치'],
        description: 'Statistics',
        icon: '\u{1F4C8}',
      ),
      DocsComponentEntry(
        name: 'Status',
        slug: 'status',
        searchKeywords: ['상태 표시'],
        description: 'Status indicator',
        icon: '\u{1F7E2}',
      ),
      DocsComponentEntry(
        name: 'Countdown',
        slug: 'countdown',
        searchKeywords: ['카운트다운 남은 시간'],
        description: 'Count down timer',
        icon: '\u{23F1}',
      ),
      DocsComponentEntry(
        name: 'DescriptionCard',
        slug: 'description-card',
        searchKeywords: ['설명 카드 정보'],
        description: '라벨/값 메타데이터 요약 카드',
        englishDescription: 'Card summarizing label/value metadata',
        icon: '\u{1F4DC}',
      ),
      DocsComponentEntry(
        name: 'Loading',
        slug: 'loading',
        searchKeywords: ['로딩 대기'],
        description: 'Loading spinner',
        icon: '\u{1F504}',
      ),
      DocsComponentEntry(
        name: 'HoverGallery',
        slug: 'hover-gallery',
        description: 'Hover gallery',
        icon: '\u{1F5BC}',
      ),
      DocsComponentEntry(
        name: 'ValidationBadge',
        slug: 'validation-badge',
        searchKeywords: ['검증 배지'],
        description: 'Validation status',
        icon: '\u{2705}',
      ),
      DocsComponentEntry(
        name: 'Tracker',
        slug: 'tracker',
        searchKeywords: ['추적 상태 기록'],
        description: 'Status tracker',
        icon: '\u{1F4CA}',
      ),
      DocsComponentEntry(
        name: 'CategoryBreakdown',
        slug: 'category-breakdown',
        description: 'Category share — bars or donut',
        icon: '\u{1F967}',
      ),
      DocsComponentEntry(
        name: 'TrendChart',
        slug: 'trend-chart',
        description: 'Time-series trend chart',
        icon: '\u{1F4C8}',
      ),
      DocsComponentEntry(
        name: 'Mockup',
        slug: 'mockup',
        searchKeywords: ['목업 기기'],
        description: 'Device mockup',
        icon: '\u{1F4F1}',
      ),
      DocsComponentEntry(
        name: 'MockupBrowser',
        slug: 'mockup-browser',
        description: 'Browser and app window frame',
        icon: '\u{1F310}',
      ),
      DocsComponentEntry(
        name: 'MockupCode',
        slug: 'mockup-code',
        description: 'Code editor frame',
        icon: '\u{1F4BB}',
      ),
      DocsComponentEntry(
        name: 'MockupDevice',
        slug: 'mockup-device',
        description: 'Phone and tablet bezel frame',
        icon: '\u{1F4F1}',
      ),
      DocsComponentEntry(
        name: 'MockupFoldable',
        slug: 'mockup-foldable',
        searchKeywords: ['폴더블 접이식 접힘'],
        description: 'Folding device frame with an adjustable fold angle',
        icon: '\u{1F4F1}',
      ),
      DocsComponentEntry(
        name: 'Timeline',
        slug: 'timeline',
        searchKeywords: ['타임라인 내역 이력'],
        description: 'Event timeline',
        icon: '\u{1F4C5}',
      ),
      DocsComponentEntry(
        name: 'Swap',
        slug: 'swap',
        description: 'Swap animation',
        icon: '\u{1F504}',
      ),
      DocsComponentEntry(
        name: 'DisclosureBadge',
        slug: 'disclosure-badge',
        description: '근거를 지금 열 수 있는지 표시하는 정적 배지',
        englishDescription: 'Static badge stating whether a source can be opened now',
        icon: '\u{1F50F}',
      ),
    ],
  ),
  DocsComponentGroup(
    id: 'layout',
    title: 'Layout',
    description: 'Structure, containers, and layout components.',
    items: [
      DocsComponentEntry(
        name: 'Accordion',
        slug: 'accordion',
        searchKeywords: ['아코디언 접기 펼치기'],
        description: 'Expandable sections',
        icon: '\u{1F4D6}',
      ),
      DocsComponentEntry(
        name: 'Collapsible',
        slug: 'collapsible',
        searchKeywords: ['접기 펼치기'],
        description: 'Collapsible panel',
        icon: '\u{1F4E6}',
      ),
      DocsComponentEntry(
        name: 'Disclosure',
        slug: 'disclosure',
        searchKeywords: ['접기 펼치기'],
        description: 'Native <details> section that opens without JavaScript',
        icon: '\u{1F53D}',
      ),
      DocsComponentEntry(
        name: 'Card',
        slug: 'card',
        searchKeywords: ['카드 콘텐츠'],
        description: '슬롯 기반 콘텐츠 카드',
        englishDescription: 'Slot-based content card',
        icon: '\u{1F4C7}',
      ),
      DocsComponentEntry(
        name: 'CardImage',
        slug: 'card-image',
        searchKeywords: ['이미지 카드'],
        description: '이미지 + 제목/부제 카드',
        englishDescription: 'Card with an image plus title/subtitle',
        icon: '\u{1F5BC}',
      ),
      DocsComponentEntry(
        name: 'Table',
        slug: 'table',
        searchKeywords: ['테이블 표 데이터 목록'],
        description: 'Data table',
        icon: '\u{1F4CA}',
      ),
      DocsComponentEntry(
        name: 'Stepper',
        slug: 'stepper',
        searchKeywords: ['단계 스테퍼 순서'],
        description: 'Step indicator',
        icon: '\u{1F463}',
      ),
      DocsComponentEntry(
        name: 'Steps',
        slug: 'steps',
        searchKeywords: ['단계 절차'],
        description: 'Steps display',
        icon: '\u{1F6B6}',
      ),
      DocsComponentEntry(
        name: 'StepItem',
        slug: 'step-item',
        description: '진행 단계 한 줄 — Steps 의 list 가 쌓는 행',
        englishDescription: 'One step row — the unit Steps (list) stacks',
        icon: '\u{2611}',
      ),
      DocsComponentEntry(
        name: 'Tree',
        slug: 'tree',
        searchKeywords: ['트리 파일 폴더 계층'],
        description: 'Tree view',
        icon: '\u{1F333}',
      ),
      DocsComponentEntry(
        name: 'Resizable',
        slug: 'resizable',
        searchKeywords: ['크기 조절 분할 패널'],
        description: 'Resizable panel',
        icon: '\u{2194}',
      ),
      DocsComponentEntry(
        name: 'ScrollArea',
        slug: 'scroll-area',
        searchKeywords: ['스크롤 영역'],
        description: 'Styled scrollable viewport',
        icon: '\u{1F4D1}',
      ),
      DocsComponentEntry(
        name: 'FadeScroll',
        slug: 'fade-scroll',
        description: 'Scroll edge fade wrapper',
        icon: '\u{1F30A}',
      ),
      DocsComponentEntry(
        name: 'ScrollableClient',
        slug: 'scrollable-client',
        description: '2D scrollable viewport with offset-aware builder',
        icon: '\u{2B0D}',
      ),
      DocsComponentEntry(
        name: 'OverflowMarquee',
        slug: 'overflow-marquee',
        description: 'Scrolling marquee for overflow text',
        icon: '\u{1F3AC}',
      ),
      DocsComponentEntry(
        name: 'Stacks',
        slug: 'stack-layout',
        description: 'Layered children with per-layer offset',
        icon: '\u{1F4E6}',
      ),
      DocsComponentEntry(
        name: 'StageContainer',
        slug: 'stage-container',
        description: 'Responsive container with breakpoint padding',
        icon: '\u{1F3AD}',
      ),
      DocsComponentEntry(
        name: 'Window',
        slug: 'window',
        searchKeywords: ['창 윈도우'],
        description: '드래그 · 리사이즈 · 스냅 창 매니저',
        englishDescription: 'Window manager with drag, resize, and snap',
        icon: '\u{1F5BC}',
      ),
      DocsComponentEntry(
        name: 'WindowPanel',
        slug: 'window-panel',
        description: 'Window-style panel with title bar + controls',
        icon: '\u{1F5D4}',
      ),
      DocsComponentEntry(
        name: 'DraggablePanel',
        slug: 'draggable-panel',
        description: 'Floating, draggable, edge-docking tool palette',
        icon: '\u{1F3AF}',
      ),
      DocsComponentEntry(
        name: 'Join',
        slug: 'join',
        description: 'Join elements',
        icon: '\u{1F517}',
      ),
      DocsComponentEntry(
        name: 'Basic',
        slug: 'basic',
        description: 'Slot-based row layout',
        icon: '\u{1F4C7}',
      ),
      DocsComponentEntry(
        name: 'Frame',
        slug: 'frame',
        description: 'Figma Frame 1:1 레이아웃 프리미티브',
        englishDescription: 'Layout primitive mirroring a Figma frame 1:1',
        icon: '\u{1F5BC}',
      ),
      DocsComponentEntry(
        name: 'Hidden',
        slug: 'hidden',
        description: 'Collapse toggle wrapper with fade + size animation',
        icon: '\u{1F648}',
      ),
      DocsComponentEntry(
        name: 'Listing',
        slug: 'listing',
        searchKeywords: ['목록 리스트'],
        description: 'Row-based list container with smart column grow',
        icon: '\u{1F4CB}',
      ),
      DocsComponentEntry(
        name: 'SwipeActions',
        slug: 'swipe-actions',
        description: '옆으로 밀면 액션이 드러나는 목록 행',
        englishDescription: 'List row that reveals actions when swiped sideways',
        icon: '\u{1F449}',
      ),
      DocsComponentEntry(
        name: 'Gap',
        slug: 'gap',
        searchKeywords: ['간격 여백'],
        description: 'Spacing utility',
        icon: '\u{2B1C}',
      ),
      DocsComponentEntry(
        name: 'Mask',
        slug: 'mask',
        description: 'Clip content to a shape',
        icon: '\u{1F3AD}',
      ),
      DocsComponentEntry(
        name: 'MediaQuery',
        slug: 'media-query',
        description: 'Responsive visibility by breakpoint',
        icon: '\u{1F4F6}',
      ),
      DocsComponentEntry(
        name: 'Breakpoint',
        slug: 'breakpoint',
        description: 'Current viewport tier accessor (mobile/tablet/desktop)',
        icon: '\u{1F4CF}',
      ),
      DocsComponentEntry(
        name: 'ResponsiveContainer',
        slug: 'responsive-container',
        description: 'Centred, max-width layout wrapper',
        icon: '\u{1F4D0}',
      ),
      DocsComponentEntry(
        name: 'ResponsiveGrid',
        slug: 'responsive-grid',
        searchKeywords: ['반응형 그리드'],
        description: 'CSS-Grid-based responsive grid with col/row span',
        icon: '\u{1F533}',
      ),
      DocsComponentEntry(
        name: 'ResponsiveRowColumn',
        slug: 'responsive-row-column',
        description: 'Row↔Column layout that flips at a breakpoint tier',
        icon: '\u{1F504}',
      ),
      DocsComponentEntry(
        name: 'Scaffold',
        slug: 'scaffold',
        searchKeywords: ['스캐폴드 화면 뼈대'],
        description: 'Screen layout structure',
        icon: '\u{1F5C2}',
      ),
      DocsComponentEntry(
        name: 'PageHeader',
        slug: 'page-header',
        description: '페이지 머리 — 보조 설명 · 제목 · 행동',
        englishDescription: 'Page head — eyebrow, title and actions',
        icon: '\u{1F4C3}',
      ),
      DocsComponentEntry(
        name: 'PanelHeader',
        slug: 'panel-header',
        description: '패널 머리 — 제목과 끝의 행동 하나',
        englishDescription: 'Panel head — a title and one trailing action',
        icon: '\u{1F4D1}',
      ),
      DocsComponentEntry(
        name: 'BottomActionBar',
        slug: 'bottom-action-bar',
        description: '하단 행동 바 — 화면 아래에 붙는 주 행동과 보조 행동',
        englishDescription: 'Bottom action bar — the primary and secondary actions at the foot of a screen',
        icon: '\u{23EC}',
      ),
    ],
  ),
  DocsComponentGroup(
    id: 'navigation',
    title: 'Navigation',
    description: 'Navigation and wayfinding components.',
    items: [
      DocsComponentEntry(
        name: 'AppBar',
        slug: 'app-bar',
        description: 'Application bar with leading / title / trailing clusters',
        icon: '\u{1F4CC}',
      ),
      DocsComponentEntry(
        name: 'Dock',
        slug: 'dock',
        searchKeywords: ['독 도크'],
        description: 'Bottom navigation bar',
        icon: '\u{2693}',
      ),
      DocsComponentEntry(
        name: 'Tabs',
        slug: 'tabs',
        searchKeywords: ['탭 전환'],
        description: 'Tab navigation',
        icon: '\u{1F4D1}',
      ),
      DocsComponentEntry(
        name: 'TabPane',
        slug: 'tab-pane',
        description: 'Tabbed content panels',
        icon: '\u{1F4D1}',
      ),
      DocsComponentEntry(
        name: 'NavigationBar',
        slug: 'navigation-bar',
        searchKeywords: ['내비게이션 메뉴 탐색'],
        description: 'Bottom nav bar',
        icon: '\u{2B07}',
      ),
      DocsComponentEntry(
        name: 'NavigationBarItem',
        slug: 'navigation-bar-item',
        searchKeywords: ['내비게이션 항목'],
        description: '내비게이션 항목 — 바 밖에서 쓰는 사이드바 한 줄',
        englishDescription: 'Navigation item — one sidebar row, usable outside the bar',
        icon: '\u{1F4CC}',
      ),
      DocsComponentEntry(
        name: 'Sidebar',
        slug: 'sidebar',
        searchKeywords: ['사이드바 메뉴'],
        description: '사이드바 — 앱의 신원 · 검색 · 메뉴 · 계정을 담는 옆 내비게이션',
        englishDescription: 'Sidebar — side navigation with identity, search, rows and the account',
        icon: '\u{1F5C2}',
      ),
      DocsComponentEntry(
        name: 'Breadcrumb',
        slug: 'breadcrumb',
        searchKeywords: ['경로 탐색 브레드크럼'],
        description: 'Breadcrumb trail',
        icon: '\u{27A1}',
      ),
      DocsComponentEntry(
        name: 'Pagination',
        slug: 'pagination',
        searchKeywords: ['페이지 나누기'],
        description: 'Page navigation',
        icon: '\u{1F4C4}',
      ),
      DocsComponentEntry(
        name: 'Switcher',
        slug: 'switcher',
        searchKeywords: ['전환 스위처'],
        description: 'View switcher',
        icon: '\u{1F500}',
      ),
      DocsComponentEntry(
        name: 'IndexedSwitcher',
        slug: 'indexed-switcher',
        searchKeywords: ['탭 화면 전환', '목적지 전환', '쉘 라우트 전환'],
        description: 'Destination switcher that keeps every view',
        icon: '\u{1F504}',
      ),
    ],
  ),
  DocsComponentGroup(
    id: 'menu',
    title: 'Menu',
    description: 'Menus and contextual actions.',
    items: [
      DocsComponentEntry(
        name: 'Menu',
        slug: 'menu',
        searchKeywords: ['메뉴'],
        description: 'Menu list',
        icon: '\u{1F4CB}',
      ),
      DocsComponentEntry(
        name: 'MenuItem',
        slug: 'menu-item',
        searchKeywords: ['메뉴 항목'],
        description: '메뉴 행 하나 — Menu · Select 가 놓는 단위',
        englishDescription: 'A single menu row — the unit Menu and Select lay out',
        icon: '\u{2630}',
      ),
      DocsComponentEntry(
        name: 'ContextMenu',
        slug: 'context-menu',
        searchKeywords: ['우클릭 컨텍스트 메뉴'],
        description: 'Right-click menu',
        icon: '\u{1F5B1}',
      ),
      DocsComponentEntry(
        name: 'DropdownMenu',
        slug: 'dropdown-menu',
        searchKeywords: ['드롭다운 메뉴'],
        description: 'Dropdown actions',
        icon: '\u{1F53D}',
      ),
      DocsComponentEntry(
        name: 'Menubar',
        slug: 'menubar',
        searchKeywords: ['메뉴바'],
        description: 'App menu bar',
        icon: '\u{2630}',
      ),
      DocsComponentEntry(
        name: 'ToolbarGroup',
        slug: 'toolbar-group',
        searchKeywords: ['도구 모음 툴바'],
        description: '관련 동작이 공유하는 툴바 표면',
        englishDescription: 'Related toolbar controls on one shared surface',
        icon: '\u{2630}',
      ),
      DocsComponentEntry(
        name: 'NavigationMenu',
        slug: 'navigation-menu',
        searchKeywords: ['내비게이션 메뉴'],
        description: 'Horizontal mega-menu',
        icon: '\u{1F5C2}',
      ),
    ],
  ),
  DocsComponentGroup(
    id: 'overlay',
    title: 'Overlay',
    description: 'Dialogs, popovers, and overlays.',
    items: [
      DocsComponentEntry(
        name: 'Dialog',
        slug: 'dialog',
        searchKeywords: ['대화상자 모달 팝업'],
        description: 'Modal dialog',
        icon: '\u{1F4AC}',
      ),
      DocsComponentEntry(
        name: 'Drawer',
        slug: 'drawer',
        searchKeywords: ['드로어 서랍 패널'],
        description: 'Side drawer',
        icon: '\u{1F4E5}',
      ),
      DocsComponentEntry(
        name: 'HoverCard',
        slug: 'hover-card',
        searchKeywords: ['호버 카드 미리보기'],
        description: 'Hover popup',
        icon: '\u{1F4C7}',
      ),
      DocsComponentEntry(
        name: 'Popover',
        slug: 'popover',
        searchKeywords: ['팝오버 팝업'],
        description: 'Popover panel',
        icon: '\u{1F4AD}',
      ),
      DocsComponentEntry(
        name: 'Toast',
        slug: 'toast',
        searchKeywords: ['토스트 알림'],
        description: 'Notification toast',
        icon: '\u{1F514}',
      ),
      DocsComponentEntry(
        name: 'Tooltip',
        slug: 'tooltip',
        searchKeywords: ['툴팁 도움말'],
        description: 'Tooltip hint',
        icon: '\u{1F4A1}',
      ),
      DocsComponentEntry(
        name: 'Swiper',
        slug: 'swiper',
        searchKeywords: ['스와이프 밀기'],
        description: 'Swipe gesture',
        icon: '\u{1F91A}',
      ),
      DocsComponentEntry(
        name: 'RefreshTrigger',
        slug: 'refresh-trigger',
        searchKeywords: ['새로고침 당겨서 갱신'],
        description: 'Pull to refresh',
        icon: '\u{1F504}',
      ),
      DocsComponentEntry(
        name: 'Alert',
        slug: 'alert',
        searchKeywords: ['알림 경고'],
        description: 'Alert message',
        icon: '\u{26A0}',
      ),
    ],
  ),
  DocsComponentGroup(
    id: 'icon',
    title: 'Icon',
    description: 'Iconography components.',
    items: [
      DocsComponentEntry(
        name: 'Icon',
        slug: 'icon',
        searchKeywords: ['아이콘'],
        description: 'Icon display',
        icon: '\u{2B50}',
      ),
    ],
  ),
  DocsComponentGroup(
    id: 'text',
    title: 'Text',
    description: 'Typography and text components.',
    items: [
      DocsComponentEntry(
        name: 'Text',
        slug: 'text',
        searchKeywords: ['텍스트 글자'],
        description: 'Typography',
        icon: '\u{1F524}',
      ),
      DocsComponentEntry(
        name: 'Selectable Text',
        slug: 'selectable-text',
        searchKeywords: ['선택 가능한 텍스트'],
        description: 'User-selectable text',
        icon: '\u{1F5B1}',
      ),
      DocsComponentEntry(
        name: 'TextBlock',
        slug: 'text-block',
        searchKeywords: ['텍스트 블록'],
        description: 'Semantic prose text block',
        icon: '\u{1F4C4}',
      ),
      DocsComponentEntry(
        name: 'Link',
        slug: 'link',
        searchKeywords: ['링크 이동'],
        description: 'Styled link',
        icon: '\u{1F517}',
      ),
      DocsComponentEntry(
        name: 'DefinitionList',
        slug: 'definition-list',
        description: '용어와 설명을 쌍으로 묶는 정의 목록',
        englishDescription: 'Definition list pairing terms with descriptions',
        icon: '\u{1F4D6}',
      ),
    ],
  ),
  DocsComponentGroup(
    id: 'infra',
    title: 'Infra',
    description: 'Low-level building-block components.',
    items: [
      DocsComponentEntry(
        name: 'Clickable',
        slug: 'clickable',
        searchKeywords: ['클릭 동작'],
        description: 'Interaction wrapper',
        icon: '\u{1F446}',
      ),
      DocsComponentEntry(
        name: 'FocusOutline',
        slug: 'focus-outline',
        searchKeywords: ['포커스 윤곽선'],
        description: 'Focus ring around a control',
        icon: '\u{1F3AF}',
      ),
      DocsComponentEntry(
        name: 'OutlinedContainer',
        slug: 'outlined-container',
        searchKeywords: ['테두리 컨테이너'],
        description: 'Bordered container box',
        icon: '\u{1F5BE}',
      ),
      DocsComponentEntry(
        name: 'SubfocusScope',
        slug: 'subfocus',
        description: 'Keyboard focus traversal scope',
        icon: '\u{2328}',
      ),
      DocsComponentEntry(
        name: 'ScrollViewInterceptor',
        slug: 'scrollview',
        description: 'Desktop scroll interception',
        icon: '\u{1F5B2}',
      ),
      DocsComponentEntry(
        name: 'Popup',
        slug: 'popup',
        description: 'Floating panel container',
        icon: '\u{1F5C2}',
      ),
      DocsComponentEntry(
        name: 'Scrollbar',
        slug: 'scrollbar',
        searchKeywords: ['스크롤바'],
        description: 'Themed scrollbar',
        icon: '\u{1F4DC}',
      ),
    ],
  ),
];

/// 모든 그룹을 표시 순서대로 펼친 컴포넌트 목록.
///
/// 검색 인덱스와, 그룹핑이 필요 없는 슬러그 조회에 쓴다.
final List<DocsComponentEntry> kDocsComponentEntries = [
  for (final group in kDocsComponentGroups) ...group.items,
];

/// 슬러그로 컴포넌트를 찾는다. 문서화되지 않은 슬러그면 `null`.
DocsComponentEntry? docsComponentBySlug(String slug) {
  for (final entry in kDocsComponentEntries) {
    if (entry.slug == slug) return entry;
  }
  return null;
}

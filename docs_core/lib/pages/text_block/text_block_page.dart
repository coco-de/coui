/// TextBlock 페이지 — 플레이그라운드와 두 플랫폼 미리보기가 같이 읽는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `text_block_web.dart` · `text_block_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 둘이다 — `element`(`CoreTextBlockElement` 의 이름)와 `presets`
/// (`none` 또는 [demoRolePresets] 의 이름 하나). 프리셋 값의 타입은 플랫폼마다
/// 달라서(Flutter 는 `TextStyle`, Web 은 클래스 문자열) 이름만 여기서 정하고,
/// 이름을 값으로 바꾸는 일은 두 플랫폼 파일이 한다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/text-block.md`.
const String slug = 'text-block';

/// 플레이그라운드의 글 — 태그가 `label` 을 주지 않을 때.
const String demoLabel = '글 블록 예시';

/// 속성 `presets` 로 고를 수 있는 프리셋 이름. 모두 `BuildContext` 를 받고
/// 글자 역할을 함께 가진 프리셋이라, 두 플랫폼이 같은 글자를 그린다.
const List<String> demoRolePresets = [
  'heading1',
  'heading2',
  'heading3',
  'heading4',
  'lead',
  'lg',
  'sm',
  'muted',
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'element': 'h3', 'presets': 'none'},
  label: demoLabel,
  controls: [
    DocsPlaygroundChoice(
      label: 'element',
      prop: 'element',
      options: [
        'p',
        'span',
        'h1',
        'h2',
        'h3',
        'h4',
        'h5',
        'h6',
        'blockquote',
        'pre',
        'label',
        'strong',
        'em',
        'small',
      ],
    ),
    DocsPlaygroundChoice(label: 'presets', prop: 'presets', options: ['none', ...demoRolePresets]),
  ],
  code: _textBlockCode,
);

/// 크기 표. TextBlock 에는 크기 축이 없다 — 글자 크기는 `element` 가 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `element` — 없거나 모르는 값은 위젯의 기본값(`p`).
CoreTextBlockElement demoElementOf(Map<String, String> props) =>
    previewEnum(CoreTextBlockElement.values, props['element'], CoreTextBlockElement.defaultElement);

/// 속성의 `presets` — [demoRolePresets] 에 없는 값(`none` 포함)은 `null`.
String? demoPresetOf(Map<String, String> props) {
  final name = props['presets'];
  return demoRolePresets.contains(name) ? name : null;
}

/// 장면의 열 폭(logical px).
const double demoColumnWidth = 360;

/// 이렇게 하세요 / 하지 마세요 카드 속 열의 폭(logical px).
const double demoCardColumnWidth = 240;

/// `text-block/headings` 장면 — 제목 요소와 그 글.
const List<(CoreTextBlockElement, String)> demoHeadingBlocks = [
  (CoreTextBlockElement.h1, 'h1 제목'),
  (CoreTextBlockElement.h2, 'h2 제목'),
  (CoreTextBlockElement.h3, 'h3 제목'),
  (CoreTextBlockElement.h4, 'h4 제목'),
  (CoreTextBlockElement.h5, 'h5 제목'),
  (CoreTextBlockElement.h6, 'h6 제목'),
];

/// `text-block/body` 장면 — 상자를 그리지 않는 나머지 요소와 그 글.
const List<(CoreTextBlockElement, String)> demoBodyBlocks = [
  (CoreTextBlockElement.p, 'p — 문단 글입니다.'),
  (CoreTextBlockElement.span, 'span — 짧은 글입니다.'),
  (CoreTextBlockElement.label, 'label — 라벨 글입니다.'),
  (CoreTextBlockElement.strong, 'strong — 굵은 글입니다.'),
  (CoreTextBlockElement.em, 'em — 기울인 글입니다.'),
  (CoreTextBlockElement.small, 'small — 작은 글입니다.'),
];

/// 상자 장면의 인용 글.
const String demoQuoteText = '색은 상태와 분류를 알릴 때만 씁니다.';

/// 상자 장면의 코드 글 — 두 줄이다.
const String demoCodeText = 'final total = price * count;\nprint(total);';

/// `text-block/override` 장면의 인용 덮어쓰기 — 선을 `primary` 4px 로.
const CoreTextBlockStyle demoQuoteOverride = CoreTextBlockStyle(
  blockQuoteBorderColor: CoreColor.token(CoreColors.primary),
  blockQuoteBorderWidth: CoreStrokeWidth.stroke4,
);

/// `text-block/override` 장면의 코드 상자 덮어쓰기 — 채움 · 모서리 · 글자 색.
const CoreTextBlockStyle demoCodeOverride = CoreTextBlockStyle(
  inlineCodeBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
  inlineCodeRadius: CoreRadius.radius8,
  inlineCodeTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onPrimaryContainer)),
);

/// 제목 카드의 제목 글.
const String demoSectionTitle = '배송 안내';

/// 제목 카드의 본문 글.
const String demoSectionBody = '주문은 결제한 다음 날 보냅니다.';

/// 크기 카드의 글.
const String demoNotice = '이번 달 사용량이 한도에 가까워졌습니다.';

String _textBlockCode(Map<String, String> props, String? label) {
  final element = demoElementOf(props);
  final preset = demoPresetOf(props);
  final lines = [
    "text: '${label ?? demoLabel}',",
    if (element != CoreTextBlockElement.defaultElement) 'element: CoreTextBlockElement.${element.name},',
    if (preset != null) 'presets: [TextBlock.$preset(context)],',
  ];
  return 'TextBlock(\n${lines.map((line) => '  $line').join('\n')}\n)';
}

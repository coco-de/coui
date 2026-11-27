/// DotIndicator 페이지 — 플레이그라운드와 장면이 함께 읽는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `dot_indicator_web.dart` · `dot_indicator_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 크기 축은 `CoreComponentSize` 가 아니라 `CoreDotIndicatorSize` 라서 크기 표를
/// 레지스트리에 싣지 않고, 페이지가 장면과 표로 보인다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/dot-indicator.md`.
const String slug = 'dot-indicator';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성에 `length` 가 없을 때의 점 개수.
const int dotIndicatorPreviewLength = 5;

/// 속성에 `index` 가 없을 때 처음 고르는 점.
const int dotIndicatorPreviewStart = 1;

/// 긴 현재 점의 길이 — 플레이그라운드와 장면이 함께 쓴다.
const double dotIndicatorPreviewActiveLength = CoreSpace.space24;

/// 현재 점만 놓이는 방향으로 길게 하는 스타일.
const CoreDotIndicatorStyle dotIndicatorElongatedStyle = CoreDotIndicatorStyle(
  activeLength: dotIndicatorPreviewActiveLength,
);

/// 나머지 점을 링으로 그리는 스타일. 채움을 비우는 것만으로는 테두리 폭이 0 이라
/// 폭을 함께 준다.
const CoreDotIndicatorStyle dotIndicatorRingStyle = CoreDotIndicatorStyle(
  inactiveColor: CoreColor.transparent,
  inactiveBorderColor: CoreColor.token(CoreColors.outline),
  inactiveBorderWidth: CoreStrokeWidth.stroke2,
);

/// 누르는 점을 지나치게 줄인 예 — 점 4, 간격 4, 둘레 여백 0.
const CoreDotIndicatorStyle dotIndicatorTinyStyle = CoreDotIndicatorStyle(
  dotSize: CoreSpace.space4,
  spacing: CoreSpace.space4,
  padding: CoreEdgeInsets.zero,
);

/// `dot-indicator/active-shape` 장면의 이름표와 스타일. 두 플랫폼 장면이 함께 읽는다.
const List<(String, CoreDotIndicatorStyle?)> dotIndicatorShapeSamples = [
  ('기본', null),
  ('activeLength', dotIndicatorElongatedStyle),
  ('링', dotIndicatorRingStyle),
];

/// `dot-indicator/related-carousel` 장면의 띠 — 제목과 설명.
const List<(String, String)> dotIndicatorCarouselSlides = [
  ('이번 주 신간', '새 책 세 권'),
  ('독서 챌린지', '한 달에 두 권'),
];

/// `dot-indicator/related-steps` 장면의 단계.
const List<CoreStepData> dotIndicatorStepSamples = [
  CoreStepData(title: '담기'),
  CoreStepData(title: '결제'),
  CoreStepData(title: '완료'),
];

/// 속성의 `length` — 없거나 숫자가 아니면 [dotIndicatorPreviewLength], 1 미만이면 1.
int dotIndicatorPreviewCount(Map<String, String> props) {
  final length = int.tryParse(props['length'] ?? '') ?? dotIndicatorPreviewLength;
  return length < 1 ? 1 : length;
}

/// 속성의 `index`(처음 고를 점) — 0 ~ 개수 - 1 로 맞춘다. 없으면 [dotIndicatorPreviewStart].
int dotIndicatorPreviewIndex(Map<String, String> props) =>
    (int.tryParse(props['index'] ?? '') ?? dotIndicatorPreviewStart).clamp(0, dotIndicatorPreviewCount(props) - 1);

// 크기 선택지는 enum 에서 읽는다. 세로 방향은 넣지 않는다 — 플레이그라운드의
// Flutter 자리는 점 한 줄 높이라 점을 세로로 쌓으면 잘린다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'size': CoreDotIndicatorSize.defaultSize.name,
    'length': '$dotIndicatorPreviewLength',
    'interactive': 'true',
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreDotIndicatorSize.values) size.name],
      segmented: true,
    ),
    const DocsPlaygroundChoice(label: 'length', prop: 'length', options: ['3', '5', '7'], segmented: true),
    const DocsPlaygroundFlag(label: 'onChanged', on: {'interactive': 'true'}),
    const DocsPlaygroundFlag(label: '긴 현재 점', on: {'elongated': 'true'}),
  ],
  code: _dotIndicatorCode,
);

/// 속성 → 코드. 기본값과 같은 값은 적지 않는다. `const` 를 붙이지 않아 두
/// 플랫폼에서 같은 코드다(Web 의 `DotIndicator` 생성자는 `const` 가 아니다).
String _dotIndicatorCode(Map<String, String> props, String? label) {
  final size = previewEnum(CoreDotIndicatorSize.values, props['size'], CoreDotIndicatorSize.defaultSize);
  final lines = [
    'index: currentPage,',
    'length: ${dotIndicatorPreviewCount(props)},',
    if (previewFlag(props, 'interactive')) 'onChanged: (next) => setState(() => currentPage = next),',
    if (size != CoreDotIndicatorSize.defaultSize) 'size: CoreDotIndicatorSize.${size.name},',
    if (previewFlag(props, 'elongated'))
      'dotIndicatorStyle: CoreDotIndicatorStyle(activeLength: CoreSpace.space${dotIndicatorPreviewActiveLength.toInt()}),',
  ];
  return 'DotIndicator(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

/// Timeline 페이지 — 플레이그라운드와 장면이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `timeline_web.dart` · `timeline_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 다섯이다: `count`(항목 수) · `timeColumnWidth`(`CoreSpace` 단계의
/// 숫자) · `timestamp` · `description` · `long`(첫 항목에 긴 글). 해석은
/// [timelinePreviewItems] · [timelinePreviewTimeColumnWidth] 한 곳에 두어 두
/// 플랫폼의 속성 빌더와 코드가 같은 뜻으로 읽는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/timeline.md`.
const String slug = 'timeline';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 장면에서 Timeline 을 담는 상자의 폭(logical px).
const double timelineSceneWidth = 320;

/// 구조 장면의 폭. 390px 에서 옆 번호가 무대 안에 놓이게 좁힌다.
const double timelineAnatomyWidth = 264;

/// `timeline/narrow` 장면의 상자 폭(logical px).
const double timelineNarrowSceneWidth = 240;

/// 플레이그라운드와 여러 장면이 그리는 주문 이력.
const List<CoreTimelineItem> timelineOrderItems = [
  CoreTimelineItem(title: '주문 접수', timestamp: '오전 10:00', description: '주문을 접수했어요.'),
  CoreTimelineItem(title: '처리 중', timestamp: '오전 11:30', description: '상품을 포장하고 있어요.'),
  CoreTimelineItem(title: '발송 완료', timestamp: '오후 2:00', description: '택배사에 상품을 넘겼어요.'),
];

/// 구조 장면의 항목. 좁힌 폭에서 설명이 두 줄이 되면 장면이 높아져 위쪽 번호가
/// 무대를 벗어나므로 설명을 짧게 둔다.
const List<CoreTimelineItem> timelineAnatomyItems = [
  CoreTimelineItem(title: '주문 접수', timestamp: '오전 10:00', description: '접수했어요.'),
  CoreTimelineItem(title: '처리 중', timestamp: '오전 11:30', description: '포장 중이에요.'),
  CoreTimelineItem(title: '발송 완료', timestamp: '오후 2:00', description: '보냈어요.'),
];

/// 시각 · 제목 · 설명이 모두 긴 항목 — 줄바꿈을 보여 주는 자리에 쓴다.
const CoreTimelineItem timelineLongItem = CoreTimelineItem(
  title: '주문이 접수되어 결제 확인을 기다리고 있어요',
  timestamp: '3월 12일 목요일 오전 10:00',
  description: '결제가 확인되면 판매자에게 주문 내용을 보내고 상품 준비를 시작해요. 확인에는 시간이 걸릴 수 있어요.',
);

/// `timeline/long-text` 장면의 항목.
const List<CoreTimelineItem> timelineLongItems = [
  timelineLongItem,
  CoreTimelineItem(title: '처리 중', timestamp: '오전 11:30'),
];

/// `timeline/connector` 장면의 항목 — 가운데 줄만 높다.
const List<CoreTimelineItem> timelineConnectorItems = [
  CoreTimelineItem(title: '주문 접수', timestamp: '오전 10:00'),
  CoreTimelineItem(
    title: '처리 중',
    timestamp: '오전 11:30',
    description: '상품을 포장하고 송장을 붙이는 중이에요. 설명이 길어지면 줄이 높아지고, 연결선도 그 높이만큼 길어져요.',
  ),
  CoreTimelineItem(title: '발송 완료', timestamp: '오후 2:00'),
];

/// `timeline/states` 장면의 항목 — 비운 값과 마지막 항목.
const List<CoreTimelineItem> timelineStateItems = [
  CoreTimelineItem(title: '시각 · 제목 · 설명', timestamp: '오전 10:00', description: '세 값을 모두 준 항목이에요.'),
  CoreTimelineItem(title: '설명이 없는 항목', timestamp: '오전 11:30'),
  CoreTimelineItem(title: '시각이 없는 항목', description: '시각 칸은 비어 있어요.'),
  CoreTimelineItem(title: '마지막 항목', timestamp: '오후 2:00', description: '점 아래에 선이 없어요.'),
];

/// 카드 장면의 짧은 이력.
const List<CoreTimelineItem> timelineShortItems = [
  CoreTimelineItem(title: '접수', timestamp: '10:00'),
  CoreTimelineItem(title: '처리', timestamp: '11:30'),
  CoreTimelineItem(title: '발송', timestamp: '14:00'),
];

/// `timeline/do-optional` 카드의 항목 — 설명이 있는 것과 없는 것.
const List<CoreTimelineItem> timelineOptionalItems = [
  CoreTimelineItem(title: '접수', timestamp: '10:00', description: '주문을 받았어요.'),
  CoreTimelineItem(title: '처리 중', timestamp: '11:30'),
];

/// `timeline/do-state-text` 카드의 항목 — 상태를 글로 말한다.
const List<CoreTimelineItem> timelineStateTextItems = [
  CoreTimelineItem(title: '접수 완료', timestamp: '10:00'),
  CoreTimelineItem(title: '발송 실패', timestamp: '11:30', description: '주소를 확인해 주세요.'),
];

/// `timeline/dont-state-color` 카드의 항목 — 글에는 상태가 없다.
const List<CoreTimelineItem> timelineStateColorItems = [
  CoreTimelineItem(title: '접수', timestamp: '10:00'),
  CoreTimelineItem(title: '발송', timestamp: '11:30'),
];

/// 항목 수를 말하는 제목 — `timeline/do-count` 카드.
const String timelineCountHeading = '주문 이력 · 3건';

/// 좁은 카드에서 쓰는 스타일 — 시각 칸만 줄인다.
const CoreTimelineStyle timelineCompactStyle = CoreTimelineStyle(timeColumnWidth: CoreSpace.space72);

/// 한 항목의 실패를 점 색으로 말하려 한 스타일 — 모든 점이 함께 바뀐다.
const CoreTimelineStyle timelineErrorDotStyle = CoreTimelineStyle(
  timeColumnWidth: CoreSpace.space72,
  dotColor: CoreColor.token(CoreColors.error),
);

/// 점만 키운 스타일 — 점의 가운데가 제목 첫 줄의 가운데보다 아래로 내려간다.
const CoreTimelineStyle timelineLargeDotStyle = CoreTimelineStyle(
  timeColumnWidth: CoreSpace.space72,
  dotSize: CoreSpace.space16,
);

/// 점을 키우면서 위 여백도 맞춘 스타일.
const CoreTimelineStyle timelineAlignedDotStyle = CoreTimelineStyle(
  timeColumnWidth: CoreSpace.space72,
  dotSize: CoreSpace.space16,
  dotTopMargin: CoreSpace.space2,
);

/// `timeline/styled` 장면의 스타일 — "사용 예" 의 코드와 같은 값이다.
const CoreTimelineStyle timelineStyledStyle = CoreTimelineStyle(
  dotColor: CoreColor.token(CoreColors.success),
  dotSize: CoreSpace.space16,
  dotTopMargin: CoreSpace.space2,
  connectorThickness: CoreStrokeWidth.stroke1,
  rowSpacing: CoreSpace.space24,
);

/// 고를 수 있는 항목 수.
const List<int> _countOptions = [1, 2, 3];

/// 고를 수 있는 시각 칸 폭 — 마지막이 기본값이다.
const List<double> _timeColumnWidthOptions = [
  CoreSpace.space72,
  CoreSpace.space96,
  CoreTimelineStyle.defaultTimeColumnWidth,
];

/// 속성 → 항목. `count` 는 1 … [timelineOrderItems] 의 길이이고, 없으면 전부다.
List<CoreTimelineItem> timelinePreviewItems(Map<String, String> props) {
  final count = (int.tryParse(props['count'] ?? '') ?? timelineOrderItems.length).clamp(1, timelineOrderItems.length);
  final source = [
    if (previewFlag(props, 'long')) timelineLongItem else timelineOrderItems.first,
    ...timelineOrderItems.skip(1),
  ];
  final showTimestamp = previewFlag(props, 'timestamp');
  final showDescription = previewFlag(props, 'description');
  return [
    for (final item in source.take(count))
      CoreTimelineItem(
        title: item.title,
        timestamp: showTimestamp ? item.timestamp : null,
        description: showDescription ? item.description : null,
      ),
  ];
}

/// 속성의 `timeColumnWidth` → 폭(logical px). `CoreSpace` 의 단계가 아니면
/// `null` — 그때 미리보기는 기본 폭을 그린다.
double? timelinePreviewTimeColumnWidth(Map<String, String> props) {
  final px = double.tryParse(props['timeColumnWidth'] ?? '');
  return px != null && CoreSpace.steps.contains(px) ? px : null;
}

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'count': '${timelineOrderItems.length}',
    'timeColumnWidth': '${CoreTimelineStyle.defaultTimeColumnWidth.toInt()}',
    'timestamp': 'true',
    'description': 'true',
  },
  controls: [
    DocsPlaygroundChoice(
      label: '항목 수',
      prop: 'count',
      options: [for (final count in _countOptions) '$count'],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'timeColumnWidth',
      prop: 'timeColumnWidth',
      options: [for (final width in _timeColumnWidthOptions) '${width.toInt()}'],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '시각', on: {'timestamp': 'true'}),
    const DocsPlaygroundFlag(label: '설명', on: {'description': 'true'}),
    const DocsPlaygroundFlag(label: '첫 항목에 긴 글', on: {'long': 'true'}),
  ],
  code: _timelineCode,
);

/// 속성 → 코드. 기본값과 같은 시각 칸 폭은 적지 않는다.
String _timelineCode(Map<String, String> props, String? label) {
  final width = timelinePreviewTimeColumnWidth(props);
  return [
    'Timeline(',
    '  items: [',
    for (final item in timelinePreviewItems(props)) ...[
      '    CoreTimelineItem(',
      "      title: '${item.title}',",
      if (item.timestamp case final timestamp?) "      timestamp: '$timestamp',",
      if (item.description case final description?) "      description: '$description',",
      '    ),',
    ],
    '  ],',
    if (width != null && width != CoreTimelineStyle.defaultTimeColumnWidth)
      '  timelineStyle: CoreTimelineStyle(timeColumnWidth: CoreSpace.space${width.toInt()}),',
    ')',
  ].join('\n');
}

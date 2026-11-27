/// Tracker 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `tracker_web.dart` · `tracker_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 다섯이다: `segments`(구간 수) · `itemHeight` · `itemSpacing` ·
/// `rounded` · `segmentColor`(`primary` 면 모든 구간을 한 색으로 칠한다).
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/tracker.md`.
const String slug = 'tracker';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. Tracker 에는 크기 단계가 없고 높이는 `itemHeight` 값 하나다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 장면의 폭. Tracker 는 부모의 폭을 나눠 쓰므로 장면마다 폭을 정한다.
const double trackerSceneWidth = CoreSpace.space256 + CoreSpace.space64;

/// 카드 안 장면의 폭.
const double trackerCardWidth = CoreSpace.space192;

/// 처음에 보이는 구간 수.
const int trackerDefaultCount = 14;

/// 플레이그라운드에서 고를 수 있는 구간 수.
const List<int> trackerCountOptions = [7, trackerDefaultCount, 30];

/// 플레이그라운드에서 고를 수 있는 구간 높이.
const List<double> trackerHeightOptions = [
  CoreSpace.space16,
  CoreSpace.space24,
  CoreSpace.space32,
  CoreSpace.space48,
];

/// 플레이그라운드에서 고를 수 있는 구간 간격.
const List<double> trackerSpacingOptions = [CoreSpace.space0, CoreSpace.space2, CoreSpace.space4];

/// 상태를 말하는 낱말 — 툴팁과 요약 문장이 함께 쓴다.
const Map<CoreTrackerStatus, String> trackerStatusWords = {
  CoreTrackerStatus.fine: '정상',
  CoreTrackerStatus.warning: '느림',
  CoreTrackerStatus.critical: '중단',
  CoreTrackerStatus.unknown: '기록 없음',
};

const CoreTrackerStatus _fine = CoreTrackerStatus.fine;
const CoreTrackerStatus _warning = CoreTrackerStatus.warning;
const CoreTrackerStatus _critical = CoreTrackerStatus.critical;
const CoreTrackerStatus _unknown = CoreTrackerStatus.unknown;

/// 장면과 플레이그라운드가 쓰는 30일 이력 — 앞에서부터 필요한 만큼 쓴다.
const List<CoreTrackerStatus> trackerHistory = [
  _fine,
  _fine,
  _fine,
  _warning,
  _fine,
  _critical,
  _fine,
  _fine,
  _unknown,
  _fine,
  _fine,
  _warning,
  _fine,
  _fine,
  _fine,
  _fine,
  _fine,
  _fine,
  _warning,
  _fine,
  _fine,
  _fine,
  _fine,
  _critical,
  _fine,
  _fine,
  _fine,
  _unknown,
  _fine,
  _fine,
];

/// 구간이 많은 장면의 60칸 이력.
const List<CoreTrackerStatus> trackerDenseHistory = [...trackerHistory, ...trackerHistory];

/// 구간이 많은 장면의 `trackerStyle`.
const CoreTrackerStyle trackerDenseStyle = CoreTrackerStyle(itemSpacing: CoreSpace.space2);

/// 구조 그림의 이력.
const List<CoreTrackerStatus> trackerAnatomyHistory = [_fine, _fine, _warning, _fine, _critical, _unknown];

/// 구조 그림의 `trackerStyle` — 높이 · 간격 · 모서리를 키워 부분이 잘 보이게
/// 한다.
const CoreTrackerStyle trackerAnatomyStyle = CoreTrackerStyle(
  itemHeight: CoreSpace.space48,
  itemSpacing: CoreSpace.space12,
  endRadius: CoreRadius.radius12,
);

/// 높이 장면의 설명과 `itemHeight`.
const List<(String, double)> trackerHeightSamples = [
  ('itemHeight: 16', CoreSpace.space16),
  ('itemHeight: 32 (기본)', CoreTrackerStyle.defaultItemHeight),
  ('itemHeight: 48', CoreSpace.space48),
];

/// 형태 장면의 설명 · `rounded` · `endRadius`(`null` 이면 기본값).
const List<(String, bool, double?)> trackerShapeSamples = [
  ('rounded: true, endRadius: 2 (기본)', true, null),
  ('rounded: true, endRadius: 12', true, CoreRadius.radius12),
  ('rounded: false', false, null),
];

/// 관련 컴포넌트의 Timeline 그림이 그리는 사건.
const List<CoreTimelineItem> trackerRelatedEvents = [
  CoreTimelineItem(title: '배포 시작', timestamp: '09:00'),
  CoreTimelineItem(title: '배포 완료', timestamp: '09:12'),
];

/// 이력 → 구간 목록. 툴팁에 며칠째인지와 상태를 함께 적는다.
List<CoreTrackerSegment> trackerSegments(Iterable<CoreTrackerStatus> history) => [
  for (final (index, status) in history.indexed)
    CoreTrackerSegment(status: status, tooltip: '${index + 1}일 · ${trackerStatusWords[status]}'),
];

/// [trackerHistory] 앞의 [count] 일.
List<CoreTrackerSegment> trackerSample([int count = trackerDefaultCount]) =>
    trackerSegments(trackerHistory.take(count));

/// [trackerHistory] 앞의 [count] 일을 한 문장으로 — 상태마다 날 수를 센다.
String trackerSummary([int count = trackerDefaultCount]) {
  final history = trackerHistory.take(count).toList();
  final parts = [
    for (final status in CoreTrackerStatus.values)
      if (history.where((item) => item == status).length case final days when days > 0)
        '${trackerStatusWords[status]} $days일',
  ];
  return '최근 ${history.length}일: ${parts.join(' · ')}';
}

/// 속성의 `segments` → 구간 수. 선택지에 없는 값이면 기본값.
int trackerPreviewCount(Map<String, String> props) {
  final count = int.tryParse(props['segments'] ?? '');
  return trackerCountOptions.contains(count) ? count! : trackerDefaultCount;
}

/// 속성 → `trackerStyle`. 모두 기본값이면 `null`.
CoreTrackerStyle? trackerPreviewStyle(Map<String, String> props) {
  final itemHeight = _changedStep(props['itemHeight'], CoreTrackerStyle.defaultItemHeight);
  final itemSpacing = _changedStep(props['itemSpacing'], CoreTrackerStyle.defaultItemSpacing);
  final oneColor = props['segmentColor'] == 'primary';
  if (itemHeight == null && itemSpacing == null && !oneColor) return null;
  return CoreTrackerStyle(
    itemHeight: itemHeight,
    itemSpacing: itemSpacing,
    segmentColor: oneColor ? const CoreColor.token(CoreColors.primary) : null,
  );
}

/// `CoreSpace` 의 단계이면서 [fallback] 과 다른 값. 아니면 `null`.
double? _changedStep(String? raw, double fallback) {
  final px = double.tryParse(raw ?? '');
  if (px == null || px == fallback || !CoreSpace.steps.contains(px)) return null;
  return px;
}

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'segments': '$trackerDefaultCount',
    'itemHeight': '${CoreTrackerStyle.defaultItemHeight.toInt()}',
    'itemSpacing': '${CoreTrackerStyle.defaultItemSpacing.toInt()}',
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'segments',
      prop: 'segments',
      options: [for (final count in trackerCountOptions) '$count'],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'itemHeight',
      prop: 'itemHeight',
      options: [for (final height in trackerHeightOptions) '${height.toInt()}'],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'itemSpacing',
      prop: 'itemSpacing',
      options: [for (final spacing in trackerSpacingOptions) '${spacing.toInt()}'],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '각진 끝', on: {'rounded': 'false'}),
    const DocsPlaygroundFlag(label: '한 가지 색', on: {'segmentColor': 'primary'}),
  ],
  code: _trackerCode,
);

/// 속성 → 코드. 기본값과 같은 인자는 적지 않는다.
String _trackerCode(Map<String, String> props, String? label) {
  final style = trackerPreviewStyle(props);
  final lines = [
    'segments: [',
    for (final segment in trackerSample(trackerPreviewCount(props)))
      "  CoreTrackerSegment(status: CoreTrackerStatus.${segment.status.name}, tooltip: '${segment.tooltip}'),",
    '],',
    if (!previewFlag(props, 'rounded', fallback: true)) 'rounded: false,',
    if (style != null) ...[
      'trackerStyle: CoreTrackerStyle(',
      if (style.itemHeight case final height?) '  itemHeight: CoreSpace.space${height.toInt()},',
      if (style.itemSpacing case final spacing?) '  itemSpacing: CoreSpace.space${spacing.toInt()},',
      if (style.segmentColor != null) '  segmentColor: CoreColor.token(CoreColors.primary),',
      '),',
    ],
  ];
  return 'Tracker(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

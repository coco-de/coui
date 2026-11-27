/// Progress 페이지 — 플레이그라운드와 장면이 함께 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `progress_web.dart` · `progress_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 크기 표(`sizeSpec`)는 두지 않는다. 크기 표 블록의 행은 `CoreComponentSize` 인데
/// `Progress` 의 크기는 `xs2` 가 있는 `CoreProgressSize` 다. 크기 장면이 대신
/// Core 의 크기 행을 읽어 이름과 치수를 적는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/progress.md`.
const String slug = 'progress';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. `CoreProgressSize` 는 크기 표 블록의 행 타입이 아니라서 두지 않는다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기에 `value` 를 주지 않았을 때의 값.
const double progressDemoValue = 0.65;

/// 라벨 칸을 켰을 때의 이름.
const String progressDemoLabel = '파일 업로드';

/// 라벨 칸을 켰을 때의 보조 설명.
const String progressDemoCaption = '큰 파일은 시간이 더 걸립니다';

/// `progress/anatomy` 장면의 값.
const double progressPlanValue = 0.62;

/// `progress/anatomy` 장면의 이름.
const String progressPlanLabel = '팀 요금제';

/// `progress/anatomy` 장면의 값 글자.
const String progressPlanValueText = '62%';

/// `progress/anatomy` 장면의 보조 설명.
const String progressPlanCaption = 'AI 사용량 · 18일 남음';

/// `progress/segments` 장면의 단계 라벨.
const String progressStepLabel = '1 / 2단계';

/// 느린 작업 장면의 보조 설명.
const String progressSlowCaption = '대용량 파일 처리 중...';

/// 원형 진행률 사용 예의 설명.
const String progressRadialStatCaption = '이번 달 목표';

/// 원형 진행률 가운데에 직접 넣는 글.
const String progressRadialChildText = '3/5';

/// 한 줄 배치 장면의 이름.
const String progressRowLabel = '다운로드';

/// 한 줄 배치 장면의 값 글자.
const String progressRowValueText = '42%';

/// 접근성 장면에서 막대에 붙이는 이름.
const String progressA11yName = '파일 업로드';

/// 접근성 장면에서 원형 진행률에 붙이는 이름.
const String progressRadialA11yName = '저장 공간';

/// `progress/states` 장면 — 설명 · 값 · 톤.
const List<(String, double?, CoreProgressTone)> progressStateSamples = [
  ('시작 전 · value 0', 0, CoreProgressTone.primary),
  ('진행 중 · value 0.65', 0.65, CoreProgressTone.primary),
  ('완료 · tone success', 1, CoreProgressTone.success),
  ('실패 · tone destructive', 0.4, CoreProgressTone.destructive),
  ('불확정 · value null', null, CoreProgressTone.primary),
];

/// `progress/segment-count` 장면의 칸 수.
const int progressCountCells = 4;

/// `progress/segment-count` 장면의 값.
const List<double> progressCountSamples = [0.24, 0.25, 0.99, 1];

/// 속성 `value` → 진행 값. `null` 이라고 적으면 불확정 막대이고, 적지 않으면
/// [progressDemoValue] 다.
double? progressPreviewValue(Map<String, String> props) {
  final raw = props['value'];
  if (raw == 'null') return null;
  final parsed = double.tryParse(raw ?? '') ?? progressDemoValue;
  return parsed.clamp(CoreProgressContract.defaultMin, CoreProgressContract.defaultMax).toDouble();
}

/// 속성 `segments` → 칸 수. 없거나 1보다 작으면 `null`(연속 막대).
int? progressPreviewSegments(Map<String, String> props) {
  final parsed = int.tryParse(props['segments'] ?? '');
  return parsed != null && parsed >= 1 ? parsed : null;
}

/// [value] 까지 채워지는 칸 수 — 위젯이 쓰는 것과 같은 계산이다.
int progressFilledCells(double value, int segments) => CoreProgressContract.filledSegmentsOf(
  value: value,
  min: CoreProgressContract.defaultMin,
  max: CoreProgressContract.defaultMax,
  segments: segments,
);

/// 값 칸의 글자 — 연속 막대는 백분율, 단계형은 단계. 불확정이면 `null`.
String? progressPreviewValueText(double? value, int? segments) {
  if (value == null) return null;
  if (segments == null) return '${(value * 100).round()}%';
  return '${progressFilledCells(value, segments)} / $segments단계';
}

/// `progress/segment-count` 장면의 한 줄 설명.
String progressCountCaption(double value) =>
    'value ${docsSizeNumber(value)} → ${progressFilledCells(value, progressCountCells)}칸';

/// 직선형 크기 장면의 설명 — 두께를 Core 의 크기 행에서 읽는다.
String progressSizeCaption(CoreProgressSize size) {
  final thickness = docsSizeNumber(CoreProgressStyle.defaultsBySize[size]!.minHeight);
  final suffix = size == CoreProgressSize.defaultSize ? ' · 기본' : '';
  return '${size.name} · 두께 $thickness$suffix';
}

/// 원형 크기 장면의 설명 — 지름과 링 두께를 Core 의 크기 행에서 읽는다.
String progressRadialSizeCaption(CoreProgressSize size) {
  final row = CoreRadialProgressStyle.defaultsBySize[size]!;
  final suffix = size == CoreRadialProgressContract.defaultSize ? ' · 기본' : '';
  return '${size.name} · 지름 ${docsSizeNumber(row.size)} · 두께 ${docsSizeNumber(row.strokeWidth)}$suffix';
}

// 톤과 크기 선택지는 enum 과 크기 행에서 읽는다 — 톤이나 크기가 늘면
// 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'value': '$progressDemoValue',
    'tone': CoreProgressTone.defaultTone.name,
    'size': CoreProgressSize.defaultSize.name,
    'labelled': 'true',
  },
  controls: [
    const DocsPlaygroundChoice(
      label: 'value',
      prop: 'value',
      options: ['0', '0.25', '0.65', '1', 'null'],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'tone',
      prop: 'tone',
      options: [for (final tone in CoreProgressTone.values) tone.name],
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreProgressStyle.defaultsBySize.keys) size.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '4칸 단계형', on: {'segments': '4'}),
    const DocsPlaygroundFlag(label: '라벨 · 값 · 캡션', on: {'labelled': 'true'}),
    const DocsPlaygroundFlag(label: '값 전환 애니메이션 끄기', on: {'disableAnimation': 'true'}),
  ],
  code: _progressCode,
);

/// 속성 → 코드. 기본값과 같은 인자는 적지 않는다. 불확정 막대는 `segments` 와
/// `disableAnimation` 을 쓰지 않으므로 적지 않는다.
String _progressCode(Map<String, String> props, String? label) {
  final value = progressPreviewValue(props);
  final segments = value == null ? null : progressPreviewSegments(props);
  final tone = previewEnum(CoreProgressTone.values, props['tone'], CoreProgressTone.defaultTone);
  final size = previewEnum(CoreProgressSize.values, props['size'], CoreProgressSize.defaultSize);
  final labelled = previewFlag(props, 'labelled');
  final valueText = progressPreviewValueText(value, segments);
  final lines = [
    if (value != null) 'value: ${docsSizeNumber(value)},',
    if (segments != null) 'segments: $segments,',
    if (tone != CoreProgressTone.defaultTone) 'tone: CoreProgressTone.${tone.name},',
    if (size != CoreProgressSize.defaultSize) 'size: CoreProgressSize.${size.name},',
    if (value != null && previewFlag(props, 'disableAnimation')) 'disableAnimation: true,',
    if (labelled) "label: Text('${label ?? progressDemoLabel}'),",
    if (labelled && valueText != null) "valueLabel: Text('$valueText'),",
    if (labelled) "caption: Text('$progressDemoCaption'),",
  ];
  if (lines.isEmpty) return 'Progress()';
  return 'Progress(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

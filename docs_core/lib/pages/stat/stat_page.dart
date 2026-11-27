/// Stat 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `stat_web.dart` · `stat_flutter.dart` 가 그린다. 두 플랫폼 장면이
/// 같은 글과 폭을 쓰도록 예시 값과 폭은 이 파일에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/stat.md`.
const String slug = 'stat';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _statSizeSpec;

/// 카드 한 장짜리 장면과 속성 미리보기의 폭.
const double statSceneWidth = CoreLayout.layout240;

/// 큰 숫자(display)를 보이는 장면의 폭.
const double statWideWidth = CoreLayout.layout280;

/// 두 열로 놓는 장면의 폭.
const double statGridWidth = CoreLayout.layout400;

/// 추세 장면과 관련 컴포넌트 장면의 작은 폭.
const double statSmallWidth = CoreLayout.layout160;

/// 미리보기의 예시 라벨.
const String statSampleLabel = '월간 주문';

/// 미리보기의 예시 값.
const String statSampleValue = '1,284';

/// 미리보기의 예시 단위.
const String statSampleUnit = '건';

/// 미리보기의 예시 설명 줄.
const String statSampleDescription = '지난 30일';

/// 추세마다 변동 줄에 적는 글.
const Map<CoreStatChangeType, String> statSampleChanges = {
  CoreStatChangeType.positive: '+20.1%',
  CoreStatChangeType.negative: '-4.3%',
  CoreStatChangeType.neutral: '변동 없음',
};

/// 장면에 놓는 작은 카드 한 장의 내용.
typedef StatSample = ({String label, String value, String? unit, String change, CoreStatChangeType type});

/// `stat/trend` 장면 — 추세마다 한 장.
const List<StatSample> statTrendSamples = [
  (label: '신규 가입', value: '1,284', unit: '명', change: '+8.2%', type: CoreStatChangeType.positive),
  (label: '취소율', value: '1.4', unit: '%', change: '-0.3%p', type: CoreStatChangeType.negative),
  (label: '활성 세션', value: '892', unit: null, change: '변동 없음', type: CoreStatChangeType.neutral),
];

/// `stat/grid` 장면 — 두 열에 놓는 네 장.
const List<StatSample> statGridSamples = [
  (label: '총 사용자', value: '12,480', unit: '명', change: '+5.2%', type: CoreStatChangeType.positive),
  (label: '새 주문', value: '384', unit: '건', change: '+12건', type: CoreStatChangeType.positive),
  (label: '전환율', value: '2.4', unit: '%', change: '-0.3%p', type: CoreStatChangeType.negative),
  (label: '평균 응답', value: '245', unit: 'ms', change: '변동 없음', type: CoreStatChangeType.neutral),
];

/// `stat/related-number-ticker` 장면의 숫자.
const int statTickerValue = 1284;

/// `stat/related-number-ticker` 장면이 숫자를 글로 바꾸는 방법.
String statTickerText(num value) => '${value.round()}건';

/// 크기 표에 행이 있는 크기 — 작은 크기부터.
final List<CoreComponentSize> statSizes = [
  for (final size in CoreComponentSize.values)
    if (CoreStatStyle.defaultsBySize.containsKey(size)) size,
];

/// 속성의 `size` → 크기. 표에 없는 이름은 `md`.
CoreComponentSize statPreviewSize(Map<String, String> props) =>
    previewEnum(statSizes, props['size'], CoreComponentSize.md);

/// 속성 → 변동 종류. `change` 가 꺼져 있으면 `null` 이고 변동 줄이 없다.
CoreStatChangeType? statPreviewChange(Map<String, String> props) => previewFlag(props, 'change')
    ? previewEnum(CoreStatChangeType.values, props['changeType'], CoreStatChangeType.positive)
    : null;

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'variant': CoreStatVariant.defaultVariant.name,
    'size': CoreComponentSize.md.name,
    'changeType': CoreStatChangeType.positive.name,
    'change': 'true',
    'unit': 'true',
    'description': 'true',
  },
  label: statSampleLabel,
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreStatVariant.values) variant.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in statSizes) size.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'changeType',
      prop: 'changeType',
      options: [for (final type in CoreStatChangeType.values) type.name],
    ),
    const DocsPlaygroundFlag(label: '변동 줄', on: {'change': 'true'}),
    const DocsPlaygroundFlag(label: '단위', on: {'unit': 'true'}),
    const DocsPlaygroundFlag(label: '설명 줄', on: {'description': 'true'}),
    const DocsPlaygroundFlag(label: '아이콘', on: {'icon': 'calendar'}),
    const DocsPlaygroundFlag(label: '값이 아직 없음', on: {'empty': 'true'}),
  ],
  code: _statCode,
);

/// 속성 → 코드. 기본값과 같은 축은 적지 않는다.
String _statCode(Map<String, String> props, String? label) {
  final variant = previewEnum(CoreStatVariant.values, props['variant'], CoreStatVariant.defaultVariant);
  final size = statPreviewSize(props);
  final change = statPreviewChange(props);
  final icon = props['icon'];
  final lines = <String>[
    "label: '${label ?? statSampleLabel}',",
    if (!previewFlag(props, 'empty')) "value: '$statSampleValue',",
    if (previewFlag(props, 'unit')) "unit: '$statSampleUnit',",
    if (variant != CoreStatVariant.defaultVariant) 'variant: CoreStatVariant.${variant.name},',
    if (size != CoreComponentSize.md) 'size: CoreComponentSize.${size.name},',
    if (change != null) ...[
      "change: '${statSampleChanges[change]}',",
      'changeType: CoreStatChangeType.${change.name},',
    ],
    if (previewFlag(props, 'description')) "description: '$statSampleDescription',",
    if (icon != null) 'icon: Icon(LucideIcons.${docsIconIdentifier(icon)}),',
  ];
  return 'Stat(\n${lines.map((line) => '  $line').join('\n')}\n)';
}

DocsSizeSpec _statSizeSpec() => DocsSizeSpec(
  columns: const ['size', '여백 (위아래 · 좌우)', '줄 간격', '라벨 · 설명', '값', '단위 · 변동'],
  rows: [for (final size in statSizes) _statSizeRow(size, CoreStatStyle.defaultsBySize[size]!)],
);

DocsSizeSpecRow _statSizeRow(CoreComponentSize size, CoreStatStyle row) {
  return DocsSizeSpecRow(
    size: size,
    cells: [
      '${docsSizeNumber(row.padding?.top)} · ${docsSizeNumber(row.padding?.left)}',
      docsSizeNumber(row.contentGapStyle?.size),
      '${_textCell(row.labelTextStyle)} · ${_textCell(row.descriptionTextStyle)}',
      _textCell(row.valueTextStyle),
      '${_textCell(row.unitTextStyle)} · ${_textCell(row.changeTextStyle)}',
    ],
  );
}

/// 글자 칸 — 역할의 크기에, 크기 행이 따로 적은 굵기가 있으면 그 굵기를 적는다.
String _textCell(CoreTextStyle? style) =>
    docsSizeLabel(docsSizeResolve(style)?.copyWith(fontWeight: style?.fontWeight));

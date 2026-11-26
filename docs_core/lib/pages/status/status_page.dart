/// Status 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `status_web.dart` · `status_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 다섯이다: `variant`(enum 값의 이름, `null` 이면 주지 않는다) ·
/// `color` · `size` · `showLabel`(점 옆의 보이는 글자) · `animated`.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/status.md`.
const String slug = 'status';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _statusSpec;

/// `color` 를 주지 않았을 때의 값 — 위젯 생성자의 기본값.
const CoreStatusColor statusDefaultColor = CoreStatusColor.neutral;

/// `size` 를 주지 않았을 때의 값 — 위젯 생성자의 기본값.
const CoreStatusSize statusDefaultSize = CoreStatusSize.md;

/// `variant` 선택지에서 `variant` 를 주지 않는 칸의 이름.
const String statusNoVariantOption = 'null';

/// 접속 상태를 말하는 낱말 — 두 플랫폼의 속성 빌더와 장면이 함께 읽는다.
const Map<CoreStatusVariant, String> statusVariantWords = {
  CoreStatusVariant.online: '온라인',
  CoreStatusVariant.busy: '방해 금지',
  CoreStatusVariant.away: '자리 비움',
  CoreStatusVariant.offline: '오프라인',
};

/// 색 이름을 말하는 낱말.
const Map<CoreStatusColor, String> statusColorWords = {
  CoreStatusColor.neutral: '중립',
  CoreStatusColor.primary: '주요',
  CoreStatusColor.secondary: '보조',
  CoreStatusColor.tertiary: '3차',
  CoreStatusColor.info: '정보',
  CoreStatusColor.success: '성공',
  CoreStatusColor.warning: '경고',
  CoreStatusColor.error: '오류',
};

/// 속성의 `variant` → 접속 상태. 없거나 모르는 이름(`null` 포함)이면 `null`.
CoreStatusVariant? statusPreviewVariant(Map<String, String> props) {
  for (final variant in CoreStatusVariant.values) {
    if (variant.name == props['variant']) return variant;
  }
  return null;
}

/// 미리보기와 코드가 쓰는 상태 낱말 — [label] 이 있으면 그것을, 없으면
/// [variant] 의 낱말을, [variant] 도 없으면 [color] 의 낱말을 쓴다.
String statusPreviewWord(CoreStatusVariant? variant, CoreStatusColor color, String? label) =>
    label ?? (variant == null ? statusColorWords[color]! : statusVariantWords[variant]!);

/// 구조 그림의 `statusStyle` — 점 · 막대 · 간격을 키워 번호가 부분을 가리키게
/// 한다.
const CoreStatusStyle statusAnatomyStyle = CoreStatusStyle(
  size: CoreSize.size48,
  barLength: CoreSize.size24,
  barWidth: CoreStrokeWidth.stroke8,
  labelSpacing: CoreSpace.space48,
);

/// 서비스 목록 장면의 색과 글.
const List<(CoreStatusColor, String)> statusServiceSamples = [
  (CoreStatusColor.success, 'API 서버 · 정상'),
  (CoreStatusColor.warning, '배치 작업 · 지연'),
  (CoreStatusColor.error, '결제 모듈 · 장애'),
];

/// 아바타 장면의 이니셜과 접속 상태.
const List<(String, CoreStatusVariant)> statusAvatarSamples = [
  ('AB', CoreStatusVariant.online),
  ('CD', CoreStatusVariant.busy),
  ('EF', CoreStatusVariant.away),
  ('GH', CoreStatusVariant.offline),
];

/// 색만 다른 점을 늘어놓은 예의 색.
const List<CoreStatusColor> statusColorOnlySamples = [
  CoreStatusColor.success,
  CoreStatusColor.warning,
  CoreStatusColor.error,
  CoreStatusColor.neutral,
];

/// 관련 컴포넌트의 Tracker 그림이 그리는 이력.
const List<CoreTrackerStatus> statusHistorySamples = [
  CoreTrackerStatus.fine,
  CoreTrackerStatus.fine,
  CoreTrackerStatus.warning,
  CoreTrackerStatus.fine,
  CoreTrackerStatus.critical,
  CoreTrackerStatus.fine,
];

// 선택지는 enum 과 크기 행에서 읽는다 — 접속 상태 · 색 · 크기 행이 늘면
// 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'variant': CoreStatusVariant.online.name,
    'color': statusDefaultColor.name,
    'size': statusDefaultSize.name,
    'showLabel': 'true',
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreStatusVariant.values) variant.name, statusNoVariantOption],
    ),
    DocsPlaygroundChoice(label: 'color', prop: 'color', options: [for (final c in CoreStatusColor.values) c.name]),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreStatusStyle.defaultsBySize.keys) size.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '보이는 글자', on: {'showLabel': 'true'}),
    const DocsPlaygroundFlag(label: '맥동', on: {'animated': 'true'}),
  ],
  code: _statusCode,
);

/// 속성 → 코드. 기본값과 같은 인자는 적지 않고, `variant` 가 있으면 쓰이지 않는
/// `color` 를 적지 않는다. 보이는 글자가 없으면 같은 낱말을 `semanticLabel` 로
/// 적는다.
String _statusCode(Map<String, String> props, String? label) {
  final variant = statusPreviewVariant(props);
  final color = previewEnum(CoreStatusColor.values, props['color'], statusDefaultColor);
  final size = previewEnum(CoreStatusSize.values, props['size'], statusDefaultSize);
  final word = statusPreviewWord(variant, color, label);
  final lines = [
    if (variant != null)
      'variant: CoreStatusVariant.${variant.name},'
    else if (color != statusDefaultColor)
      'color: CoreStatusColor.${color.name},',
    if (size != statusDefaultSize) 'size: CoreStatusSize.${size.name},',
    if (previewFlag(props, 'showLabel')) "label: Text('$word')," else "semanticLabel: '$word',",
    if (previewFlag(props, 'animated')) 'animated: true,',
  ];
  return 'Status(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _statusSpec() {
  return DocsSizeSpec(
    columns: const ['size', '점 지름', 'busy 막대 길이', '라벨 글자', '점 · 라벨 간격'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreStatusStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          // 크기 표의 행은 `CoreComponentSize` 로 적는다 — `CoreStatusSize` 는
          // 같은 이름의 다섯 단계(xs … xl)다.
          size: CoreComponentSize.values.byName(size.name),
          cells: [
            docsSizeNumber(row.size),
            docsSizeNumber(row.barLength),
            docsSizeLabel(row.labelStyle),
            docsSizeNumber(row.labelSpacing),
          ],
        ),
    ],
  );
}

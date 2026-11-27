/// Indicator 페이지 — 플레이그라운드와 장면이 함께 읽는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `indicator_web.dart` · `indicator_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성 `item` · `child` 는 슬롯에 무엇을 넣을지 고르는 문서 속성이다 —
/// `item` 은 `count`(기본) · `dot` · `label`, `child` 는 `button`(기본) ·
/// `avatar`.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/indicator.md`.
const String slug = 'indicator';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. Indicator 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// `offset` 선택지 — 속성에 적는 이름과 값(논리 px).
const Map<String, double> indicatorOffsetSteps = {
  '-4': -CoreSpace.space4,
  '0': CoreIndicatorStyle.defaultOffset,
  '4': CoreSpace.space4,
  '8': CoreSpace.space8,
};

/// `ringWidth` 선택지 — 속성에 적는 이름과 값(논리 px).
const Map<String, double> indicatorRingSteps = {
  '0': CoreStrokeWidth.stroke0,
  '2': CoreIndicatorStyle.defaultRingWidth,
  '4': CoreStrokeWidth.stroke4,
};

/// 모서리 네 자리 — 위치 장면이 두 플랫폼에서 같은 순서로 그린다.
const List<(CoreIndicatorHorizontalPosition, CoreIndicatorVerticalPosition)> indicatorCorners = [
  (CoreIndicatorHorizontalPosition.start, CoreIndicatorVerticalPosition.top),
  (CoreIndicatorHorizontalPosition.end, CoreIndicatorVerticalPosition.top),
  (CoreIndicatorHorizontalPosition.start, CoreIndicatorVerticalPosition.bottom),
  (CoreIndicatorHorizontalPosition.end, CoreIndicatorVerticalPosition.bottom),
];

/// offset 장면이 나란히 보이는 값 — [indicatorOffsetSteps] 의 이름.
const List<String> indicatorOffsetSamples = ['-4', '0', '8'];

/// 아바타를 `child` 로 쓸 때의 이니셜.
const String indicatorSampleInitials = 'KS';

/// 버튼을 `child` 로 쓸 때의 글.
const String indicatorSampleButtonText = '받은 편지함';

/// 미리보기에 라벨을 주지 않았을 때 `item` 배지에 넣는 글.
String indicatorSampleText(String item, String? label) => label ?? (item == 'label' ? '신규' : '3');

// 위치 선택지는 모서리 네 자리다. `center` · `middle` 은 두 플랫폼의 그림이
// 달라 본문의 위치 섹션에서 따로 설명한다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'horizontalPosition': CoreIndicatorHorizontalPosition.end.name,
    'verticalPosition': CoreIndicatorVerticalPosition.top.name,
    'offset': '0',
    'ringWidth': '2',
    'item': 'count',
    'child': 'button',
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'horizontalPosition',
      prop: 'horizontalPosition',
      options: [
        for (final position in CoreIndicatorHorizontalPosition.values)
          if (position != CoreIndicatorHorizontalPosition.center) position.name,
      ],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'verticalPosition',
      prop: 'verticalPosition',
      options: [
        for (final position in CoreIndicatorVerticalPosition.values)
          if (position != CoreIndicatorVerticalPosition.middle) position.name,
      ],
      segmented: true,
    ),
    DocsPlaygroundChoice(label: 'offset', prop: 'offset', options: [...indicatorOffsetSteps.keys], segmented: true),
    DocsPlaygroundChoice(
      label: 'ringWidth',
      prop: 'ringWidth',
      options: [...indicatorRingSteps.keys],
      segmented: true,
    ),
    const DocsPlaygroundChoice(label: 'item 내용', prop: 'item', options: ['count', 'dot', 'label'], segmented: true),
    const DocsPlaygroundChoice(label: 'child 내용', prop: 'child', options: ['button', 'avatar'], segmented: true),
  ],
  code: _indicatorCode,
);

/// 기본값이 아닌 `offset` 을 코드에 적는 글.
const Map<String, String> _offsetCode = {
  '-4': '-CoreSpace.space4',
  '4': 'CoreSpace.space4',
  '8': 'CoreSpace.space8',
};

/// 기본값이 아닌 `ringWidth` 를 코드에 적는 글.
const Map<String, String> _ringCode = {
  '0': 'CoreStrokeWidth.stroke0',
  '4': 'CoreStrokeWidth.stroke4',
};

/// 속성 → 코드. 기본값과 같은 위치 · 스타일은 적지 않는다. 두 플랫폼의 코드가
/// 같다.
String _indicatorCode(Map<String, String> props, String? label) {
  final horizontal = previewEnum(
    CoreIndicatorHorizontalPosition.values,
    props['horizontalPosition'],
    CoreIndicatorHorizontalPosition.end,
  );
  final vertical = previewEnum(
    CoreIndicatorVerticalPosition.values,
    props['verticalPosition'],
    CoreIndicatorVerticalPosition.top,
  );
  final item = props['item'] ?? 'count';
  final styleLines = [
    if (_offsetCode[props['offset']] case final value?) 'offset: $value,',
    if (_ringCode[props['ringWidth']] case final value?) 'ringWidth: $value,',
  ];
  final lines = [
    if (horizontal != CoreIndicatorHorizontalPosition.end)
      'horizontalPosition: CoreIndicatorHorizontalPosition.${horizontal.name},',
    if (vertical != CoreIndicatorVerticalPosition.top)
      'verticalPosition: CoreIndicatorVerticalPosition.${vertical.name},',
    if (styleLines.isNotEmpty) ...[
      'indicatorStyle: CoreIndicatorStyle(',
      for (final line in styleLines) '  $line',
      '),',
    ],
    ..._itemCode(item, indicatorSampleText(item, label)),
    ..._childCode(props['child']),
  ];
  return 'Indicator(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

List<String> _itemCode(String item, String text) => switch (item) {
  'dot' => ['item: Status(color: CoreStatusColor.success, size: CoreStatusSize.lg),'],
  'label' => [
    'item: Badge(',
    '  tone: CoreBadgeTone.info,',
    '  variant: CoreBadgeVariant.filled,',
    '  size: CoreComponentSize.xs,',
    "  child: Text('$text'),",
    '),',
  ],
  _ => [
    'item: Badge(',
    '  tone: CoreBadgeTone.destructive,',
    '  variant: CoreBadgeVariant.filled,',
    '  form: CoreBadgeForm.count,',
    '  size: CoreComponentSize.xs,',
    "  child: Text('$text'),",
    '),',
  ],
};

List<String> _childCode(String? child) => switch (child) {
  'avatar' => ["child: Avatar(initials: '$indicatorSampleInitials', size: CoreComponentSize.xl),"],
  _ => [
    'child: Button(',
    '  onPressed: openInbox,',
    "  child: Text('$indicatorSampleButtonText'),",
    '),',
  ],
};

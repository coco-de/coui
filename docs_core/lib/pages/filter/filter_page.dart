/// Filter 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `filter_web.dart` · `filter_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/filter.md`.
const String slug = 'filter';

/// 미리보기 · 코드가 함께 쓰는 항목 — 값 · 라벨 · 아이콘 이름.
const List<(String, String, String)> kFilterPreviewItems = [
  ('all', '전체', 'hash'),
  ('upcoming', '예정', 'calendar'),
  ('starred', '관심', 'star'),
];

/// 라벨이 긴 예 — 값 · 라벨.
const List<(String, String)> kFilterLongItems = [
  ('ordering', '진행 중인 주문'),
  ('shipped', '배송이 끝난 주문'),
];

/// 함께 켤 수 있는 조건 — Filter 에 두면 안 되는 예와 ChipGroup 예가 같이 쓴다.
const List<(String, String)> kFilterFeatureItems = [
  ('wireless', '무선'),
  ('waterproof', '방수'),
  ('sale', '할인'),
];

/// 폭을 채우는 미리보기의 폭(logical px) — 두 플랫폼이 같은 폭으로 그린다.
const double kFilterPreviewFillWidth = 360;

/// 처음 고른 값 — `value` 속성이 없으면 첫 항목, `none` 이면 선택 없음.
String? filterPreviewValue(Map<String, String> props) => switch (props['value']) {
  'none' => null,
  final value? => value,
  null => kFilterPreviewItems.first.$1,
};

/// 칸에 아이콘을 두는가 — 라벨을 끈 칸은 아이콘이 있어야 보이므로 함께 켠다.
bool filterPreviewShowsIcon(Map<String, String> props) =>
    previewFlag(props, 'icon') || !previewFlag(props, 'showLabel', fallback: true);

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'size': 'md', 'showResetButton': 'true'},
  controls: [
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md'], segmented: true),
    DocsPlaygroundFlag(label: '초기화 버튼', on: {'showResetButton': 'true'}),
    DocsPlaygroundFlag(label: '아이콘', on: {'icon': 'true'}),
    DocsPlaygroundFlag(label: '아이콘만', on: {'showLabel': 'false'}),
    DocsPlaygroundFlag(label: '폭 채우기', on: {'fillWidth': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _filterCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// Filter 의 크기 행은 초기화 버튼과 구분선만 정하고, 트랙과 칸은 안에 있는
/// ToggleGroup 의 같은 크기 행이 정한다 — 그래서 각 열을 그 행에서 읽는다.
DocsSizeSpec Function()? get sizeSpec => _filterSpec;

String _filterCode(Map<String, String> props, String? label) {
  final size = previewEnum(CoreComponentSize.values, props['size'], CoreFilterContract.defaultSize);
  final showReset = previewFlag(props, 'showResetButton');
  final showIcon = filterPreviewShowsIcon(props);
  final showLabel = previewFlag(props, 'showLabel', fallback: true);

  List<String> item((String, String, String) entry) {
    final (value, text, icon) = entry;
    if (!showIcon) return ["CoreFilterItem(value: '$value', label: '$text'),"];
    return [
      'CoreFilterItem(',
      "  value: '$value',",
      "  label: '$text',",
      '  icon: Icon(LucideIcons.${docsIconIdentifier(icon)}),',
      if (!showLabel) '  showLabel: false,',
      '),',
    ];
  }

  final lines = [
    if (size != CoreFilterContract.defaultSize) 'size: CoreComponentSize.${size.name},',
    'groupValue: selected,',
    'onValueChanged: setSelected,',
    if (showReset) ...['showResetButton: true,', 'onReset: clearSelected,'],
    if (previewFlag(props, 'fillWidth')) 'fillWidth: true,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'items: ${showIcon ? '' : 'const '}[',
    for (final entry in kFilterPreviewItems)
      for (final line in item(entry)) '  $line',
    '],',
  ];
  return 'Filter<String>(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _filterSpec() {
  // 크기 행의 맵은 기본 크기부터 적혀 있다 — 표는 작은 크기부터 놓는다.
  final sizes = CoreFilterStyle.defaultsBySize.keys.toList()..sort((a, b) => a.index.compareTo(b.index));
  return DocsSizeSpec(
    columns: const ['size', '트랙 높이', '칸 높이', '트랙 · 칸 모서리', '라벨', '초기화 버튼 · 모서리', '초기화 아이콘 · 구분선 길이'],
    rows: [for (final size in sizes) _filterSizeRow(size)],
  );
}

DocsSizeSpecRow _filterSizeRow(CoreComponentSize size) {
  final group = CoreToggleGroupStyle.sizeDefaults(size);
  final filter = CoreFilterStyle.sizeDefaults(size);
  final reset = CoreFilterStyle.defaultResetButtonStyle.merge(filter.resetButtonStyle);
  final inset = group.padding ?? CoreToggleGroupStyle.defaultPadding;
  final segment = group.itemHeight ?? CoreToggleGroupStyle.defaultItemHeight;
  final trackRadius = group.borderRadius ?? CoreToggleGroupStyle.defaultBorderRadius;
  final segmentRadius = group.itemBorderRadius ?? CoreToggleGroupStyle.defaultItemBorderRadius;
  final dividerHeight = filter.dividerHeight ?? CoreFilterStyle.defaultDividerHeight;
  return DocsSizeSpecRow(
    size: size,
    cells: [
      docsSizeNumber(inset.top + segment + inset.bottom),
      docsSizeNumber(segment),
      '${docsSizeNumber(trackRadius.topLeft)} · ${docsSizeNumber(segmentRadius.topLeft)}',
      docsSizeLabel(CoreToggleGroupStyle.defaultLabelTextStyle.merge(group.labelTextStyle)),
      '${docsSizeNumber(reset.width)} × ${docsSizeNumber(reset.height)} · ${docsSizeNumber(reset.borderRadius?.topLeft)}',
      '${docsSizeNumber(reset.leadingIconStyle?.size)} · ${docsSizeNumber(dividerHeight)}',
    ],
  );
}

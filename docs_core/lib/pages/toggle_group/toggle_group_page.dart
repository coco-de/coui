/// ToggleGroup 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `toggle_group_web.dart` · `toggle_group_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/toggle-group.md`.
const String slug = 'toggle-group';

/// 미리보기 · 코드가 함께 쓰는 칸 — 값, 라벨, 아이콘 이름(Lucide kebab-case).
const List<(String, String, String)> toggleGroupPreviewItems = [
  ('list', '목록', 'list'),
  ('grid', '격자', 'layout-grid'),
  ('calendar', '달력', 'calendar'),
];

/// 상태 · 사용 가이드 장면의 칸 — 값과 라벨.
const List<(String, String)> toggleGroupPeriodItems = [
  ('am', '오전'),
  ('pm', '오후'),
];

/// 칸이 많은 예(다섯 개 이상)의 칸 — 값과 라벨.
const List<(String, String)> toggleGroupWeekdayItems = [
  ('mon', '월'),
  ('tue', '화'),
  ('wed', '수'),
  ('thu', '목'),
  ('fri', '금'),
];

/// Filter 관련 카드의 칸 — 값과 라벨.
const List<(String, String)> toggleGroupFilterItems = [
  ('all', '전체'),
  ('open', '진행 중'),
];

/// `trailing` 장면에 두는 초기화 버튼의 접근성 이름.
const String toggleGroupResetLabel = '초기화';

/// 플레이그라운드.
///
/// 크기 선택지는 크기 행이 있는 sm · md 둘이다 — 다른 크기 값은 md 로 그려진다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'size': 'md', 'direction': 'horizontal'},
  controls: [
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md'], segmented: true),
    DocsPlaygroundChoice(
      label: 'direction',
      prop: 'direction',
      options: ['horizontal', 'vertical'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '아이콘', on: {'icon': 'true'}),
    DocsPlaygroundFlag(label: '아이콘만', on: {'showLabel': 'false'}),
    DocsPlaygroundFlag(label: '가로 채우기', on: {'fillWidth': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _toggleGroupCode,
);

/// 크기 표. 크기 행이 있는 sm · md 만 싣는다 — 다른 크기 값은 md 행을 읽는다
/// (`CoreToggleGroupStyle.sizeDefaults`).
DocsSizeSpec Function()? get sizeSpec => _toggleGroupSpec;

String _toggleGroupCode(Map<String, String> props, String? label) {
  final size = props['size'] ?? 'md';
  final direction = props['direction'] ?? 'horizontal';
  final showLabel = previewFlag(props, 'showLabel', fallback: true);
  // 라벨을 숨긴 칸은 아이콘이 있어야 보인다.
  final showIcon = previewFlag(props, 'icon') || !showLabel;

  String item(String value, String text, String icon) {
    final fields = [
      "value: '$value'",
      "label: '$text'",
      if (showIcon) 'icon: Icon(LucideIcons.${docsIconIdentifier(icon)})',
      if (!showLabel) 'showLabel: false',
    ];
    return 'CoreToggleGroupItem(${fields.join(', ')}),';
  }

  final lines = [
    'value: view,',
    'onChanged: (next) => setState(() => view = next),',
    if (size != 'md') 'size: CoreComponentSize.$size,',
    if (direction != 'horizontal') 'direction: CoreAxis.$direction,',
    if (previewFlag(props, 'fillWidth')) 'fillWidth: true,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'items: const [',
    for (final (value, text, icon) in toggleGroupPreviewItems) '  ${item(value, text, icon)}',
    '],',
  ];
  return 'ToggleGroup<String>(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _toggleGroupSpec() {
  final sizes = [...CoreToggleGroupStyle.defaultsBySize.keys]..sort((a, b) => a.index.compareTo(b.index));
  return DocsSizeSpec(
    columns: const ['size', '칸 높이 · 트랙 높이', '트랙 안쪽 여백 · 칸 좌우 여백', '모서리 (트랙 · 칸)', '라벨 · 고른 라벨', '아이콘'],
    rows: [for (final size in sizes) _toggleGroupSpecRow(size)],
  );
}

/// 크기 행 하나 — 행이 적지 않은 값은 `CoreToggleGroupStyle` 의 기본값이다.
DocsSizeSpecRow _toggleGroupSpecRow(CoreComponentSize size) {
  final row = CoreToggleGroupStyle.sizeDefaults(size);
  final height = row.itemHeight ?? CoreToggleGroupStyle.defaultItemHeight;
  final inset = row.padding ?? CoreToggleGroupStyle.defaultPadding;
  final itemInset = row.itemPadding ?? CoreToggleGroupStyle.defaultItemPadding;
  final corner = row.borderRadius ?? CoreToggleGroupStyle.defaultBorderRadius;
  final itemCorner = row.itemBorderRadius ?? CoreToggleGroupStyle.defaultItemBorderRadius;
  final label = CoreToggleGroupStyle.defaultLabelTextStyle.merge(row.labelTextStyle);
  final selected = docsSizeResolve(
    CoreToggleGroupStyle.defaultSelectedLabelTextStyle.merge(row.selectedLabelTextStyle),
  );
  return DocsSizeSpecRow(
    size: size,
    cells: [
      '${docsSizeNumber(height)} · ${docsSizeNumber(inset.top + height + inset.bottom)}',
      '${docsSizeNumber(inset.top)} · ${docsSizeNumber(itemInset.left)}',
      '${docsSizeNumber(corner.topLeft)} · ${docsSizeNumber(itemCorner.topLeft)}',
      '${docsSizeLabel(label)} · ${docsSizeLabel(CoreTextStyle(fontSize: selected?.fontSize, fontWeight: CoreToggleGroupStyle.defaultSelectedFontWeight))}',
      docsSizeNumber(CoreToggleGroupStyle.defaultIconStyle.size),
    ],
  );
}

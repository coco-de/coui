/// MenuItem 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `menu_item_web.dart` · `menu_item_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/menu-item.md`.
const String slug = 'menu-item';

/// `tone` 별 예시 행 — 라벨 · 설명 · 단축키 · 앞 아이콘 이름 · 콜백 이름.
typedef MenuItemSample = ({String label, String description, String shortcut, String icon, String callback});

/// [tone] 의 예시 행. 빨간 행이 복사처럼 되돌릴 수 있는 일을 말하지 않도록
/// 글자도 `tone` 을 따른다. `icon` 은 `page_kit` 의 아이콘 이름이다.
MenuItemSample menuItemSample(CoreMenuItemTone tone) => switch (tone) {
  CoreMenuItemTone.neutral => (
    label: '복사',
    description: '클립보드에 담습니다',
    shortcut: '⌘C',
    icon: 'copy',
    callback: 'copyItem',
  ),
  CoreMenuItemTone.critical => (
    label: '삭제',
    description: '되돌릴 수 없습니다',
    shortcut: '⌫',
    icon: 'trash-2',
    callback: 'deleteItem',
  ),
};

/// 속성의 `tone`.
CoreMenuItemTone menuItemPreviewTone(Map<String, String> props) =>
    previewEnum(CoreMenuItemTone.values, props['tone'], CoreMenuItemTone.defaultTone);

/// 속성의 `size`.
CoreMenuItemSize menuItemPreviewSize(Map<String, String> props) =>
    previewEnum(CoreMenuItemSize.values, props['size'], CoreMenuItemSize.defaultSize);

/// 속성의 설명 글 — `true` 면 `tone` 의 예시 글.
String? menuItemPreviewDescription(Map<String, String> props) =>
    _sampleOr(props['description'], menuItemSample(menuItemPreviewTone(props)).description);

/// 속성의 단축키 글 — `true` 면 `tone` 의 예시 글.
String? menuItemPreviewShortcut(Map<String, String> props) =>
    _sampleOr(props['shortcut'], menuItemSample(menuItemPreviewTone(props)).shortcut);

/// 속성의 앞 아이콘 이름 — `true` 면 `tone` 의 예시 아이콘.
String? menuItemPreviewLeading(Map<String, String> props) =>
    _sampleOr(props['leading'], menuItemSample(menuItemPreviewTone(props)).icon);

String? _sampleOr(String? value, String sample) => value == 'true' ? sample : value;

/// 상태 장면의 행 — 이름, 선택 여부, 활성 여부.
const List<(String, bool, bool)> menuItemStateRows = [
  ('기본', false, true),
  ('선택', true, true),
  ('비활성', false, false),
  ('선택 · 비활성', true, false),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'size': 'sm', 'tone': 'neutral', 'leading': 'true', 'shortcut': 'true'},
  controls: [
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md', 'lg'], segmented: true),
    DocsPlaygroundChoice(label: 'tone', prop: 'tone', options: ['neutral', 'critical'], segmented: true),
    DocsPlaygroundFlag(label: '앞 아이콘', on: {'leading': 'true'}),
    DocsPlaygroundFlag(label: '단축키', on: {'shortcut': 'true'}),
    DocsPlaygroundFlag(label: '설명', on: {'description': 'true'}),
    DocsPlaygroundFlag(label: '체크 표시', on: {'mark': 'true'}),
    DocsPlaygroundFlag(label: '서브메뉴', on: {'hasSubmenu': 'true'}),
    DocsPlaygroundFlag(label: '선택', on: {'selected': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _menuItemCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// 행은 `CoreMenuItemStyle.defaultsBySize` 에서 읽는다.
DocsSizeSpec Function()? get sizeSpec => _menuItemSpec;

String _menuItemCode(Map<String, String> props, String? label) {
  final size = menuItemPreviewSize(props);
  final tone = menuItemPreviewTone(props);
  final sample = menuItemSample(tone);
  final leading = menuItemPreviewLeading(props);
  final description = menuItemPreviewDescription(props);
  final shortcut = menuItemPreviewShortcut(props);
  final lines = [
    if (size != CoreMenuItemSize.defaultSize) 'size: CoreMenuItemSize.${size.name},',
    if (tone != CoreMenuItemTone.defaultTone) 'tone: CoreMenuItemTone.${tone.name},',
    if (previewFlag(props, 'mark')) 'mark: Icon(LucideIcons.check),',
    if (previewFlag(props, 'reserveMark')) 'reserveMark: true,',
    if (leading != null) 'leading: Icon(LucideIcons.${docsIconIdentifier(leading)}),',
    "label: Text('${label ?? sample.label}'),",
    if (description != null) "description: Text('$description'),",
    if (shortcut != null) "shortcut: Text('$shortcut'),",
    if (previewFlag(props, 'hasSubmenu')) 'hasSubmenu: true,',
    if (previewFlag(props, 'selected')) 'selected: true,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onPressed: ${sample.callback},',
  ];
  return 'MenuItem(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _menuItemSpec() {
  return DocsSizeSpec(
    columns: const ['size', '최소 높이 · 모서리', '좌우 · 위아래 여백 · 간격', '앞 아이콘', '라벨', '설명 · 단축키'],
    rows: [
      for (final size in CoreMenuItemSize.values)
        if (CoreMenuItemStyle.defaultsBySize[size]! case final row)
          DocsSizeSpecRow(
            size: size.toComponentSize(),
            cells: [
              '${docsSizeNumber(row.minHeight)} · ${docsSizeNumber(row.borderRadius?.topLeft)}',
              '${docsSizeNumber(row.padding?.left)} · ${docsSizeNumber(row.padding?.top)} · '
                  '${docsSizeNumber(row.contentGapStyle?.size)}',
              docsSizeNumber(row.leadingIconStyle?.size),
              docsSizeLabel(row.labelStyle),
              '${docsSizeLabel(row.descriptionStyle)} · ${docsSizeLabel(row.shortcutTextStyle)}',
            ],
          ),
    ],
  );
}

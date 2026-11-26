/// Menu 페이지 — 플레이그라운드 · 크기 표 · 미리보기의 항목 목록. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `menu_web.dart` · `menu_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// `CoreMenuItem` 은 위젯 타입만 다른 같은 데이터라, 항목 목록을 여기 한 곳에서
/// 만들고 두 플랫폼은 `Menu` 로 감싸기만 한다. 플레이그라운드의 속성은
/// `size`(`CoreMenuItemSize` 이름)와, 항목을 더하거나 바꾸는 `standardAction` ·
/// `description` · `disabled` · `submenu` · `toggles` · `critical` 이다.
/// `sample=size` 는 크기 표의 짧은 목록을 고른다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/menu.md`.
const String slug = 'menu';

/// 플레이그라운드 메뉴의 접근 가능한 이름.
const String menuPreviewAriaLabel = '편집 메뉴';

/// 플레이그라운드 메뉴의 헤딩.
const String menuPreviewHeading = '편집';

/// `설명` 을 켰을 때 첫 줄의 둘째 줄.
const String menuPreviewDescription = '선택한 부분을 복사합니다';

/// radio 줄의 값과 라벨.
const List<(String, String)> menuPreviewDensities = [('compact', '좁게'), ('comfortable', '넓게')];

/// radio 줄에서 처음 고른 값.
const String menuPreviewDefaultDensity = 'comfortable';

/// 속성의 `size` — 없거나 모르는 이름이면 기본값(sm).
CoreMenuItemSize menuPreviewSize(Map<String, String> props) =>
    previewEnum(CoreMenuItemSize.values, props['size'], CoreMenuItemSize.defaultSize);

/// 플레이그라운드의 항목. `checkbox` · `radio` 의 값은 미리보기가 들고 있다.
List<CoreMenuItem<W>> menuPreviewItems<W>(
  Map<String, String> props, {
  required bool autoSave,
  required String density,
  required void Function(bool value) onAutoSave,
  required void Function(String value) onDensity,
}) {
  if (props['sample'] == 'size') return menuSizeSampleItems<W>();
  final icons = previewFlag(props, 'standardAction');
  CoreMenuAction? standard(CoreMenuAction action) => icons ? action : null;

  return [
    CoreMenuItem<W>.label(menuPreviewHeading),
    CoreMenuItem<W>.action(
      '복사',
      standardAction: standard(CoreMenuAction.copy),
      description: previewFlag(props, 'description') ? menuPreviewDescription : null,
      shortcut: '⌘C',
      onPressed: _noop,
    ),
    CoreMenuItem<W>.action(
      '붙여넣기',
      standardAction: standard(CoreMenuAction.paste),
      shortcut: '⌘V',
      disabled: previewFlag(props, 'disabled'),
      onPressed: _noop,
    ),
    CoreMenuItem<W>.action('이름 바꾸기', standardAction: standard(CoreMenuAction.rename), onPressed: _noop),
    if (previewFlag(props, 'submenu'))
      CoreMenuItem<W>.action(
        '공유',
        standardAction: standard(CoreMenuAction.share),
        submenu: [
          CoreMenuItem<W>.action('링크 복사', onPressed: _noop),
          CoreMenuItem<W>.action('이메일로 보내기', onPressed: _noop),
        ],
      ),
    if (previewFlag(props, 'toggles')) ...[
      CoreMenuItem<W>.divider(),
      CoreMenuItem<W>.checkbox('자동 저장', checked: autoSave, onChanged: onAutoSave),
      for (final (value, text) in menuPreviewDensities)
        CoreMenuItem<W>.radio(text, selected: density == value, onChanged: (_) => onDensity(value)),
    ],
    if (previewFlag(props, 'critical')) ...[
      CoreMenuItem<W>.divider(),
      CoreMenuItem<W>.action(
        '삭제',
        standardAction: standard(CoreMenuAction.delete),
        tone: CoreMenuItemTone.critical,
        onPressed: _noop,
      ),
    ],
  ];
}

/// 크기 표의 목록 — size 에 따라 달라지는 높이 · 여백 · 아이콘 · 글자만 보이는
/// 세 줄.
List<CoreMenuItem<W>> menuSizeSampleItems<W>() => [
  CoreMenuItem<W>.action('복사', standardAction: CoreMenuAction.copy, shortcut: '⌘C', onPressed: _noop),
  CoreMenuItem<W>.action('붙여넣기', standardAction: CoreMenuAction.paste, shortcut: '⌘V', onPressed: _noop),
  CoreMenuItem<W>.action('이름 바꾸기', standardAction: CoreMenuAction.rename, onPressed: _noop),
];

/// 장면에 그리는 목록과 그 접근 가능한 이름.
enum MenuPreviewList {
  /// 구조.
  anatomy('편집'),

  /// 선택된 radio 를 점으로 그리는 목록.
  radioDot('밀도'),

  /// 선택된 radio 를 체크로 그리는 목록.
  radioCheck('정렬'),

  /// 둘째 줄이 있는 줄.
  description('저장'),

  /// 표준 명령의 기본 아이콘.
  standardActions('편집 명령'),

  /// 위험한 동작.
  critical('파일 동작'),

  /// 인라인 서브메뉴.
  submenu('파일'),

  /// 구분선과 간격.
  dividerGap('문서'),

  /// 줄 상태.
  states('줄 상태'),

  /// 가로 메뉴.
  horizontal('주 메뉴'),

  /// 위험한 동작을 그룹 끝에 둔 목록.
  criticalLast('파일 동작'),

  /// 위험한 동작을 가운데에 둔 목록.
  criticalMiddle('파일 동작'),

  /// 모든 줄에 아이콘이 있는 목록.
  leadingAligned('편집'),

  /// 아이콘이 있는 줄과 없는 줄이 섞인 목록.
  leadingMixed('편집');

  const MenuPreviewList(this.ariaLabel);

  /// 메뉴의 접근 가능한 이름.
  final String ariaLabel;
}

/// 표준 명령과 장면의 라벨.
const List<(CoreMenuAction, String)> menuStandardActionLabels = [
  (CoreMenuAction.cut, '잘라내기'),
  (CoreMenuAction.copy, '복사'),
  (CoreMenuAction.paste, '붙여넣기'),
  (CoreMenuAction.undo, '실행 취소'),
  (CoreMenuAction.redo, '다시 실행'),
  (CoreMenuAction.share, '공유'),
  (CoreMenuAction.rename, '이름 바꾸기'),
  (CoreMenuAction.delete, '삭제'),
];

/// [list] 의 항목.
List<CoreMenuItem<W>> menuItemsFor<W>(MenuPreviewList list) => switch (list) {
  MenuPreviewList.anatomy => [
    CoreMenuItem<W>.label('편집'),
    CoreMenuItem<W>.action('복사', shortcut: '⌘C', onPressed: _noop),
    CoreMenuItem<W>.action('붙여넣기', shortcut: '⌘V', onPressed: _noop),
    CoreMenuItem<W>.divider(),
    CoreMenuItem<W>.checkbox('자동 저장', checked: true, onChanged: _ignore),
  ],
  MenuPreviewList.radioDot => [
    CoreMenuItem<W>.label('밀도'),
    CoreMenuItem<W>.radio('좁게', onChanged: _ignore),
    CoreMenuItem<W>.radio('넓게', selected: true, onChanged: _ignore),
    CoreMenuItem<W>.divider(),
    CoreMenuItem<W>.checkbox('격자 보기', checked: true, onChanged: _ignore),
    CoreMenuItem<W>.checkbox('미리 보기', onChanged: _ignore),
  ],
  MenuPreviewList.radioCheck => [
    CoreMenuItem<W>.label('정렬'),
    CoreMenuItem<W>.radio('최신순', selected: true, radioMark: CoreMenuRadioMark.check, onChanged: _ignore),
    CoreMenuItem<W>.radio('인기순', radioMark: CoreMenuRadioMark.check, onChanged: _ignore),
    CoreMenuItem<W>.radio('낮은 가격순', radioMark: CoreMenuRadioMark.check, onChanged: _ignore),
  ],
  MenuPreviewList.description => [
    CoreMenuItem<W>.action('저장', description: '이 기기에만 저장합니다', shortcut: '⌘S', onPressed: _noop),
    CoreMenuItem<W>.action('사본 저장', description: '새 파일로 한 번 더 저장합니다', onPressed: _noop),
  ],
  MenuPreviewList.standardActions => [
    for (final (action, text) in menuStandardActionLabels)
      CoreMenuItem<W>.action(text, standardAction: action, onPressed: _noop),
  ],
  MenuPreviewList.critical => [
    CoreMenuItem<W>.action('이름 바꾸기', standardAction: CoreMenuAction.rename, onPressed: _noop),
    CoreMenuItem<W>.action('공유', standardAction: CoreMenuAction.share, onPressed: _noop),
    CoreMenuItem<W>.divider(),
    CoreMenuItem<W>.action(
      '삭제',
      standardAction: CoreMenuAction.delete,
      tone: CoreMenuItemTone.critical,
      onPressed: _noop,
    ),
  ],
  MenuPreviewList.submenu => [
    CoreMenuItem<W>.action('열기', onPressed: _noop),
    CoreMenuItem<W>.action(
      '내보내기',
      submenu: [
        CoreMenuItem<W>.action('PDF', onPressed: _noop),
        CoreMenuItem<W>.action('CSV', onPressed: _noop),
      ],
    ),
    CoreMenuItem<W>.action('인쇄', onPressed: _noop),
  ],
  MenuPreviewList.dividerGap => [
    CoreMenuItem<W>.action('새 문서', onPressed: _noop),
    CoreMenuItem<W>.action('열기', onPressed: _noop),
    CoreMenuItem<W>.divider(),
    CoreMenuItem<W>.action('저장', onPressed: _noop),
    CoreMenuItem<W>.gap(CoreSpace.space16),
    CoreMenuItem<W>.action('닫기', onPressed: _noop),
  ],
  MenuPreviewList.states => [
    CoreMenuItem<W>.action('기본', onPressed: _noop),
    CoreMenuItem<W>.action('현재 항목 (active)', active: true, onPressed: _noop),
    CoreMenuItem<W>.checkbox('켜짐 (checked)', checked: true, onChanged: _ignore),
    CoreMenuItem<W>.action('비활성 (disabled)', disabled: true, onPressed: _noop),
    CoreMenuItem<W>.action('삭제 (critical)', tone: CoreMenuItemTone.critical, onPressed: _noop),
  ],
  MenuPreviewList.horizontal => [
    CoreMenuItem<W>.action('홈', active: true, onPressed: _noop),
    CoreMenuItem<W>.action('문서', onPressed: _noop),
    CoreMenuItem<W>.action('설정', onPressed: _noop),
  ],
  MenuPreviewList.criticalLast => [
    CoreMenuItem<W>.action('이름 바꾸기', onPressed: _noop),
    CoreMenuItem<W>.action('복제', onPressed: _noop),
    CoreMenuItem<W>.divider(),
    CoreMenuItem<W>.action('삭제', tone: CoreMenuItemTone.critical, onPressed: _noop),
  ],
  MenuPreviewList.criticalMiddle => [
    CoreMenuItem<W>.action('이름 바꾸기', onPressed: _noop),
    CoreMenuItem<W>.action('삭제', tone: CoreMenuItemTone.critical, onPressed: _noop),
    CoreMenuItem<W>.action('복제', onPressed: _noop),
  ],
  MenuPreviewList.leadingAligned => [
    CoreMenuItem<W>.action('복사', standardAction: CoreMenuAction.copy, onPressed: _noop),
    CoreMenuItem<W>.action('붙여넣기', standardAction: CoreMenuAction.paste, onPressed: _noop),
    CoreMenuItem<W>.action('이름 바꾸기', standardAction: CoreMenuAction.rename, onPressed: _noop),
  ],
  MenuPreviewList.leadingMixed => [
    CoreMenuItem<W>.action('복사', standardAction: CoreMenuAction.copy, onPressed: _noop),
    CoreMenuItem<W>.action('붙여넣기', onPressed: _noop),
    CoreMenuItem<W>.action('이름 바꾸기', standardAction: CoreMenuAction.rename, onPressed: _noop),
  ],
};

/// 장면의 줄은 눌러도 아무것도 바꾸지 않는다.
void _noop() {}

/// 장면의 checkbox · radio 는 값을 바꾸지 않는다.
void _ignore(bool value) {}

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'size': 'sm', 'standardAction': 'true', 'critical': 'true'},
  controls: [
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md', 'lg'], segmented: true),
    DocsPlaygroundFlag(label: '표준 명령 아이콘', on: {'standardAction': 'true'}),
    DocsPlaygroundFlag(label: '설명', on: {'description': 'true'}),
    DocsPlaygroundFlag(label: '비활성 항목', on: {'disabled': 'true'}),
    DocsPlaygroundFlag(label: '서브메뉴', on: {'submenu': 'true'}),
    DocsPlaygroundFlag(label: '체크 · 라디오', on: {'toggles': 'true'}),
    DocsPlaygroundFlag(label: '위험한 항목', on: {'critical': 'true'}),
  ],
  code: _menuCode,
);

/// 크기 표 — 줄의 크기 행(`CoreMenuItemStyle.defaultsBySize`)에서 읽는다.
///
/// 메뉴가 `size` 하나를 모든 줄(`MenuItem`)에 넘기므로 크기 값은 줄의 것이다.
DocsSizeSpec Function()? get sizeSpec => _menuSpec;

DocsSizeSpec _menuSpec() => DocsSizeSpec(
  columns: const ['size', '줄 최소 높이', '좌우 · 위아래 여백', '부품 간격', 'leading 아이콘', '라벨', '설명', '단축키'],
  rows: [
    for (final MapEntry(key: size, value: row) in CoreMenuItemStyle.defaultsBySize.entries)
      DocsSizeSpecRow(
        size: size.toComponentSize(),
        cells: [
          docsSizeNumber(row.minHeight),
          '${docsSizeNumber(row.padding?.left)} · ${docsSizeNumber(row.padding?.top)}',
          docsSizeNumber(row.contentGapStyle?.size),
          docsSizeNumber(row.leadingIconStyle?.size),
          docsSizeLabel(row.labelStyle),
          docsSizeLabel(row.descriptionStyle),
          docsSizeLabel(row.shortcutTextStyle),
        ],
      ),
  ],
);

String _menuCode(Map<String, String> props, String? label) {
  final size = menuPreviewSize(props);
  final icons = previewFlag(props, 'standardAction');
  final lines = [
    "ariaLabel: '$menuPreviewAriaLabel',",
    if (size != CoreMenuItemSize.defaultSize) 'size: CoreMenuItemSize.${size.name},',
    'items: [',
    "  const CoreMenuItem.label('$menuPreviewHeading'),",
    '  CoreMenuItem.action(',
    "    '복사',",
    if (icons) '    standardAction: CoreMenuAction.copy,',
    if (previewFlag(props, 'description')) "    description: '$menuPreviewDescription',",
    "    shortcut: '⌘C',",
    '    onPressed: copySelection,',
    '  ),',
    '  CoreMenuItem.action(',
    "    '붙여넣기',",
    if (icons) '    standardAction: CoreMenuAction.paste,',
    "    shortcut: '⌘V',",
    if (previewFlag(props, 'disabled')) '    disabled: true,',
    '    onPressed: pasteClipboard,',
    '  ),',
    '  CoreMenuItem.action(',
    "    '이름 바꾸기',",
    if (icons) '    standardAction: CoreMenuAction.rename,',
    '    onPressed: renameItem,',
    '  ),',
    if (previewFlag(props, 'submenu')) ...[
      '  CoreMenuItem.action(',
      "    '공유',",
      if (icons) '    standardAction: CoreMenuAction.share,',
      '    submenu: [',
      "      CoreMenuItem.action('링크 복사', onPressed: copyLink),",
      "      CoreMenuItem.action('이메일로 보내기', onPressed: sendEmail),",
      '    ],',
      '  ),',
    ],
    if (previewFlag(props, 'toggles')) ...[
      '  const CoreMenuItem.divider(),',
      "  CoreMenuItem.checkbox('자동 저장', checked: autoSave, onChanged: setAutoSave),",
      for (final (value, text) in menuPreviewDensities) ...[
        '  CoreMenuItem.radio(',
        "    '$text',",
        "    selected: density == '$value',",
        "    onChanged: (_) => setDensity('$value'),",
        '  ),',
      ],
    ],
    if (previewFlag(props, 'critical')) ...[
      '  const CoreMenuItem.divider(),',
      '  CoreMenuItem.action(',
      "    '삭제',",
      if (icons) '    standardAction: CoreMenuAction.delete,',
      '    tone: CoreMenuItemTone.critical,',
      '    onPressed: deleteItem,',
      '  ),',
    ],
    '],',
  ];
  return 'Menu(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

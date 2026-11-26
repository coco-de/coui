/// DropdownMenu 페이지 — 플레이그라운드와 미리보기의 항목. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `dropdown_menu_web.dart` · `dropdown_menu_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 메뉴 항목(`CoreMenuItem`)은 플랫폼에 매이지 않아, 두 미리보기의 항목과
/// 플레이그라운드의 코드가 모두 이 파일에서 나온다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/dropdown-menu.md`.
const String slug = 'dropdown-menu';

/// 트리거 버튼의 글자 — 그림 · 실제 `DropdownMenu` · 코드가 함께 쓴다.
const String demoTriggerLabel = '메뉴 열기';

/// "값 고르기에 쓰지 않기" 카드의 트리거 글자.
const String demoValuePickTrigger = '국가';

/// 플레이그라운드의 그림과 그 아래 실제 트리거 사이의 간격 — 자리가 모자라
/// 실제 패널이 위로 열릴 때를 생각해 넉넉히 둔다.
const double demoOpenerGap = CoreSpace.space48;

/// checkbox · radio 행의 값.
typedef DropdownDemoValues = ({bool showGrid, bool showRuler, String sortBy});

/// 처음 값 — 그림과 코드가 이 상태를 그린다.
const DropdownDemoValues demoInitialValues = (showGrid: true, showRuler: false, sortBy: 'name');

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// DropdownMenu 에는 variant · 크기 속성이 없어, 컨트롤은 `items` 에 넣는 것을
/// 고른다. `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 그림
/// 아래에 실제 `DropdownMenu` 를 둔다. 플레이그라운드만 켠다: 사이트의 다른
/// 무대는 브라우저에서 깨어나지 않아 눌러도 열리지 않는다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'kind': 'action', 'shortcut': 'true', 'opener': 'true'},
  label: demoTriggerLabel,
  controls: [
    DocsPlaygroundChoice(label: '항목 종류', prop: 'kind', options: ['action', 'checkbox', 'radio'], segmented: true),
    DocsPlaygroundFlag(label: '단축키 힌트 (shortcut)', on: {'shortcut': 'true'}),
    DocsPlaygroundFlag(label: '아이콘 (leading)', on: {'icons': 'true'}),
    DocsPlaygroundFlag(label: '비활성 행 (disabled)', on: {'disabled': 'true'}),
  ],
  code: _dropdownMenuCode,
);

/// 크기 표. DropdownMenu 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 `kind` 가 고르는 항목 종류 — 모르는 값이면 `action` 이다.
CoreMenuItemKind demoKind(Map<String, String> props) =>
    previewEnum(CoreMenuItemKind.values, props['kind'], CoreMenuItemKind.action);

/// 동작 행 하나 — 글자, 아이콘과 그 상수 이름, 단축키 힌트, 코드의 콜백 이름.
typedef _Action = ({String label, IconName icon, String iconId, String shortcut, String callback});

const _Action _rename = (
  label: '이름 바꾸기',
  icon: LucideIcons.pencil,
  iconId: 'pencil',
  shortcut: 'F2',
  callback: 'rename',
);
const _Action _duplicate = (
  label: '복제',
  icon: LucideIcons.copy,
  iconId: 'copy',
  shortcut: 'Ctrl+D',
  callback: 'duplicate',
);
const _Action _delete = (
  label: '삭제',
  icon: LucideIcons.trash2,
  iconId: 'trash2',
  shortcut: 'Delete',
  callback: 'deleteItem',
);
const _Action _viewSettings = (
  label: '보기 설정',
  icon: LucideIcons.settings,
  iconId: 'settings',
  shortcut: 'Ctrl+,',
  callback: 'openViewSettings',
);
const _Action _resetSort = (
  label: '정렬 초기화',
  icon: LucideIcons.rotateCcw,
  iconId: 'rotateCcw',
  shortcut: 'Ctrl+0',
  callback: 'resetSort',
);

/// 플레이그라운드의 항목.
///
/// [icon] 은 플랫폼의 아이콘 위젯을 만든다. checkbox · radio 행은 [values] 를
/// 그리고, 누르면 [onValues] 에 다음 값을 알린다. `disabled` 는 각 목록의 둘째
/// 누를 수 있는 행에 걸린다.
List<CoreMenuItem<W>> demoItems<W>(
  Map<String, String> props, {
  required W Function(IconName name) icon,
  DropdownDemoValues values = demoInitialValues,
  void Function(DropdownDemoValues next)? onValues,
}) {
  final shortcuts = previewFlag(props, 'shortcut');
  final icons = previewFlag(props, 'icons');
  final secondDisabled = previewFlag(props, 'disabled');

  CoreMenuItem<W> action(
    _Action row, {
    CoreMenuItemTone tone = CoreMenuItemTone.neutral,
    bool disabled = false,
    void Function()? onPressed,
  }) => CoreMenuItem<W>.action(
    row.label,
    tone: tone,
    leading: icons ? icon(row.icon) : null,
    shortcut: shortcuts ? row.shortcut : null,
    disabled: disabled,
    onPressed: onPressed ?? () {},
  );

  void sortBy(String next) => onValues?.call((showGrid: values.showGrid, showRuler: values.showRuler, sortBy: next));

  return switch (demoKind(props)) {
    CoreMenuItemKind.checkbox => [
      CoreMenuItem<W>.label('보기'),
      CoreMenuItem<W>.checkbox(
        '눈금선',
        checked: values.showGrid,
        onChanged: (next) => onValues?.call((showGrid: next, showRuler: values.showRuler, sortBy: values.sortBy)),
      ),
      CoreMenuItem<W>.checkbox(
        '눈금자',
        checked: values.showRuler,
        disabled: secondDisabled,
        onChanged: (next) => onValues?.call((showGrid: values.showGrid, showRuler: next, sortBy: values.sortBy)),
      ),
      CoreMenuItem<W>.divider(),
      action(_viewSettings),
    ],
    CoreMenuItemKind.radio => [
      CoreMenuItem<W>.label('정렬'),
      CoreMenuItem<W>.radio(
        '이름순',
        selected: values.sortBy == 'name',
        shortcut: shortcuts ? 'Ctrl+1' : null,
        onChanged: (_) => sortBy('name'),
      ),
      CoreMenuItem<W>.radio(
        '날짜순',
        selected: values.sortBy == 'date',
        shortcut: shortcuts ? 'Ctrl+2' : null,
        disabled: secondDisabled,
        onChanged: (_) => sortBy('date'),
      ),
      CoreMenuItem<W>.divider(),
      action(_resetSort, onPressed: () => sortBy(demoInitialValues.sortBy)),
    ],
    _ => [
      action(_rename),
      action(_duplicate, disabled: secondDisabled),
      CoreMenuItem<W>.divider(),
      action(_delete, tone: CoreMenuItemTone.critical),
    ],
  };
}

String _dropdownMenuCode(Map<String, String> props, String? label) {
  final shortcuts = previewFlag(props, 'shortcut');
  final icons = previewFlag(props, 'icons');
  final secondDisabled = previewFlag(props, 'disabled');

  List<String> action(_Action row, {bool critical = false, bool disabled = false}) => [
    'CoreMenuItem.action(',
    "  '${row.label}',",
    if (critical) '  tone: CoreMenuItemTone.critical,',
    if (icons) '  leading: Icon(LucideIcons.${row.iconId}),',
    if (shortcuts) "  shortcut: '${row.shortcut}',",
    if (disabled) '  disabled: true,',
    '  onPressed: ${row.callback},',
    '),',
  ];

  List<String> radio(String text, String value, String keys, {bool disabled = false}) => [
    'CoreMenuItem.radio(',
    "  '$text',",
    "  selected: sortBy == '$value',",
    if (shortcuts) "  shortcut: '$keys',",
    if (disabled) '  disabled: true,',
    "  onChanged: (_) => setSortBy('$value'),",
    '),',
  ];

  final items = switch (demoKind(props)) {
    CoreMenuItemKind.checkbox => [
      "const CoreMenuItem.label('보기'),",
      'CoreMenuItem.checkbox(',
      "  '눈금선',",
      '  checked: showGrid,',
      '  onChanged: setShowGrid,',
      '),',
      'CoreMenuItem.checkbox(',
      "  '눈금자',",
      '  checked: showRuler,',
      if (secondDisabled) '  disabled: true,',
      '  onChanged: setShowRuler,',
      '),',
      'const CoreMenuItem.divider(),',
      ...action(_viewSettings),
    ],
    CoreMenuItemKind.radio => [
      "const CoreMenuItem.label('정렬'),",
      ...radio('이름순', 'name', 'Ctrl+1'),
      ...radio('날짜순', 'date', 'Ctrl+2', disabled: secondDisabled),
      'const CoreMenuItem.divider(),',
      ...action(_resetSort),
    ],
    _ => [
      ...action(_rename),
      ...action(_duplicate, disabled: secondDisabled),
      'const CoreMenuItem.divider(),',
      ...action(_delete, critical: true),
    ],
  };

  final lines = [
    'trigger: Button(',
    '  variant: CoreButtonVariant.outline,',
    '  onPressed: () {},',
    "  child: Text('${label ?? demoTriggerLabel}'),",
    '),',
    'items: [',
    for (final line in items) '  $line',
    '],',
  ];
  return 'DropdownMenu(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

/// 구조 장면의 항목 — 제목, 동작 행, 구분선.
List<CoreMenuItem<W>> demoAnatomyItems<W>() => [
  CoreMenuItem<W>.label('문서'),
  CoreMenuItem<W>.action('이름 바꾸기', standardAction: CoreMenuAction.rename, shortcut: 'F2', onPressed: () {}),
  CoreMenuItem<W>.action('복제', standardAction: CoreMenuAction.copy, onPressed: () {}),
  CoreMenuItem<W>.divider(),
  CoreMenuItem<W>.action(
    '삭제',
    standardAction: CoreMenuAction.delete,
    tone: CoreMenuItemTone.critical,
    onPressed: () {},
  ),
];

/// 항목 장면의 왼쪽 패널 — 제목, 동작 행의 모양, 빈 칸, 서브메뉴.
List<CoreMenuItem<W>> demoEntryItems<W>() => [
  CoreMenuItem<W>.label('편집'),
  CoreMenuItem<W>.action('잘라내기', standardAction: CoreMenuAction.cut, shortcut: 'Ctrl+X', onPressed: () {}),
  CoreMenuItem<W>.action(
    '붙여넣기',
    description: '클립보드의 내용',
    standardAction: CoreMenuAction.paste,
    onPressed: () {},
  ),
  CoreMenuItem<W>.gap(CoreSpace.space8),
  CoreMenuItem<W>.action(
    '공유',
    standardAction: CoreMenuAction.share,
    submenu: [
      CoreMenuItem<W>.action('링크 복사', onPressed: () {}),
      CoreMenuItem<W>.action('메일로 보내기', onPressed: () {}),
    ],
  ),
];

/// 항목 장면의 오른쪽 패널 — checkbox 와 radio.
List<CoreMenuItem<W>> demoToggleItems<W>() => [
  CoreMenuItem<W>.label('보기'),
  CoreMenuItem<W>.checkbox('눈금선', checked: true, onChanged: (_) {}),
  CoreMenuItem<W>.checkbox('눈금자', onChanged: (_) {}),
  CoreMenuItem<W>.divider(),
  CoreMenuItem<W>.label('정렬'),
  CoreMenuItem<W>.radio('이름순', selected: true, onChanged: (_) {}),
  CoreMenuItem<W>.radio('날짜순', onChanged: (_) {}),
];

/// 단축키 힌트 장면의 항목.
List<CoreMenuItem<W>> demoShortcutItems<W>() => [
  CoreMenuItem<W>.action('실행 취소', shortcut: 'Ctrl+Z', onPressed: () {}),
  CoreMenuItem<W>.action('다시 실행', shortcut: 'Ctrl+Shift+Z', disabled: true, onPressed: () {}),
];

/// 상태 장면의 항목 — hover · 눌림 · 포커스는 켜 둘 수 없어 표의 설명으로 대신한다.
List<CoreMenuItem<W>> demoStateItems<W>() => [
  CoreMenuItem<W>.action('기본', onPressed: () {}),
  CoreMenuItem<W>.action('선택 (active)', active: true, onPressed: () {}),
  CoreMenuItem<W>.checkbox('켜진 checkbox', checked: true, onChanged: (_) {}),
  CoreMenuItem<W>.action('비활성 (disabled)', disabled: true, onPressed: () {}),
  CoreMenuItem<W>.action('위험 (critical)', tone: CoreMenuItemTone.critical, onPressed: () {}),
];

/// "구분선으로 묶기" 카드의 항목.
List<CoreMenuItem<W>> demoGroupItems<W>() => [
  CoreMenuItem<W>.action('이름 바꾸기', onPressed: () {}),
  CoreMenuItem<W>.action('복제', onPressed: () {}),
  CoreMenuItem<W>.divider(),
  CoreMenuItem<W>.action('링크 복사', onPressed: () {}),
  CoreMenuItem<W>.action('내보내기', onPressed: () {}),
];

/// "값 고르기에 쓰지 않기" 카드의 항목.
List<CoreMenuItem<W>> demoValuePickItems<W>() => [
  CoreMenuItem<W>.action('대한민국', onPressed: () {}),
  CoreMenuItem<W>.action('일본', onPressed: () {}),
  CoreMenuItem<W>.action('미국', onPressed: () {}),
];

/// "위험한 행동은 맨 끝에" 카드의 항목.
List<CoreMenuItem<W>> demoCriticalLastItems<W>() => [
  CoreMenuItem<W>.action('편집', onPressed: () {}),
  CoreMenuItem<W>.action('복제', onPressed: () {}),
  CoreMenuItem<W>.divider(),
  CoreMenuItem<W>.action('삭제', tone: CoreMenuItemTone.critical, onPressed: () {}),
];

/// "위험한 행동을 사이에 끼우지 않기" 카드의 항목.
List<CoreMenuItem<W>> demoCriticalMiddleItems<W>() => [
  CoreMenuItem<W>.action('편집', onPressed: () {}),
  CoreMenuItem<W>.action('삭제', tone: CoreMenuItemTone.critical, onPressed: () {}),
  CoreMenuItem<W>.action('복제', onPressed: () {}),
];

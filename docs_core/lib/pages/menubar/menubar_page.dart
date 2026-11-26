/// Menubar 페이지 — 플레이그라운드와 미리보기의 메뉴. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `menubar_web.dart` · `menubar_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 메뉴(`CoreMenubarMenu`)는 플랫폼에 매이지 않아, 두 미리보기의 그림 · 실제
/// `Menubar` · 장면이 이 파일의 목록에서 나오고, 플레이그라운드의 코드도 같은
/// 목록에서 만든다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/menubar.md`.
const String slug = 'menubar';

/// 플레이그라운드의 그림과 그 아래 실제 `Menubar` 사이의 간격 — 자리가 모자라
/// 실제 패널이 위로 열릴 때를 생각해 넉넉히 둔다.
const double demoOpenerGap = CoreSpace.space48;

/// 속성 `border` — 없으면 `Menubar` 의 기본값처럼 켠다.
bool demoBorder(Map<String, String> props) => previewFlag(props, 'border', fallback: true);

/// 미리보기의 항목은 눌러도 아무것도 바꾸지 않는다. `onSelect` 가 있어야 고른
/// 뒤에 메뉴가 닫힌다.
void demoNoop() {}

/// 플레이그라운드의 동작 항목 하나.
class _DemoAction {
  const _DemoAction(this.label, this.callback, {this.shortcut, this.standardAction, this.disabledByFlag = false});

  final String label;

  /// 코드 상자의 `onSelect` 이름.
  final String callback;
  final String? shortcut;
  final CoreMenuAction? standardAction;

  /// 속성 `disabled` 를 켜면 비활성이 되는 항목.
  final bool disabledByFlag;
}

/// 플레이그라운드의 메뉴 — 이름과 항목. `null` 은 구분선이다.
const List<(String, List<_DemoAction?>)> _demoMenus = [
  (
    '파일',
    [
      _DemoAction('새로 만들기', 'newDocument', shortcut: 'Ctrl+N'),
      _DemoAction('열기', 'openDocument', shortcut: 'Ctrl+O'),
      _DemoAction('저장', 'saveDocument', shortcut: 'Ctrl+S', disabledByFlag: true),
      null,
      _DemoAction('종료', 'quitApp'),
    ],
  ),
  (
    '편집',
    [
      _DemoAction('잘라내기', 'cutSelection', shortcut: 'Ctrl+X', standardAction: CoreMenuAction.cut),
      _DemoAction('복사', 'copySelection', shortcut: 'Ctrl+C', standardAction: CoreMenuAction.copy),
      _DemoAction('붙여넣기', 'pasteClipboard', shortcut: 'Ctrl+V', standardAction: CoreMenuAction.paste),
    ],
  ),
  (
    '보기',
    [
      _DemoAction('확대', 'zoomIn'),
      _DemoAction('축소', 'zoomOut'),
      null,
      _DemoAction('전체 화면', 'toggleFullScreen'),
    ],
  ),
];

/// 속성(`shortcut` · `disabled`)으로 고른 메뉴 — 그림 · 실제 `Menubar` 가 함께
/// 쓴다.
List<CoreMenubarMenu> demoMenus(Map<String, String> props) {
  final shortcuts = previewFlag(props, 'shortcut');
  final disabled = previewFlag(props, 'disabled');
  return [
    for (final (title, actions) in _demoMenus)
      CoreMenubarMenu(
        label: title,
        entries: [
          for (final action in actions)
            if (action == null)
              const CoreMenubarEntry.divider()
            else
              CoreMenubarEntry.action(
                label: action.label,
                shortcut: shortcuts ? action.shortcut : null,
                standardAction: action.standardAction,
                enabled: !(disabled && action.disabledByFlag),
                onSelect: demoNoop,
              ),
        ],
      ),
  ];
}

/// `Menubar` 가 [menu] 의 항목을 패널의 `Menu` 에 넘기는 것과 같은 목록 — 그림의
/// 패널이 쓴다.
List<CoreMenuItem<W>> demoPanelItems<W>(CoreMenubarMenu menu) => [
  for (final entry in menu.entries)
    if (entry.kind == CoreMenubarEntryKind.divider)
      CoreMenuItem<W>.divider()
    else
      CoreMenuItem<W>.action(
        entry.label,
        onPressed: entry.onSelect,
        shortcut: entry.shortcut,
        standardAction: entry.standardAction,
        disabled: !entry.enabled,
      ),
];

/// 항목 장면의 메뉴 — 구분선, 단축키 힌트, 표준 명령 아이콘, 비활성 항목.
const CoreMenubarMenu demoEntriesMenu = CoreMenubarMenu(
  label: '편집',
  entries: [
    CoreMenubarEntry.action(
      label: '실행 취소',
      shortcut: 'Ctrl+Z',
      standardAction: CoreMenuAction.undo,
      onSelect: demoNoop,
    ),
    CoreMenubarEntry.action(
      label: '다시 실행',
      shortcut: 'Ctrl+Shift+Z',
      standardAction: CoreMenuAction.redo,
      enabled: false,
      onSelect: demoNoop,
    ),
    CoreMenubarEntry.divider(),
    CoreMenubarEntry.action(
      label: '잘라내기',
      shortcut: 'Ctrl+X',
      standardAction: CoreMenuAction.cut,
      onSelect: demoNoop,
    ),
    CoreMenubarEntry.action(
      label: '복사',
      shortcut: 'Ctrl+C',
      standardAction: CoreMenuAction.copy,
      onSelect: demoNoop,
    ),
    CoreMenubarEntry.action(
      label: '붙여넣기',
      shortcut: 'Ctrl+V',
      standardAction: CoreMenuAction.paste,
      onSelect: demoNoop,
    ),
  ],
);

/// "구분선으로 묶기" 카드의 메뉴.
const CoreMenubarMenu demoGroupedMenu = CoreMenubarMenu(
  label: '파일',
  entries: [
    CoreMenubarEntry.action(label: '새로 만들기', onSelect: demoNoop),
    CoreMenubarEntry.action(label: '열기', onSelect: demoNoop),
    CoreMenubarEntry.divider(),
    CoreMenubarEntry.action(label: '저장', onSelect: demoNoop),
    CoreMenubarEntry.divider(),
    CoreMenubarEntry.action(label: '종료', onSelect: demoNoop),
  ],
);

/// "구분 없이 늘어놓지 않기" 카드의 메뉴 — [demoGroupedMenu] 에서 구분선을 뺀다.
const CoreMenubarMenu demoUngroupedMenu = CoreMenubarMenu(
  label: '파일',
  entries: [
    CoreMenubarEntry.action(label: '새로 만들기', onSelect: demoNoop),
    CoreMenubarEntry.action(label: '열기', onSelect: demoNoop),
    CoreMenubarEntry.action(label: '저장', onSelect: demoNoop),
    CoreMenubarEntry.action(label: '종료', onSelect: demoNoop),
  ],
);

/// "단축키 힌트" 카드의 메뉴.
const CoreMenubarMenu demoShortcutMenu = CoreMenubarMenu(
  label: '파일',
  entries: [
    CoreMenubarEntry.action(label: '새로 만들기', shortcut: 'Ctrl+N', onSelect: demoNoop),
    CoreMenubarEntry.action(label: '열기', shortcut: 'Ctrl+O', onSelect: demoNoop),
    CoreMenubarEntry.action(label: '저장', shortcut: 'Ctrl+S', onSelect: demoNoop),
  ],
);

/// "모바일 주 탐색에 쓰지 않기" 카드의 메뉴 — 화면 이름을 늘어놓은 막대.
const List<CoreMenubarMenu> demoMobileNavMenus = [
  CoreMenubarMenu(label: '홈'),
  CoreMenubarMenu(label: '검색'),
  CoreMenubarMenu(label: '프로필'),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// Menubar 의 variant 는 하나라, 컨트롤은 테두리와 항목의 모양을 고른다.
/// `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 그림 아래에
/// 실제 `Menubar` 를 둔다. 플레이그라운드만 켠다: 사이트의 다른 무대는
/// 브라우저에서 깨어나지 않아 눌러도 열리지 않는다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'shortcut': 'true', 'opener': 'true'},
  controls: [
    DocsPlaygroundFlag(label: '테두리 없음 (border: false)', on: {'border': 'false'}),
    DocsPlaygroundFlag(label: '단축키 힌트 (shortcut)', on: {'shortcut': 'true'}),
    DocsPlaygroundFlag(label: '비활성 항목 (enabled: false)', on: {'disabled': 'true'}),
  ],
  code: _menubarCode,
);

/// 크기 표. Menubar 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _menubarCode(Map<String, String> props, String? label) {
  final shortcuts = previewFlag(props, 'shortcut');
  final disabled = previewFlag(props, 'disabled');

  List<String> action(_DemoAction item) => [
    'CoreMenubarEntry.action(',
    "  label: '${item.label}',",
    if (shortcuts && item.shortcut != null) "  shortcut: '${item.shortcut}',",
    if (item.standardAction != null) '  standardAction: CoreMenuAction.${item.standardAction!.name},',
    if (disabled && item.disabledByFlag) '  enabled: false,',
    '  onSelect: ${item.callback},',
    '),',
  ];

  final lines = [
    'menus: [',
    for (final (title, actions) in _demoMenus) ...[
      '  CoreMenubarMenu(',
      "    label: '$title',",
      '    entries: [',
      for (final item in actions)
        if (item == null) '      CoreMenubarEntry.divider(),' else for (final line in action(item)) '      $line',
      '    ],',
      '  ),',
    ],
    '],',
    if (!demoBorder(props)) 'border: false,',
  ];
  return 'Menubar(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

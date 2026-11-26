/// ContextMenu 페이지 — 플레이그라운드와 미리보기의 항목 · 글자. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `context_menu_web.dart` · `context_menu_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 메뉴 항목(`CoreMenuItem`)은 플랫폼에 매이지 않아, 두 미리보기의 항목과
/// 플레이그라운드의 코드가 모두 이 파일에서 나온다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/context-menu.md`.
const String slug = 'context-menu';

/// 메뉴를 여는 영역(`child`)의 글자 — 그림 · 실제 `ContextMenu` · 코드가 함께 쓴다.
const String demoTargetLabel = '오른쪽 클릭하거나 길게 눌러 보세요';

/// `preview` 에 넣는 글자.
const String demoPreviewText = '분기 보고서.pdf · 2.4MB';

/// "여는 길" 카드의 파일 이름.
const String demoFileName = '분기 보고서.pdf';

/// "여는 길" 카드에서 버튼과 메뉴가 함께 여는 행동의 이름.
const String demoVisibleAction = '내려받기';

/// 플레이그라운드의 그림과 그 아래 실제 영역 사이의 간격 — 자리가 모자라 실제
/// 패널이 위로 열릴 때를 생각해 넉넉히 둔다.
const double demoOpenerGap = CoreSpace.space48;

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// ContextMenu 에는 variant · 크기 속성이 없어, 컨트롤은 켜고 끄는 속성과 항목의
/// 단축키 힌트를 고른다. `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 —
/// 켜면 그림 아래에 실제 `ContextMenu` 로 감싼 영역을 둔다. 플레이그라운드만
/// 켠다: 사이트의 다른 무대는 브라우저에서 깨어나지 않아 우클릭해도 열리지 않는다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'shortcut': 'true', 'opener': 'true'},
  label: demoTargetLabel,
  controls: [
    DocsPlaygroundFlag(label: '미리보기 (preview)', on: {'preview': 'true'}),
    DocsPlaygroundFlag(label: '들어 올리기 (liftChild)', on: {'liftChild': 'true'}),
    DocsPlaygroundFlag(label: '글라이드 (glideToSelect)', on: {'glideToSelect': 'true'}),
    DocsPlaygroundFlag(label: '햅틱 (haptics)', on: {'haptics': 'true'}),
    DocsPlaygroundFlag(label: '단축키 힌트 (shortcut)', on: {'shortcut': 'true'}),
    DocsPlaygroundFlag(label: '비활성 (enabled: false)', on: {'enabled': 'false'}),
  ],
  code: _contextMenuCode,
);

/// 크기 표. ContextMenu 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 `enabled` — 적지 않으면 켜져 있다.
bool demoEnabled(Map<String, String> props) => previewFlag(props, 'enabled', fallback: true);

/// 실제 `ContextMenu` 의 키 — 속성이 바뀌면 새로 만든다. 열려 있는 메뉴에서
/// 속성을 빼는 일이 없게 한다.
String demoPreviewKey(Map<String, String> props) {
  final values = [
    for (final entry in props.entries)
      if (entry.key != 'opener') '${entry.key}=${entry.value}',
  ];
  return 'context-menu:${values.join(';')}';
}

/// 동작 행 하나 — 글자, 단축키 힌트, 코드의 콜백 이름.
typedef _Action = ({String label, String shortcut, String callback});

const _Action _openFile = (label: '열기', shortcut: 'Ctrl+O', callback: 'openFile');
const _Action _shareFile = (label: '공유', shortcut: 'Ctrl+Shift+S', callback: 'shareFile');
const _Action _deleteFile = (label: '삭제', shortcut: 'Delete', callback: 'deleteFile');

/// 플레이그라운드의 항목.
List<CoreMenuItem<W>> demoItems<W>(Map<String, String> props) {
  final shortcuts = previewFlag(props, 'shortcut');

  CoreMenuItem<W> action(_Action row, {CoreMenuItemTone tone = CoreMenuItemTone.neutral}) =>
      CoreMenuItem<W>.action(row.label, tone: tone, shortcut: shortcuts ? row.shortcut : null, onPressed: () {});

  return [
    action(_openFile),
    action(_shareFile),
    CoreMenuItem<W>.divider(),
    action(_deleteFile, tone: CoreMenuItemTone.critical),
  ];
}

String _contextMenuCode(Map<String, String> props, String? label) {
  final shortcuts = previewFlag(props, 'shortcut');

  List<String> action(_Action row, {bool critical = false}) => [
    'CoreMenuItem.action(',
    "  '${row.label}',",
    if (critical) '  tone: CoreMenuItemTone.critical,',
    if (shortcuts) "  shortcut: '${row.shortcut}',",
    '  onPressed: ${row.callback},',
    '),',
  ];

  final items = [
    ...action(_openFile),
    ...action(_shareFile),
    'const CoreMenuItem.divider(),',
    ...action(_deleteFile, critical: true),
  ];

  final lines = [
    if (!demoEnabled(props)) 'enabled: false,',
    if (previewFlag(props, 'liftChild')) 'liftChild: true,',
    if (previewFlag(props, 'glideToSelect')) 'glideToSelect: true,',
    if (previewFlag(props, 'haptics')) 'haptics: true,',
    if (previewFlag(props, 'preview')) "preview: Text('$demoPreviewText'),",
    'items: [',
    for (final line in items) '  $line',
    '],',
    'child: OutlinedContainer(',
    '  containerStyle: CoreOutlinedContainerStyle(',
    '    padding: CoreEdgeInsets.all(CoreSpace.space24),',
    '  ),',
    "  child: Text('${label ?? demoTargetLabel}'),",
    '),',
  ];
  return 'ContextMenu(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

/// 구조 장면의 항목 — 아이콘이 붙은 동작 행, 구분선, 위험한 행.
List<CoreMenuItem<W>> demoAnatomyItems<W>() => [
  CoreMenuItem<W>.action('복사', standardAction: CoreMenuAction.copy, shortcut: 'Ctrl+C', onPressed: () {}),
  CoreMenuItem<W>.action('이름 바꾸기', standardAction: CoreMenuAction.rename, shortcut: 'F2', onPressed: () {}),
  CoreMenuItem<W>.divider(),
  CoreMenuItem<W>.action(
    '삭제',
    standardAction: CoreMenuAction.delete,
    tone: CoreMenuItemTone.critical,
    onPressed: () {},
  ),
];

/// "여는 길" 카드의 메뉴 항목.
List<CoreMenuItem<W>> demoPathItems<W>() => [
  CoreMenuItem<W>.action(demoVisibleAction, onPressed: () {}),
  CoreMenuItem<W>.action('이름 바꾸기', onPressed: () {}),
];

/// "위험한 행동은 맨 끝에" 카드의 항목.
List<CoreMenuItem<W>> demoCriticalLastItems<W>() => [
  CoreMenuItem<W>.action('열기', onPressed: () {}),
  CoreMenuItem<W>.action('공유', onPressed: () {}),
  CoreMenuItem<W>.divider(),
  CoreMenuItem<W>.action('삭제', tone: CoreMenuItemTone.critical, onPressed: () {}),
];

/// "위험한 행동을 사이에 끼우지 않기" 카드의 항목.
List<CoreMenuItem<W>> demoCriticalMiddleItems<W>() => [
  CoreMenuItem<W>.action('열기', onPressed: () {}),
  CoreMenuItem<W>.action('삭제', tone: CoreMenuItemTone.critical, onPressed: () {}),
  CoreMenuItem<W>.action('공유', onPressed: () {}),
];

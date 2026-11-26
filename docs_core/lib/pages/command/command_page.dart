/// Command 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `command_web.dart` · `command_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// `Command` 는 놓인 자리에 그려지는 상자라 무대의 팔레트는 실제 컴포넌트다.
/// 항목 · 범위 · 장면의 글자와 속성 해석은 이 파일 한 곳에 둔다 — 두 플랫폼의
/// 미리보기와 플레이그라운드의 코드가 같은 항목을 쓴다.
///
/// 속성: `presentation` · `size`(enum 이름), `showFooter`(`null` · `true` ·
/// `false`), `scopes` · `icons` · `overline` · `dismiss`(켜고 끄기),
/// `items=short`(첫 그룹만), `query`(처음 검색어), `width`(미리보기 폭,
/// `CoreLayout` 단계). `opener` 는 위젯의 속성이 아니라 플레이그라운드의
/// 손잡이다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/command.md`.
const String slug = 'command';

/// 미리보기 팔레트의 폭.
const double commandPreviewWidth = CoreLayout.layout400;

/// Flutter 미리보기가 줄이지 않고 그리는 가장 좁은 폭 — 이보다 좁은 칸에서는
/// 팔레트를 통째로 줄여 그린다.
const double commandPreviewMinWidth = CoreLayout.layout320;

/// `fullscreen` 미리보기가 화면 대신 쓰는 높이.
const double commandPreviewScreenHeight = CoreLayout.layout400;

/// 실제 `Dialog` 를 여는 버튼의 글자 — 플레이그라운드의 dialog 형태에만 있다.
const String commandPreviewOpener = '열어 보기';

/// 팔레트를 대화상자에 넣을 때의 `dialogStyle` — 플레이그라운드의 "열어 보기"와
/// 만들어진 코드가 같은 값을 쓴다. 팔레트가 자기 패널을 그리므로 대화상자의
/// 여백 · 테두리 · 머리 간격을 없애고, 폭 한계를 팔레트의 640 에 맞춘다.
const CoreDialogStyle commandPreviewDialogStyle = CoreDialogStyle(
  panelPadding: CoreEdgeInsets.zero,
  panelBorderWidth: 0,
  sectionGapStyle: CoreGapStyle(size: 0),
  panelMaxWidth: CoreLayout.layout640,
);

/// 윗줄(`overline`)을 켰을 때 두 줄이 되는 항목.
const String commandPreviewOverlineValue = 'notifications';

/// [commandPreviewOverlineValue] 의 윗줄.
const String commandPreviewOverline = '계정';

/// 범위 칩.
const List<CoreCommandScope> commandPreviewScopes = [
  CoreCommandScope(value: 'actions', label: '작업'),
  CoreCommandScope(value: 'pages', label: '페이지'),
];

/// `command/scopes` 장면에서 고른 범위.
const String commandScopesSceneValue = 'pages';

/// `command/keywords` 장면의 검색어 — 라벨에는 없고 `keywords` 에만 있다.
const String commandKeywordQuery = 'date';

/// 빈 결과 장면의 검색어.
const String commandEmptyQuery = 'zzz';

/// 빈 결과 장면의 행동 버튼 글자.
const String commandEmptyActionLabel = '검색어 지우기';

/// 미리보기 항목 하나.
typedef CommandPreviewItem = ({String value, String label, IconName icon, String? shortcut, List<String> keywords});

/// 미리보기 그룹 하나.
typedef CommandPreviewGroup = ({String heading, String scope, List<CommandPreviewItem> items});

/// 미리보기와 코드의 항목.
const List<CommandPreviewGroup> commandPreviewData = [
  (
    heading: '추천',
    scope: 'actions',
    items: [
      (value: 'calendar', label: '캘린더', icon: LucideIcons.calendar, shortcut: null, keywords: ['일정', 'date']),
      (value: 'upload', label: '파일 올리기', icon: LucideIcons.upload, shortcut: null, keywords: []),
      (value: 'download', label: '내려받기', icon: LucideIcons.download, shortcut: null, keywords: []),
    ],
  ),
  (
    heading: '설정',
    scope: 'pages',
    items: [
      (value: 'settings', label: '환경 설정', icon: LucideIcons.settings, shortcut: '⌘,', keywords: []),
      (value: 'notifications', label: '알림', icon: LucideIcons.bell, shortcut: '⌘B', keywords: []),
    ],
  ),
];

/// `command/dont-flat` 장면의 항목 — 그룹 없이 늘어놓은 열 개.
const List<(String, String)> commandFlatSceneItems = [
  ('calendar', '캘린더'),
  ('upload', '파일 올리기'),
  ('download', '내려받기'),
  ('settings', '환경 설정'),
  ('notifications', '알림'),
  ('security', '보안'),
  ('share', '공유'),
  ('copy', '링크 복사'),
  ('inbox', '받은 편지함'),
  ('profile', '프로필'),
];

/// `command/long-list` 장면의 항목 수 — 목록의 높이 한계를 넘는다.
const int commandLongListSceneCount = 24;

/// 속성 문자열을 읽은 값.
class CommandPreviewOptions {
  /// 속성 [props] 를 읽는다. 모르는 값은 위젯의 기본값으로 떨어진다.
  CommandPreviewOptions.from(Map<String, String> props)
    : presentation = previewEnum(
        CoreCommandPresentation.values,
        props['presentation'],
        CoreCommandPresentation.defaultPresentation,
      ),
      size = previewEnum(CoreCommandSize.values, props['size'], CoreCommandSize.defaultSize),
      showFooter = _showFooterOf(props['showFooter']),
      scopes = previewFlag(props, 'scopes'),
      icons = previewFlag(props, 'icons'),
      overline = previewFlag(props, 'overline'),
      dismiss = previewFlag(props, 'dismiss'),
      shortItems = props['items'] == 'short',
      query = props['query'] ?? '',
      width = _widthOf(props['width']);

  /// 형태.
  final CoreCommandPresentation presentation;

  /// 크기.
  final CoreCommandSize size;

  /// 푸터 — `null` 이면 형태가 정한다.
  final bool? showFooter;

  /// 범위 칩을 둘지.
  final bool scopes;

  /// 항목에 아이콘을 둘지.
  final bool icons;

  /// 한 항목에 윗줄을 둘지.
  final bool overline;

  /// `onDismiss` 를 줄지.
  final bool dismiss;

  /// 첫 그룹만 보일지.
  final bool shortItems;

  /// 처음 검색어.
  final String query;

  /// 미리보기 폭.
  final double width;
}

bool? _showFooterOf(String? raw) => switch (raw) {
  'true' => true,
  'false' => false,
  _ => null,
};

double _widthOf(String? raw) {
  final px = double.tryParse(raw ?? '');
  return px != null && CoreLayout.values.contains(px) ? px : commandPreviewWidth;
}

/// [options] 의 그룹 — 아이콘 위젯은 플랫폼마다 [glyph] 가 만든다.
List<CoreCommandGroup<W>> commandPreviewGroups<W>(CommandPreviewOptions options, W Function(IconName icon) glyph) {
  final data = options.shortItems ? commandPreviewData.take(1) : commandPreviewData;
  return [
    for (final group in data)
      CoreCommandGroup<W>(
        heading: group.heading,
        scope: options.scopes ? group.scope : null,
        items: [
          for (final item in group.items)
            CoreCommandItem<W>(
              value: item.value,
              label: item.label,
              icon: options.icons ? glyph(item.icon) : null,
              shortcut: item.shortcut,
              keywords: item.keywords,
              overline: options.overline && item.value == commandPreviewOverlineValue ? commandPreviewOverline : null,
            ),
        ],
      ),
  ];
}

/// `command/items` 장면 — 강조된 행 · 단축키 · 윗줄 · 비활성 행.
List<CoreCommandGroup<W>> commandItemsSceneGroups<W>(W Function(IconName icon) glyph) => [
  CoreCommandGroup<W>(
    heading: '항목',
    items: [
      CoreCommandItem<W>(value: 'calendar', label: '캘린더', icon: glyph(LucideIcons.calendar)),
      CoreCommandItem<W>(value: 'settings', label: '환경 설정', icon: glyph(LucideIcons.settings), shortcut: '⌘,'),
      CoreCommandItem<W>(
        value: 'notifications',
        label: '알림 설정',
        overline: commandPreviewOverline,
        icon: glyph(LucideIcons.bell),
      ),
      CoreCommandItem<W>(value: 'download', label: '내려받기', icon: glyph(LucideIcons.download), enabled: false),
    ],
  ),
];

/// `command/dont-flat` 장면의 그룹 — 제목 없는 한 덩어리.
List<CoreCommandGroup<W>> commandFlatSceneGroups<W>() => [
  CoreCommandGroup<W>(
    items: [
      for (final (value, label) in commandFlatSceneItems) CoreCommandItem<W>(value: value, label: label),
    ],
  ),
];

/// `command/long-list` 장면의 그룹 — 목록 안에서 스크롤할 만큼의 항목.
List<CoreCommandGroup<W>> commandLongListSceneGroups<W>() => [
  CoreCommandGroup<W>(
    heading: '페이지',
    items: [
      for (var i = 1; i <= commandLongListSceneCount; i++) CoreCommandItem<W>(value: 'page-$i', label: '페이지 $i'),
    ],
  ),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 `presentation` 이
/// dialog 일 때 팔레트 아래에 실제 `Dialog` 를 여는 버튼을 두고, 무대의
/// 팔레트는 입력에 따라 걸러진다. 플레이그라운드만 브라우저에서 깨어난다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'presentation': 'inline', 'size': 'md', 'showFooter': 'null', 'icons': 'true', 'opener': 'true'},
  controls: [
    DocsPlaygroundChoice(label: 'presentation', prop: 'presentation', options: ['inline', 'dialog', 'fullscreen']),
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md', 'lg'], segmented: true),
    DocsPlaygroundChoice(label: 'showFooter', prop: 'showFooter', options: ['null', 'true', 'false'], segmented: true),
    DocsPlaygroundFlag(label: '범위 칩 (scopes)', on: {'scopes': 'true'}),
    DocsPlaygroundFlag(label: '항목 아이콘', on: {'icons': 'true'}),
    DocsPlaygroundFlag(label: '윗줄 (overline)', on: {'overline': 'true'}),
    DocsPlaygroundFlag(label: 'onDismiss', on: {'dismiss': 'true'}),
  ],
  code: _commandCode,
);

/// 크기 표.
DocsSizeSpec Function()? get sizeSpec => _commandSpec;

String _commandCode(Map<String, String> props, String? label) {
  final options = CommandPreviewOptions.from(props);
  final arguments = _commandArguments(options);
  if (options.presentation == CoreCommandPresentation.dialog) {
    return [
      'Dialog(',
      '  open: isOpen,',
      '  onClose: close,',
      '  content: Command(',
      for (final line in arguments) '    $line',
      '  ),',
      '  dialogStyle: CoreDialogStyle(',
      '    panelPadding: CoreEdgeInsets.zero,',
      '    panelBorderWidth: 0,',
      '    sectionGapStyle: CoreGapStyle(size: 0),',
      '    panelMaxWidth: CoreLayout.layout640,',
      '  ),',
      ')',
    ].join('\n');
  }
  return [
    if (options.presentation == CoreCommandPresentation.fullscreen) '// 높이가 정해진 자리(화면 전체를 쓰는 라우트)에 놓습니다.',
    'Command(',
    for (final line in arguments) '  $line',
    ')',
  ].join('\n');
}

List<String> _commandArguments(CommandPreviewOptions options) {
  final data = options.shortItems ? commandPreviewData.take(1) : commandPreviewData;
  return [
    if (options.presentation != CoreCommandPresentation.defaultPresentation)
      'presentation: CoreCommandPresentation.${options.presentation.name},',
    if (options.size != CoreCommandSize.defaultSize) 'size: CoreCommandSize.${options.size.name},',
    'query: query,',
    'onQueryChanged: setQuery,',
    if (options.scopes) ...[
      'scopes: [',
      for (final scope in commandPreviewScopes) "  CoreCommandScope(value: '${scope.value}', label: '${scope.label}'),",
      '],',
      'scope: scope,',
      'onScopeChanged: setScope,',
    ],
    'onSelect: runCommand,',
    if (options.dismiss) 'onDismiss: close,',
    if (options.showFooter case final show?) 'showFooter: $show,',
    if (options.presentation == CoreCommandPresentation.inline) 'autofocus: false,',
    'groups: [',
    for (final group in data) ...[
      '  CoreCommandGroup(',
      "    heading: '${group.heading}',",
      if (options.scopes) "    scope: '${group.scope}',",
      '    items: [',
      for (final item in group.items) ...[
        '      CoreCommandItem(',
        "        value: '${item.value}',",
        "        label: '${item.label}',",
        if (options.overline && item.value == commandPreviewOverlineValue)
          "        overline: '$commandPreviewOverline',",
        if (options.icons) '        icon: Icon(LucideIcons.${docsIconIdentifier(item.icon.name)}),',
        if (item.shortcut case final shortcut?) "        shortcut: '$shortcut',",
        if (item.keywords.isNotEmpty) "        keywords: [${item.keywords.map((k) => "'$k'").join(', ')}],",
        '      ),',
      ],
      '    ],',
      '  ),',
    ],
    '],',
  ];
}

DocsSizeSpec _commandSpec() {
  return DocsSizeSpec(
    columns: const ['size', '검색 줄 · 행 높이', '행 좌우 · 위아래 여백', '검색 · 항목 아이콘', '항목 글자', '범위 칩 높이'],
    rows: [for (final size in CoreCommandSize.values) _commandSizeRow(size)],
  );
}

DocsSizeSpecRow _commandSizeRow(CoreCommandSize size) {
  final row = CoreCommandStyle.defaultsBySize[size]!;
  final chip = CoreChipStyle.defaultsBySize[size.toChipSize()]!;
  return DocsSizeSpecRow(
    size: size.toComponentSize(),
    cells: [
      '${docsSizeNumber(row.searchInputHeight)} · ${docsSizeNumber(row.itemMinHeight)}',
      '${docsSizeNumber(row.itemPadding?.left)} · ${docsSizeNumber(row.itemPadding?.top)}',
      '${docsSizeNumber(row.searchIconStyle?.size)} · ${docsSizeNumber(row.itemIconStyle?.size)}',
      docsSizeLabel(row.labelStyle),
      docsSizeNumber(chip.minHeight),
    ],
  );
}

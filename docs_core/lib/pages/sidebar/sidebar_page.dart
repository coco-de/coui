/// Sidebar 페이지 — 플레이그라운드와 미리보기 · 장면이 함께 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `sidebar_web.dart` · `sidebar_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/sidebar.md`.
const String slug = 'sidebar';

/// 미리보기의 목적지 하나 — 패널의 행 또는 레일의 칸.
typedef SidebarPreviewDestination = ({String id, String label, IconName icon});

/// 미리보기의 하위 행 하나.
typedef SidebarPreviewSubPage = ({String id, String label});

/// 패널 본문의 목적지.
const List<SidebarPreviewDestination> kSidebarPreviewPages = [
  (id: 'home', label: '홈', icon: LucideIcons.house),
  (id: 'inbox', label: '받은 편지함', icon: LucideIcons.inbox),
  (id: 'calendar', label: '일정', icon: LucideIcons.calendar),
];

/// 레일의 영역.
const List<SidebarPreviewDestination> kSidebarPreviewAreas = [
  (id: 'work', label: '작업', icon: LucideIcons.layoutGrid),
  (id: 'schedule', label: '일정', icon: LucideIcons.calendar),
  (id: 'alerts', label: '알림', icon: LucideIcons.bell),
];

/// 하위 그룹의 행.
const List<SidebarPreviewSubPage> kSidebarPreviewSubPages = [
  (id: 'design', label: '디자인 시스템'),
  (id: 'website', label: '웹사이트'),
];

/// 처음에 선택된 패널 행.
const String kSidebarPreviewFirstPage = 'home';

/// 처음에 선택된 레일 칸.
const String kSidebarPreviewFirstArea = 'work';

/// 안 읽음 점과 개수를 다는 패널 행.
const String kSidebarPreviewUnreadPage = 'inbox';

/// 안 읽음 점을 다는 레일 칸.
const String kSidebarPreviewUnreadArea = 'alerts';

/// 내비게이션 랜드마크의 이름.
const String kSidebarPreviewLabel = '주 메뉴';

/// 워크스페이스 이름.
const String kSidebarPreviewWorkspace = '나음 병원';

/// 워크스페이스 설명 줄.
const String kSidebarPreviewRole = '본원 · 관리자';

/// 워크스페이스 아바타의 글자.
const String kSidebarPreviewMark = 'C';

/// 로그인한 사람의 이름.
const String kSidebarPreviewUser = '김하나';

/// 로그인한 사람의 설명 줄.
const String kSidebarPreviewEmail = 'hana@example.com';

/// 로그인한 사람의 아바타 글자.
const String kSidebarPreviewUserInitials = '김';

/// 검색 버튼의 글자.
const String kSidebarPreviewSearch = '검색';

/// 검색 단축키 — 사이드바는 그리기만 한다.
const List<String> kSidebarPreviewShortcut = ['⌘', 'K'];

/// 행 묶음 제목.
const String kSidebarPreviewSection = '업무';

/// 하위 그룹 행의 이름.
const String kSidebarPreviewGroup = '프로젝트';

/// 도움말 행의 이름.
const String kSidebarPreviewHelp = '도움말';

/// 두 칸 패널의 제목.
const String kSidebarPreviewPanelTitle = '작업 보드';

/// 레일 맨 아래 설정 칸의 이름.
const String kSidebarPreviewSettings = '설정';

/// 사용량 카드의 라벨.
const String kSidebarPreviewUsageLabel = '저장 공간';

/// 사용량 카드의 값 글자.
const String kSidebarPreviewUsageValue = '60%';

/// 사용량 카드의 값.
const double kSidebarPreviewUsage = 0.6;

/// 한 패널 · 두 칸 미리보기의 높이 — 사이드바는 부모 높이를 채운다.
const double kSidebarStandardHeight = 560;

/// 아래 영역이 없는 두 칸 장면의 높이.
const double kSidebarTwoPaneHeight = 440;

/// 레일만 그리는 미리보기의 높이.
const double kSidebarCollapsedHeight = 320;

/// 카드 안 장면에서 쓰는 좁은 패널.
const CoreSidebarStyle kSidebarNarrowStyle = CoreSidebarStyle(panelWidth: CoreLayout.layout160);

/// 속성의 `type` — 없거나 모르는 값이면 기본 형태.
CoreSidebarType sidebarPreviewType(Map<String, String> props) =>
    previewEnum(CoreSidebarType.values, props['type'], CoreSidebarType.defaultType);

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'type': 'standard', 'search': 'true', 'bottom': 'true', 'group': 'true'},
  controls: [
    DocsPlaygroundChoice(label: 'type', prop: 'type', options: ['standard', 'twoPane', 'collapsed']),
    DocsPlaygroundFlag(label: '검색', on: {'search': 'true'}),
    DocsPlaygroundFlag(label: '도움말 · 사용자', on: {'bottom': 'true'}),
    DocsPlaygroundFlag(label: '하위 그룹', on: {'group': 'true'}),
    DocsPlaygroundFlag(label: '안 읽음 점', on: {'dot': 'true'}),
    DocsPlaygroundFlag(label: '개수 배지', on: {'count': '3'}),
  ],
  code: _sidebarCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

String _sidebarCode(Map<String, String> props, String? label) {
  final type = sidebarPreviewType(props);
  final dot = previewFlag(props, 'dot');
  final lines = [
    if (type != CoreSidebarType.defaultType) 'type: CoreSidebarType.${type.name},',
    "semanticLabel: '$kSidebarPreviewLabel',",
    if (type.hasRail) ..._railCode(dot: dot),
    if (type.hasPanel) ...[
      if (type == CoreSidebarType.standard) ..._workspaceCode(),
      if (type == CoreSidebarType.twoPane) ...[
        "panelTitle: Text('$kSidebarPreviewPanelTitle'),",
        'panelAction: Icon(LucideIcons.plus),',
      ],
      if (previewFlag(props, 'search')) ..._searchCode(),
      ..._rowsCode(group: previewFlag(props, 'group'), dot: dot, count: props['count']),
      if (previewFlag(props, 'bottom')) ..._bottomCode(),
    ],
  ];
  return 'Sidebar(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

/// 여는 줄, 두 칸 들여 쓴 본문, 닫는 줄.
List<String> _block(String open, Iterable<String> body, [String close = '),']) => [
  open,
  for (final line in body) '  $line',
  close,
];

String _iconCode(IconName icon) => 'LucideIcons.${docsIconIdentifier(icon.name)}';

List<String> _railCode({required bool dot}) => [
  "railHeader: Avatar(initials: '$kSidebarPreviewMark'),",
  ..._block('railItems: [', [
    for (final area in kSidebarPreviewAreas)
      ..._block('SidebarRailItem(', [
        'icon: Icon(${_iconCode(area.icon)}),',
        "label: '${area.label}',",
        if (dot && area.id == kSidebarPreviewUnreadArea) 'dot: true,',
        "selected: area == '${area.id}',",
        "onPressed: () => openArea('${area.id}'),",
      ]),
  ], '],'),
  ..._block('railFooter: SidebarRailItem(', [
    'icon: Icon(LucideIcons.settings),',
    "label: '$kSidebarPreviewSettings',",
    'onPressed: openSettings,',
  ]),
];

List<String> _workspaceCode() => _block('header: SidebarHeader(', [
  "leading: Avatar(initials: '$kSidebarPreviewMark'),",
  "title: Text('$kSidebarPreviewWorkspace'),",
  "subtitle: Text('$kSidebarPreviewRole'),",
  'trailing: Icon(LucideIcons.chevronsUpDown),',
  'onPressed: openWorkspaces,',
]);

List<String> _searchCode() => _block('search: SidebarSearch(', [
  "placeholder: '$kSidebarPreviewSearch',",
  'shortcut: [${kSidebarPreviewShortcut.map((key) => "'$key'").join(', ')}],',
  'onPressed: openSearch,',
]);

List<String> _rowsCode({required bool group, required bool dot, String? count}) => _block('children: [', [
  for (final destination in kSidebarPreviewPages)
    ..._block('SidebarItem(', [
      'leading: Icon(${_iconCode(destination.icon)}),',
      "label: Text('${destination.label}'),",
      if (dot && destination.id == kSidebarPreviewUnreadPage) 'dot: true,',
      if (count != null && destination.id == kSidebarPreviewUnreadPage)
        "count: Badge(form: CoreBadgeForm.count, child: Text('$count')),",
      "selected: page == '${destination.id}',",
      "onPressed: () => openPage('${destination.id}'),",
    ]),
  if (group) ...[
    "SidebarSection(label: Text('$kSidebarPreviewSection')),",
    ..._block('SidebarGroup(', [
      'leading: Icon(LucideIcons.folder),',
      "label: Text('$kSidebarPreviewGroup'),",
      ..._block('children: [', [
        for (final sub in kSidebarPreviewSubPages)
          ..._block('SidebarItem(', [
            'level: CoreSidebarItemLevel.nested,',
            "label: Text('${sub.label}'),",
            "selected: page == '${sub.id}',",
            "onPressed: () => openPage('${sub.id}'),",
          ]),
      ], '],'),
    ]),
  ],
], '],');

List<String> _bottomCode() => [
  ..._block('help: SidebarItem(', [
    'leading: Icon(LucideIcons.info),',
    "label: Text('$kSidebarPreviewHelp'),",
    'onPressed: openHelp,',
  ]),
  ..._block('user: SidebarHeader(', [
    'variant: CoreSidebarHeaderVariant.card,',
    "leading: Avatar(initials: '$kSidebarPreviewUserInitials'),",
    "title: Text('$kSidebarPreviewUser'),",
    "subtitle: Text('$kSidebarPreviewEmail'),",
  ]),
];

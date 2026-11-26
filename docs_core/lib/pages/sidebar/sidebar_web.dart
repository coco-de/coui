/// Sidebar 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="sidebar/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`sidebar_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 사이드바는 부모의 높이를 채우므로 모든 미리보기가 높이를 정한 상자에
/// 그린다. 폭이 모자란 칸에서는 상자 안에서 가로로 밀어 본다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'sidebar_page.dart' as page;

/// 속성 → Component.
///
/// 행은 눌러야 선택이 옮겨 가므로 빌더가 선택을 기억한다. 서버에서 그리는
/// 블록에서는 처음 선택만 보이고, 브라우저에서 깨어나는 플레이그라운드에서는
/// 행과 레일을 누를 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _SidebarPreview(props: props);

/// 장면 이름(`sidebar/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'sidebar/anatomy': _anatomy,
  'sidebar/anatomy-two-pane': _anatomyTwoPane,
  'sidebar/standard': () => _frame(
    _sidebar(type: CoreSidebarType.standard, search: true, bottom: true, group: true, dot: true, count: '3'),
    height: page.kSidebarStandardHeight,
  ),
  'sidebar/two-pane': () => _frame(
    _sidebar(type: CoreSidebarType.twoPane, search: true, group: true, dot: true),
    height: page.kSidebarTwoPaneHeight,
  ),
  'sidebar/collapsed': () => _frame(
    _sidebar(type: CoreSidebarType.collapsed, dot: true),
    height: page.kSidebarCollapsedHeight,
  ),
  'sidebar/rows': _rows,
  'sidebar/headers': _headers,
  'sidebar/states': _states,
  'sidebar/placement': _placement,
  'sidebar/do-one-selected': () => _narrow([
    _choice('홈', LucideIcons.house, selected: true),
    _choice('받은 편지함', LucideIcons.inbox),
    _choice('일정', LucideIcons.calendar),
  ]),
  'sidebar/dont-many-selected': () => _narrow([
    _choice('홈', LucideIcons.house, selected: true),
    _choice('받은 편지함', LucideIcons.inbox, selected: true),
    _choice('일정', LucideIcons.calendar),
  ]),
  'sidebar/do-sub-level': () => _narrow([_subGroup(CoreSidebarItemLevel.nested)]),
  'sidebar/dont-top-level-rows': () => _narrow([_subGroup(CoreSidebarItemLevel.top)]),
  'sidebar/related-navigation-bar': () => div(styles: Styles(raw: {'width': '12rem', 'max-width': '100%'}), [
    NavigationBar(
      mode: CoreNavigationBarMode.bar,
      selectedIndex: 0,
      onSelected: (_) {},
      labelMode: CoreNavigationLabelMode.all,
      items: [
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.house), label: '홈'),
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.search), label: '검색'),
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.settings), label: '설정'),
      ],
    ),
  ]),
  'sidebar/related-kbd': () => Kbd(keys: page.kSidebarPreviewShortcut),
};

class _SidebarPreview extends StatefulComponent {
  const _SidebarPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_SidebarPreview> createState() => _SidebarPreviewState();
}

class _SidebarPreviewState extends State<_SidebarPreview> {
  String _selectedPage = page.kSidebarPreviewFirstPage;
  String _selectedArea = page.kSidebarPreviewFirstArea;

  @override
  Component build(BuildContext context) {
    final props = component.props;
    final type = page.sidebarPreviewType(props);
    return _frame(
      _sidebar(
        type: type,
        search: previewFlag(props, 'search'),
        bottom: previewFlag(props, 'bottom'),
        group: previewFlag(props, 'group'),
        dot: previewFlag(props, 'dot'),
        count: props['count'],
        selectedPage: _selectedPage,
        selectedArea: _selectedArea,
        onPage: (id) => setState(() => _selectedPage = id),
        onArea: (id) => setState(() => _selectedArea = id),
      ),
      height: type == CoreSidebarType.collapsed ? page.kSidebarCollapsedHeight : page.kSidebarStandardHeight,
    );
  }
}

/// 높이를 정한 상자 — 사이드바가 이 높이를 채운다.
Component _frame(Component child, {required double height, String? width}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'height': '${height}px',
      'width': ?width,
      'max-width': '100%',
      'min-width': '0',
      'overflow': 'auto',
    },
  ),
  [child],
);

void _ignore(String id) {}

Component _sidebar({
  required CoreSidebarType type,
  bool search = false,
  bool bottom = false,
  bool group = false,
  bool dot = false,
  String? count,
  String selectedPage = page.kSidebarPreviewFirstPage,
  String selectedArea = page.kSidebarPreviewFirstArea,
  void Function(String id) onPage = _ignore,
  void Function(String id) onArea = _ignore,
}) {
  final standard = type == CoreSidebarType.standard;
  final twoPane = type == CoreSidebarType.twoPane;
  return Sidebar(
    type: type,
    semanticLabel: page.kSidebarPreviewLabel,
    railHeader: Avatar(initials: page.kSidebarPreviewMark),
    railItems: [
      for (final area in page.kSidebarPreviewAreas)
        SidebarRailItem(
          icon: Icon(area.icon),
          label: area.label,
          dot: dot && area.id == page.kSidebarPreviewUnreadArea,
          selected: area.id == selectedArea,
          onPressed: () => onArea(area.id),
        ),
    ],
    railFooter: _settingsRailItem(),
    header: standard ? _workspace() : null,
    panelTitle: twoPane ? Text(page.kSidebarPreviewPanelTitle) : null,
    panelAction: twoPane ? Icon(LucideIcons.plus) : null,
    search: search ? _search() : null,
    help: bottom ? _help() : null,
    user: bottom ? _user() : null,
    children: [
      for (final destination in page.kSidebarPreviewPages)
        SidebarItem(
          leading: Icon(destination.icon),
          label: Text(destination.label),
          dot: dot && destination.id == page.kSidebarPreviewUnreadPage,
          count: count != null && destination.id == page.kSidebarPreviewUnreadPage
              ? Badge(form: CoreBadgeForm.count, child: Text(count))
              : null,
          selected: destination.id == selectedPage,
          onPressed: () => onPage(destination.id),
        ),
      if (group) ...[
        SidebarSection(label: Text(page.kSidebarPreviewSection)),
        SidebarGroup(
          leading: Icon(LucideIcons.folder),
          label: Text(page.kSidebarPreviewGroup),
          children: [
            for (final sub in page.kSidebarPreviewSubPages)
              SidebarItem(
                level: CoreSidebarItemLevel.nested,
                label: Text(sub.label),
                selected: sub.id == selectedPage,
                onPressed: () => onPage(sub.id),
              ),
          ],
        ),
      ],
    ],
  );
}

Component _workspace({Map<String, String>? attributes}) => SidebarHeader(
  leading: Avatar(initials: page.kSidebarPreviewMark),
  title: Text(page.kSidebarPreviewWorkspace),
  subtitle: Text(page.kSidebarPreviewRole),
  trailing: Icon(LucideIcons.chevronsUpDown),
  onPressed: () {},
  attributes: attributes,
);

Component _search({Map<String, String>? attributes}) => SidebarSearch(
  placeholder: page.kSidebarPreviewSearch,
  shortcut: page.kSidebarPreviewShortcut,
  onPressed: () {},
  attributes: attributes,
);

Component _help({Map<String, String>? attributes}) => SidebarItem(
  leading: Icon(LucideIcons.info),
  label: Text(page.kSidebarPreviewHelp),
  onPressed: () {},
  attributes: attributes,
);

Component _user({Map<String, String>? attributes}) => SidebarHeader(
  variant: CoreSidebarHeaderVariant.card,
  leading: Avatar(initials: page.kSidebarPreviewUserInitials),
  title: Text(page.kSidebarPreviewUser),
  subtitle: Text(page.kSidebarPreviewEmail),
  attributes: attributes,
);

Component _settingsRailItem({Map<String, String>? attributes}) => SidebarRailItem(
  icon: Icon(LucideIcons.settings),
  label: page.kSidebarPreviewSettings,
  onPressed: () {},
  attributes: attributes,
);

Component _anatomy() => _frame(
  Sidebar(
    semanticLabel: page.kSidebarPreviewLabel,
    header: _workspace(attributes: const {'data-docs-part': 'header'}),
    search: _search(attributes: const {'data-docs-part': 'search'}),
    footer: div(
      attributes: const {'data-docs-part': 'footer'},
      [
        Card(
          body: Progress(
            value: page.kSidebarPreviewUsage,
            label: Text(page.kSidebarPreviewUsageLabel),
            valueLabel: Text(page.kSidebarPreviewUsageValue),
          ),
        ),
      ],
    ),
    help: _help(attributes: const {'data-docs-part': 'help'}),
    user: _user(attributes: const {'data-docs-part': 'user'}),
    children: [
      for (final destination in page.kSidebarPreviewPages)
        SidebarItem(
          leading: Icon(destination.icon),
          label: Text(destination.label),
          selected: destination.id == page.kSidebarPreviewFirstPage,
          onPressed: () {},
        ),
    ],
  ),
  height: page.kSidebarStandardHeight,
);

Component _anatomyTwoPane() => _frame(
  Sidebar(
    type: CoreSidebarType.twoPane,
    semanticLabel: page.kSidebarPreviewLabel,
    railHeader: Avatar(initials: page.kSidebarPreviewMark, attributes: const {'data-docs-part': 'rail-header'}),
    railItems: [
      for (final (index, area) in page.kSidebarPreviewAreas.indexed)
        SidebarRailItem(
          icon: Icon(area.icon),
          label: area.label,
          selected: area.id == page.kSidebarPreviewFirstArea,
          onPressed: () {},
          attributes: index == 0 ? const {'data-docs-part': 'rail-item'} : null,
        ),
    ],
    railFooter: _settingsRailItem(attributes: const {'data-docs-part': 'rail-footer'}),
    panelTitle: Text(page.kSidebarPreviewPanelTitle),
    panelAction: span(attributes: const {'data-docs-part': 'panel-action'}, [Icon(LucideIcons.plus)]),
    children: [
      for (final destination in page.kSidebarPreviewPages)
        SidebarItem(
          leading: Icon(destination.icon),
          label: Text(destination.label),
          selected: destination.id == page.kSidebarPreviewFirstPage,
          onPressed: () {},
        ),
    ],
  ),
  height: page.kSidebarTwoPaneHeight,
);

Component _rows() => _frame(
  Sidebar(
    semanticLabel: page.kSidebarPreviewLabel,
    children: [
      SidebarItem(
        leading: Icon(LucideIcons.inbox),
        label: Text('받은 편지함'),
        count: Badge(form: CoreBadgeForm.count, child: Text('3')),
        onPressed: () {},
      ),
      SidebarItem(leading: Icon(LucideIcons.bell), label: Text('알림'), dot: true, onPressed: () {}),
      SidebarItem(
        leading: Icon(LucideIcons.settings),
        label: Text(page.kSidebarPreviewSettings),
        trailing: Icon(LucideIcons.chevronRight),
        onPressed: () {},
      ),
      SidebarSection(label: Text(page.kSidebarPreviewSection), action: Icon(LucideIcons.plus)),
      _subGroup(CoreSidebarItemLevel.nested),
    ],
  ),
  height: 300,
);

Component _headers() => _frame(
  Sidebar(semanticLabel: page.kSidebarPreviewLabel, header: _workspace(), user: _user()),
  height: 200,
);

Component _states() => div(
  styles: Styles(raw: {'display': 'flex', 'gap': '24px', 'max-width': '100%', 'overflow': 'auto'}),
  [
    _frame(
      Sidebar(
        sidebarStyle: page.kSidebarNarrowStyle,
        children: [
          SidebarItem(leading: Icon(LucideIcons.house), label: Text('기본'), onPressed: () {}),
          SidebarItem(leading: Icon(LucideIcons.inbox), label: Text('선택됨'), selected: true, onPressed: () {}),
          SidebarItem(leading: Icon(LucideIcons.calendar), label: Text('비활성')),
          SidebarItem(
            leading: Icon(LucideIcons.bell),
            label: Text('비활성 선택'),
            selected: true,
            enabled: false,
            onPressed: () {},
          ),
        ],
      ),
      height: 220,
    ),
    _frame(
      Sidebar(
        type: CoreSidebarType.collapsed,
        railItems: [
          SidebarRailItem(icon: Icon(LucideIcons.house), label: '선택됨', selected: true, onPressed: () {}),
          SidebarRailItem(icon: Icon(LucideIcons.inbox), label: '기본 · 점', dot: true, onPressed: () {}),
          SidebarRailItem(icon: Icon(LucideIcons.calendar), label: '비활성'),
        ],
      ),
      height: 220,
    ),
  ],
);

Component _placement() => _frame(
  Component.fragment([
    Sidebar(
      sidebarStyle: page.kSidebarNarrowStyle,
      help: _help(),
      children: [
        for (var index = 1; index <= 10; index++) SidebarItem(label: Text('메뉴 $index'), onPressed: () {}),
      ],
    ),
    div(
      styles: Styles(
        raw: {'flex': '1', 'display': 'flex', 'align-items': 'center', 'justify-content': 'center'},
      ),
      [const Text('화면 내용').bodyMedium.onSurfaceVariant],
    ),
  ]),
  height: 320,
  width: '320px',
);

Component _narrow(List<Component> children) => _frame(
  Sidebar(sidebarStyle: page.kSidebarNarrowStyle, children: children),
  height: 160,
);

Component _choice(String label, IconName icon, {bool selected = false}) =>
    SidebarItem(leading: Icon(icon), label: Text(label), selected: selected, onPressed: () {});

Component _subGroup(CoreSidebarItemLevel level) => SidebarGroup(
  leading: Icon(LucideIcons.folder),
  label: Text(page.kSidebarPreviewGroup),
  children: [
    for (final label in const ['디자인', '웹사이트']) SidebarItem(level: level, label: Text(label), onPressed: () {}),
  ],
);

/// Sidebar 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="sidebar/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`sidebar_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Flutter 의 `Sidebar` 는 높이가 정해진 부모가 필요하므로 모든 미리보기가
/// 높이를 정한 상자에 그린다. 폭이 모자란 칸에서는 상자를 줄여 그린다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'sidebar_page.dart' as page;

/// 속성 → Widget.
///
/// 행은 눌러야 선택이 옮겨 가므로 빌더가 선택을 기억한다 — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _SidebarPreview(props: props);

/// 장면 이름(`sidebar/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
  'sidebar/related-navigation-bar': () => SizedBox(
    width: 192,
    child: NavigationBar(
      mode: CoreNavigationBarMode.bar,
      selectedIndex: 0,
      onSelected: (_) {},
      labelMode: CoreNavigationLabelMode.all,
      items: const [
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.house), label: '홈'),
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.search), label: '검색'),
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.settings), label: '설정'),
      ],
    ),
  ),
  'sidebar/related-kbd': () => const Kbd(keys: page.kSidebarPreviewShortcut),
};

class _SidebarPreview extends StatefulWidget {
  const _SidebarPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_SidebarPreview> createState() => _SidebarPreviewState();
}

class _SidebarPreviewState extends State<_SidebarPreview> {
  String _selectedPage = page.kSidebarPreviewFirstPage;
  String _selectedArea = page.kSidebarPreviewFirstArea;

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
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

/// 높이를 정한 상자 — 사이드바가 이 높이를 채운다. 폭이 모자라면 줄인다.
Widget _frame(Widget child, {required double height}) => FittedBox(
  fit: BoxFit.scaleDown,
  child: SizedBox(height: height, child: child),
);

void _ignore(String id) {}

Widget _sidebar({
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
    railHeader: const Avatar(initials: page.kSidebarPreviewMark),
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
    panelTitle: twoPane ? const Text(page.kSidebarPreviewPanelTitle) : null,
    panelAction: twoPane ? const Icon(LucideIcons.plus) : null,
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
        const SidebarSection(label: Text(page.kSidebarPreviewSection)),
        SidebarGroup(
          leading: const Icon(LucideIcons.folder),
          label: const Text(page.kSidebarPreviewGroup),
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

Widget _workspace() => SidebarHeader(
  leading: const Avatar(initials: page.kSidebarPreviewMark),
  title: const Text(page.kSidebarPreviewWorkspace),
  subtitle: const Text(page.kSidebarPreviewRole),
  trailing: const Icon(LucideIcons.chevronsUpDown),
  onPressed: () {},
);

Widget _search() => SidebarSearch(
  placeholder: page.kSidebarPreviewSearch,
  shortcut: page.kSidebarPreviewShortcut,
  onPressed: () {},
);

Widget _help() => SidebarItem(
  leading: const Icon(LucideIcons.info),
  label: const Text(page.kSidebarPreviewHelp),
  onPressed: () {},
);

Widget _user() => const SidebarHeader(
  variant: CoreSidebarHeaderVariant.card,
  leading: Avatar(initials: page.kSidebarPreviewUserInitials),
  title: Text(page.kSidebarPreviewUser),
  subtitle: Text(page.kSidebarPreviewEmail),
);

Widget _settingsRailItem() => SidebarRailItem(
  icon: const Icon(LucideIcons.settings),
  label: page.kSidebarPreviewSettings,
  onPressed: () {},
);

Widget _anatomy() => _frame(
  Sidebar(
    semanticLabel: page.kSidebarPreviewLabel,
    header: _workspace(),
    search: _search(),
    footer: const Card(
      body: Progress(
        value: page.kSidebarPreviewUsage,
        label: Text(page.kSidebarPreviewUsageLabel),
        valueLabel: Text(page.kSidebarPreviewUsageValue),
      ),
    ),
    help: _help(),
    user: _user(),
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

Widget _anatomyTwoPane() => _frame(
  Sidebar(
    type: CoreSidebarType.twoPane,
    semanticLabel: page.kSidebarPreviewLabel,
    railHeader: const Avatar(initials: page.kSidebarPreviewMark),
    railItems: [
      for (final area in page.kSidebarPreviewAreas)
        SidebarRailItem(
          icon: Icon(area.icon),
          label: area.label,
          selected: area.id == page.kSidebarPreviewFirstArea,
          onPressed: () {},
        ),
    ],
    railFooter: _settingsRailItem(),
    panelTitle: const Text(page.kSidebarPreviewPanelTitle),
    panelAction: const Icon(LucideIcons.plus),
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

Widget _rows() => _frame(
  Sidebar(
    semanticLabel: page.kSidebarPreviewLabel,
    children: [
      SidebarItem(
        leading: const Icon(LucideIcons.inbox),
        label: const Text('받은 편지함'),
        count: const Badge(form: CoreBadgeForm.count, child: Text('3')),
        onPressed: () {},
      ),
      SidebarItem(leading: const Icon(LucideIcons.bell), label: const Text('알림'), dot: true, onPressed: () {}),
      SidebarItem(
        leading: const Icon(LucideIcons.settings),
        label: const Text(page.kSidebarPreviewSettings),
        trailing: const Icon(LucideIcons.chevronRight),
        onPressed: () {},
      ),
      const SidebarSection(label: Text(page.kSidebarPreviewSection), action: Icon(LucideIcons.plus)),
      _subGroup(CoreSidebarItemLevel.nested),
    ],
  ),
  height: 300,
);

Widget _headers() => _frame(
  Sidebar(semanticLabel: page.kSidebarPreviewLabel, header: _workspace(), user: _user()),
  height: 200,
);

Widget _states() => _frame(
  Row(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space24,
    children: [
      Sidebar(
        sidebarStyle: page.kSidebarNarrowStyle,
        children: [
          SidebarItem(leading: const Icon(LucideIcons.house), label: const Text('기본'), onPressed: () {}),
          SidebarItem(
            leading: const Icon(LucideIcons.inbox),
            label: const Text('선택됨'),
            selected: true,
            onPressed: () {},
          ),
          const SidebarItem(leading: Icon(LucideIcons.calendar), label: Text('비활성')),
          SidebarItem(
            leading: const Icon(LucideIcons.bell),
            label: const Text('비활성 선택'),
            selected: true,
            enabled: false,
            onPressed: () {},
          ),
        ],
      ),
      Sidebar(
        type: CoreSidebarType.collapsed,
        railItems: [
          SidebarRailItem(icon: const Icon(LucideIcons.house), label: '선택됨', selected: true, onPressed: () {}),
          SidebarRailItem(icon: const Icon(LucideIcons.inbox), label: '기본 · 점', dot: true, onPressed: () {}),
          const SidebarRailItem(icon: Icon(LucideIcons.calendar), label: '비활성'),
        ],
      ),
    ],
  ),
  height: 220,
);

Widget _placement() => FittedBox(
  fit: BoxFit.scaleDown,
  child: SizedBox(
    width: 320,
    height: 320,
    child: Row(
      children: [
        Sidebar(
          sidebarStyle: page.kSidebarNarrowStyle,
          help: _help(),
          children: [
            for (var index = 1; index <= 10; index++) SidebarItem(label: Text('메뉴 $index'), onPressed: () {}),
          ],
        ),
        Expanded(
          child: Center(child: const Text('화면 내용').bodyMedium.onSurfaceVariant),
        ),
      ],
    ),
  ),
);

Widget _narrow(List<Widget> children) => _frame(
  Sidebar(sidebarStyle: page.kSidebarNarrowStyle, children: children),
  height: 160,
);

Widget _choice(String label, IconName icon, {bool selected = false}) =>
    SidebarItem(leading: Icon(icon), label: Text(label), selected: selected, onPressed: () {});

Widget _subGroup(CoreSidebarItemLevel level) => SidebarGroup(
  leading: const Icon(LucideIcons.folder),
  label: const Text(page.kSidebarPreviewGroup),
  children: [
    for (final label in const ['디자인', '웹사이트']) SidebarItem(level: level, label: Text(label), onPressed: () {}),
  ],
);

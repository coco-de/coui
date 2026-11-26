import 'package:coui_web/coui_web.dart';

class SidebarTwoPaneExample extends StatelessComponent {
  const SidebarTwoPaneExample({super.key});

  @override
  Component build(BuildContext context) {
    // The rail switches between areas; the panel lists the current area.
    return div(classes: 'h-${CoreLayout.scale.layout640}', [
      Sidebar(
        type: CoreSidebarType.twoPane,
        railHeader: Avatar(initials: 'C'),
        railItems: [
          SidebarRailItem(
            icon: Icon(LucideIcons.layoutGrid),
            label: '작업',
            selected: true,
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: Icon(LucideIcons.users),
            label: '팀',
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: Icon(LucideIcons.bell),
            label: '알림',
            dot: true,
            onPressed: () {},
          ),
        ],
        railFooter: SidebarRailItem(
          icon: Icon(LucideIcons.settings),
          label: '설정',
          onPressed: () {},
        ),
        panelTitle: Text('작업 보드'),
        panelAction: Icon(LucideIcons.plus),
        search: SidebarSearch(placeholder: '검색', onPressed: () {}),
        children: [
          SidebarItem(
            leading: Icon(LucideIcons.inbox),
            label: Text('내 작업'),
            selected: true,
            onPressed: () {},
          ),
          SidebarItem(
            leading: Icon(LucideIcons.calendar),
            label: Text('이번 주'),
            onPressed: () {},
          ),
          SidebarSection(label: Text('보드')),
          SidebarItem(
            leading: Icon(LucideIcons.folder),
            label: Text('디자인'),
            onPressed: () {},
          ),
        ],
      ),
    ]);
  }
}

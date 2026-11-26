import 'package:coui_flutter/coui_flutter.dart';

class SidebarTwoPaneExample extends StatelessWidget {
  const SidebarTwoPaneExample({super.key});

  @override
  Widget build(BuildContext context) {
    // The rail switches between areas; the panel lists the current area.
    return SizedBox(
      height: CoreLayout.layout640,
      child: Sidebar(
        type: CoreSidebarType.twoPane,
        railHeader: const Avatar(initials: 'C'),
        railItems: [
          SidebarRailItem(
            icon: const Icon(LucideIcons.layoutGrid),
            label: '작업',
            selected: true,
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: const Icon(LucideIcons.users),
            label: '팀',
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: const Icon(LucideIcons.bell),
            label: '알림',
            dot: true,
            onPressed: () {},
          ),
        ],
        railFooter: SidebarRailItem(
          icon: const Icon(LucideIcons.settings),
          label: '설정',
          onPressed: () {},
        ),
        panelTitle: const Text('작업 보드'),
        panelAction: const Icon(LucideIcons.plus),
        search: SidebarSearch(placeholder: '검색', onPressed: () {}),
        children: [
          SidebarItem(
            leading: const Icon(LucideIcons.inbox),
            label: const Text('내 작업'),
            selected: true,
            onPressed: () {},
          ),
          SidebarItem(
            leading: const Icon(LucideIcons.calendar),
            label: const Text('이번 주'),
            onPressed: () {},
          ),
          const SidebarSection(label: Text('보드')),
          SidebarItem(
            leading: const Icon(LucideIcons.folder),
            label: const Text('디자인'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

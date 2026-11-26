import 'package:coui_flutter/coui_flutter.dart';

class SidebarDefaultExample extends StatelessWidget {
  const SidebarDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    // A standard sidebar — identity, search, the rows, help and the person.
    return SizedBox(
      height: CoreLayout.layout640,
      child: Sidebar(
        semanticLabel: '주 메뉴',
        header: SidebarHeader(
          leading: const Avatar(initials: 'C'),
          title: const Text('나음 병원'),
          subtitle: const Text('본원 · 관리자'),
          trailing: const Icon(LucideIcons.chevronsUpDown),
          onPressed: () {},
        ),
        search: SidebarSearch(
          placeholder: '검색',
          shortcut: const ['⌘', 'K'],
          onPressed: () {},
        ),
        help: SidebarItem(
          leading: const Icon(LucideIcons.lifeBuoy),
          label: const Text('도움말'),
          onPressed: () {},
        ),
        user: const SidebarHeader(
          variant: CoreSidebarHeaderVariant.card,
          leading: Avatar(initials: 'B'),
          title: Text('김하나'),
          subtitle: Text('hana@example.com'),
        ),
        children: [
          SidebarItem(
            leading: const Icon(LucideIcons.house),
            label: const Text('홈'),
            selected: true,
            onPressed: () {},
          ),
          SidebarItem(
            leading: const Icon(LucideIcons.inbox),
            label: const Text('받은 편지함'),
            dot: true,
            onPressed: () {},
          ),
          const SidebarSection(label: Text('업무')),
          SidebarGroup(
            leading: const Icon(LucideIcons.folder),
            label: const Text('프로젝트'),
            children: [
              SidebarItem(
                level: CoreSidebarItemLevel.nested,
                label: const Text('디자인 시스템'),
                onPressed: () {},
              ),
              SidebarItem(
                level: CoreSidebarItemLevel.nested,
                label: const Text('웹사이트'),
                onPressed: () {},
              ),
            ],
          ),
          SidebarItem(
            leading: const Icon(LucideIcons.calendar),
            label: const Text('일정'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

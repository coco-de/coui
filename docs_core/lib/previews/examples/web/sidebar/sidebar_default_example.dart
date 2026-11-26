import 'package:coui_web/coui_web.dart';

class SidebarDefaultExample extends StatelessComponent {
  const SidebarDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // A standard sidebar — identity, search, the rows, help and the person.
    return div(classes: 'h-${CoreLayout.scale.layout640}', [
      Sidebar(
        semanticLabel: '주 메뉴',
        header: SidebarHeader(
          leading: Avatar(initials: 'C'),
          title: Text('나음 병원'),
          subtitle: Text('본원 · 관리자'),
          trailing: Icon(LucideIcons.chevronsUpDown),
          onPressed: () {},
        ),
        search: SidebarSearch(
          placeholder: '검색',
          shortcut: ['⌘', 'K'],
          onPressed: () {},
        ),
        help: SidebarItem(
          leading: Icon(LucideIcons.lifeBuoy),
          label: Text('도움말'),
          onPressed: () {},
        ),
        user: SidebarHeader(
          variant: CoreSidebarHeaderVariant.card,
          leading: Avatar(initials: 'B'),
          title: Text('김하나'),
          subtitle: Text('hana@example.com'),
        ),
        children: [
          SidebarItem(
            leading: Icon(LucideIcons.house),
            label: Text('홈'),
            selected: true,
            onPressed: () {},
          ),
          SidebarItem(
            leading: Icon(LucideIcons.inbox),
            label: Text('받은 편지함'),
            dot: true,
            onPressed: () {},
          ),
          SidebarSection(label: Text('업무')),
          SidebarGroup(
            leading: Icon(LucideIcons.folder),
            label: Text('프로젝트'),
            children: [
              SidebarItem(
                level: CoreSidebarItemLevel.nested,
                label: Text('디자인 시스템'),
                onPressed: () {},
              ),
              SidebarItem(
                level: CoreSidebarItemLevel.nested,
                label: Text('웹사이트'),
                onPressed: () {},
              ),
            ],
          ),
          SidebarItem(
            leading: Icon(LucideIcons.calendar),
            label: Text('일정'),
            onPressed: () {},
          ),
        ],
      ),
    ]);
  }
}

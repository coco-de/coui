/// Returns a Flutter code snippet string for the Sidebar component.
String sidebarCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class SidebarChainExample extends StatelessWidget {
  const SidebarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    // withStyle full-control — a narrower panel on the page's own face.
    return SizedBox(
      height: CoreLayout.layout400,
      child:
          Sidebar(
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
                onPressed: () {},
              ),
            ],
          ).withStyle(
            const CoreSidebarStyle(
              panelWidth: CoreLayout.layout240,
              backgroundColor: CoreColor.token(CoreColors.surface),
            ),
          ),
    );
  }
}''',
    'two-pane' =>
      '''
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
}''',
    'collapsed' =>
      '''
class SidebarCollapsedExample extends StatelessWidget {
  const SidebarCollapsedExample({super.key});

  @override
  Widget build(BuildContext context) {
    // The rail alone — each destination named by its tooltip.
    return SizedBox(
      height: CoreLayout.layout400,
      child: Sidebar(
        type: CoreSidebarType.collapsed,
        railHeader: const Avatar(initials: 'C'),
        railItems: [
          SidebarRailItem(
            icon: const Icon(LucideIcons.house),
            label: '홈',
            selected: true,
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: const Icon(LucideIcons.inbox),
            label: '받은 편지함',
            dot: true,
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: const Icon(LucideIcons.calendar),
            label: '일정',
            onPressed: () {},
          ),
        ],
        railFooter: SidebarRailItem(
          icon: const Icon(LucideIcons.settings),
          label: '설정',
          onPressed: () {},
        ),
      ),
    );
  }
}''',
    _ =>
      '''
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
}''',
  };
}

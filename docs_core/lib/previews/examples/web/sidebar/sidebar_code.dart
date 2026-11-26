/// Returns a Web code snippet string for the Sidebar component.
String sidebarCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class SidebarChainExample extends StatelessComponent {
  const SidebarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    // withStyle full-control — a narrower panel on the page's own face.
    return div(classes: 'h-\${CoreLayout.scale.layout400}', [
      Sidebar(
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
            onPressed: () {},
          ),
        ],
      ).withStyle(
        const CoreSidebarStyle(
          panelWidth: CoreLayout.layout240,
          backgroundColor: CoreColor.token(CoreColors.surface),
        ),
      ),
    ]);
  }
}''',
    'two-pane' =>
      '''
class SidebarTwoPaneExample extends StatelessComponent {
  const SidebarTwoPaneExample({super.key});

  @override
  Component build(BuildContext context) {
    // The rail switches between areas; the panel lists the current area.
    return div(classes: 'h-\${CoreLayout.scale.layout640}', [
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
}''',
    'collapsed' =>
      '''
class SidebarCollapsedExample extends StatelessComponent {
  const SidebarCollapsedExample({super.key});

  @override
  Component build(BuildContext context) {
    // The rail alone — each destination named by its tooltip.
    return div(classes: 'h-\${CoreLayout.scale.layout400}', [
      Sidebar(
        type: CoreSidebarType.collapsed,
        railHeader: Avatar(initials: 'C'),
        railItems: [
          SidebarRailItem(
            icon: Icon(LucideIcons.house),
            label: '홈',
            selected: true,
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: Icon(LucideIcons.inbox),
            label: '받은 편지함',
            dot: true,
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: Icon(LucideIcons.calendar),
            label: '일정',
            onPressed: () {},
          ),
        ],
        railFooter: SidebarRailItem(
          icon: Icon(LucideIcons.settings),
          label: '설정',
          onPressed: () {},
        ),
      ),
    ]);
  }
}''',
    _ =>
      '''
class SidebarDefaultExample extends StatelessComponent {
  const SidebarDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // A standard sidebar — identity, search, the rows, help and the person.
    return div(classes: 'h-\${CoreLayout.scale.layout640}', [
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
}''',
  };
}

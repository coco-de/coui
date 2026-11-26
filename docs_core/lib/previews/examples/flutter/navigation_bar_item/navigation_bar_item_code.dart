/// Returns a Flutter code snippet string for the NavigationBarItem component.
String navigationBarItemCode(String? variant) {
  return switch (variant) {
    'drawer' =>
      '''
class NavigationBarItemDrawerExample extends StatefulWidget {
  const NavigationBarItemDrawerExample({super.key});

  @override
  State<NavigationBarItemDrawerExample> createState() => _NavigationBarItemDrawerExampleState();
}

class _NavigationBarItemDrawerExampleState extends State<NavigationBarItemDrawerExample> {
  int _page = 0;

  void _open(BuildContext context) {
    openDrawer<void>(
      context: context,
      side: CoreDrawerSide.left,
      builder: (drawerContext) {
        void go(int page) {
          setState(() => _page = page);
          closeDrawer<void>(drawerContext);
        }

        return Drawer(
          title: '워크스페이스',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CoreSpace.space2,
            children: [
              NavigationBarItem(
                icon: const Icon(LucideIcons.house),
                label: '홈',
                selected: _page == 0,
                onPressed: () => go(0),
              ),
              NavigationBarItem(
                icon: const Icon(LucideIcons.inbox),
                label: '받은편지함',
                badge: const Badge(
                  form: CoreBadgeForm.count,
                  tone: CoreBadgeTone.info,
                  variant: CoreBadgeVariant.filled,
                  size: CoreComponentSize.xs,
                  child: Text('3'),
                ),
                selected: _page == 1,
                onPressed: () => go(1),
              ),
              NavigationBarItem(
                icon: const Icon(LucideIcons.settings),
                label: '설정',
                selected: _page == 2,
                onPressed: () => go(2),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      leading: const Icon(LucideIcons.menu),
      onPressed: () => _open(context),
      child: const Text('사이드바 열기'),
    );
  }
}''',
    'chain' =>
      '''
class NavigationBarItemChainExample extends StatelessWidget {
  const NavigationBarItemChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CoreLayout.layout240),
      child:
          NavigationBarItem(
            icon: const Icon(LucideIcons.inbox),
            label: '받은편지함',
            selected: true,
            onPressed: () {},
          ).withStyle(
            const CoreNavigationBarStyle(
              selectedBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
              itemRadius: CoreBorderRadius.all(CoreRadiusRole.panel),
            ),
          ),
    );
  }
}''',
    _ =>
      '''
class NavigationBarItemDefaultExample extends StatefulWidget {
  const NavigationBarItemDefaultExample({super.key});

  @override
  State<NavigationBarItemDefaultExample> createState() => _NavigationBarItemDefaultExampleState();
}

class _NavigationBarItemDefaultExampleState extends State<NavigationBarItemDefaultExample> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CoreLayout.layout240),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CoreSpace.space2,
        children: [
          NavigationBarItem(
            icon: const Icon(LucideIcons.inbox),
            label: '받은편지함',
            badge: const Badge(
              form: CoreBadgeForm.count,
              tone: CoreBadgeTone.info,
              variant: CoreBadgeVariant.filled,
              size: CoreComponentSize.xs,
              child: Text('3'),
            ),
            selected: _page == 0,
            onPressed: () => setState(() => _page = 0),
          ),
          NavigationBarItem(
            icon: const Icon(LucideIcons.bell),
            label: '알림',
            selected: _page == 1,
            onPressed: () => setState(() => _page = 1),
          ),
          NavigationBarItem(
            icon: const Icon(LucideIcons.settings),
            label: '설정',
            selected: _page == 2,
            onPressed: () => setState(() => _page = 2),
          ),
          const NavigationBarItem(
            icon: Icon(LucideIcons.lock),
            label: '관리자',
            enabled: false,
          ),
        ],
      ),
    );
  }
}''',
  };
}

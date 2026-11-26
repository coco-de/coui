import 'package:coui_flutter/coui_flutter.dart';

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
}

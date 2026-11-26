import 'package:coui_web/coui_web.dart';

class NavigationBarItemDrawerExample extends StatefulComponent {
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
      builder: (close) {
        void go(int page) {
          setState(() => _page = page);
          close();
        }

        return Drawer(
          title: '워크스페이스',
          content: div(
            [
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
            classes: 'flex flex-col gap-${CoreSpace.scale.space2}',
          ),
        );
      },
    );
  }

  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      leading: const Icon(LucideIcons.menu),
      onPressed: () => _open(context),
      child: const Text('사이드바 열기'),
    );
  }
}

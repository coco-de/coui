import 'package:coui_web/coui_web.dart';

class NavigationBarItemDefaultExample extends StatefulComponent {
  const NavigationBarItemDefaultExample({super.key});

  @override
  State<NavigationBarItemDefaultExample> createState() => _NavigationBarItemDefaultExampleState();
}

class _NavigationBarItemDefaultExampleState extends State<NavigationBarItemDefaultExample> {
  int _page = 0;

  @override
  Component build(BuildContext context) {
    return div(
      [
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
      classes:
          'flex flex-col w-full max-w-${CoreLayout.scale.layout240} '
          'gap-${CoreSpace.scale.space2}',
    );
  }
}

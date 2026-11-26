import 'package:coui_flutter/coui_flutter.dart';

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
}

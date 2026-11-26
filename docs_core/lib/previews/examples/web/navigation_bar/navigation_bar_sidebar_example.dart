import 'package:coui_web/coui_web.dart';

class NavigationBarSidebarExample extends StatefulComponent {
  const NavigationBarSidebarExample({super.key});

  @override
  State<NavigationBarSidebarExample> createState() => _NavigationBarSidebarExampleState();
}

// This example documents `mode: sidebar`, which `Sidebar` replaces; it
// stays (and is announced with the mode) until the mode is removed.
@Deprecated('Use Sidebar (since 0.164) — this shows the announced mode.')
class _NavigationBarSidebarExampleState extends State<NavigationBarSidebarExample> {
  int _selectedIndex = 0;

  @override
  Component build(BuildContext context) {
    return NavigationBar(
      mode: CoreNavigationBarMode.sidebar,
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      items: const [
        CoreNavigationBarItem.label('메인'),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.house),
          label: '대시보드',
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.search),
          label: '탐색',
        ),
        CoreNavigationBarItem.divider(),
        CoreNavigationBarItem.label('계정'),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.bell),
          label: '알림',
          badge: Badge(
            form: CoreBadgeForm.count,
            tone: CoreBadgeTone.info,
            variant: CoreBadgeVariant.filled,
            size: CoreComponentSize.xs,
            child: Text('3'),
          ),
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.settings),
          label: '설정',
        ),
      ],
      footer: const Text('무료 플랜 · 좌석 5개 중 3개 사용').labelMedium.onSurfaceVariant,
    );
  }
}

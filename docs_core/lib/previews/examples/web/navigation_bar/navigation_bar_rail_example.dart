import 'package:coui_web/coui_web.dart';

class NavigationBarRailExample extends StatefulComponent {
  const NavigationBarRailExample({super.key});

  @override
  State<NavigationBarRailExample> createState() => _NavigationBarRailExampleState();
}

class _NavigationBarRailExampleState extends State<NavigationBarRailExample> {
  int _selectedIndex = 0;

  @override
  Component build(BuildContext context) {
    return NavigationBar(
      mode: CoreNavigationBarMode.rail,
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      items: const [
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.house),
          label: '홈',
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.search),
          label: '검색',
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.bell),
          label: '알림',
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.user),
          label: '프로필',
        ),
      ],
    );
  }
}

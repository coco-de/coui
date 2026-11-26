import 'package:coui_flutter/coui_flutter.dart';

class NavigationBarRailExample extends StatefulWidget {
  const NavigationBarRailExample({super.key});

  @override
  State<NavigationBarRailExample> createState() => _NavigationBarRailExampleState();
}

class _NavigationBarRailExampleState extends State<NavigationBarRailExample> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
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

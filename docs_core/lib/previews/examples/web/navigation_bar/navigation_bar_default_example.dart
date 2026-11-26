import 'package:coui_web/coui_web.dart';

class NavigationBarDefaultExample extends StatefulComponent {
  const NavigationBarDefaultExample({super.key});

  @override
  State<NavigationBarDefaultExample> createState() => _NavigationBarDefaultExampleState();
}

class _NavigationBarDefaultExampleState extends State<NavigationBarDefaultExample> {
  int _selectedIndex = 0;

  @override
  Component build(BuildContext context) {
    return NavigationBar(
      mode: CoreNavigationBarMode.bar,
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      labelMode: CoreNavigationLabelMode.all,
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

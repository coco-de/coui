import 'package:coui_flutter/coui_flutter.dart';

class NavigationBarTextTabsExample extends StatefulWidget {
  const NavigationBarTextTabsExample({super.key});

  @override
  State<NavigationBarTextTabsExample> createState() => _NavigationBarTextTabsExampleState();
}

class _NavigationBarTextTabsExampleState extends State<NavigationBarTextTabsExample> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Bare-label tabs: no icons, every label shown, and a dot over the
    // selected one. Every tab keeps the dot's room, so the labels stay level.
    return NavigationBar(
      mode: CoreNavigationBarMode.bar,
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      labelMode: CoreNavigationLabelMode.all,
      selectionMark: CoreNavigationSelectionMark.dot,
      items: const [
        CoreNavigationBarItem.destination(label: '홈'),
        CoreNavigationBarItem.destination(label: '지도'),
        CoreNavigationBarItem.destination(label: '채팅'),
        CoreNavigationBarItem.destination(label: '내 정보'),
      ],
    );
  }
}

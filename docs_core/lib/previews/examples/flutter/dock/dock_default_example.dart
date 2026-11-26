import 'package:coui_flutter/coui_flutter.dart';

class DockDefaultExample extends StatefulWidget {
  const DockDefaultExample({super.key});

  @override
  State<DockDefaultExample> createState() => _DockDefaultExampleState();
}

class _DockDefaultExampleState extends State<DockDefaultExample> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    CoreDockItemData<Widget> item(
      int idx,
      IconName icon,
      String label,
    ) {
      return CoreDockItemData<Widget>(
        icon: Icon(icon),
        label: label,
        isActive: _index == idx,
        onPressed: () => setState(() => _index = idx),
      );
    }

    return Dock(
      items: [
        item(0, LucideIcons.house, '홈'),
        item(1, LucideIcons.search, '검색'),
        item(2, LucideIcons.user, '프로필'),
      ],
    );
  }
}

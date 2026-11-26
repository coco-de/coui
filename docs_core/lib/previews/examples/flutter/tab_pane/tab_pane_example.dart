import 'package:coui_flutter/coui_flutter.dart';

class TabPaneExample extends StatefulWidget {
  const TabPaneExample({super.key});

  @override
  State<TabPaneExample> createState() => _TabPaneExampleState();
}

class _TabPaneExampleState extends State<TabPaneExample> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return TabPane(
      tabs: [
        CoreTabItem(
          label: '계정',
          content: Padding(
            padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
            child: Text('계정 설정을 관리해요.').bodyMedium.onSurfaceVariant,
          ),
        ),
        CoreTabItem(
          label: '비밀번호',
          content: Padding(
            padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
            child: Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant,
          ),
        ),
      ],
      selectedIndex: _index,
      onChanged: (i) => setState(() => _index = i),
    );
  }
}

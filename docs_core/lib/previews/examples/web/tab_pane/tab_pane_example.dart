import 'package:coui_web/coui_web.dart';

class TabPaneExample extends StatefulComponent {
  const TabPaneExample({super.key});

  @override
  State<TabPaneExample> createState() => _TabPaneExampleState();
}

class _TabPaneExampleState extends State<TabPaneExample> {
  int _index = 0;

  @override
  Component build(BuildContext context) {
    return TabPane(
      tabs: [
        CoreTabItem(
          label: '계정',
          content: div(
            [Text('계정 설정을 관리해요.').bodyMedium.onSurfaceVariant],
            classes: 'p-${CoreSpace.scale.space20}',
          ),
        ),
        CoreTabItem(
          label: '비밀번호',
          content: div(
            [Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant],
            classes: 'p-${CoreSpace.scale.space20}',
          ),
        ),
      ],
      selectedIndex: _index,
      onChanged: (index) => setState(() => _index = index),
    );
  }
}

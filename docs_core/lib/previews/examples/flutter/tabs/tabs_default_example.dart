import 'package:coui_flutter/coui_flutter.dart';

class TabsDefaultExample extends StatefulWidget {
  const TabsDefaultExample({super.key});

  @override
  State<TabsDefaultExample> createState() => _TabsDefaultExampleState();
}

class _TabsDefaultExampleState extends State<TabsDefaultExample> {
  static const _contents = [
    '계정 설정을 관리해요.',
    '여기에서 비밀번호를 바꿔요.',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tabs(
          tabs: const [
            CoreTabItem(label: '계정'),
            CoreTabItem(label: '비밀번호'),
          ],
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
        const Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
    );
  }
}

import 'package:coui_flutter/coui_flutter.dart';

class TabsLineExample extends StatefulWidget {
  const TabsLineExample({super.key});

  @override
  State<TabsLineExample> createState() => _TabsLineExampleState();
}

class _TabsLineExampleState extends State<TabsLineExample> {
  static const _contents = [
    '계정 설정을 관리해요.',
    '여기에서 비밀번호를 바꿔요.',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tabs(
          tabs: const [
            CoreTabItem(label: '계정'),
            CoreTabItem(label: '비밀번호'),
          ],
          selectedIndex: _index,
          variant: CoreTabVariant.underline,
          onChanged: (i) => setState(() => _index = i),
        ),
        const Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
    );
  }
}

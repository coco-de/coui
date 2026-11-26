import 'package:coui_web/coui_web.dart';

class TabsLineExample extends StatefulComponent {
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
  Component build(BuildContext context) {
    return div(
      [
        Tabs(
          tabs: const [
            CoreTabItem(label: '계정'),
            CoreTabItem(label: '비밀번호'),
          ],
          selectedIndex: _index,
          variant: CoreTabVariant.underline,
          onChanged: (index) => setState(() => _index = index),
        ),
        Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
      classes: 'flex flex-col items-stretch w-full',
    );
  }
}

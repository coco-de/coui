import 'package:coui_web/coui_web.dart';

class TabsBadgeExample extends StatefulComponent {
  const TabsBadgeExample({super.key});

  @override
  State<TabsBadgeExample> createState() => _TabsBadgeExampleState();
}

class _TabsBadgeExampleState extends State<TabsBadgeExample> {
  static const _contents = [
    '읽지 않은 메시지가 3개 있어요.',
    '아직 보낸 메시지가 없어요.',
    '작성 중인 글은 자동으로 저장돼요.',
  ];

  int _index = 0;

  @override
  Component build(BuildContext context) {
    return div(
      [
        Tabs(
          tabs: [
            CoreTabItem(
              label: '받은편지함',
              badge: Badge(
                variant: CoreBadgeVariant.filled,
                form: CoreBadgeForm.count,
                size: CoreComponentSize.xs,
                child: Text('3'),
              ),
            ),
            const CoreTabItem(label: '보낸편지함'),
            const CoreTabItem(label: '임시보관함'),
          ],
          selectedIndex: _index,
          onChanged: (index) => setState(() => _index = index),
        ),
        Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
      classes: 'flex flex-col items-start',
    );
  }
}

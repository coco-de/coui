import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreTabsStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.surfaceContainer`
/// getter (a direct 1:1 alias for `CoreColors.surfaceContainer`), which
/// is shorter than a second `.withStyle(const CoreTabsStyle(backgroundColor:
/// CoreColor.token(CoreColors.surfaceContainer)))` call.
class TabsChainExample extends StatefulWidget {
  const TabsChainExample({super.key});

  @override
  State<TabsChainExample> createState() => _TabsChainExampleState();
}

class _TabsChainExampleState extends State<TabsChainExample> {
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
            )
            .withStyle(
              const CoreTabsStyle(
                tabPadding: CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space16,
                  vertical: CoreSpace.space8,
                ),
                containerRadius: CoreBorderRadius.all(CoreRadius.radius24),
                tabSpacing: CoreSpace.space8,
              ),
            )
            .surfaceContainer,
        const Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
    );
  }
}

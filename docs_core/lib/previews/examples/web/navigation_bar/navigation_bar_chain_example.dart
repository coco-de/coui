import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreNavigationBarStyle] slot without constructing the
/// widget from scratch — chained with the primitive-token
/// `.surfaceContainer` getter (a direct 1:1 alias for
/// `CoreColors.surfaceContainer`), which is shorter than a second
/// `.withStyle(const CoreNavigationBarStyle(backgroundColor:
/// CoreColor.token(CoreColors.surfaceContainer)))` call.
class NavigationBarChainExample extends StatefulComponent {
  const NavigationBarChainExample({super.key});

  @override
  State<NavigationBarChainExample> createState() => _NavigationBarChainExampleState();
}

class _NavigationBarChainExampleState extends State<NavigationBarChainExample> {
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
        )
        .withStyle(
          const CoreNavigationBarStyle(
            itemSpacing: CoreSpace.space12,
            itemPadding: CoreEdgeInsets.all(CoreSpace.space12),
            itemRadius: CoreBorderRadius.all(CoreRadius.radius16),
          ),
        )
        .surfaceContainer;
  }
}

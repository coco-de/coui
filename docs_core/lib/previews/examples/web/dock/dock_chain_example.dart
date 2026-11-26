import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDockStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.surfaceContainer`
/// getter (a direct 1:1 alias for `CoreColors.surfaceContainer`), which
/// is shorter than a second `.withStyle(const CoreDockStyle(backgroundColor:
/// CoreColor.token(CoreColors.surfaceContainer)))` call.
class DockChainExample extends StatefulComponent {
  const DockChainExample({super.key});

  @override
  State<DockChainExample> createState() => _DockChainExampleState();
}

class _DockChainExampleState extends State<DockChainExample> {
  int _index = 0;

  @override
  Component build(BuildContext context) {
    CoreDockItemData<Component> item(int idx, IconName icon, String label) {
      return CoreDockItemData<Component>(
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
        )
        .withStyle(
          const CoreDockStyle(
            padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space24),
            barRadius: CoreBorderRadius.all(CoreRadius.radius24),
            barMargin: CoreEdgeInsets.all(CoreSpace.space8),
          ),
        )
        .surfaceContainer;
  }
}

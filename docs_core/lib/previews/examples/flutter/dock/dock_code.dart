/// Returns a Flutter code snippet string for the Dock component.
String dockCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class DockChainExample extends StatefulWidget {
  const DockChainExample({super.key});

  @override
  State<DockChainExample> createState() => _DockChainExampleState();
}

class _DockChainExampleState extends State<DockChainExample> {
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
}''',
    _ =>
      '''
class DockDefaultExample extends StatefulWidget {
  const DockDefaultExample({super.key});

  @override
  State<DockDefaultExample> createState() => _DockDefaultExampleState();
}

class _DockDefaultExampleState extends State<DockDefaultExample> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    CoreDockItemData<Widget> item(int idx, IconName icon, String label) {
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
}''',
  };
}

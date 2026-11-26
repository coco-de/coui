/// Returns a Flutter code snippet string for the ContextMenu component.
String contextMenuCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ContextMenuChainExample extends StatelessWidget {
  const ContextMenuChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ContextMenu(
      items: [
        CoreMenuItem.action('복사', onPressed: () {}),
        CoreMenuItem.action('붙여넣기', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('삭제', onPressed: () {}),
      ],
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.theme.colorScheme.outline.toValue(),
            width: CoreStrokeWidth.stroke1,
          ),
          borderRadius: BorderRadius.circular(CoreRadius.radius8),
        ),
        child: Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space24,
            vertical: CoreSpace.space16,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('여기를 오른쪽 클릭해 보세요').bodyMedium,
        ),
      ),
    ).withStyle(
      const CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space12,
            ),
            contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
          ),
          labelTextStyle: CoreTextStyle.token(
            CoreTextStyles.bodyMedium,
            color: CoreColor.token(CoreColors.onSurface),
          ),
          leadingColumnWidth: CoreSize.size24,
        ),
      ),
    );
  }
}''',
    'lift' =>
      '''
class ContextMenuLiftExample extends StatelessWidget {
  const ContextMenuLiftExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ContextMenu(
      liftChild: true,
      haptics: true,
      items: [
        CoreMenuItem.action('열기', onPressed: () {}),
        CoreMenuItem.action('공유', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('삭제', onPressed: () {}),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface.toValue(),
          border: Border.all(
            color: context.theme.colorScheme.outline.toValue(),
            width: CoreStrokeWidth.stroke1,
          ),
          borderRadius: BorderRadius.circular(CoreRadius.radius16),
        ),
        child: Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space24,
            vertical: CoreSpace.space16,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('길게 눌러 보세요').bodyMedium,
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class ContextMenuDefaultExample extends StatelessWidget {
  const ContextMenuDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ContextMenu(
      items: [
        CoreMenuItem.action('복사', onPressed: () {}),
        CoreMenuItem.action('붙여넣기', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('삭제', onPressed: () {}),
      ],
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.theme.colorScheme.outline.toValue(),
            width: CoreStrokeWidth.stroke1,
          ),
          borderRadius: BorderRadius.circular(CoreRadius.radius8),
        ),
        child: Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space24,
            vertical: CoreSpace.space16,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('여기를 오른쪽 클릭해 보세요').bodyMedium,
        ),
      ),
    );
  }
}''',
  };
}

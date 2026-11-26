/// Source snippet for the Flutter `StageContainer` previews.
///
/// Must mirror the corresponding `stage_container_*_example.dart` verbatim
/// (minus imports) so the docs site's "View code" tab stays in sync.
String stageContainerCode(String? variant) => switch (variant) {
  'chain' =>
    '''
class StageContainerChainExample extends StatelessWidget {
  const StageContainerChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StageContainer(
      builder: (context, padding) {
        return Padding(
          padding: padding.toValue(),
          child: Container(
            height: CoreSpace.space80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.toValue(),
              borderRadius: BorderRadius.circular(CoreRadius.radius16),
              border: Border.all(color: theme.colorScheme.outline.toValue()),
            ),
            child: Text(
              '왼쪽: \${padding.left.toStringAsFixed(0)}, '
              '오른쪽: \${padding.right.toStringAsFixed(0)}',
              style: theme.typography.bodyMedium
                  .toValue(theme: theme)
                  .copyWith(
                    color: theme.colorScheme.onSurface.toValue(),
                  ),
            ),
          ),
        );
      },
    ).withStyle(
      const CoreStageContainerStyle(
        breakpoint: CoreConstantStageBreakpoint(CoreSpace.space256),
        padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space32),
      ),
    );
  }
}''',
  _ =>
    '''
class StageContainerDefaultExample extends StatelessWidget {
  const StageContainerDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StageContainer(
      builder: (context, padding) {
        return Padding(
          padding: padding.toValue(),
          child: Container(
            height: CoreSpace.space80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.toValue(),
              borderRadius: BorderRadius.circular(CoreRadius.radius16),
              border: Border.all(color: theme.colorScheme.outline.toValue()),
            ),
            child: Text(
              '왼쪽: \${padding.left.toStringAsFixed(0)}, '
              '오른쪽: \${padding.right.toStringAsFixed(0)}',
              style: theme.typography.bodyMedium.toValue(theme: theme).copyWith(
                color: theme.colorScheme.onSurface.toValue(),
              ),
            ),
          ),
        );
      },
    );
  }
}
''',
};

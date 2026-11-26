/// Source snippet for the Web `StageContainer` previews.
///
/// Must mirror the corresponding `stage_container_*_example.dart` verbatim
/// (minus imports) so the docs site's "View code" tab stays in sync.
String stageContainerCode(String? variant) => switch (variant) {
  'chain' =>
    '''
class StageContainerChainExample extends StatelessComponent {
  const StageContainerChainExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final boxClasses =
        'h-\${CoreSpace.scale.space80} '
        'flex items-center justify-center '
        'bg-\${cs.surfaceContainer} border border-\${cs.outline} '
        'rounded-\${CoreRadius.scale.radius16} '
        'text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurface}';
    return StageContainer(
      builder: (context, padding) {
        return div(
          [
            Text(
              '왼쪽: \${padding.left.toStringAsFixed(0)}, '
              '오른쪽: \${padding.right.toStringAsFixed(0)}',
            ),
          ],
          classes: boxClasses,
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
class StageContainerDefaultExample extends StatelessComponent {
  const StageContainerDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final boxClasses =
        'h-\${CoreSpace.scale.space80} '
        'flex items-center justify-center '
        'bg-\${cs.surfaceContainer} border border-\${cs.outline} '
        'rounded-\${CoreRadius.scale.radius16} '
        'text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurface}';
    return StageContainer(
      builder: (context, padding) {
        return div(
          [
            Text(
              '왼쪽: \${padding.left.toStringAsFixed(0)}, '
              '오른쪽: \${padding.right.toStringAsFixed(0)}',
            ),
          ],
          classes: boxClasses,
        );
      },
    );
  }
}
''',
};

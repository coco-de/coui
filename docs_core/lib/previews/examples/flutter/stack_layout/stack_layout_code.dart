/// Source snippet for the Flutter `StackLayout` default preview.
///
/// Must mirror `stack_layout_default_example.dart` verbatim (minus imports)
/// so the docs site's "View code" tab stays in sync.
String stackLayoutCode(String? variant) => '''
class StackLayoutDefaultExample extends StatelessWidget {
  const StackLayoutDefaultExample({super.key});

  static const _kLabels = ['레이어 1', '레이어 2', '레이어 3'];
  static const _kPerLayerOffset = CoreSpace.space8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalHeight =
        CoreSpace.space80 + (_kLabels.length - 1) * _kPerLayerOffset;
    return SizedBox(
      width: CoreSpace.space160,
      height: totalHeight,
      child: Stacks(
        children: [
          for (var i = 0; i < _kLabels.length; i++)
            Position(
              top: i * _kPerLayerOffset,
              child: Container(
                width: CoreSpace.space160,
                height: CoreSpace.space80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer.toValue(),
                  borderRadius: BorderRadius.circular(CoreRadius.radius16),
                  border: Border.all(color: theme.colorScheme.outline.toValue()),
                ),
                child: Text(
                  _kLabels[i],
                  style: theme.typography.bodyMedium.toValue(theme: theme).copyWith(
                    color: theme.colorScheme.onSurface.toValue(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
''';

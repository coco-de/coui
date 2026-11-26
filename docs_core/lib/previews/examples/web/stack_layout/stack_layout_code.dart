/// Source snippet for the Web `StackLayout` default preview.
///
/// Must mirror `stack_layout_default_example.dart` verbatim (minus imports)
/// so the docs site's "View code" tab stays in sync.
String stackLayoutCode(String? variant) => '''
class StackLayoutDefaultExample extends StatelessComponent {
  const StackLayoutDefaultExample({super.key});

  static const _kLabels = ['레이어 1', '레이어 2', '레이어 3'];
  static const _kPerLayerOffset = CoreSpace.space8;

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final layerClasses =
        'w-\${CoreSpace.scale.space160} h-\${CoreSpace.scale.space80} '
        'flex items-center justify-center '
        'bg-\${cs.surfaceContainer} border border-\${cs.outline} '
        'rounded-\${CoreRadius.scale.radius16} '
        'text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurface}';
    final totalHeight =
        CoreSpace.space80 + (_kLabels.length - 1) * _kPerLayerOffset;
    return div(
      [
        Stacks(
          children: [
            for (var i = 0; i < _kLabels.length; i++)
              Position(
                top: i * _kPerLayerOffset,
                child: div(
                  [Text(_kLabels[i])],
                  classes: layerClasses,
                ),
              ),
          ],
        ),
      ],
      styles: Styles(
        raw: {
          'width': '\${CoreSpace.space160 / 16}rem',
          'height': '\${totalHeight / 16}rem',
        },
      ),
    );
  }
}
''';

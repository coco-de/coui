/// Source snippet for the Web `ScrollableClient` default preview.
///
/// Must mirror `scrollable_client_default_example.dart` verbatim (minus
/// imports) so the docs site's "View code" tab stays in sync.
String scrollableClientCode(String? variant) => '''
class ScrollableClientDefaultExample extends StatelessComponent {
  const ScrollableClientDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return div(
      [
        ScrollableClient(
          diagonalDragBehavior: CoreDiagonalDragBehavior.free,
          builder: (context, offset, viewportSize, child) {
            return div(
              [
                Text(
                  '오프셋: \${offset.dx.toStringAsFixed(1)}, '
                  '\${offset.dy.toStringAsFixed(1)}',
                ),
                Gap.space8(),
                Text(
                  '뷰포트: \${viewportSize.width.toStringAsFixed(0)} × '
                  '\${viewportSize.height.toStringAsFixed(0)}',
                ),
                Gap.space16(),
                Text(
                  '끌거나 스크롤해서 1200 × 560 콘텐츠를 둘러보세요.',
                ),
              ],
              classes:
                  'flex flex-col bg-\${cs.surfaceContainer} text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurface} rounded-\${CoreRadius.scale.radius16} p-\${CoreSpace.scale.space16}',
              styles: Styles(
                raw: const {
                  'width': '\${1200 / 16}rem',
                  'height': '\${560 / 16}rem',
                },
              ),
            );
          },
        ),
      ],
      styles: Styles(
        raw: const {
          'height': '\${320 / 16}rem',
          'width': '100%',
          'min-width': '0',
        },
      ),
    );
  }
}
''';

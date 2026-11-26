/// Source snippet for the Flutter `ScrollableClient` default preview.
///
/// Must mirror `scrollable_client_default_example.dart` verbatim (minus
/// imports) so the docs site's "View code" tab stays in sync.
String scrollableClientCode(String? variant) => '''
class ScrollableClientDefaultExample extends StatelessWidget {
  const ScrollableClientDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 320,
      child: ScrollableClient(
        diagonalDragBehavior: CoreDiagonalDragBehavior.free,
        builder: (context, offset, viewportSize, child) {
          return Container(
            width: 1200,
            height: 560,
            padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: theme.geometry),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.toValue(),
              borderRadius: BorderRadius.circular(CoreRadius.radius16),
            ),
            child: DefaultTextStyle.merge(
              style: theme.typography.bodyMedium.toValue(theme: theme).copyWith(
                color: theme.colorScheme.onSurface.toValue(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '오프셋: \${offset.dx.toStringAsFixed(1)}, '
                    '\${offset.dy.toStringAsFixed(1)}',
                  ),
                  const Gap.space8(),
                  Text(
                    '뷰포트: \${viewportSize.width.toStringAsFixed(0)} × '
                    '\${viewportSize.height.toStringAsFixed(0)}',
                  ),
                  const Gap.space16(),
                  const Text(
                    '끌거나 스크롤해서 1200 × 560 콘텐츠를 둘러보세요.',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
''';

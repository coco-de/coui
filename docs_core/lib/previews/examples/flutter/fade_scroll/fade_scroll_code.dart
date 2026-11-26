/// Returns a Flutter code snippet string for the FadeScroll component.
String fadeScrollCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FadeScrollChainExample extends StatelessWidget {
  const FadeScrollChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CoreSpace.space200,
      child:
          FadeScroll(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 20; i += 1)
                  Padding(
                    padding: const CoreEdgeInsets.symmetric(
                      vertical: CoreSpace.space8,
                      horizontal: CoreSpace.space16,
                    ).toValue(geometry: Theme.of(context).geometry),
                    child: Text('항목 \${i + 1}').bodyMedium.onSurface,
                  ),
              ],
            ),
          ).withStyle(
            const CoreFadeScrollStyle(
              startOffset: CoreSpace.space80,
              endOffset: CoreSpace.space80,
              gradient: [
                CoreColor.token(CoreColors.primary),
                CoreColor.transparent,
              ],
            ),
          ),
    );
  }
}
''',
    'with-scrollbar' =>
      '''
class FadeScrollWithScrollbarExample extends StatelessWidget {
  const FadeScrollWithScrollbarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: FadeScroll(
        showScrollbar: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 20; i += 1)
              Padding(
                padding: const CoreEdgeInsets.symmetric(
                  vertical: CoreSpace.space8,
                  horizontal: CoreSpace.space16,
                ).toValue(geometry: Theme.of(context).geometry),
                child: Text('항목 \${i + 1}').bodyMedium.onSurface,
              ),
          ],
        ),
      ),
    );
  }
}''',
    'horizontal' =>
      '''
class FadeScrollHorizontalExample extends StatelessWidget {
  const FadeScrollHorizontalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FadeScroll(
      direction: .horizontal,
      showScrollbar: true,
      child: Row(
        children: [
          for (var i = 0; i < 20; i += 1)
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space12,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Center(
                child: Text('항목 \${i + 1}').bodyMedium.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}''',
    _ =>
      '''
class FadeScrollDefaultExample extends StatelessWidget {
  const FadeScrollDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: FadeScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 20; i += 1)
              Padding(
                padding: const CoreEdgeInsets.symmetric(
                  vertical: CoreSpace.space8,
                  horizontal: CoreSpace.space16,
                ).toValue(geometry: Theme.of(context).geometry),
                child: Text('항목 \${i + 1}').bodyMedium.onSurface,
              ),
          ],
        ),
      ),
    );
  }
}''',
  };
}

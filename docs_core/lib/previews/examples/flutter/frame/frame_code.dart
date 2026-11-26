/// Returns a Flutter code snippet string for the Frame component.
String frameCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FrameChainExample extends StatelessWidget {
  const FrameChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Frame(
          direction: CoreFrameDirection.row,
          gap: CoreSpace.space12,
          crossAxisAlignment: CoreCrossAxisAlignment.center,
          padding: const CoreEdgeInsets.all(CoreSpace.space16),
          children: const [
            Icon(
              LucideIcons.frame,
              iconStyle: CoreIconStyle(size: CoreSpace.space24),
            ),
            Text('기본 프레임'),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        Frame(
          direction: CoreFrameDirection.row,
          gap: CoreSpace.space12,
          crossAxisAlignment: CoreCrossAxisAlignment.center,
          padding: const CoreEdgeInsets.all(CoreSpace.space16),
          children: const [
            Icon(
              LucideIcons.frame,
              iconStyle: CoreIconStyle(size: CoreSpace.space24),
            ),
            Text('직접 지정'),
          ],
        ).withStyle(
          const CoreFrameStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
    );
  }
}''',
    'column' =>
      '''
class FrameColumnExample extends StatelessWidget {
  const FrameColumnExample({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Frame(
      direction: CoreFrameDirection.column,
      gap: CoreSpace.space8,
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
      backgroundColor: colorScheme.surfaceContainer,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      children: const [
        Text('첫째 행'),
        Text('둘째 행'),
        Text('셋째 행'),
      ],
    );
  }
}''',
    'dashed' =>
      '''
class FrameDashedExample extends StatelessWidget {
  const FrameDashedExample({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Frame(
      direction: CoreFrameDirection.row,
      mainAxisAlignment: CoreMainAxisAlignment.center,
      crossAxisAlignment: CoreCrossAxisAlignment.center,
      padding: const CoreEdgeInsets.all(CoreSpace.space24),
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      borderColor: colorScheme.outline,
      borderWidth: CoreStrokeWidth.stroke2,
      borderStyle: CoreFrameBorderStyle.dashed,
      child: const Text('점선 테두리 프레임'),
    );
  }
}''',
    'elevated' =>
      '''
class FrameElevatedExample extends StatelessWidget {
  const FrameElevatedExample({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Frame(
      direction: CoreFrameDirection.column,
      gap: CoreSpace.space4,
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
      backgroundColor: colorScheme.surface,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      elevation: CoreFrameElevation.medium,
      children: const [
        Text('그림자 프레임'),
        Text('md 그림자를 쓰고 테두리는 없어요.'),
      ],
    );
  }
}''',
    _ =>
      '''
class FrameDefaultExample extends StatelessWidget {
  const FrameDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Frame(
      direction: CoreFrameDirection.row,
      gap: CoreSpace.space12,
      crossAxisAlignment: CoreCrossAxisAlignment.center,
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
      backgroundColor: colorScheme.surfaceContainer,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      borderColor: colorScheme.outlineVariant,
      borderWidth: CoreStrokeWidth.stroke1,
      children: const [
        Icon(LucideIcons.frame, iconStyle: CoreIconStyle(size: CoreSpace.space24)),
        Text('기본 프레임'),
      ],
    );
  }
}''',
  };
}

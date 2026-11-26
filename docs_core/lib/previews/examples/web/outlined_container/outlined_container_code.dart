String outlinedContainerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class OutlinedContainerChainExample extends StatelessComponent {
  const OutlinedContainerChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        OutlinedContainer(
          containerStyle: const CoreOutlinedContainerStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space16),
          ),
          child: Text('테두리 컨테이너').bodyMedium,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        OutlinedContainer(
          child: Text('직접 지정').bodyMedium,
        ).withStyle(
          const CoreOutlinedContainerStyle(
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderWidth: CoreStrokeWidth.stroke2,
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    _ =>
      '''
class OutlinedContainerDefaultExample extends StatelessComponent {
  const OutlinedContainerDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return OutlinedContainer(
      containerStyle: const CoreOutlinedContainerStyle(
        padding: CoreEdgeInsets.all(CoreSpace.space16),
      ),
      child: Text('테두리 컨테이너').bodyMedium,
    );
  }
}''',
  };
}

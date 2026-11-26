/// Returns a Flutter code snippet string for the Card component.
String cardCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class CardChainExample extends StatelessWidget {
  const CardChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Card(
          header: const Text('프로젝트 요약'),
          body: const Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: const Text('자세히 보기'),
          ),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth/padding)까지.
        Card(
          header: const Text('프로젝트 요약'),
          body: const Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: const Text('자세히 보기'),
          ),
        ).withStyle(
          const CoreCardStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space24),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            backgroundColor: CoreColor.token(
              CoreColors.surfaceContainerHighest,
            ),
            borderColor: CoreColor.token(CoreColors.tertiary),
          ),
        ),
      ],
    );
  }
}''',
    'filled' =>
      '''
class CardFilledExample extends StatelessWidget {
  const CardFilledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      variant: CoreCardVariant.filled,
      header: Text('채운 카드'),
      body: Text('서피스 컨테이너 색으로 채운 카드예요.'),
    );
  }
}''',
    'elevated' =>
      '''
class CardElevatedExample extends StatelessWidget {
  const CardElevatedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: CoreCardElevation.medium,
      header: Text('띄운 카드'),
      body: Text('중간 높이의 그림자를 드리운 카드예요.'),
    );
  }
}''',
    _ =>
      '''
class CardDefaultExample extends StatelessWidget {
  const CardDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      header: const Text('프로젝트 요약'),
      body: const Text('이번 주 진행 상황을 확인해 보세요.'),
      footer: Button(
        variant: CoreButtonVariant.primary,
        onPressed: () {},
        child: const Text('자세히 보기'),
      ),
    );
  }
}''',
  };
}

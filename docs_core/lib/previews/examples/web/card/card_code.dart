/// Returns a Web code snippet string for the Card component.
String cardCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class CardChainExample extends StatelessComponent {
  const CardChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Card(
          header: Text('프로젝트 요약'),
          body: Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: Text('자세히 보기'),
          ),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth/padding)까지.
        Card(
          header: Text('프로젝트 요약'),
          body: Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: Text('자세히 보기'),
          ),
        ).withStyle(
          const CoreCardStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space24),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            backgroundColor: .surfaceContainerHighest,
            borderColor: .tertiary,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'filled' =>
      '''
class CardFilledExample extends StatelessComponent {
  const CardFilledExample({super.key});

  @override
  Component build(BuildContext context) {
    return Card(
      variant: CoreCardVariant.filled,
      header: Text('채운 카드'),
      body: Text('서피스 컨테이너 색으로 채운 카드예요.'),
    );
  }
}''',
    'elevated' =>
      '''
class CardElevatedExample extends StatelessComponent {
  const CardElevatedExample({super.key});

  @override
  Component build(BuildContext context) {
    return Card(
      elevation: CoreCardElevation.medium,
      header: Text('띄운 카드'),
      body: Text('중간 높이의 그림자를 드리운 카드예요.'),
    );
  }
}''',
    _ =>
      '''
class CardDefaultExample extends StatelessComponent {
  const CardDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Card(
      header: Text('프로젝트 요약'),
      body: Text('이번 주 진행 상황을 확인해 보세요.'),
      footer: Button(
        variant: CoreButtonVariant.primary,
        onPressed: () {},
        child: Text('자세히 보기'),
      ),
    );
  }
}''',
  };
}

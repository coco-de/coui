/// Returns a Web code snippet string for the Steps component.
String stepsCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class StepsChainExample extends StatelessComponent {
  const StepsChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Steps(
      currentStep: 2,
      items: [
        CoreStepData(
          title: '계정 만들기',
          description: '이메일로 가입해요',
        ),
        CoreStepData(
          title: '이메일 인증',
          description: '받은편지함을 확인해 주세요',
        ),
        CoreStepData(
          title: '프로필 설정',
          description: '정보를 입력해 주세요',
        ),
        CoreStepData(
          title: '완료',
          description: '시작할 준비가 됐어요',
        ),
      ],
    ).withStyle(
      const CoreStepsStyle(
        indicatorSize: CoreSize.size40,
        activeIndicatorColor: CoreColor.token(CoreColors.primary),
        connectorThickness: CoreStrokeWidth.stroke4,
        indicatorContentGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}''',
    'horizontal' =>
      '''
class StepsHorizontalExample extends StatelessComponent {
  const StepsHorizontalExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Steps(
      currentStep: 1,
      vertical: false,
      items: [
        CoreStepData(title: '장바구니'),
        CoreStepData(title: '배송'),
        CoreStepData(title: '결제'),
        CoreStepData(title: '확인'),
      ],
    );
  }
}''',
    'list' =>
      '''
class StepsListExample extends StatelessComponent {
  const StepsListExample({super.key});

  @override
  Component build(BuildContext context) {
    // 목록은 자기 폭을 정하지 않는다 — 호스트가 정한다. 프리뷰에서는
    // 폭 상한(`layout280`)을 부모가 대신 준다.
    return div(
      [
        const Steps(
          variant: CoreStepsVariant.list,
          currentStep: 1,
          items: [
            CoreStepData(title: '의존성 설치', trailing: '12초'),
            CoreStepData(title: '테스트 실행', trailing: '41초'),
            CoreStepData(
              title: '린트',
              status: CoreStepStatus.failed,
              trailing: 'exit 1',
            ),
            CoreStepData(title: '배포', trailing: '대기 중'),
          ],
        ),
      ],
      classes: 'w-\${CoreLayout.scale.layout280}',
    );
  }
}''',
    _ =>
      '''
class StepsDefaultExample extends StatelessComponent {
  const StepsDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Steps(
      currentStep: 2,
      items: [
        CoreStepData(
          title: '계정 만들기',
          description: '이메일로 가입해요',
        ),
        CoreStepData(
          title: '이메일 인증',
          description: '받은편지함을 확인해 주세요',
        ),
        CoreStepData(
          title: '프로필 설정',
          description: '정보를 입력해 주세요',
        ),
        CoreStepData(
          title: '완료',
          description: '시작할 준비가 됐어요',
        ),
      ],
    );
  }
}''',
  };
}

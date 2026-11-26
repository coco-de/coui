/// Returns a Flutter code snippet string for the StepItem component.
String stepItemCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class StepItemChainExample extends StatelessWidget {
  const StepItemChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreLayout.layout280,
      child:
          const StepItem(
            title: '테스트 실행',
            status: CoreStepStatus.current,
            trailing: '41초',
          ).withStyle(
            const CoreStepItemStyle(
              padding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space10),
              iconTitleGapStyle: CoreGapStyle(size: CoreSpace.space16),
              titleStyle: CoreTextStyle(
                color: CoreColor.token(CoreColors.primary),
              ),
            ),
          ),
    );
  }
}''',
    _ =>
      '''
class StepItemDefaultExample extends StatelessWidget {
  const StepItemDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 행은 자기 폭을 정하지 않는다 — 호스트가 정한다. 프리뷰에서는
    // 폭 상한(`layout280`)을 부모가 대신 준다.
    return SizedBox(
      width: CoreLayout.layout280,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: const [
          StepItem(
            title: '의존성 설치',
            status: CoreStepStatus.done,
            trailing: '12초',
          ),
          StepItem(
            title: '테스트 실행',
            status: CoreStepStatus.current,
            trailing: '41초',
          ),
          StepItem(title: '배포', trailing: '대기 중'),
          StepItem(
            title: '린트',
            status: CoreStepStatus.failed,
            trailing: 'exit 1',
          ),
        ],
      ),
    );
  }
}''',
  };
}

import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreStepsStyle] slot without constructing the widget
/// from scratch. The patch enlarges and recolours the active indicator,
/// thickens the connector and widens the indicator-to-content gap.
class StepsChainExample extends StatelessWidget {
  const StepsChainExample({super.key});

  @override
  Widget build(BuildContext context) {
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
}

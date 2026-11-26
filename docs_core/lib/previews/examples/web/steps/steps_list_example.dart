import 'package:coui_web/coui_web.dart';

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
      classes: 'w-${CoreLayout.scale.layout280}',
    );
  }
}

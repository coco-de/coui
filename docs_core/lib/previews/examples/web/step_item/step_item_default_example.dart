import 'package:coui_web/coui_web.dart';

class StepItemDefaultExample extends StatelessComponent {
  const StepItemDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // 행은 자기 폭을 정하지 않는다 — 호스트가 정한다. 프리뷰에서는
    // 폭 상한(`layout280`)을 부모가 대신 준다.
    return div(
      [
        const StepItem(
          title: '의존성 설치',
          status: CoreStepStatus.done,
          trailing: '12초',
        ),
        const StepItem(
          title: '테스트 실행',
          status: CoreStepStatus.current,
          trailing: '41초',
        ),
        const StepItem(title: '배포', trailing: '대기 중'),
        const StepItem(
          title: '린트',
          status: CoreStepStatus.failed,
          trailing: 'exit 1',
        ),
      ],
      classes: 'w-${CoreLayout.scale.layout280}',
    );
  }
}

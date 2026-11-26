import 'package:coui_flutter/coui_flutter.dart';

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
}

import 'package:coui_web/coui_web.dart';

class StepperDisabledExample extends StatelessComponent {
  const StepperDisabledExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Stepper(
      currentStep: 1,
      enabled: false,
      steps: [
        CoreStepItem(label: '계정', description: '계정 만들기'),
        CoreStepItem(label: '프로필', description: '프로필 설정'),
        CoreStepItem(label: '완료', description: '모두 끝났어요'),
      ],
    );
  }
}

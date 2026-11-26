import 'package:coui_web/coui_web.dart';

class StepperDefaultExample extends StatefulComponent {
  const StepperDefaultExample({super.key});

  @override
  State<StepperDefaultExample> createState() => _StepperDefaultExampleState();
}

class _StepperDefaultExampleState extends State<StepperDefaultExample> {
  int _currentStep = 1;

  void handleStepChanged(int index) {
    setState(() {
      _currentStep = index;
    });
  }

  @override
  Component build(BuildContext context) {
    return Stepper(
      currentStep: _currentStep,
      onStepChanged: handleStepChanged,
      steps: const [
        CoreStepItem(label: '계정', description: '계정 만들기'),
        CoreStepItem(label: '프로필', description: '프로필 설정'),
        CoreStepItem(label: '완료', description: '모두 끝났어요'),
      ],
    );
  }
}

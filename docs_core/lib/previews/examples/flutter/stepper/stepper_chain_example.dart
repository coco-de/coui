import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreStepperStyle] slot without constructing the widget
/// from scratch. The patch enlarges and recolours the active indicator,
/// thickens the connector and widens the indicator-to-label gap.
class StepperChainExample extends StatefulWidget {
  const StepperChainExample({super.key});

  @override
  State<StepperChainExample> createState() => _StepperChainExampleState();
}

class _StepperChainExampleState extends State<StepperChainExample> {
  int _currentStep = 1;

  void handleStepChanged(int index) {
    setState(() {
      _currentStep = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stepper(
      currentStep: _currentStep,
      onStepChanged: handleStepChanged,
      steps: const [
        CoreStepItem(label: '계정', description: '계정 만들기'),
        CoreStepItem(label: '프로필', description: '프로필 설정'),
        CoreStepItem(label: '완료', description: '모두 끝났어요'),
      ],
    ).withStyle(
      const CoreStepperStyle(
        indicatorActiveColor: CoreColor.token(CoreColors.primary),
        indicatorSize: CoreSize.size40,
        connectorThickness: CoreStrokeWidth.stroke6,
        indicatorContentGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}

/// Returns a Web code snippet string for the Stepper component.
String stepperCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class StepperChainExample extends StatefulComponent {
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
  Component build(BuildContext context) {
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
}''',
    'disabled' =>
      '''
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
''',
    'vertical' =>
      '''
class StepperVerticalExample extends StatefulComponent {
  const StepperVerticalExample({super.key});

  @override
  State<StepperVerticalExample> createState() => _StepperVerticalExampleState();
}

class _StepperVerticalExampleState extends State<StepperVerticalExample> {
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
      orientation: CoreStepperOrientation.vertical,
      onStepChanged: handleStepChanged,
      steps: const [
        CoreStepItem(label: '계정', description: '계정 만들기'),
        CoreStepItem(label: '프로필', description: '프로필 설정'),
        CoreStepItem(label: '완료', description: '모두 끝났어요'),
      ],
    );
  }
}''',
    _ =>
      '''
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
}''',
  };
}

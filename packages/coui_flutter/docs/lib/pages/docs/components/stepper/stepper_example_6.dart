import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';

class StepperExample6 extends StatefulWidget {
  const StepperExample6({super.key});

  @override
  State<StepperExample6> createState() => _StepperExample6State();
}

class _StepperExample6State extends State<StepperExample6> {
  static const List<StepVariant> _variants = [
    StepVariant.circle,
    StepVariant.circleAlt,
    StepVariant.line,
  ];
  static const List<String> _variantNames = ['Circle', 'Circle Alt', 'Line'];
  static const List<StepSize> _stepSize = StepSize.values;
  static const List<String> _stepSizeNames = ['Small', 'Medium', 'Large'];
  final StepperController controller = StepperController();
  int _currentVariant = 0;
  int _currentStepSize = 0;
  Axis direction = Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runAlignment: WrapAlignment.center,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Toggle(
              onChanged: (value) {
                if (value) {
                  setState(() {
                    direction = Axis.horizontal;
                  });
                } else {
                  setState(() {
                    direction = Axis.vertical;
                  });
                }
              },
              trailing: const Text('Horizontal'),
              value: direction == Axis.horizontal,
            ),
            Toggle(
              onChanged: (value) {
                if (value) {
                  setState(() {
                    direction = Axis.vertical;
                  });
                } else {
                  setState(() {
                    direction = Axis.horizontal;
                  });
                }
              },
              trailing: const Text('Vertical'),
              value: direction == Axis.vertical,
            ),
            const VerticalDivider().sized(height: 16),
            for (var i = 0; i < _variants.length; i++)
              Toggle(
                onChanged: (value) {
                  setState(() {
                    _currentVariant = i;
                  });
                },
                trailing: Text(_variantNames[i]),
                value: _currentVariant == i,
              ),
            const VerticalDivider().sized(height: 16),
            for (var i = 0; i < _stepSize.length; i++)
              Toggle(
                onChanged: (value) {
                  setState(() {
                    _currentStepSize = i;
                  });
                },
                trailing: Text(_stepSizeNames[i]),
                value: _currentStepSize == i,
              ),
            const VerticalDivider().sized(height: 16),
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Toggle(
                  onChanged: (value) {
                    if (value) {
                      controller.setStatus(1, StepState.failed);
                    } else {
                      controller.setStatus(1, null);
                    }
                  },
                  trailing: const Text('Toggle Error'),
                  value: controller.value.stepStates[1] == StepState.failed,
                );
              },
            ),
          ],
        ),
        const Gap(16),
        Stepper(
          controller: controller,
          direction: direction,
          size: _stepSize[_currentStepSize],
          steps: [
            Step(
              contentBuilder: (context) {
                return StepContainer(
                  actions: [
                    const SecondaryButton(child: Text('Prev')),
                    PrimaryButton(
                      child: const Text('Next'),
                      onPressed: () {
                        controller.nextStep();
                      },
                    ),
                  ],
                  child: const NumberedContainer(index: 1, height: 200),
                );
              },
              title: const Text('Step 1'),
            ),
            Step(
              contentBuilder: (context) {
                return StepContainer(
                  actions: [
                    SecondaryButton(
                      child: const Text('Prev'),
                      onPressed: () {
                        controller.previousStep();
                      },
                    ),
                    PrimaryButton(
                      child: const Text('Next'),
                      onPressed: () {
                        controller.nextStep();
                      },
                    ),
                  ],
                  child: const NumberedContainer(index: 2, height: 200),
                );
              },
              title: const StepTitle(
                subtitle: Text('Optional Step'),
                title: Text('Step 2'),
              ),
            ),
            Step(
              contentBuilder: (context) {
                return StepContainer(
                  actions: [
                    SecondaryButton(
                      child: const Text('Prev'),
                      onPressed: () {
                        controller.previousStep();
                      },
                    ),
                    PrimaryButton(
                      child: const Text('Finish'),
                      onPressed: () {
                        controller.nextStep();
                      },
                    ),
                  ],
                  child: const NumberedContainer(index: 3, height: 200),
                );
              },
              title: const Text('Step 3'),
            ),
          ],
          variant: _variants[_currentVariant],
        ),
      ],
    );
  }
}

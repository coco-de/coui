import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';

class StepperExample3 extends StatefulWidget {
  const StepperExample3({super.key});

  @override
  State<StepperExample3> createState() => _StepperExample3State();
}

class _StepperExample3State extends State<StepperExample3> {
  final StepperController controller = StepperController(
    currentStep: 1,
    stepStates: {1: StepState.failed},
  );

  @override
  Widget build(BuildContext context) {
    return Stepper(
      controller: controller,
      direction: Axis.horizontal,
      steps: [
        Step(
          contentBuilder: (context) {
            return const StepContainer(
              actions: [
                SecondaryButton(child: Text('Prev')),
                PrimaryButton(child: Text('Next')),
              ],
              child: NumberedContainer(index: 1, height: 200),
            );
          },
          title: const Text('Step 1'),
        ),
        Step(
          contentBuilder: (context) {
            return const StepContainer(
              actions: [
                SecondaryButton(child: Text('Prev')),
                PrimaryButton(child: Text('Next')),
              ],
              child: NumberedContainer(index: 2, height: 200),
            );
          },
          title: const Text('Step 2'),
        ),
        Step(
          contentBuilder: (context) {
            return const StepContainer(
              actions: [
                SecondaryButton(child: Text('Prev')),
                PrimaryButton(child: Text('Finish')),
              ],
              child: NumberedContainer(index: 3, height: 200),
            );
          },
          title: const Text('Step 3'),
        ),
      ],
    );
  }
}

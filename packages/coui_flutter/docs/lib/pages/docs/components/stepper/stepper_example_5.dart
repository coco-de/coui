import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';

class StepperExample5 extends StatefulWidget {
  const StepperExample5({super.key});

  @override
  State<StepperExample5> createState() => _StepperExample5State();
}

class _StepperExample5State extends State<StepperExample5> {
  final StepperController controller = StepperController();

  @override
  Widget build(BuildContext context) {
    return Stepper(
      controller: controller,
      direction: Axis.horizontal,
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
          icon: const StepNumber(icon: Icon(Icons.person)),
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
          icon: const StepNumber(icon: Icon(Icons.house_outlined)),
          title: const Text('Step 2'),
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
          icon: const StepNumber(icon: Icon(Icons.work_outline)),
          title: const Text('Step 3'),
        ),
      ],
    );
  }
}

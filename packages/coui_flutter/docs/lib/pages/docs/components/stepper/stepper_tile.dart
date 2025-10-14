import 'package:docs/pages/docs/components_page.dart';
import 'package:docs/pages/docs/components/stepper/stepper_example_2.dart';
import 'package:coui_flutter/coui_flutter.dart';

class StepperTile extends StatelessWidget implements IComponentPage {
  const StepperTile({super.key});

  @override
  String get title => 'Stepper';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'stepper',
      title: 'Stepper',
      example: const StepperExample2().sized(height: 500, width: 400),
      scale: 1,
    );
  }
}

import 'package:coui_flutter/coui_flutter.dart';

class StepsExample1 extends StatelessWidget {
  const StepsExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return const Steps(
      children: [
        StepItem(
          content: [
            Text('Create a new project in the project manager.'),
            Text('Add the required files to the project.'),
          ],
          title: Text('Create a project'),
        ),
        StepItem(
          content: [Text('Add the required dependencies to the project.')],
          title: Text('Add dependencies'),
        ),
        StepItem(
          content: [Text('Run the project in the project manager.')],
          title: Text('Run the project'),
        ),
      ],
    );
  }
}

import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class StepsTile extends StatelessWidget implements IComponentPage {
  const StepsTile({super.key});

  @override
  String get title => 'Steps';

  @override
  Widget build(BuildContext context) {
    return const ComponentCard(
      name: 'steps',
      title: 'Steps',
      example: Card(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Steps(
          children: [
            StepItem(
              content: [Text('Create a new flutter project')],
              title: Text('Create a project'),
            ),
            StepItem(
              content: [Text('Add dependencies to pubspec.yaml')],
              title: Text('Add dependencies'),
            ),
            StepItem(
              content: [Text('Run the project using flutter run')],
              title: Text('Run the project'),
            ),
          ],
        ),
      ),
    );
  }
}

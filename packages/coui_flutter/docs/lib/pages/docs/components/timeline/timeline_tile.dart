import 'package:docs/pages/docs/components_page.dart';
import 'package:docs/pages/docs/components/timeline/timeline_example_1.dart';
import 'package:coui_flutter/coui_flutter.dart';

class TimelineTile extends StatelessWidget implements IComponentPage {
  const TimelineTile({super.key});

  @override
  String get title => 'Timeline';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'timeline',
      title: 'Timeline',
      example: const TimelineExample1().sized(height: 800, width: 700),
      scale: 1,
    );
  }
}

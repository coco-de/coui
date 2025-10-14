import 'package:docs/pages/docs/components_page.dart';
import 'package:docs/pages/docs/components/tracker/tracker_example_1.dart';
import 'package:coui_flutter/coui_flutter.dart';

class TrackerTile extends StatelessWidget implements IComponentPage {
  const TrackerTile({super.key});

  @override
  String get title => 'Tracker';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'tracker',
      title: 'Tracker',
      example: const TrackerExample1().sized(width: 500),
      verticalOffset: 48,
      scale: 2,
    );
  }
}

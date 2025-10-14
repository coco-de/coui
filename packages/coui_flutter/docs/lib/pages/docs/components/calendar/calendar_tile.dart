import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class CalendarTile extends StatelessWidget implements IComponentPage {
  const CalendarTile({super.key});

  @override
  String get title => 'Calendar';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'calendar',
      title: 'Calendar',
      example: Calendar(
        selectionMode: CalendarSelectionMode.none,
        view: CalendarView.now(),
      ),
      scale: 1,
    );
  }
}

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class TimePickerTile extends StatelessWidget implements IComponentPage {
  const TimePickerTile({super.key});

  @override
  String get title => 'Time Picker';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'time_picker',
      title: 'Time Picker',
      example: Card(
        child: TimePickerDialog(
          initialValue: TimeOfDay.now(),
          use24HourFormat: true,
        ).withAlign(Alignment.topLeft),
      ).sized(height: 300),
      scale: 1.2,
    );
  }
}

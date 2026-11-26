import 'package:coui_flutter/coui_flutter.dart';

class CalendarNoneExample extends StatefulWidget {
  const CalendarNoneExample({super.key});

  @override
  State<CalendarNoneExample> createState() => _CalendarNoneExampleState();
}

class _CalendarNoneExampleState extends State<CalendarNoneExample> {
  @override
  Widget build(BuildContext context) {
    return Calendar(
      selectionMode: CoreCalendarSelectionMode.none,
    );
  }
}

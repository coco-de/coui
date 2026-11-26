import 'package:coui_web/coui_web.dart';

class CalendarNoneExample extends StatefulComponent {
  const CalendarNoneExample({super.key});

  @override
  State<CalendarNoneExample> createState() => _CalendarNoneExampleState();
}

class _CalendarNoneExampleState extends State<CalendarNoneExample> {
  @override
  Component build(BuildContext context) {
    return Calendar(
      selectionMode: CoreCalendarSelectionMode.none,
    );
  }
}

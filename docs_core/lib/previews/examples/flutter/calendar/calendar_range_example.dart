import 'package:coui_flutter/coui_flutter.dart';

class CalendarRangeExample extends StatefulWidget {
  const CalendarRangeExample({super.key});

  @override
  State<CalendarRangeExample> createState() => _CalendarRangeExampleState();
}

class _CalendarRangeExampleState extends State<CalendarRangeExample> {
  @override
  Widget build(BuildContext context) {
    return const Calendar.range();
  }
}

import 'package:coui_web/coui_web.dart';

class CalendarRangeExample extends StatefulComponent {
  const CalendarRangeExample({super.key});

  @override
  State<CalendarRangeExample> createState() => _CalendarRangeExampleState();
}

class _CalendarRangeExampleState extends State<CalendarRangeExample> {
  @override
  Component build(BuildContext context) {
    return Calendar.range();
  }
}

import 'package:coui_flutter/coui_flutter.dart';

class CalendarMultiExample extends StatefulWidget {
  const CalendarMultiExample({super.key});

  @override
  State<CalendarMultiExample> createState() => _CalendarMultiExampleState();
}

class _CalendarMultiExampleState extends State<CalendarMultiExample> {
  @override
  Widget build(BuildContext context) {
    return Calendar.multi();
  }
}

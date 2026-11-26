import 'package:coui_flutter/coui_flutter.dart';

class CalendarDefaultExample extends StatefulWidget {
  const CalendarDefaultExample({super.key});

  @override
  State<CalendarDefaultExample> createState() => _CalendarDefaultExampleState();
}

class _CalendarDefaultExampleState extends State<CalendarDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return Calendar.single();
  }
}

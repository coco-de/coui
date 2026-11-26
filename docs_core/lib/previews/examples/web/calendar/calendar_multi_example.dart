import 'package:coui_web/coui_web.dart';

class CalendarMultiExample extends StatefulComponent {
  const CalendarMultiExample({super.key});

  @override
  State<CalendarMultiExample> createState() => _CalendarMultiExampleState();
}

class _CalendarMultiExampleState extends State<CalendarMultiExample> {
  @override
  Component build(BuildContext context) {
    return Calendar.multi();
  }
}

import 'package:coui_web/coui_web.dart';

class CalendarDefaultExample extends StatefulComponent {
  const CalendarDefaultExample({super.key});

  @override
  State<CalendarDefaultExample> createState() => _CalendarDefaultExampleState();
}

class _CalendarDefaultExampleState extends State<CalendarDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Calendar.single();
  }
}

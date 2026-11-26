import 'package:coui_web/coui_web.dart';

class CalendarMarkersExample extends StatelessComponent {
  const CalendarMarkersExample({super.key});

  static CoreCalendarMarker? _markerFor(DateTime date) =>
      date.day % 5 == 0 ? CoreCalendarMarker(count: date.day ~/ 5) : null;

  @override
  Component build(BuildContext context) {
    return const Calendar.range(markerBuilder: _markerFor);
  }
}

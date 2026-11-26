import 'package:coui_flutter/coui_flutter.dart';

class CalendarMarkersExample extends StatelessWidget {
  const CalendarMarkersExample({super.key});

  static CoreCalendarMarker? _markerFor(DateTime date) =>
      date.day % 5 == 0 ? CoreCalendarMarker(count: date.day ~/ 5) : null;

  @override
  Widget build(BuildContext context) {
    return const Calendar.range(markerBuilder: _markerFor);
  }
}

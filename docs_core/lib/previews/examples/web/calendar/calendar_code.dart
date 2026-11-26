/// Returns a Web code snippet string for the Calendar component.
String calendarCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class CalendarChainExample extends StatelessComponent {
  const CalendarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Calendar.single().withStyle(
      const CoreCalendarStyle(
        dayCellSize: CoreSpace.space40,
        cellSpacing: CoreSpace.space12,
        endpointPillBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        headerTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}''',
    'markers' =>
      '''
class CalendarMarkersExample extends StatelessComponent {
  const CalendarMarkersExample({super.key});

  static CoreCalendarMarker? _markerFor(DateTime date) =>
      date.day % 5 == 0 ? CoreCalendarMarker(count: date.day ~/ 5) : null;

  @override
  Component build(BuildContext context) {
    return const Calendar.range(markerBuilder: _markerFor);
  }
}''',
    'range' =>
      '''
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
}''',
    'multi' =>
      '''
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
}''',
    'none' =>
      '''
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
}''',
    _ =>
      '''
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
}''',
  };
}

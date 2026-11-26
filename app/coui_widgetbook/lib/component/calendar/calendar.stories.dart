import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'calendar.stories.g.dart';

/// Interactive demo host for [Calendar] stories.
///
/// Owns the selected [CoreCalendarValue] so the calendar responds to
/// taps inside the preview.
class CalendarDemo extends StatefulWidget {
  /// Creates a [CalendarDemo].
  const CalendarDemo({
    super.key,
    this.selectionMode = CoreCalendarSelectionMode.range,
    this.showMarkers = false,
  });

  /// Date selection mode of the hosted [Calendar].
  final CoreCalendarSelectionMode selectionMode;

  /// Whether the hosted [Calendar] draws date markers — a dot per item on
  /// every fifth day, with the count growing across the month.
  final bool showMarkers;

  @override
  State<CalendarDemo> createState() => _CalendarDemoState();
}

class _CalendarDemoState extends State<CalendarDemo> {
  CoreCalendarValue? _value;

  @override
  void didUpdateWidget(CalendarDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectionMode != widget.selectionMode) {
      _value = null;
    }
  }

  void handleChanged(CoreCalendarValue? value) {
    setState(() => _value = value);
  }

  static CoreCalendarMarker? _markerFor(DateTime date) =>
      date.day % 5 == 0 ? CoreCalendarMarker(count: date.day ~/ 5) : null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        child: Calendar(
          onChanged: handleChanged,
          selectionMode: widget.selectionMode,
          value: _value,
          markerBuilder: widget.showMarkers ? _markerFor : null,
        ),
      ),
    );
  }
}

/// Navigation metadata for the Calendar component.
const kComponentMeta = ComponentMeta(name: 'Calendar', path: 'display');

/// Story metadata for [CalendarDemo].
const kMeta = Meta(CalendarDemo.new);

/// Range-selection calendar with editable knobs.
final $Default = _Story();

/// Single-date selection calendar.
final $Single = _Story(
  args: _Args(
    selectionMode: EnumArg(
      CoreCalendarSelectionMode.single,
      values: CoreCalendarSelectionMode.values,
    ),
  ),
);

/// Multi-date selection calendar.
final $Multi = _Story(
  args: _Args(
    selectionMode: EnumArg(
      CoreCalendarSelectionMode.multi,
      values: CoreCalendarSelectionMode.values,
    ),
  ),
);

/// Range calendar with date markers — the check-in / check-out span keeps
/// each date's dots, and a selected endpoint repaints them for contrast.
final $Markers = _Story(
  args: _Args(showMarkers: BoolArg(true)),
);

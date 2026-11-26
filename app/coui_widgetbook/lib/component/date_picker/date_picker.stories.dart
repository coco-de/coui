import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'date_picker.stories.g.dart';

/// Interactive demo host for [DatePicker] / [DateRangePicker] stories.
///
/// Keeps the picked value in local state. The single-date picker
/// disables future dates via `stateBuilder`; enabling [range] swaps
/// in a [DateRangePicker] instead.
class DatePickerDemo extends StatefulWidget {
  /// Creates a [DatePickerDemo].
  const DatePickerDemo({
    super.key,
    this.mode = CorePromptMode.popover,
    this.range = false,
  });

  /// Overlay mode for the picker prompt (popover / dialog).
  final CorePromptMode mode;

  /// Whether a [DateRangePicker] is shown instead of a [DatePicker].
  final bool range;

  @override
  State<DatePickerDemo> createState() => _DatePickerDemoState();
}

class _DatePickerDemoState extends State<DatePickerDemo> {
  DateTime? _date;
  DateTimeRange? _dateRange;

  void handleDateChanged(DateTime? value) {
    setState(() {
      _date = value;
    });
  }

  void handleRangeChanged(DateTimeRange? value) {
    setState(() {
      _dateRange = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.range
        ? DateRangePicker(
            onChanged: handleRangeChanged,
            value: _dateRange,
            mode: widget.mode,
          )
        : DatePicker(
            onChanged: handleDateChanged,
            mode: widget.mode,
            value: _date,
            stateBuilder: (date) => date.isAfter(DateTime.now())
                ? CoreCalendarDateState.disabled
                : CoreCalendarDateState.enabled,
          );
  }
}

/// Navigation metadata for the DatePicker component.
const kComponentMeta = ComponentMeta(name: 'DatePicker', path: 'form');

/// Story metadata for [DatePickerDemo].
const kMeta = Meta(DatePickerDemo.new);

/// Single-date picker (future dates disabled) in popover mode.
final $Default = _Story();

/// Date-range picker in dialog mode.
final $Range = _Story(
  args: _Args(
    mode: EnumArg(CorePromptMode.dialog, values: CorePromptMode.values),
    range: BoolArg(true),
  ),
);

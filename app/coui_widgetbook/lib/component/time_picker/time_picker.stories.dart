import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'time_picker.stories.g.dart';

/// Interactive demo host for [TimePicker] stories.
///
/// Owns the selected time value so picking commits visibly.
class TimePickerDemo extends StatefulWidget {
  /// Creates a [TimePickerDemo].
  const TimePickerDemo({
    super.key,
    this.enabled = true,
    this.use24HourFormat = true,
    this.showSeconds = false,
    this.mode = CorePromptMode.dialog,
  });

  /// Whether the picker accepts input.
  final bool enabled;

  /// Whether the 24-hour format is used.
  final bool use24HourFormat;

  /// Whether a seconds segment is shown.
  final bool showSeconds;

  /// How the picker overlay is presented.
  final CorePromptMode mode;

  @override
  State<TimePickerDemo> createState() => _TimePickerDemoState();
}

class _TimePickerDemoState extends State<TimePickerDemo> {
  String? _value = '14:30';

  @override
  Widget build(BuildContext context) {
    return TimePicker(
      onChanged: (value) => setState(() => _value = value),
      value: _value,
      enabled: widget.enabled,
      showSeconds: widget.showSeconds,
      use24HourFormat: widget.use24HourFormat,
      mode: widget.mode,
    );
  }
}

/// Navigation metadata for the TimePicker component.
const kComponentMeta = ComponentMeta(name: 'TimePicker', path: 'form');

/// Story metadata for [TimePickerDemo].
const kMeta = Meta(TimePickerDemo.new);

/// Time picker with format, seconds and mode knobs.
final $Default = _Story();

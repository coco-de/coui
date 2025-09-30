import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

class TimePickerTheme {
  const TimePickerTheme({
    this.dialogTitle,
    this.mode,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverPadding,
    this.showSeconds,
    this.use24HourFormat,
  });

  final PromptMode? mode;
  final AlignmentGeometry? popoverAlignment;
  final AlignmentGeometry? popoverAnchorAlignment;
  final EdgeInsetsGeometry? popoverPadding;
  final bool? use24HourFormat;
  final bool? showSeconds;

  final Widget? dialogTitle;

  TimePickerTheme copyWith({
    ValueGetter<Widget?>? dialogTitle,
    ValueGetter<PromptMode?>? mode,
    ValueGetter<AlignmentGeometry?>? popoverAlignment,
    ValueGetter<AlignmentGeometry?>? popoverAnchorAlignment,
    ValueGetter<EdgeInsetsGeometry?>? popoverPadding,
    ValueGetter<bool?>? showSeconds,
    ValueGetter<bool?>? use24HourFormat,
  }) {
    return TimePickerTheme(
      dialogTitle: dialogTitle == null ? this.dialogTitle : dialogTitle(),
      mode: mode == null ? this.mode : mode(),
      popoverAlignment: popoverAlignment == null
          ? this.popoverAlignment
          : popoverAlignment(),
      popoverAnchorAlignment: popoverAnchorAlignment == null
          ? this.popoverAnchorAlignment
          : popoverAnchorAlignment(),
      popoverPadding: popoverPadding == null
          ? this.popoverPadding
          : popoverPadding(),
      showSeconds: showSeconds == null ? this.showSeconds : showSeconds(),
      use24HourFormat: use24HourFormat == null
          ? this.use24HourFormat
          : use24HourFormat(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimePickerTheme &&
        other.mode == mode &&
        other.popoverAlignment == popoverAlignment &&
        other.popoverAnchorAlignment == popoverAnchorAlignment &&
        other.popoverPadding == popoverPadding &&
        other.use24HourFormat == use24HourFormat &&
        other.showSeconds == showSeconds &&
        other.dialogTitle == dialogTitle;
  }

  @override
  int get hashCode => Object.hash(
    mode,
    popoverAlignment,
    popoverAnchorAlignment,
    popoverPadding,
    use24HourFormat,
    showSeconds,
    dialogTitle,
  );
}

/// A controller for managing [ControlledTimePicker] values programmatically.
///
/// This controller extends [ValueNotifier<TimeOfDay?>] to provide reactive
/// state management for time picker components. It implements [ComponentController]
/// to integrate with the controlled component system, allowing external control
/// and listening to time selection changes.
///
/// Example:
/// ```dart
/// final controller = TimePickerController(TimeOfDay(hour: 12, minute: 30));
/// controller.addListener(() {
///   print('Selected time: ${controller.value}');
/// });
/// ```
class TimePickerController extends ValueNotifier<TimeOfDay?>
    with ComponentController<TimeOfDay?> {
  /// Creates a [TimePickerController] with an optional initial value.
  ///
  /// Parameters:
  /// - [value] (TimeOfDay?, optional): Initial time value for the controller
  TimePickerController([super.value]);
}

/// A controlled time picker widget for selecting time values with external state management.
///
/// This widget provides a time selection interface that can be controlled either through
/// a [TimePickerController] or through direct property values. It supports multiple
/// presentation modes (dialog or popover), customizable time formats (12-hour/24-hour),
/// and optional seconds display.
///
/// The time picker integrates with the controlled component system, making it suitable
/// for form integration, validation, and programmatic control. It presents the selected
/// time in a readable format and opens an interactive time selection interface when activated.
///
/// Example:
/// ```dart
/// ControlledTimePicker(
///   initialValue: TimeOfDay(hour: 9, minute: 30),
///   use24HourFormat: true,
///   showSeconds: false,
///   placeholder: Text('Select meeting time'),
///   onChanged: (time) {
///     print('Selected time: ${time?.format(context)}');
///   },
/// );
/// ```
class ControlledTimePicker extends StatelessWidget
    with ControlledComponent<TimeOfDay?> {
  /// Creates a [ControlledTimePicker].
  ///
  /// Either [controller] or [initialValue] should be provided to establish
  /// the initial time state. The picker can be customized with various
  /// presentation options and time format preferences.
  ///
  /// Parameters:
  /// - [controller] (TimePickerController?, optional): External controller for programmatic control
  /// - [initialValue] (TimeOfDay?, optional): Initial time when no controller is provided
  /// - [onChanged] (ValueChanged<TimeOfDay?>?, optional): Callback for time selection changes
  /// - [enabled] (bool, default: true): Whether the picker accepts user interaction
  /// - [mode] (PromptMode, default: PromptMode.dialog): Presentation style (dialog or popover)
  /// - [placeholder] (Widget?, optional): Content displayed when no time is selected
  /// - [popoverAlignment] (AlignmentGeometry?, optional): Popover positioning relative to anchor
  /// - [popoverAnchorAlignment] (AlignmentGeometry?, optional): Anchor point on picker button
  /// - [popoverPadding] (EdgeInsetsGeometry?, optional): Internal popover content padding
  /// - [use24HourFormat] (bool?, optional): Whether to use 24-hour time format
  /// - [showSeconds] (bool, default: false): Whether to include seconds selection
  /// - [dialogTitle] (Widget?, optional): Title for dialog mode display
  ///
  /// Example:
  /// ```dart
  /// ControlledTimePicker(
  ///   initialValue: TimeOfDay(hour: 14, minute: 30),
  ///   mode: PromptMode.popover,
  ///   use24HourFormat: true,
  ///   onChanged: (time) => print('Selected: $time'),
  /// );
  /// ```
  const ControlledTimePicker({
    this.controller,
    this.dialogTitle,
    this.enabled = true,
    this.initialValue,
    super.key,
    this.mode = PromptMode.dialog,
    this.onChanged,
    this.placeholder,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverPadding,
    this.showSeconds = false,
    this.use24HourFormat,
  });

  @override
  final TimeOfDay? initialValue;
  @override
  final ValueChanged<TimeOfDay?>? onChanged;
  @override
  final bool enabled;

  @override
  final TimePickerController? controller;

  /// The presentation mode for the time picker interface.
  ///
  /// Determines how the time selection interface is displayed to the user.
  /// Can be either dialog mode (modal popup) or popover mode (dropdown).
  final PromptMode mode;

  /// Widget displayed when no time is selected.
  ///
  /// This placeholder appears in the picker button when [initialValue] is null
  /// and no time has been selected yet. If null, a default placeholder is used.
  final Widget? placeholder;

  /// Alignment for the popover relative to its anchor widget.
  ///
  /// Used only when [mode] is [PromptMode.popover]. Controls where the popover
  /// appears relative to the picker button.
  final AlignmentGeometry? popoverAlignment;

  /// Alignment of the anchor point on the picker button.
  ///
  /// Used only when [mode] is [PromptMode.popover]. Determines which point
  /// on the picker button the popover aligns to.
  final AlignmentGeometry? popoverAnchorAlignment;

  /// Internal padding for the popover content.
  ///
  /// Used only when [mode] is [PromptMode.popover]. Controls spacing inside
  /// the popover container around the time picker interface.
  final EdgeInsetsGeometry? popoverPadding;

  /// Whether to use 24-hour format for time display and input.
  ///
  /// When true, times are displayed in 24-hour format (00:00-23:59).
  /// When false or null, uses the system default format preference.
  final bool? use24HourFormat;

  /// Whether to include seconds in the time selection.
  ///
  /// When true, the time picker allows selection of seconds in addition
  /// to hours and minutes. When false, only hours and minutes are selectable.
  final bool showSeconds;

  /// Optional title widget for the dialog mode.
  ///
  /// Used only when [mode] is [PromptMode.dialog]. Displayed at the top
  /// of the modal time picker dialog.
  final Widget? dialogTitle;

  @override
  Widget build(BuildContext context) {
    return ControlledComponentAdapter(
      builder: (context, data) {
        return TimePicker(
          dialogTitle: dialogTitle,
          enabled: data.enabled,
          mode: mode,
          onChanged: data.onChanged,
          placeholder: placeholder,
          popoverAlignment: popoverAlignment,
          popoverAnchorAlignment: popoverAnchorAlignment,
          popoverPadding: popoverPadding,
          showSeconds: showSeconds,
          use24HourFormat: use24HourFormat,
          value: data.value,
        );
      },
      controller: controller,
      enabled: enabled,
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}

class TimePicker extends StatelessWidget {
  const TimePicker({
    this.dialogTitle,
    this.enabled,
    super.key,
    this.mode = PromptMode.dialog,
    this.onChanged,
    this.placeholder,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverPadding,
    this.showSeconds = false,
    this.use24HourFormat,
    required this.value,
  });

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?>? onChanged;
  final PromptMode mode;
  final Widget? placeholder;
  final AlignmentGeometry? popoverAlignment;
  final AlignmentGeometry? popoverAnchorAlignment;
  final EdgeInsetsGeometry? popoverPadding;
  final bool? use24HourFormat;
  final bool showSeconds;
  final Widget? dialogTitle;

  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final compTheme = ComponentTheme.maybeOf<TimePickerTheme>(context);
    final use24HourFormat =
        this.use24HourFormat ??
        compTheme?.use24HourFormat ??
        MediaQuery.of(context).alwaysUse24HourFormat;
    final showSeconds = compTheme?.showSeconds ?? this.showSeconds;

    return ObjectFormField(
      builder: (context, value) {
        return Text(
          localizations.formatTimeOfDay(
            value,
            showSeconds: showSeconds,
            use24HourFormat: use24HourFormat,
          ),
        );
      },
      dialogTitle: dialogTitle ?? compTheme?.dialogTitle,
      editorBuilder: (context, handler) {
        return TimePickerDialog(
          initialValue: handler.value,
          onChanged: (value) {
            handler.value = value;
          },
          showSeconds: showSeconds,
          use24HourFormat: use24HourFormat,
        );
      },
      enabled: enabled,
      mode: compTheme?.mode ?? mode,
      onChanged: onChanged,
      placeholder: placeholder ?? Text(localizations.placeholderTimePicker),
      popoverAlignment: popoverAlignment ?? compTheme?.popoverAlignment,
      popoverAnchorAlignment:
          popoverAnchorAlignment ?? compTheme?.popoverAnchorAlignment,
      popoverPadding: popoverPadding ?? compTheme?.popoverPadding,
      trailing: const Icon(Icons.access_time),
      value: value,
    );
  }
}

class TimePickerDialog extends StatefulWidget {
  const TimePickerDialog({
    this.initialValue,
    super.key,
    this.onChanged,
    this.showSeconds = false,
    required this.use24HourFormat,
  });

  final TimeOfDay? initialValue;
  final ValueChanged<TimeOfDay?>? onChanged;
  final bool use24HourFormat;

  final bool showSeconds;

  @override
  State<TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<TimePickerDialog> {
  TextEditingController _hourController;
  TextEditingController _minuteController;
  TextEditingController _secondController;
  bool _pm;

  static String _formatDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  static Widget _buildInput(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: theme.scaling * 72,
        minWidth: theme.scaling * 72,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: TextField(
              controller: controller,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                const _TimeFormatter(),
              ],
              style: theme.typography.x4Large,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
          Positioned(
            bottom: (-24) * theme.scaling,
            child: Text(label).muted(),
          ),
        ],
      ),
    );
  }

  static Widget _buildSeparator(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return const Text(':').x5Large().withPadding(horizontal: scaling * 8);
  }

  @override
  void initState() {
    super.initState();
    _pm = (widget.initialValue?.hour ?? 0) >= 12;
    int initialHour = widget.initialValue?.hour ?? 0;
    final initialMinute = widget.initialValue?.minute ?? 0;
    final initialSecond = widget.initialValue?.second ?? 0;
    if (!widget.use24HourFormat && initialHour > 12 && initialHour <= 23) {
      initialHour -= 12;
      _pm = true;
    }
    _hourController = TextEditingController(
      text: _formatDigits(initialHour),
    );
    _minuteController = TextEditingController(
      text: _formatDigits(initialMinute),
    );
    _secondController = TextEditingController(
      text: _formatDigits(initialSecond),
    );
    _hourController.addListener(_onChanged);
    _minuteController.addListener(_onChanged);
    _secondController.addListener(_onChanged);
  }

  void _onChanged() {
    int hour = int.tryParse(_hourController.text) ?? 0;
    int minute = int.tryParse(_minuteController.text) ?? 0;
    int second = int.tryParse(_secondController.text) ?? 0;
    if (widget.use24HourFormat) {
      hour = hour.clamp(0, 23);
      minute = minute.clamp(0, 59);
      second = second.clamp(0, 59);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.onChanged?.call(
          TimeOfDay(hour: hour, minute: minute, second: second),
        );
      });
    } else {
      if (_pm && hour < 12) {
        hour += 12;
      } else if (!_pm && hour == 12) {
        hour = 0;
      }
      hour = hour.clamp(0, 23);
      minute = minute.clamp(0, 59);
      second = second.clamp(0, 59);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (!mounted) return;
        widget.onChanged?.call(
          TimeOfDay(hour: hour, minute: minute, second: second),
        );
      });
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final localizations = CoUILocalizations.of(context);

    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: Padding(
          padding: EdgeInsets.only(bottom: (16 + 12) * scaling),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: _buildInput(
                  context,
                  _hourController,
                  localizations.timeHour,
                ),
              ),
              _buildSeparator(context),
              Expanded(
                child: _buildInput(
                  context,
                  _minuteController,
                  localizations.timeMinute,
                ),
              ),
              if (widget.showSeconds) ...[
                _buildSeparator(context),
                Expanded(
                  child: _buildInput(
                    context,
                    _secondController,
                    localizations.timeSecond,
                  ),
                ),
              ],
              if (!widget.use24HourFormat) ...[
                Gap(scaling * 8),
                IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Toggle(
                          onChanged: (value) {
                            setState(() {
                              _pm = !value;
                              _onChanged();
                            });
                          },
                          value: !_pm,
                          child: Text(localizations.timeAM),
                        ),
                      ),
                      Expanded(
                        child: Toggle(
                          onChanged: (value) {
                            setState(() {
                              _pm = value;
                              _onChanged();
                            });
                          },
                          value: _pm,
                          child: Text(localizations.timePM),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeFormatter extends TextInputFormatter {
  const _TimeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue newValue,
    TextEditingValue oldValue,
  ) {
    String newText = newValue.text;
    int substringCount = 0;
    if (newText.length > 2) {
      substringCount = newText.length - 2;
      newText = newText.substring(substringCount);
    }
    final padLength = 2 - newText.length;
    int baseOffset2 = newValue.selection.baseOffset;
    int extentOffset2 = newValue.selection.extentOffset;
    if (padLength > 0) {
      newText = newText.padLeft(2, '0');
      baseOffset2 += padLength;
      extentOffset2 += padLength;
    }

    return newValue.copyWith(
      composing: newValue.composing.isValid
          ? TextRange(
              end: newValue.composing.end.clamp(0, 2),
              start: newValue.composing.start.clamp(0, 2),
            )
          : newValue.composing,
      selection: TextSelection(
        baseOffset: baseOffset2.clamp(0, 2),
        extentOffset: extentOffset2.clamp(0, 2),
      ),
      text: newText,
    );
  }
}

class DurationPickerController extends ValueNotifier<Duration?>
    with ComponentController<Duration?> {
  DurationPickerController(super.value);
}

enum DurationPart {
  day,
  hour,
  minute,
  second,
}

enum TimePart {
  hour,
  minute,
  second,
}

class DurationPicker extends StatelessWidget {
  const DurationPicker({
    this.dialogTitle,
    this.enabled,
    super.key,
    this.mode = PromptMode.dialog,
    this.onChanged,
    this.placeholder,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverPadding,
    required this.value,
  });

  final Duration? value;
  final ValueChanged<Duration?>? onChanged;
  final PromptMode mode;
  final Widget? placeholder;
  final AlignmentGeometry? popoverAlignment;
  final AlignmentGeometry? popoverAnchorAlignment;
  final EdgeInsetsGeometry? popoverPadding;
  final Widget? dialogTitle;

  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);

    return ObjectFormField(
      builder: (context, value) {
        return Text(localizations.formatDuration(value));
      },
      dialogTitle: dialogTitle,
      editorBuilder: (context, handler) {
        return DurationPickerDialog(
          initialValue: handler.value,
          onChanged: (value) {
            handler.value = value;
          },
        );
      },
      enabled: enabled,
      mode: mode,
      onChanged: onChanged,
      placeholder: placeholder ?? Text(localizations.placeholderDurationPicker),
      trailing: const Icon(Icons.access_time),
      value: value,
    );
  }
}

class DurationPickerDialog extends StatefulWidget {
  const DurationPickerDialog({this.initialValue, super.key, this.onChanged});

  final Duration? initialValue;

  final ValueChanged<Duration?>? onChanged;

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  TextEditingController _dayController;
  TextEditingController _hourController;
  TextEditingController _minuteController;
  TextEditingController _secondController;

  static String _formatDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  static Widget _buildInput(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: theme.scaling * 72,
        minWidth: theme.scaling * 72,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: TextField(
              controller: controller,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                const _TimeFormatter(),
              ],
              style: theme.typography.x4Large,
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            bottom: (-24) * theme.scaling,
            child: Text(label).muted(),
          ),
        ],
      ),
    );
  }

  static Widget _buildSeparator(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return const Text(':').x5Large().withPadding(horizontal: scaling * 8);
  }

  @override
  void initState() {
    super.initState();
    final initialDay = widget.initialValue?.inDays ?? 0;
    final initialHour = widget.initialValue?.inHours ?? 0;
    final initialMinute = widget.initialValue?.inMinutes ?? 0;
    final initialSecond = widget.initialValue?.inSeconds ?? 0;
    _dayController = TextEditingController(text: _formatDigits(initialDay));
    _hourController = TextEditingController(
      text: _formatDigits(initialHour % Duration.hoursPerDay),
    );
    _minuteController = TextEditingController(
      text: _formatDigits(initialMinute % Duration.minutesPerHour),
    );
    _secondController = TextEditingController(
      text: _formatDigits(initialSecond % Duration.secondsPerMinute),
    );
    _dayController.addListener(_onChanged);
    _hourController.addListener(_onChanged);
    _minuteController.addListener(_onChanged);
    _secondController.addListener(_onChanged);
  }

  void _onChanged() {
    int day = int.tryParse(_dayController.text) ?? 0;
    int hour = int.tryParse(_hourController.text) ?? 0;
    int minute = int.tryParse(_minuteController.text) ?? 0;
    int second = int.tryParse(_secondController.text) ?? 0;
    day = day.clamp(0, 999);
    hour = hour.clamp(0, 23);
    minute = minute.clamp(0, 59);
    second = second.clamp(0, 59);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.onChanged?.call(
        Duration(
          days: day,
          hours: hour,
          minutes: minute,
          seconds: second,
        ),
      );
    });
  }

  @override
  void dispose() {
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final localizations = CoUILocalizations.of(context);

    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: Padding(
          padding: EdgeInsets.only(bottom: (16 + 12) * scaling),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: _buildInput(
                  context,
                  _dayController,
                  localizations.durationDay,
                ),
              ),
              _buildSeparator(context),
              Expanded(
                child: _buildInput(
                  context,
                  _hourController,
                  localizations.durationHour,
                ),
              ),
              _buildSeparator(context),
              Expanded(
                child: _buildInput(
                  context,
                  _minuteController,
                  localizations.durationMinute,
                ),
              ),
              _buildSeparator(context),
              Expanded(
                child: _buildInput(
                  context,
                  _secondController,
                  localizations.durationSecond,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimeRange {
  const TimeRange({
    required this.end,
    required this.start,
  });

  final TimeOfDay start;

  final TimeOfDay end;

  TimeRange copyWith({
    ValueGetter<TimeOfDay>? end,
    ValueGetter<TimeOfDay>? start,
  }) {
    return TimeRange(
      end: end == null ? this.end : end(),
      start: start == null ? this.start : start(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  String toString() {
    return 'TimeRange{start: $start, end: $end}';
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

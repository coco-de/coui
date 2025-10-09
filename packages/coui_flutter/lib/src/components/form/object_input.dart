import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Reactive date input field with integrated date picker and text editing.
///
/// A high-level date input widget that combines text field functionality with
/// date picker integration. Provides automatic state management through the
/// controlled component pattern with support for both dialog and popover modes.
///
/// ## Features
///
/// - **Dual input modes**: Text field editing with date picker integration
/// - **Multiple presentation modes**: Dialog or popover-based date selection
/// - **Flexible date formatting**: Customizable date part ordering and separators
/// - **Calendar integration**: Rich calendar interface with multiple view types
/// - **Form integration**: Automatic validation and form field registration
/// - **Accessibility**: Full screen reader and keyboard navigation support
///
/// ## Usage Patterns
///
/// **Controller-based (recommended for complex state):**
/// ```dart
/// final controller = DatePickerController(DateTime.now());
///
/// DateInput(
///   controller: controller,
///   mode: PromptMode.popover,
///   placeholder: Text('Select date'),
/// )
/// ```
///
/// **Callback-based (simple state management):**
/// ```dart
/// DateTime? selectedDate;
///
/// DateInput(
///   initialValue: selectedDate,
///   onChanged: (date) => setState(() => selectedDate = date),
///   mode: PromptMode.dialog,
///   dialogTitle: Text('Choose Date'),
/// )
/// ```
class DateInput extends StatefulWidget with ControlledComponent<DateTime?> {
  /// Creates a [DateInput].
  ///
  /// Either [controller] or [onChanged] should be provided for interactivity.
  /// The widget supports both controller-based and callback-based state management
  /// patterns with flexible date picker integration options.
  ///
  /// Parameters:
  /// - [controller] (DatePickerController?, optional): external state controller
  /// - [initialValue] (DateTime?, optional): starting date when no controller
  /// - [onChanged] (ValueChanged<DateTime?>?, optional): date change callback
  /// - [enabled] (bool, default: true): whether input is interactive
  /// - [placeholder] (Widget?, optional): widget shown when no date selected
  /// - [mode] (PromptMode, default: dialog): date picker presentation mode
  /// - [initialView] (CalendarView?, optional): starting calendar view
  /// - [popoverAlignment] (AlignmentGeometry?, optional): popover alignment
  /// - [popoverAnchorAlignment] (AlignmentGeometry?, optional): anchor alignment
  /// - [popoverPadding] (EdgeInsetsGeometry?, optional): popover padding
  /// - [dialogTitle] (Widget?, optional): title for dialog mode
  /// - [initialViewType] (CalendarViewType?, optional): calendar view type
  /// - [stateBuilder] (DateStateBuilder?, optional): custom date state builder
  /// - [datePartsOrder] (List<DatePart>?, optional): order of date components
  /// - [separator] (InputPart?, optional): separator between date parts
  /// - [placeholders] (Map<DatePart, Widget>?, optional): placeholders for date parts
  ///
  /// Example:
  /// ```dart
  /// DateInput(
  ///   controller: controller,
  ///   mode: PromptMode.popover,
  ///   placeholder: Text('Select date'),
  ///   datePartsOrder: [DatePart.month, DatePart.day, DatePart.year],
  /// )
  /// ```
  const DateInput({
    this.controller,
    this.datePartsOrder,
    this.enabled = true,
    this.initialValue,
    this.initialView,
    this.initialViewType,
    super.key,
    this.onChanged,
    this.placeholders,
    this.stateBuilder,
  });

  @override
  final DateTime? initialValue;
  @override
  final ValueChanged<DateTime?>? onChanged;
  @override
  final bool enabled;

  @override
  final DatePickerController? controller;
  final CalendarView? initialView;
  final CalendarViewType? initialViewType;
  final DateStateBuilder? stateBuilder;
  final List<DatePart>? datePartsOrder;
  final Map<DatePart, Widget>? placeholders;

  @override
  State<DateInput> createState() => _DateInputState();
}

class NullableDate {
  const NullableDate({this.day, this.month, this.year});

  final int? year;
  final int? month;
  final int? day;

  @override
  String toString() {
    return 'NullableDate{year: $year, month: $month, day: $day}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NullableDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  DateTime get date {
    return DateTime(year ?? 0, month ?? 0, day ?? 0);
  }

  DateTime? get nullableDate {
    return year == null || month == null || day == null ? null : date;
  }
}

class _DateInputState extends State<DateInput> {
  late ComponentController<NullableDate> _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller == null
        ? ComponentValueController<NullableDate>(
            _convertToNullableDate(widget.initialValue),
          )
        : ConvertedController<DateTime?, NullableDate>(
            BiDirectionalConvert(
              _convertToNullableDate,
              _convertFromNullableDate,
            ),
            widget.controller!,
          );
  }

  NullableDate _convertToDateTime(List<String?> values) {
    final parts = <DatePart, String?>{};
    final datePartsOrder =
        widget.datePartsOrder ?? CoUILocalizations.of(context).datePartsOrder;
    for (int i = 0; i < values.length; i += 1) {
      parts[datePartsOrder[i]] = values[i];
    }
    final yearString = parts[DatePart.year];
    final monthString = parts[DatePart.month];
    final dayString = parts[DatePart.day];
    final year = yearString == null || yearString.isEmpty
        ? null
        : int.tryParse(yearString);
    final month = monthString == null || monthString.isEmpty
        ? null
        : int.tryParse(monthString);
    final day = dayString == null || dayString.isEmpty
        ? null
        : int.tryParse(dayString);

    return NullableDate(day: day, month: month, year: year);
  }

  List<String?> _convertFromDateTime(NullableDate? value) {
    final datePartsOrder =
        widget.datePartsOrder ?? CoUILocalizations.of(context).datePartsOrder;
    if (value == null) {
      return datePartsOrder.map((part) => null).toList();
    }
    final validDateTime = value.nullableDate;

    return validDateTime == null
        ? datePartsOrder.map((part) => null).toList()
        : datePartsOrder.map((part) {
            switch (part) {
              case DatePart.year:
                return validDateTime.year.toString();

              case DatePart.month:
                return validDateTime.month.toString();

              case DatePart.day:
                return validDateTime.day.toString();
            }
          }).toList();
  }

  double _getWidth(DatePart part) {
    switch (part) {
      case DatePart.year:
        return 60;

      case DatePart.month:
        return 40;

      case DatePart.day:
        return 40;
    }
  }

  Widget _getPlaceholder(DatePart part) {
    final localizations = CoUILocalizations.of(context);

    return Text(localizations.getDatePartAbbreviation(part));
  }

  int _getLength(DatePart part) {
    switch (part) {
      case DatePart.year:
        return 4;

      case DatePart.month:
        return 2;

      case DatePart.day:
        return 2;
    }
  }

  NullableDate _convertToNullableDate(DateTime? value) {
    return value == null
        ? const NullableDate()
        : NullableDate(day: value.day, month: value.month, year: value.year);
  }

  DateTime? _convertFromNullableDate(NullableDate value) {
    return value.nullableDate;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final datePartsOrder =
        widget.datePartsOrder ?? CoUILocalizations.of(context).datePartsOrder;

    return FormattedObjectInput<NullableDate>(
      controller: _controller,
      converter: BiDirectionalConvert(_convertFromDateTime, _convertToDateTime),
      initialValue: _convertToNullableDate(widget.initialValue),
      onChanged: (value) {
        widget.onChanged?.call(
          value == null ? null : _convertFromNullableDate(value),
        );
      },
      parts: datePartsOrder
          .map((part) {
            return InputPart.editable(
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              length: _getLength(part),
              placeholder: widget.placeholders?[part] ?? _getPlaceholder(part),
              width: _getWidth(part),
            );
          })
          .joinSeparator(const InputPart.static('/'))
          .toList(),
      popoverIcon: const Icon(LucideIcons.calendarDays),
      popupBuilder: (context, controller) {
        return SurfaceCard(
          child: DatePickerDialog(
            initialValue: controller.value == null
                ? null
                : CalendarValue.single(controller.value!.date),
            initialView: widget.initialView ?? CalendarView.now(),
            initialViewType: widget.initialViewType ?? CalendarViewType.date,
            onChanged: (value) {
              final date = value?.toSingle().date;
              controller.value = NullableDate(
                day: date?.day,
                month: date?.month,
                year: date?.year,
              );
            },
            selectionMode: CalendarSelectionMode.single,
            stateBuilder: widget.stateBuilder,
          ),
        );
      },
    );
  }
}

class NullableTimeOfDay {
  const NullableTimeOfDay({this.hour, this.minute, this.second});

  final int? hour;
  final int? minute;

  final int? second;

  @override
  String toString() {
    return 'NullableTimeOfDay{hour: $hour, minute: $minute, second: $second}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NullableTimeOfDay &&
        other.hour == hour &&
        other.minute == minute &&
        other.second == second;
  }

  @override
  int get hashCode => Object.hash(hour, minute, second);

  TimeOfDay? get toTimeOfDay {
    return hour == null || minute == null
        ? null
        : TimeOfDay(hour: hour!, minute: minute!);
  }
}

/// Reactive time input field with formatted text editing and validation.
///
/// A high-level time input widget that provides structured time entry through
/// formatted text fields. Supports hours, minutes, and optional seconds with
/// automatic state management through the controlled component pattern.
///
/// ## Features
///
/// - **Structured time entry**: Separate fields for hours, minutes, and seconds
/// - **Format validation**: Automatic validation and formatting of time components
/// - **Flexible display**: Optional seconds display and customizable separators
/// - **Form integration**: Automatic validation and form field registration
/// - **Keyboard navigation**: Tab navigation between time components
/// - **Accessibility**: Full screen reader support and keyboard input
///
/// ## Usage Patterns
///
/// **Controller-based (recommended for complex state):**
/// ```dart
/// final controller = ComponentController<TimeOfDay?>(TimeOfDay.now());
///
/// TimeInput(
///   controller: controller,
///   showSeconds: true,
///   placeholder: Text('Enter time'),
/// )
/// ```
///
/// **Callback-based (simple state management):**
/// ```dart
/// TimeOfDay? selectedTime;
///
/// TimeInput(
///   initialValue: selectedTime,
///   onChanged: (time) => setState(() => selectedTime = time),
///   showSeconds: false,
///   separator: InputPart.text(':'),
/// )
/// ```
class TimeInput extends StatefulWidget with ControlledComponent<TimeOfDay?> {
  /// Creates a [TimeInput].
  ///
  /// Either [controller] or [onChanged] should be provided for interactivity.
  /// The widget supports both controller-based and callback-based state management
  /// patterns with structured time component entry.
  ///
  /// Parameters:
  /// - [controller] (ComponentController<TimeOfDay?>?, optional): external state controller
  /// - [initialValue] (TimeOfDay?, optional): starting time when no controller
  /// - [onChanged] (ValueChanged<TimeOfDay?>?, optional): time change callback
  /// - [enabled] (bool, default: true): whether input is interactive
  /// - [placeholder] (Widget?, optional): widget shown when no time selected
  /// - [showSeconds] (bool, default: false): whether to include seconds input
  /// - [separator] (InputPart?, optional): separator between time components
  /// - [placeholders] (Map<TimePart, Widget>?, optional): placeholders for time parts
  ///
  /// Example:
  /// ```dart
  /// TimeInput(
  ///   controller: controller,
  ///   showSeconds: true,
  ///   separator: InputPart.text(':'),
  ///   placeholders: {
  ///     TimePart.hour: Text('HH'),
  ///     TimePart.minute: Text('MM'),
  ///     TimePart.second: Text('SS'),
  ///   },
  /// )
  /// ```
  const TimeInput({
    this.controller,
    this.enabled = true,
    this.initialValue,
    super.key,
    this.onChanged,
    this.placeholders,
    this.separator,
    this.showSeconds = false,
  });

  @override
  final TimeOfDay? initialValue;
  @override
  final ValueChanged<TimeOfDay?>? onChanged;
  @override
  final bool enabled;

  @override
  final ComponentController<TimeOfDay?>? controller;
  final bool showSeconds;
  final InputPart? separator;

  final Map<TimePart, Widget>? placeholders;

  @override
  State<TimeInput> createState() => _TimeInputState();
}

class _TimeInputState extends State<TimeInput> {
  late ComponentController<NullableTimeOfDay> _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller == null
        ? ComponentValueController<NullableTimeOfDay>(
            _convertToNullableTimeOfDay(widget.initialValue),
          )
        : ConvertedController<TimeOfDay?, NullableTimeOfDay>(BiDirectionalConvert(
              _convertToNullableTimeOfDay,
              _convertFromNullableTimeOfDay,
            ), widget.controller!);
  }

  NullableTimeOfDay _convertToTimeOfDay(List<String?> values) {
    final hour = values.first == null || values.first!.isEmpty
        ? null
        : int.tryParse(values.first!);
    final minute = values[1] == null || values[1]!.isEmpty
        ? null
        : int.tryParse(values[1]!);
    final second = widget.showSeconds && values.length > 2
        ? (values[2] == null || values[2]!.isEmpty
              ? null
              : int.tryParse(values[2]!))
        : null;

    return NullableTimeOfDay(hour: hour, minute: minute, second: second);
  }

  List<String?> _convertFromTimeOfDay(NullableTimeOfDay? value) {
    return value == null
        ? [null, null, if (widget.showSeconds) null]
        : [
            value.hour?.toString(),
            value.minute?.toString(),
            if (widget.showSeconds) value.second?.toString(),
          ];
  }

  double _getWidth(TimePart part) {
    return 40;
  }

  Widget _getPlaceholder(TimePart part) {
    final localizations = CoUILocalizations.of(context);

    return Text(localizations.getTimePartAbbreviation(part));
  }

  int _getLength(TimePart part) {
    return 2;
  }

  NullableTimeOfDay _convertToNullableTimeOfDay(TimeOfDay? value) {
    return value == null
        ? const NullableTimeOfDay()
        : NullableTimeOfDay(
            hour: value.hour,
            minute: value.minute,
            second: widget.showSeconds ? value.second : null,
          );
  }

  TimeOfDay? _convertFromNullableTimeOfDay(NullableTimeOfDay value) {
    return value.toTimeOfDay;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormattedObjectInput<NullableTimeOfDay>(
      controller: _controller,
      converter: BiDirectionalConvert(
        _convertFromTimeOfDay,
        _convertToTimeOfDay,
      ),
      initialValue: _convertToNullableTimeOfDay(widget.initialValue),
      onChanged: (value) {
        widget.onChanged?.call(
          value == null ? null : _convertFromNullableTimeOfDay(value),
        );
      },
      parts: [
        InputPart.editable(
          length: _getLength(TimePart.hour),
          placeholder:
              widget.placeholders?[TimePart.hour] ??
              _getPlaceholder(TimePart.hour),
          width: _getWidth(TimePart.hour),
        ),
        widget.separator ?? const InputPart.static(':'),
        InputPart.editable(
          length: _getLength(TimePart.minute),
          placeholder:
              widget.placeholders?[TimePart.minute] ??
              _getPlaceholder(TimePart.minute),
          width: _getWidth(TimePart.minute),
        ),
        if (widget.showSeconds) ...[
          widget.separator ?? const InputPart.static(':'),
          InputPart.editable(
            length: _getLength(TimePart.second),
            placeholder:
                widget.placeholders?[TimePart.second] ??
                _getPlaceholder(TimePart.second),
            width: _getWidth(TimePart.second),
          ),
        ],
      ],
    );
  }
}

/// Reactive duration input field with formatted text editing and validation.
///
/// A high-level duration input widget that provides structured duration entry through
/// formatted text fields. Supports hours, minutes, and optional seconds with
/// automatic state management through the controlled component pattern.
///
/// ## Features
///
/// - **Structured duration entry**: Separate fields for hours, minutes, and seconds
/// - **Format validation**: Automatic validation and formatting of duration components
/// - **Flexible display**: Optional seconds display and customizable separators
/// - **Large value support**: Handle durations spanning multiple hours or days
/// - **Form integration**: Automatic validation and form field registration
/// - **Keyboard navigation**: Tab navigation between duration components
/// - **Accessibility**: Full screen reader support and keyboard input
///
/// ## Usage Patterns
///
/// **Controller-based (recommended for complex state):**
/// ```dart
/// final controller = ComponentController<Duration?>(Duration(hours: 1, minutes: 30));
///
/// DurationInput(
///   controller: controller,
///   showSeconds: true,
///   placeholder: Text('Enter duration'),
/// )
/// ```
///
/// **Callback-based (simple state management):**
/// ```dart
/// Duration? selectedDuration;
///
/// DurationInput(
///   initialValue: selectedDuration,
///   onChanged: (duration) => setState(() => selectedDuration = duration),
///   showSeconds: false,
///   separator: InputPart.text(':'),
/// )
/// ```
class DurationInput extends StatefulWidget with ControlledComponent<Duration?> {
  /// Creates a [DurationInput].
  ///
  /// Either [controller] or [onChanged] should be provided for interactivity.
  /// The widget supports both controller-based and callback-based state management
  /// patterns with structured duration component entry.
  ///
  /// Parameters:
  /// - [controller] (ComponentController<Duration?>?, optional): external state controller
  /// - [initialValue] (Duration?, optional): starting duration when no controller
  /// - [onChanged] (ValueChanged<Duration?>?, optional): duration change callback
  /// - [enabled] (bool, default: true): whether input is interactive
  /// - [placeholder] (Widget?, optional): widget shown when no duration selected
  /// - [showSeconds] (bool, default: false): whether to include seconds input
  /// - [separator] (InputPart?, optional): separator between duration components
  /// - [placeholders] (Map<TimePart, Widget>?, optional): placeholders for time parts
  ///
  /// Example:
  /// ```dart
  /// DurationInput(
  ///   controller: controller,
  ///   showSeconds: true,
  ///   separator: InputPart.text(':'),
  ///   placeholders: {
  ///     TimePart.hour: Text('HH'),
  ///     TimePart.minute: Text('MM'),
  ///     TimePart.second: Text('SS'),
  ///   },
  /// )
  /// ```
  const DurationInput({
    this.controller,
    this.enabled = true,
    this.initialValue,
    super.key,
    this.onChanged,
    this.placeholders,
    this.separator,
    this.showSeconds = false,
  });

  @override
  final Duration? initialValue;
  @override
  final ValueChanged<Duration?>? onChanged;
  @override
  final bool enabled;

  @override
  final ComponentController<Duration?>? controller;
  final bool showSeconds;
  final InputPart? separator;

  final Map<TimePart, Widget>? placeholders;

  @override
  State<DurationInput> createState() => _DurationInputState();
}

class _DurationInputState extends State<DurationInput> {
  late ComponentController<NullableTimeOfDay> _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller == null
        ? ComponentValueController<NullableTimeOfDay>(
            _convertToNullableTimeOfDay(widget.initialValue),
          )
        : ConvertedController<Duration?, NullableTimeOfDay>(BiDirectionalConvert(
              _convertToNullableTimeOfDay,
              _convertFromNullableTimeOfDay,
            ), widget.controller!);
  }

  NullableTimeOfDay _convertToDuration(List<String?> values) {
    final hours = values.first == null || values.first!.isEmpty
        ? null
        : int.tryParse(values.first!);
    final minutes = values[1] == null || values[1]!.isEmpty
        ? null
        : int.tryParse(values[1]!);
    final seconds = widget.showSeconds && values.length > 2
        ? (values[2] == null || values[2]!.isEmpty
              ? null
              : int.tryParse(values[2]!))
        : null;

    return NullableTimeOfDay(hour: hours, minute: minutes, second: seconds);
  }

  List<String?> _convertFromDuration(NullableTimeOfDay? value) {
    return value == null
        ? [null, null, if (widget.showSeconds) null]
        : [
            value.hour?.toString(),
            value.minute?.toString(),
            if (widget.showSeconds) value.second?.toString(),
          ];
  }

  double _getWidth(TimePart part) {
    return 40;
  }

  Widget _getPlaceholder(TimePart part) {
    final localizations = CoUILocalizations.of(context);

    return Text(localizations.getTimePartAbbreviation(part));
  }

  int _getLength(TimePart part) {
    return 2;
  }

  NullableTimeOfDay _convertToNullableTimeOfDay(Duration? value) {
    return value == null
        ? const NullableTimeOfDay()
        : NullableTimeOfDay(
            hour: value.inHours,
            minute: value.inMinutes % 60,
            second: widget.showSeconds ? value.inSeconds % 60 : null,
          );
  }

  Duration? _convertFromNullableTimeOfDay(NullableTimeOfDay value) {
    return value.hour == null ||
            value.minute == null ||
            (widget.showSeconds && value.second == null)
        ? null
        : Duration(
            hours: value.hour!,
            minutes: value.minute!,
            seconds: widget.showSeconds ? (value.second ?? 0) : 0,
          );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormattedObjectInput<NullableTimeOfDay>(
      controller: _controller,
      converter: BiDirectionalConvert(_convertFromDuration, _convertToDuration),
      initialValue: _convertToNullableTimeOfDay(widget.initialValue),
      onChanged: (value) {
        widget.onChanged?.call(
          value == null ? null : _convertFromNullableTimeOfDay(value),
        );
      },
      parts: [
        InputPart.editable(
          length: _getLength(TimePart.hour),
          placeholder:
              widget.placeholders?[TimePart.hour] ??
              _getPlaceholder(TimePart.hour),
          width: _getWidth(TimePart.hour),
        ),
        widget.separator ?? const InputPart.static(':'),
        InputPart.editable(
          length: _getLength(TimePart.minute),
          placeholder:
              widget.placeholders?[TimePart.minute] ??
              _getPlaceholder(TimePart.minute),
          width: _getWidth(TimePart.minute),
        ),
        if (widget.showSeconds) ...[
          widget.separator ?? const InputPart.static(':'),
          InputPart.editable(
            length: _getLength(TimePart.second),
            placeholder:
                widget.placeholders?[TimePart.second] ??
                _getPlaceholder(TimePart.second),
            width: _getWidth(TimePart.second),
          ),
        ],
      ],
    );
  }
}

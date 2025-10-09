import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for [DatePicker] widget styling and behavior.
///
/// Defines the visual properties and default behaviors for date picker components
/// including presentation modes, calendar views, and popover positioning. Applied
/// globally through [ComponentTheme] or per-instance for customization.
///
/// Supports comprehensive customization of date picker appearance, initial views,
/// and interaction modes to match application design requirements.
class DatePickerTheme {
  /// Creates a [DatePickerTheme].
  ///
  /// All parameters are optional and fall back to framework defaults when null.
  /// The theme can be applied globally or to specific date picker instances.
  const DatePickerTheme({
    this.initialView,
    this.initialViewType,
    this.mode,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverPadding,
  });

  /// Default interaction mode for date picker triggers.
  ///
  /// Determines whether date selection opens a popover or modal dialog.
  /// When null, uses framework default prompt mode behavior.
  final PromptMode? mode;

  /// Initial calendar view to display when date picker opens.
  ///
  /// Specifies the default time period view (month, year, decade, etc.)
  /// shown when the calendar interface first appears. When null, uses
  /// framework default initial view.
  final CalendarView? initialView;

  /// Initial calendar view type for date picker interface.
  ///
  /// Determines the layout style and interaction pattern of the calendar
  /// (grid, list, compact, etc.). When null, uses framework default view type.
  final CalendarViewType? initialViewType;

  /// Alignment point on the popover for anchor attachment.
  ///
  /// Determines where the date picker popover positions itself relative
  /// to the anchor widget. When null, uses framework default alignment.
  final AlignmentGeometry? popoverAlignment;

  /// Alignment point on the anchor widget for popover positioning.
  ///
  /// Specifies which part of the trigger widget the popover should align to.
  /// When null, uses framework default anchor alignment.
  final AlignmentGeometry? popoverAnchorAlignment;

  /// Internal padding applied to the date picker popover content.
  ///
  /// Controls spacing around the calendar interface within the popover
  /// container. When null, uses framework default padding.
  final EdgeInsetsGeometry? popoverPadding;

  DatePickerTheme copyWith({
    ValueGetter<CalendarView?>? initialView,
    ValueGetter<CalendarViewType?>? initialViewType,
    ValueGetter<PromptMode?>? mode,
    ValueGetter<AlignmentGeometry?>? popoverAlignment,
    ValueGetter<AlignmentGeometry?>? popoverAnchorAlignment,
    ValueGetter<EdgeInsetsGeometry?>? popoverPadding,
  }) {
    return DatePickerTheme(
      initialView: initialView == null ? this.initialView : initialView(),
      initialViewType: initialViewType == null
          ? this.initialViewType
          : initialViewType(),
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
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DatePickerTheme &&
        other.mode == mode &&
        other.initialView == initialView &&
        other.initialViewType == initialViewType &&
        other.popoverAlignment == popoverAlignment &&
        other.popoverAnchorAlignment == popoverAnchorAlignment &&
        other.popoverPadding == popoverPadding;
  }

  @override
  int get hashCode => Object.hash(
    mode,
    initialView,
    initialViewType,
    popoverAlignment,
    popoverAnchorAlignment,
    popoverPadding,
  );
}

class DatePickerController extends ValueNotifier<DateTime?>
    with ComponentController<DateTime?> {
  DatePickerController(super.value);
}

class ControlledDatePicker extends StatelessWidget
    with ControlledComponent<DateTime?> {
  const ControlledDatePicker({
    this.controller,
    this.dialogTitle,
    this.enabled = true,
    this.initialValue,
    this.initialView,
    this.initialViewType,
    super.key,
    this.mode,
    this.onChanged,
    this.placeholder,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverPadding,
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
  final Widget? placeholder;
  final PromptMode? mode;
  final CalendarView? initialView;
  final AlignmentGeometry? popoverAlignment;
  final AlignmentGeometry? popoverAnchorAlignment;
  final EdgeInsetsGeometry? popoverPadding;
  final Widget? dialogTitle;
  final CalendarViewType? initialViewType;

  final DateStateBuilder? stateBuilder;

  @override
  Widget build(BuildContext context) {
    return ControlledComponentAdapter(
      builder: (context, data) {
        return DatePicker(
          dialogTitle: dialogTitle,
          enabled: data.enabled,
          initialView: initialView,
          initialViewType: initialViewType,
          mode: mode,
          onChanged: data.onChanged,
          placeholder: placeholder,
          popoverAlignment: popoverAlignment,
          popoverAnchorAlignment: popoverAnchorAlignment,
          popoverPadding: popoverPadding,
          stateBuilder: stateBuilder,
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

class DatePicker extends StatelessWidget {
  const DatePicker({
    this.dialogTitle,
    this.enabled,
    this.initialView,
    this.initialViewType,
    super.key,
    this.mode,
    this.onChanged,
    this.placeholder,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverPadding,
    this.stateBuilder,
    required this.value,
  });

  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final Widget? placeholder;
  final PromptMode? mode;
  final CalendarView? initialView;
  final AlignmentGeometry? popoverAlignment;
  final AlignmentGeometry? popoverAnchorAlignment;
  final EdgeInsetsGeometry? popoverPadding;
  final Widget? dialogTitle;
  final CalendarViewType? initialViewType;
  final DateStateBuilder? stateBuilder;

  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final compTheme = ComponentTheme.maybeOf<DatePickerTheme>(context);
    final resolvedMode = styleValue(
      widgetValue: mode,
      themeValue: compTheme?.mode,
      defaultValue: PromptMode.dialog,
    );
    final resolvedAlignment = styleValue(
      widgetValue: popoverAlignment,
      themeValue: compTheme?.popoverAlignment,
      defaultValue: Alignment.topLeft,
    );
    final resolvedAnchorAlignment = styleValue(
      widgetValue: popoverAnchorAlignment,
      themeValue: compTheme?.popoverAnchorAlignment,
      defaultValue: Alignment.bottomLeft,
    );
    final resolvedPadding = styleValue(
      widgetValue: popoverPadding,
      themeValue: compTheme?.popoverPadding,
      defaultValue: null,
    );
    final resolvedInitialView = styleValue(
      widgetValue: initialView,
      themeValue: compTheme?.initialView,
      defaultValue: CalendarView.now(),
    );
    final resolvedInitialViewType = styleValue(
      widgetValue: initialViewType,
      themeValue: compTheme?.initialViewType,
      defaultValue: CalendarViewType.date,
    );

    return ObjectFormField<DateTime>(
      builder: (context, value) {
        return Text(localizations.formatDateTime(value, showTime: false));
      },
      dialogTitle: dialogTitle,
      editorBuilder: (context, handler) {
        return DatePickerDialog(
          initialValue: handler.value == null
              ? null
              : CalendarValue.single(handler.value!),
          initialView: resolvedInitialView,
          initialViewType: resolvedInitialViewType,
          onChanged: (value) {
            handler.value = value == null
                ? null
                : (value as SingleCalendarValue).date;
          },
          selectionMode: CalendarSelectionMode.single,
          stateBuilder: stateBuilder,
        );
      },
      enabled: enabled,
      mode: resolvedMode,
      onChanged: onChanged,
      placeholder: placeholder ?? Text(localizations.placeholderDatePicker),
      popoverAlignment: resolvedAlignment,
      popoverAnchorAlignment: resolvedAnchorAlignment,
      popoverPadding: resolvedPadding,
      trailing: const Icon(LucideIcons.calendarDays),
      value: value,
    );
  }
}

class DateTimeRange {
  const DateTimeRange(this.end, this.start);

  final DateTime start;

  final DateTime end;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DateTimeRange && other.start == start && other.end == end;
  }

  @override
  String toString() {
    return 'DateTimeRange{start: $start, end: $end}';
  }

  DateTimeRange copyWith({
    ValueGetter<DateTime>? end,
    ValueGetter<DateTime>? start,
  }) {
    return DateTimeRange(
      start == null ? this.start : start(),
      end == null ? this.end : end(),
    );
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class DateRangePicker extends StatelessWidget {
  const DateRangePicker({
    this.dialogTitle,
    this.initialView,
    this.initialViewType,
    super.key,
    this.mode = PromptMode.dialog,
    this.onChanged,
    this.placeholder,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverPadding,
    this.stateBuilder,
    required this.value,
  });

  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?>? onChanged;
  final Widget? placeholder;
  final PromptMode mode;
  final CalendarView? initialView;
  final CalendarViewType? initialViewType;
  final AlignmentGeometry? popoverAlignment;
  final AlignmentGeometry? popoverAnchorAlignment;
  final EdgeInsetsGeometry? popoverPadding;
  final Widget? dialogTitle;

  final DateStateBuilder? stateBuilder;

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);

    return ObjectFormField<DateTimeRange>(
      builder: (context, value) {
        return Text(
          '${localizations.formatDateTime(value.start, showTime: false)} - ${localizations.formatDateTime(value.end, showTime: false)}',
        );
      },
      dialogTitle: dialogTitle,
      editorBuilder: (context, handler) {
        final value = handler.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            return DatePickerDialog(
              initialValue: value == null
                  ? null
                  : CalendarValue.range(value.start, value.end),
              initialView: initialView,
              initialViewType: initialViewType ?? CalendarViewType.date,
              onChanged: (value) {
                if (value == null) {
                  handler.value = null;
                } else {
                  final range = value.toRange();
                  handler.value = DateTimeRange(range.start, range.end);
                }
              },
              selectionMode: CalendarSelectionMode.range,
              stateBuilder: stateBuilder,
              viewMode: constraints.biggest.width < 500
                  ? CalendarSelectionMode.single
                  : CalendarSelectionMode.range,
            );
          },
        );
      },
      mode: mode,
      onChanged: onChanged,
      placeholder: placeholder ?? Text(localizations.placeholderDatePicker),
      popoverAlignment: popoverAlignment,
      popoverAnchorAlignment: popoverAnchorAlignment,
      popoverPadding: popoverPadding,
      trailing: const Icon(LucideIcons.calendarRange),
      value: value,
    );
  }
}

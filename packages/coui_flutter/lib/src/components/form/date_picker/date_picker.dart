import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';

// ── ISO format helpers (component-internal formatter detail) ──────
// `YYYY-MM-DD` zero-padding spec. Not design tokens — these are ISO
// 8601 formatter constants.

const _kIsoYearPadWidth = 4;
const _kIsoMonthDayPadWidth = 2;

/// Unified cross-platform date picker with token-based rendering.
///
/// `DatePicker` implements [CoreDatePickerContract] for cross-
/// platform API parity with the Web implementation.
///
/// Per Epic #1302 원칙 6/7/8, semantic enums (`mode`) and behaviour
/// fields (`placeholder` / `enabled` / `onChanged` / `min` / `max` /
/// `label` / `description` / `errorText`) stay flat on the widget. All
/// chrome / dimensional / nested-slot overrides flow through the single
/// [datePickerStyle] (a [CoreDatePickerStyle]):
///
/// ```text
/// design system default for date picker
///   → CoreDatePickerTheme.style
///   → widget.datePickerStyle
/// ```
///
/// Example:
/// ```dart
/// DatePicker(
///   placeholder: 'Select date',
///   onChanged: handleChanged,
///   datePickerStyle: CoreDatePickerStyle(
///     popoverStyle: CorePopoverStyle(
///       panelStyle: CorePopupStyle(
///         borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
///       ),
///     ),
///   ),
/// )
/// ```
///
/// surface:functional — the calendar opens in a `Popover` or a dialog, over
/// the page.
class DatePicker extends StatelessWidget
    implements CoreDatePickerContract<Widget, ValueChanged<DateTime?>?> {
  /// Creates a [DatePicker].
  const DatePicker({
    super.key,
    // === Contract fields ===
    this.placeholder,
    this.enabled = true,
    this.onChanged,
    this.min,
    this.max,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.errorText,
    this.mode,
    this.dialogTitle,
    this.datePickerStyle,
    // === Extended fields ===
    this.value,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.placeholderWidget,
    this.popoverPlacement = CorePopoverPlacement.bottomStart,
  }) : assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  /// Creates a [DatePicker] with a simple API compatible with the Web
  /// variant. Wraps [ControlledDatePicker] for internal state
  /// management.
  static Widget simple({
    Key? key,
    String? placeholder,
    bool enabled = true,
    ValueChanged<DateTime?>? onChanged,
    DateTime? min,
    DateTime? max,
    String? label,
    String? description,
    String? errorText,
  }) {
    return ControlledDatePicker(
      key: key,
      onChanged: onChanged,
      enabled: enabled,
      placeholder: placeholder,
      min: min,
      max: max,
      label: label,
      description: description,
      errorText: errorText,
    );
  }

  /// Formats [date] as ISO 8601 (`YYYY-MM-DD`). Mirrors the Web
  /// single picker's `_formatIso` helper so both platforms render
  /// the trigger label identically.
  static String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(_kIsoYearPadWidth, '0');
    final m = date.month.toString().padLeft(_kIsoMonthDayPadWidth, '0');
    final d = date.day.toString().padLeft(_kIsoMonthDayPadWidth, '0');
    return '$y-$m-$d';
  }

  // === Contract fields ===

  @override
  final String? placeholder;

  @override
  final bool enabled;

  @override
  final ValueChanged<DateTime?>? onChanged;

  @override
  final DateTime? min;

  @override
  final DateTime? max;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final String? description;

  @override
  final String? errorText;

  @override
  final CorePromptMode? mode;

  @override
  final Widget? dialogTitle;

  @override
  final CoreDatePickerStyle? datePickerStyle;

  // === Extended fields ===

  /// Currently selected date.
  final DateTime? value;

  /// Initial calendar view (month/year) to display when the picker
  /// opens.
  final CoreCalendarView? initialView;

  /// The weekday the calendar's weeks start on — a `DateTime.monday`…
  /// `DateTime.sunday` value, Sunday by default. Handed to the [Calendar]
  /// the picker opens; see [CoreCalendarContract.firstDayOfWeek].
  @override
  final int firstDayOfWeek;

  /// Builder for customizing individual date cell states.
  final CoreCalendarDateStateBuilder? stateBuilder;

  /// Custom placeholder widget to display when no date is selected.
  ///
  /// Takes precedence over [placeholder] string.
  @override
  final Widget? placeholderWidget;

  /// Placement of the popover panel relative to the trigger (popover
  /// mode only). Defaults to bottom-start — the picker-family
  /// convention (panel's left edge lines up with the trigger's).
  @override
  final CorePopoverPlacement popoverPlacement;

  /// Returns a copy of this [DatePicker] with the given fields
  /// replaced. All fields default to this instance's current value
  /// when omitted.
  DatePicker copyWith({
    Key? key,
    ValueChanged<DateTime?>? onChanged,
    String? placeholder,
    bool? enabled,
    DateTime? min,
    DateTime? max,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? description,
    String? errorText,
    CorePromptMode? mode,
    Widget? dialogTitle,
    CoreDatePickerStyle? datePickerStyle,
    DateTime? value,
    CoreCalendarView? initialView,
    int? firstDayOfWeek,
    CoreCalendarDateStateBuilder? stateBuilder,
    Widget? placeholderWidget,
    CorePopoverPlacement? popoverPlacement,
  }) {
    return DatePicker(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      placeholder: placeholder ?? this.placeholder,
      enabled: enabled ?? this.enabled,
      min: min ?? this.min,
      max: max ?? this.max,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      description: description ?? this.description,
      errorText: errorText ?? this.errorText,
      mode: mode ?? this.mode,
      dialogTitle: dialogTitle ?? this.dialogTitle,
      datePickerStyle: datePickerStyle ?? this.datePickerStyle,
      value: value ?? this.value,
      initialView: initialView ?? this.initialView,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      stateBuilder: stateBuilder ?? this.stateBuilder,
      placeholderWidget: placeholderWidget ?? this.placeholderWidget,
      popoverPlacement: popoverPlacement ?? this.popoverPlacement,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final resolved = resolveDatePicker(
      context,
      datePickerStyle: datePickerStyle,
      // The trigger is enabled only with a handler too (`_enabled` below),
      // and the trigger field folds the ambient scope into its own `enabled`
      // (an enclosing `Fieldset(enabled: false)` wins); the text colours
      // handed to it follow the same answer.
      enabled:
          enabled &&
          onChanged != null &&
          FormFieldScope.maybeOf(context)?.disabled != true,
    );

    final resolvedMode = mode ?? .popover;

    final effectivePlaceholder =
        placeholderWidget ??
        (placeholder != null
            ? Text(placeholder!)
            : Text(localizations.placeholderDatePicker));

    final isoLabel = _formatIsoDate;

    return _DatePickerTrigger(
      onChanged: onChanged,
      enabled: enabled,
      mode: resolvedMode,
      popoverPlacement: popoverPlacement,
      initialView: initialView,
      firstDayOfWeek: firstDayOfWeek,
      min: min,
      max: max,
      stateBuilder: stateBuilder,
      dialogTitle: dialogTitle,
      placeholder: effectivePlaceholder,
      value: value,
      label: label,
      labelMaxLines: labelMaxLines,
      labelOverflow: labelOverflow,
      description: description,
      errorText: errorText,
      resolved: resolved,
      // ISO `YYYY-MM-DD` so Flutter / Web previews show the
      // identical trigger label after a date is picked. Callers
      // who want a localized format can wrap DatePicker with
      // their own builder.
      displayLabelBuilder: isoLabel,
    );
  }
}

/// Chain sugar for merging a [CoreDatePickerStyle] patch into
/// [DatePicker.datePickerStyle] without hand-reconstructing every
/// field. Mirrors the Web `DatePicker.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDatePickerStyle.merge` right-side-wins semantics).
extension DatePickerStyleChain on DatePicker {
  /// Returns a copy of this [DatePicker] with [patch] merged into
  /// [datePickerStyle] (patch fields win on conflict).
  DatePicker withStyle(CoreDatePickerStyle patch) => copyWith(
    datePickerStyle: (datePickerStyle ?? const CoreDatePickerStyle()).merge(
      patch,
    ),
  );
}

// =============================================================================
// _DatePickerTrigger — Bordered TextField-like trigger matching Web parity.
// =============================================================================

class _DatePickerTrigger extends StatefulWidget {
  const _DatePickerTrigger({
    required this.onChanged,
    required this.enabled,
    required this.mode,
    required this.popoverPlacement,
    required this.initialView,
    required this.firstDayOfWeek,
    required this.min,
    required this.max,
    required this.stateBuilder,
    required this.dialogTitle,
    required this.placeholder,
    required this.value,
    required this.label,
    required this.labelMaxLines,
    required this.labelOverflow,
    required this.description,
    required this.errorText,
    required this.resolved,
    required this.displayLabelBuilder,
  });

  final bool enabled;
  final CorePromptMode mode;
  final CorePopoverPlacement popoverPlacement;
  final CoreCalendarView? initialView;
  final int firstDayOfWeek;
  final DateTime? min;
  final DateTime? max;
  final CoreCalendarDateStateBuilder? stateBuilder;
  final Widget? dialogTitle;
  final Widget placeholder;
  final DateTime? value;
  final String? label;
  final int? labelMaxLines;
  final CoreTextOverflow? labelOverflow;
  final String? description;
  final String? errorText;
  final ResolvedDatePicker resolved;
  final ValueChanged<DateTime?>? onChanged;
  final String Function(DateTime value) displayLabelBuilder;

  @override
  State<_DatePickerTrigger> createState() => _DatePickerTriggerState();
}

class _DatePickerTriggerState extends State<_DatePickerTrigger> {
  /// Imperative controller for the unified [Popover] hosting the
  /// calendar in `CorePromptMode.popover`. The popover dismisses itself
  /// when the user picks a date — the controller lets the calendar's
  /// `onChanged` close the panel without going through the public
  /// `PopoverController` API every caller would otherwise have to
  /// manage. Unused in `CorePromptMode.dialog`, where the picker pushes
  /// a [Dialog] via [showDialog] instead.
  final _popoverController = PopoverController();

  bool get _enabled => widget.enabled && widget.onChanged != null;

  CoreCalendarView? _resolveInitialView() {
    final iv = widget.initialView;
    if (iv != null) return iv;
    final value = widget.value;
    if (value != null) return CoreCalendarView(value.year, value.month);
    return null;
  }

  void _showDialog() {
    final localizations = CoUILocalizations.of(context);
    // The dialog reports its outcome wrapped, because the two outcomes
    // that matter are otherwise the same value. A bare `null` pop means
    // both "Cancel" and "Save, with nothing selected", so reporting the
    // raw result cleared the field every time the user backed out —
    // including on a barrier tap or a system back. The wrapper is the
    // same one `ObjectFormField` already uses for exactly this reason:
    // absent means the prompt was abandoned, present means the user
    // committed a value, which may legitimately be null.
    unawaited(
      showDialog<ObjectFormFieldDialogResult<DateTime>>(
        context: context,
        builder: (dialogContext) {
          DateTime? pending = widget.value;

          return StatefulBuilder(
            builder: (innerContext, setInnerState) {
              return Dialog(
                title: widget.dialogTitle,
                content: Calendar(
                  onChanged: (calValue) {
                    setInnerState(() {
                      pending = calValue is CoreSingleCalendarValue
                          ? calValue.date
                          : null;
                    });
                  },
                  selectionMode: .single,
                  value: pending == null
                      ? null
                      : CoreCalendarValue.single(pending!),
                  initialView: _resolveInitialView(),
                  firstDayOfWeek: widget.firstDayOfWeek,
                  stateBuilder: widget.stateBuilder,
                  minDate: widget.min,
                  maxDate: widget.max,
                  calendarStyle: widget.resolved.calendarStyle,
                ),
                actions: [
                  Button(
                    onPressed: () {
                      Navigator.of(innerContext).pop();
                    },
                    variant: .secondary,
                    child: Text(localizations.buttonCancel),
                  ),
                  Button(
                    onPressed: () {
                      Navigator.of(
                        innerContext,
                      ).pop(ObjectFormFieldDialogResult(pending));
                    },
                    variant: .primary,
                    child: Text(localizations.buttonSave),
                  ),
                ],
                dialogStyle: widget.resolved.dialogStyle,
              );
            },
          );
        },
      ).then((result) {
        if (!mounted) return;
        // Presence, not nullness. `if (result != null)` reads like the
        // simpler guard and is what `TimePicker` uses, but that only
        // works there because `TimeOfDay` is non-nullable. Here, tapping
        // the selected day deselects it, so Save-with-nothing-selected
        // is a deliberate clear the caller has to hear about — and it
        // arrives as a wrapper around null, not as a bare null.
        if (result != null) widget.onChanged?.call(result.value);
      }),
    );
  }

  /// Builds the calendar that lives inside the popover panel. Kept
  /// as a method (not inlined into `build`) so the same body is
  /// reused by [Popover.content] in popover mode and isn't
  /// accidentally rebuilt by `_showDialog` (which pushes its own
  /// [Dialog] with a separate calendar widget).
  Widget _buildPopoverCalendar() {
    return Calendar(
      onChanged: (calValue) {
        final selected = calValue is CoreSingleCalendarValue
            ? calValue.date
            : null;
        widget.onChanged?.call(selected);
        // Brief delay so the user sees the selected highlight before
        // the popover dismisses (shadcn-ui parity).
        Future<void>.delayed(
          const Duration(
            milliseconds: CoreDatePickerStyle.defaultPopoverDismissDelayMs,
          ),
          _popoverController.close,
        );
      },
      selectionMode: .single,
      value: widget.value == null
          ? null
          : CoreCalendarValue.single(widget.value!),
      initialView: _resolveInitialView(),
      firstDayOfWeek: widget.firstDayOfWeek,
      stateBuilder: widget.stateBuilder,
      minDate: widget.min,
      maxDate: widget.max,
      calendarStyle: widget.resolved.calendarStyle,
    );
  }

  void handleTap() {
    if (!_enabled) return;
    if (widget.mode == .dialog) {
      _showDialog();
    } else {
      // popover mode — the trigger field consumes tap events internally,
      // so the outer GestureDetector inside [Popover] never fires. Toggle
      // the popover explicitly through the controller.
      _popoverController.toggle();
    }
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolved;

    final currentValue = widget.value;
    final hasValue = currentValue != null;
    final hasError = widget.errorText != null;
    final label = widget.label;
    final description = widget.description;

    // The trigger is a read-only `TextField` — the TimePicker / Select input
    // look (height 40, corner 10, `outline-variant` edge that turns `primary`
    // on focus and `error` while the picker holds an error, Regular 14 value,
    // the calendar in the suffix seat), filling the width its parent gives
    // it. `readOnly` keeps the caret and the keyboard away while leaving it
    // focusable and tappable: the value is chosen in the calendar, not typed.
    // The error message is the picker's own row below, so the field is only
    // told the tone (through the ambient validation state), not the text.
    // Part of this composite: walled off from the enclosing `FormField`,
    // which is shown the composite's own value.
    Widget triggerButton = Data<FormFieldHandle>.boundary(
      child: TextField(
        onTap: _enabled ? handleTap : null,
        value: hasValue ? widget.displayLabelBuilder(currentValue) : '',
        placeholder: hasValue ? null : widget.placeholder,
        enabled: _enabled,
        readOnly: true,
        showCursor: false,
        textFieldStyle: resolved.triggerStyle,
        suffix: Icon(
          LucideIcons.calendar,
          iconStyle: resolved.trailingIconStyle,
        ),
      ),
    );
    if (hasError && _enabled) {
      triggerButton = Data<CoreValidationState>.inherit(
        data: CoreValidationState.invalid,
        child: triggerButton,
      );
    }

    // Wrap the field-style trigger in `Popover` for popover mode with
    // `openTrigger: manual` — the field's own tap handler consumes the tap
    // first, so [handleTap] toggles the popover through
    // [_popoverController]. For dialog mode the trigger stays bare and
    // `handleTap` pushes a [Dialog] via [showDialog] when tapped.
    final Widget trigger = (widget.mode != .dialog && _enabled)
        ? Popover(
            trigger: triggerButton,
            content: _buildPopoverCalendar(),
            placement: widget.popoverPlacement,
            controller: _popoverController,
            openTrigger: .manual,
            popoverStyle: resolved.popoverStyle,
          )
        : triggerButton;

    final children = <Widget>[];

    if (label != null) {
      children.add(
        DefaultTextStyle.merge(
          style: _enabled
              ? resolved.labelTextStyle
              : resolved.labelDisabledTextStyle,
          child: Text(
            label,
            maxLines: widget.labelMaxLines,
            overflow: widget.labelOverflow?.toValue(),
          ),
        ),
      );
      children.add(
        Gap(gapStyle: resolved.labelBottomGapStyle),
      );
    }

    children.add(trigger);

    if (hasError) {
      children.add(
        Gap(gapStyle: resolved.descriptionTopGapStyle),
      );
      children.add(
        DefaultTextStyle.merge(
          style: resolved.errorTextStyle,
          child: Text(widget.errorText!),
        ),
      );
    } else if (description != null) {
      children.add(
        Gap(gapStyle: resolved.descriptionTopGapStyle),
      );
      children.add(
        DefaultTextStyle.merge(
          style: resolved.descriptionTextStyle,
          child: Text(description),
        ),
      );
    }

    if (children.length == 1) {
      return children.first;
    }
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: children,
    );
  }
}

// =============================================================================
// Controller
// =============================================================================

/// Controller for [DatePicker] state management.
class DatePickerController extends ValueNotifier<DateTime?>
    with ComponentController<DateTime?> {
  /// Creates a [DatePickerController].
  DatePickerController(super.value);
}

// =============================================================================
// Controlled variant
// =============================================================================

/// Controlled wrapper for [DatePicker] with internal state management.
///
/// Manages the selected date value internally when no external
/// controller is provided.
class ControlledDatePicker extends StatelessWidget
    with ControlledComponent<DateTime?> {
  /// Creates a [ControlledDatePicker].
  const ControlledDatePicker({
    this.controller,
    this.dialogTitle,
    this.enabled = true,
    this.initialValue,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    super.key,
    this.mode,
    this.onChanged,
    this.placeholder,
    this.popoverPlacement = CorePopoverPlacement.bottomStart,
    this.stateBuilder,
    this.min,
    this.max,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.errorText,
    this.datePickerStyle,
  });

  @override
  final DateTime? initialValue;
  @override
  final ValueChanged<DateTime?>? onChanged;
  @override
  final bool enabled;

  @override
  final DatePickerController? controller;

  /// Placeholder text.
  final String? placeholder;

  /// Interaction mode.
  final CorePromptMode? mode;

  /// Initial calendar view.
  final CoreCalendarView? initialView;

  /// The weekday the calendar's weeks start on — see
  /// [DatePicker.firstDayOfWeek].
  final int firstDayOfWeek;

  /// Placement of the popover panel relative to the trigger (popover
  /// mode only). Defaults to bottom-start — the picker-family
  /// convention (panel's left edge lines up with the trigger's).
  final CorePopoverPlacement popoverPlacement;

  /// Dialog title widget.
  final Widget? dialogTitle;

  /// Date state builder.
  final CoreCalendarDateStateBuilder? stateBuilder;

  /// Minimum selectable date.
  final DateTime? min;

  /// Maximum selectable date.
  final DateTime? max;

  /// Label text displayed above the trigger.
  final String? label;

  /// Maximum number of lines for [label] before it overflows.
  final int? labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  final CoreTextOverflow? labelOverflow;

  /// Description/helper text displayed below the trigger.
  final String? description;

  /// Error message. When non-null, error styling is applied.
  final String? errorText;

  /// Per-instance date-picker style.
  final CoreDatePickerStyle? datePickerStyle;

  @override
  Widget build(BuildContext context) {
    return ControlledComponentAdapter(
      onChanged: onChanged,
      initialValue: initialValue,
      controller: controller,
      enabled: enabled,
      builder: (context, data) {
        return DatePicker(
          onChanged: data.onChanged,
          placeholder: placeholder,
          enabled: data.enabled,
          min: min,
          max: max,
          label: label,
          labelMaxLines: labelMaxLines,
          labelOverflow: labelOverflow,
          description: description,
          errorText: errorText,
          mode: mode,
          dialogTitle: dialogTitle,
          datePickerStyle: datePickerStyle,
          value: data.value,
          initialView: initialView,
          firstDayOfWeek: firstDayOfWeek,
          stateBuilder: stateBuilder,
          popoverPlacement: popoverPlacement,
        );
      },
    );
  }
}

// =============================================================================
// DateRangePicker
// =============================================================================

/// Unified cross-platform date range picker.
///
/// Presents a calendar interface with range selection mode via
/// [Calendar]. Implements [CoreDateRangePickerContract] so the
/// same surface is exposed by the Web counterpart.
class DateRangePicker extends StatefulWidget
    implements
        CoreDateRangePickerContract<Widget, ValueChanged<DateTimeRange?>?> {
  /// Creates a [DateRangePicker].
  const DateRangePicker({
    super.key,
    required this.value,
    this.onChanged,
    this.placeholder,
    this.mode = CorePromptMode.dialog,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.popoverPlacement = CorePopoverPlacement.bottomStart,
    this.dialogTitle,
    this.min,
    this.max,
    this.enabled = true,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.errorText,
    this.builder,
    this.dateRangePickerStyle,
  }) : assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  /// Currently selected date range.
  final DateTimeRange? value;

  /// Callback when the selected date range changes.
  @override
  final ValueChanged<DateTimeRange?>? onChanged;

  /// Placeholder widget.
  @override
  final Widget? placeholder;

  /// Interaction mode.
  @override
  final CorePromptMode mode;

  /// Initial calendar view.
  final CoreCalendarView? initialView;

  /// The weekday the calendar's weeks start on — a `DateTime.monday`…
  /// `DateTime.sunday` value, Sunday by default. Handed to the [Calendar]
  /// the picker opens; see [CoreCalendarContract.firstDayOfWeek].
  @override
  final int firstDayOfWeek;

  /// Date state builder.
  final CoreCalendarDateStateBuilder? stateBuilder;

  /// Placement of the popover panel relative to the trigger (popover
  /// mode only). Defaults to bottom-start — the picker-family
  /// convention (panel's left edge lines up with the trigger's).
  @override
  final CorePopoverPlacement popoverPlacement;

  /// Dialog title widget.
  @override
  final Widget? dialogTitle;

  /// Minimum selectable date.
  @override
  final DateTime? min;

  /// Maximum selectable date.
  @override
  final DateTime? max;

  /// Whether the trigger is enabled.
  @override
  final bool enabled;

  /// Label text.
  @override
  final String? label;

  /// Maximum number of lines for [label] before it overflows.
  @override
  final int? labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  @override
  final CoreTextOverflow? labelOverflow;

  /// Description text.
  @override
  final String? description;

  /// Error text.
  @override
  final String? errorText;

  /// Custom builder for displaying the selected date range.
  ///
  /// Uses default format when null.
  final Widget Function(BuildContext context, DateTimeRange value)? builder;

  /// Per-instance date-range-picker style.
  @override
  final CoreDatePickerStyle? dateRangePickerStyle;

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  /// Imperative controller for the unified [Popover] hosting the
  /// range calendar in `CorePromptMode.popover`. Closing the popover
  /// after a range is committed is what `handleRangeChanged` routes
  /// through. Unused in `CorePromptMode.dialog`.
  final _popoverController = PopoverController();

  bool get _enabled => widget.enabled && widget.onChanged != null;

  /// Formats [date] as ISO 8601 (`YYYY-MM-DD`). Mirrors the Web
  /// range picker's `_formatIso` helper so both platforms render
  /// the trigger label identically.
  String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(_kIsoYearPadWidth, '0');
    final m = date.month.toString().padLeft(_kIsoMonthDayPadWidth, '0');
    final d = date.day.toString().padLeft(_kIsoMonthDayPadWidth, '0');
    return '$y-$m-$d';
  }

  CoreCalendarView? _resolveInitialView() {
    final iv = widget.initialView;
    if (iv != null) return iv;
    final value = widget.value;
    if (value != null) {
      return CoreCalendarView(value.start.year, value.start.month);
    }
    return null;
  }

  void _showDialog(ResolvedDatePicker resolved) {
    final localizations = CoUILocalizations.of(context);
    // Wrapped, for the reason spelled out on the single-date picker:
    // a bare `null` pop means both "Cancel" and "Save with nothing
    // selected", and reporting the raw result cleared a committed range
    // every time the user backed out. This picker is the more exposed
    // of the two — its constructor defaults to `dialog` mode, so every
    // default-constructed range picker was affected without opting in.
    unawaited(
      showDialog<ObjectFormFieldDialogResult<DateTimeRange>>(
        context: context,
        builder: (dialogContext) {
          CoreCalendarValue? pending = widget.value == null
              ? null
              : CoreCalendarValue.range(
                  widget.value!.start,
                  widget.value!.end,
                );

          return StatefulBuilder(
            builder: (innerContext, setInnerState) {
              return Dialog(
                title: widget.dialogTitle,
                content: Calendar(
                  onChanged: (calValue) {
                    setInnerState(() {
                      pending = calValue;
                    });
                  },
                  selectionMode: .range,
                  value: pending,
                  initialView: _resolveInitialView(),
                  firstDayOfWeek: widget.firstDayOfWeek,
                  stateBuilder: widget.stateBuilder,
                  minDate: widget.min,
                  maxDate: widget.max,
                  calendarStyle: resolved.calendarStyle,
                ),
                actions: [
                  Button(
                    onPressed: () {
                      Navigator.of(innerContext).pop();
                    },
                    variant: .secondary,
                    child: Text(localizations.buttonCancel),
                  ),
                  Button(
                    onPressed: () {
                      DateTimeRange? result;
                      final p = pending;
                      if (p != null) {
                        final range = p.toRange();
                        result = DateTimeRange(range.start, range.end);
                      }
                      Navigator.of(
                        innerContext,
                      ).pop(ObjectFormFieldDialogResult(result));
                    },
                    variant: .primary,
                    child: Text(localizations.buttonSave),
                  ),
                ],
                dialogStyle: resolved.dialogStyle,
              );
            },
          );
        },
      ).then((result) {
        if (!mounted) return;
        // Presence, not nullness — Save with an incomplete range is a
        // deliberate clear, and it arrives wrapped around null.
        if (result != null) widget.onChanged?.call(result.value);
      }),
    );
  }

  /// Builds the range calendar that lives inside the popover panel.
  Widget _buildPopoverCalendar(ResolvedDatePicker resolved) {
    return Calendar(
      onChanged: (calValue) {
        // Calendar in range mode emits twice per pick cycle:
        //   1) first tap → `CoreSingleCalendarValue(start)`
        //   2) second tap → `CoreRangeCalendarValue(start, end)`
        // Only commit + close on the range emission so the popover
        // stays open through the intermediate single-value tap.
        if (calValue is! CoreRangeCalendarValue && calValue != null) {
          return;
        }
        handleRangeChanged(calValue);
        // Brief delay so the user sees the committed range highlight
        // before the popover dismisses (shadcn-ui parity).
        Future<void>.delayed(
          const Duration(
            milliseconds: CoreDatePickerStyle.defaultPopoverDismissDelayMs,
          ),
          _popoverController.close,
        );
      },
      selectionMode: .range,
      value: widget.value == null
          ? null
          : CoreCalendarValue.range(
              widget.value!.start,
              widget.value!.end,
            ),
      initialView: _resolveInitialView(),
      firstDayOfWeek: widget.firstDayOfWeek,
      stateBuilder: widget.stateBuilder,
      minDate: widget.min,
      maxDate: widget.max,
      calendarStyle: resolved.calendarStyle,
    );
  }

  void handleRangeChanged(CoreCalendarValue? calValue) {
    if (calValue == null) {
      widget.onChanged?.call(null);
      return;
    }
    final range = calValue.toRange();
    widget.onChanged?.call(DateTimeRange(range.start, range.end));
  }

  void handleTap(ResolvedDatePicker resolved) {
    if (!_enabled) return;
    if (widget.mode == .dialog) {
      _showDialog(resolved);
    } else {
      // popover mode — see comment in
      // `_DatePickerTriggerState.handleTap`.
      _popoverController.toggle();
    }
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final resolved = resolveDatePicker(
      context,
      datePickerStyle: widget.dateRangePickerStyle,
      enabled: _enabled && FormFieldScope.maybeOf(context)?.disabled != true,
    );

    final currentValue = widget.value;
    final hasValue = currentValue != null;
    final hasError = widget.errorText != null;
    final label = widget.label;
    final description = widget.description;

    // A caller-supplied `builder` widget cannot be the field's text `value`,
    // so it takes the field's placeholder seat (the value stays empty) under
    // the value colour; a plain range is the field's own `value`.
    final custom = hasValue
        ? widget.builder?.call(context, currentValue)
        : null;
    final String fieldValue;
    final Widget? fieldPlaceholder;
    if (hasValue && custom == null) {
      // ISO `YYYY-MM-DD` so Flutter / Web previews show the identical range
      // label inside the trigger. Callers who want a localized format can
      // supply their own [builder].
      fieldValue =
          '${_formatIsoDate(currentValue.start)} - ${_formatIsoDate(currentValue.end)}';
      fieldPlaceholder = null;
    } else if (custom != null) {
      fieldValue = '';
      fieldPlaceholder = DefaultTextStyle.merge(
        style: resolved.customValueTextStyle,
        child: custom,
      );
    } else {
      fieldValue = '';
      fieldPlaceholder =
          widget.placeholder ?? Text(localizations.placeholderDatePicker);
    }

    // The range trigger is the same read-only `TextField` as the single
    // picker's, with the range glyph in the suffix seat (see the single
    // picker for the error tone).
    Widget triggerButton = Data<FormFieldHandle>.boundary(
      child: TextField(
        onTap: _enabled ? () => handleTap(resolved) : null,
        value: fieldValue,
        placeholder: fieldPlaceholder,
        enabled: _enabled,
        readOnly: true,
        showCursor: false,
        textFieldStyle: resolved.triggerStyle,
        suffix: Icon(
          LucideIcons.calendarRange,
          iconStyle: resolved.trailingIconStyle,
        ),
      ),
    );
    if (hasError && _enabled) {
      triggerButton = Data<CoreValidationState>.inherit(
        data: CoreValidationState.invalid,
        child: triggerButton,
      );
    }

    final Widget trigger = (widget.mode != .dialog && _enabled)
        ? Popover(
            trigger: triggerButton,
            content: _buildPopoverCalendar(resolved),
            placement: widget.popoverPlacement,
            controller: _popoverController,
            openTrigger: .manual,
            popoverStyle: resolved.popoverStyle,
          )
        : triggerButton;

    final children = <Widget>[];

    if (label != null) {
      children.add(
        DefaultTextStyle.merge(
          style: _enabled
              ? resolved.labelTextStyle
              : resolved.labelDisabledTextStyle,
          child: Text(
            label,
            maxLines: widget.labelMaxLines,
            overflow: widget.labelOverflow?.toValue(),
          ),
        ),
      );
      children.add(
        Gap(gapStyle: resolved.labelBottomGapStyle),
      );
    }

    children.add(trigger);

    if (hasError) {
      children.add(
        Gap(gapStyle: resolved.descriptionTopGapStyle),
      );
      children.add(
        DefaultTextStyle.merge(
          style: resolved.errorTextStyle,
          child: Text(widget.errorText!),
        ),
      );
    } else if (description != null) {
      children.add(
        Gap(gapStyle: resolved.descriptionTopGapStyle),
      );
      children.add(
        DefaultTextStyle.merge(
          style: resolved.descriptionTextStyle,
          child: Text(description),
        ),
      );
    }

    if (children.length == 1) {
      return children.first;
    }
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: children,
    );
  }
}

class DateTimeRange {
  /// Creates a date range. Positional arguments are `(start, end)`
  /// to mirror Flutter framework's `DateTimeRange({start, end})` and
  /// the natural reading order — previously this constructor stored
  /// `(end, start)` which silently swapped the dates whenever any
  /// caller passed them in the obvious order, surfacing as
  /// `2026-05-22 - 2026-05-05` (end-before-start) trigger labels.
  const DateTimeRange(this.start, this.end);

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

/// Chain sugar for merging a [CoreDatePickerStyle] patch into
/// [ControlledDatePicker.datePickerStyle] without hand-reconstructing
/// every field. Mirrors the plain [DatePicker.withStyle] extension so
/// the controlled variant reads identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDatePickerStyle.merge` right-side-wins semantics).
extension ControlledDatePickerStyleChain on ControlledDatePicker {
  /// Returns a copy of this [ControlledDatePicker] with [patch] merged
  /// into [datePickerStyle] (patch fields win on conflict).
  ControlledDatePicker withStyle(CoreDatePickerStyle patch) => .new(
    key: key,
    onChanged: onChanged,
    initialValue: initialValue,
    controller: controller,
    dialogTitle: dialogTitle,
    enabled: enabled,
    initialView: initialView,
    mode: mode,
    placeholder: placeholder,
    popoverPlacement: popoverPlacement,
    stateBuilder: stateBuilder,
    min: min,
    max: max,
    label: label,
    labelMaxLines: labelMaxLines,
    labelOverflow: labelOverflow,
    description: description,
    errorText: errorText,
    datePickerStyle: (datePickerStyle ?? const CoreDatePickerStyle()).merge(
      patch,
    ),
  );
}

/// Chain sugar for merging a [CoreDatePickerStyle] patch into
/// [DateRangePicker.dateRangePickerStyle] without hand-reconstructing
/// every field. Mirrors the Web `DateRangePicker.withStyle` extension
/// so both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDatePickerStyle.merge` right-side-wins semantics).
extension DateRangePickerStyleChain on DateRangePicker {
  /// Returns a copy of this [DateRangePicker] with [patch] merged into
  /// [dateRangePickerStyle] (patch fields win on conflict).
  DateRangePicker withStyle(CoreDatePickerStyle patch) => .new(
    key: key,
    onChanged: onChanged,
    value: value,
    placeholder: placeholder,
    mode: mode,
    initialView: initialView,
    stateBuilder: stateBuilder,
    popoverPlacement: popoverPlacement,
    dialogTitle: dialogTitle,
    min: min,
    max: max,
    enabled: enabled,
    label: label,
    labelMaxLines: labelMaxLines,
    labelOverflow: labelOverflow,
    description: description,
    errorText: errorText,
    dateRangePickerStyle: (dateRangePickerStyle ?? const CoreDatePickerStyle())
        .merge(patch),
    builder: builder,
  );
}

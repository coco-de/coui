import 'dart:async';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/validated/validation_state_scope.dart';

/// ISO date parts count (`YYYY-MM-DD`).
const int _kDateParts = 3;

/// ISO year pad width (`YYYY`).
const int _kYearPadWidth = 4;

/// ISO month / day pad width (`MM` / `DD`).
const int _kMonthDayPadWidth = 2;

/// Process-level counter used to mint unique scope ids so multiple
/// `DatePicker` instances on the same page don't collide.
int _coDatePickerIdCounter = 0;

/// Delay between committing a value and dismissing the popover so the
/// user briefly sees the selected highlight before the surface
/// disappears. Mirrors the Flutter file + shadcn-ui calendar UX.
const Duration _kPopoverDismissDelay = Duration(
  milliseconds: CoreDatePickerStyle.defaultPopoverDismissDelayMs,
);

/// Unified cross-platform date picker for CoUI Web.
///
/// `DatePicker` implements [CoreDatePickerContract] for parity with
/// the Flutter implementation. It renders a field-style trigger that,
/// depending on [mode], opens either a [Popover] anchored to the
/// trigger or a centred [Dialog] modal containing [Calendar].
///
/// Per Epic #1302 원칙 6/7/8, semantic enums (`mode`) and behaviour
/// fields stay flat on the component. All chrome / dimensional /
/// nested-slot overrides flow through the single [datePickerStyle]
/// (a [CoreDatePickerStyle]):
///
/// ```text
/// design system default for date picker
///   → CoreDatePickerTheme.style
///   → component.datePickerStyle
/// ```
///
/// Values are exposed as ISO 8601 date strings (`YYYY-MM-DD`).
///
/// ```dart
/// DatePicker(
///   placeholder: 'Select date',
///   mode: CorePromptMode.popover,
///   onChanged: (date) => print('Selected: $date'),
/// )
/// ```
///
/// surface:functional — the calendar opens in a `Popover` or a dialog, over
/// the page.
class DatePicker extends UiStatefulComponent
    implements CoreDatePickerContract<Component, CoreValueChanged<String?>?> {
  /// Creates a [DatePicker].
  const DatePicker({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.placeholder,
    this.placeholderWidget,
    this.enabled = true,
    this.onChanged,
    this.min,
    this.max,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.errorText,
    this.value,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.mode,
    this.popoverPlacement = CorePopoverPlacement.bottomStart,
    this.dialogTitle,
    this.datePickerStyle,
  }) : assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  // === Contract fields ===

  @override
  final String? placeholder;

  /// Custom placeholder component shown when no date is selected — takes
  /// precedence over the [placeholder] string (Flutter `placeholderWidget`
  /// parity).
  @override
  final Component? placeholderWidget;

  @override
  final bool enabled;

  @override
  final String? min;

  @override
  final String? max;

  @override
  final CoreValueChanged<String?>? onChanged;

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

  /// Placement of the popover panel relative to the trigger (popover
  /// mode only). Defaults to bottom-start — the picker-family
  /// convention (panel's left edge lines up with the trigger's).
  @override
  final CorePopoverPlacement popoverPlacement;

  @override
  final Component? dialogTitle;

  @override
  final CoreDatePickerStyle? datePickerStyle;

  // === Extended fields ===

  /// Current value (ISO date string: `YYYY-MM-DD`).
  final String? value;

  /// Which month/year view the calendar opens to when the dialog is
  /// shown (`null` = the value's month, else today). Forwarded to the
  /// inner `Calendar` — matching Flutter `DatePicker.initialView`
  /// (Epic #2317, Flutter is the cross-platform reference).
  final CoreCalendarView? initialView;

  /// The weekday the calendar's weeks start on — a `DateTime.monday`…
  /// `DateTime.sunday` value, Sunday by default. Forwarded to the inner
  /// `Calendar`; see [CoreCalendarContract.firstDayOfWeek].
  @override
  final int firstDayOfWeek;

  /// Per-date-cell state builder, forwarded to the inner `Calendar` so a
  /// caller can disable / mark individual days (Flutter
  /// `DatePicker.stateBuilder` parity — the callback type lives in
  /// `coui_core`, so both platforms take the same one).
  final CoreCalendarDateStateBuilder? stateBuilder;

  /// Returns a copy of this [DatePicker] with the given fields
  /// replaced. All fields default to this instance's current value
  /// when omitted.
  DatePicker copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    String? placeholder,
    Component? placeholderWidget,
    bool? enabled,
    CoreValueChanged<String?>? onChanged,
    String? min,
    String? max,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? description,
    String? errorText,
    String? value,
    CoreCalendarView? initialView,
    int? firstDayOfWeek,
    CoreCalendarDateStateBuilder? stateBuilder,
    CorePromptMode? mode,
    CorePopoverPlacement? popoverPlacement,
    Component? dialogTitle,
    CoreDatePickerStyle? datePickerStyle,
  }) {
    return DatePicker(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      placeholder: placeholder ?? this.placeholder,
      placeholderWidget: placeholderWidget ?? this.placeholderWidget,
      enabled: enabled ?? this.enabled,
      min: min ?? this.min,
      max: max ?? this.max,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      description: description ?? this.description,
      errorText: errorText ?? this.errorText,
      value: value ?? this.value,
      initialView: initialView ?? this.initialView,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      stateBuilder: stateBuilder ?? this.stateBuilder,
      mode: mode ?? this.mode,
      popoverPlacement: popoverPlacement ?? this.popoverPlacement,
      dialogTitle: dialogTitle ?? this.dialogTitle,
      datePickerStyle: datePickerStyle ?? this.datePickerStyle,
    );
  }

  @override
  State<DatePicker> createState() => _DatePickerState();
}

/// Chain sugar for merging a [CoreDatePickerStyle] patch into
/// [DatePicker.datePickerStyle] without hand-reconstructing every
/// field. Mirrors the Flutter `DatePicker.withStyle` extension so
/// both platforms read identically.
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

class _DatePickerState extends State<DatePicker> {
  /// Imperative controller for the unified [Popover] hosting the
  /// calendar — used to close the popover after a date is picked.
  final _popoverController = PopoverController();

  /// Internal value — the picker is uncontrolled by default and only
  /// emits via `onChanged`. When [DatePicker.value] is provided it
  /// acts as the initial value and is mirrored into [_value].
  String? _value;

  /// Pending value for the dialog mode. The dialog only commits to
  /// [_value] (and fires `onChanged`) when the user clicks `Save`.
  String? _pending;

  /// Whether the dialog is currently shown — drives [Dialog.open].
  bool _dialogOpen = false;

  /// Stable scope id so the `<div>` root has a deterministic anchor
  /// (useful for tests / focus management).
  late final String _scopeId;

  @override
  void initState() {
    super.initState();
    _value = component.value;
    _scopeId = 'co-date-picker-${_coDatePickerIdCounter++}';
  }

  // ─────────────────────────── ISO helpers ──────────────────────────

  String _formatIso(DateTime date) {
    final y = date.year.toString().padLeft(_kYearPadWidth, '0');
    final m = date.month.toString().padLeft(_kMonthDayPadWidth, '0');
    final d = date.day.toString().padLeft(_kMonthDayPadWidth, '0');
    return '$y-$m-$d';
  }

  DateTime? _parseIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parts = iso.split('-');
    if (parts.length != _kDateParts) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  String _displayFormat(String iso) {
    final parts = iso.split('-');
    if (parts.length == _kDateParts) {
      return '${parts[0]}-${parts[1]}-${parts[2]}';
    }
    return iso;
  }

  CorePromptMode get _resolvedMode => component.mode ?? .popover;

  // ─────────────────────────── handlers ─────────────────────────────

  /// Popover-mode calendar pick — commits immediately and closes the
  /// popover. Dialog mode uses [_handleDialogPick] / [_handleDialogSave]
  /// instead.
  void handlePopoverPick(CoreCalendarValue? v) {
    final next = _isoFromCalendarValue(v);
    setState(() {
      _value = next;
    });
    // Brief delay so the user sees the selected highlight before
    // the popover dismisses (shadcn-ui parity).
    unawaited(
      Future.delayed(_kPopoverDismissDelay, _popoverController.close),
    );
    // A null payload is the user clearing the selection — tapping the
    // selected day deselects it — not "nothing happened". Swallowing it
    // left the host's state and the picker's permanently out of step,
    // with no way for the host to observe the divergence. Flutter has
    // always reported it; the range twin below already does too.
    component.onChanged?.call(next);
  }

  void _handleDialogPick(CoreCalendarValue? v) {
    setState(() {
      _pending = _isoFromCalendarValue(v);
    });
  }

  void _handleDialogSave() {
    final committed = _pending ?? _value;
    setState(() {
      _value = committed;
      _dialogOpen = false;
    });
    component.onChanged?.call(committed);
  }

  void _handleDialogCancel() {
    setState(() {
      _dialogOpen = false;
      _pending = null;
    });
  }

  void _handleDialogOpen() {
    if (!component.enabled) return;
    setState(() {
      _pending = _value;
      _dialogOpen = true;
    });
  }

  String? _isoFromCalendarValue(CoreCalendarValue? v) {
    if (v is CoreSingleCalendarValue) return _formatIso(v.date);
    if (v is CoreRangeCalendarValue) return _formatIso(v.start);
    return null;
  }

  // ─────────────────────────── render ───────────────────────────────

  Component _buildCalendar({
    required CoreValueChanged<CoreCalendarValue?> onChanged,
    required String? value,
    required CoreCalendarStyle? calendarStyle,
  }) {
    return Calendar(
      onChanged: onChanged,
      selectionMode: .single,
      value: value == null
          ? null
          : (_parseIso(value) != null
                ? CoreCalendarValue.single(_parseIso(value)!)
                : null),
      initialView: component.initialView,
      firstDayOfWeek: component.firstDayOfWeek,
      stateBuilder: component.stateBuilder,
      minDate: _parseIso(component.min),
      maxDate: _parseIso(component.max),
      calendarStyle: calendarStyle,
    );
  }

  // ─────────────────────────── lifecycle ────────────────────────────

  @override
  void didUpdateComponent(DatePicker oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.value != component.value) {
      _value = component.value;
    }
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveDatePicker(
      context,
      datePickerStyle: component.datePickerStyle,
      enabled: component.enabled,
    );

    final currentValue = _value;
    final hasValue = currentValue != null && currentValue.isNotEmpty;
    final currentLabel = component.label;
    final currentDescription = component.description;
    final currentError = component.errorText;
    final hasError = currentError != null && currentError.isNotEmpty;
    final effectivePlaceholder =
        component.placeholder ??
        CouiLocalizations.of(context).placeholderDatePicker;
    final mode = _resolvedMode;

    // Display text on the trigger.
    final displayText = hasValue
        ? _displayFormat(currentValue)
        : effectivePlaceholder;

    // The trigger is a read-only `TextField` — the TimePicker / Select input
    // look (height 40, corner 10, `outline-variant` edge that turns `primary`
    // on focus and `error` while the picker holds an error, Regular 14 value,
    // the calendar in the suffix seat). `readOnly` keeps the caret and the
    // keyboard away while leaving it focusable and tappable: the value is
    // chosen in the calendar, not typed. In popover mode the wrapping
    // `Popover` opens on the click; dialog mode opens its own. The error
    // message is the picker's own row below, so the field is only told the
    // tone (through the ambient validation state), not the text. Part of
    // this composite: walled off from the enclosing `FormField`, which is
    // shown the composite's own value.
    Component trigger = FormFieldHandleScope.boundary(
      child: TextField(
        onTap: (mode == .dialog && component.enabled)
            ? _handleDialogOpen
            : null,
        value: hasValue ? displayText : '',
        // Custom placeholder component takes precedence over the
        // placeholder string (Flutter `placeholderWidget` parity).
        placeholder: hasValue
            ? null
            : (component.placeholderWidget ?? Text(displayText)),
        enabled: component.enabled,
        readOnly: true,
        showCursor: false,
        textFieldStyle: resolved.triggerStyle,
        suffix: Icon(
          LucideIcons.calendar,
          iconStyle: resolved.trailingIconStyle,
        ),
      ),
    );
    if (hasError && component.enabled) {
      trigger = ValidationStateScope(
        state: CoreValidationState.invalid,
        child: trigger,
      );
    }

    // Trigger surface depends on mode. Popover wraps the trigger in
    // Popover; dialog renders the trigger inline alongside the
    // Dialog instance (which mounts itself onto the overlay host
    // when [open] is true).
    final Component triggerSurface;
    if (!component.enabled) {
      triggerSurface = trigger;
    } else if (mode == .popover) {
      triggerSurface = Popover(
        trigger: trigger,
        content: _buildCalendar(
          onChanged: handlePopoverPick,
          value: _value,
          calendarStyle: resolved.calendarStyle,
        ),
        placement: component.popoverPlacement,
        controller: _popoverController,
        popoverStyle: resolved.popoverStyle,
      );
    } else {
      // Always-mount the Dialog and let `open: _dialogOpen` drive
      // the portal lifecycle — `if (_dialogOpen) Dialog(...)`
      // would tear down + remount the dialog component each open,
      // and the inner `_isMounted` / `_overlayController` /
      // `_overlayToken` reset would drop the action button event
      // listeners and barrier click handler. Always-mounted matches
      // the dialog preview pattern in `dialog_default_example.dart`.
      triggerSurface = div(
        [
          trigger,
          Dialog(
            title: component.dialogTitle,
            // Calendar root 가 `inline-flex` 라 dialog content
            // stretch 영역에서도 자기 자연 width 로 좌측 정렬됨.
            // `flex justify-center` wrapper 로 가운데 정렬.
            content: div(
              [
                _buildCalendar(
                  onChanged: _handleDialogPick,
                  value: _pending ?? _value,
                  calendarStyle: resolved.calendarStyle,
                ),
              ],
              classes: resolved.dialogContentWrap.className,
              styles: resolved.dialogContentWrap.inlineStyles,
            ),
            actions: [
              Button(
                onPressed: _handleDialogCancel,
                variant: .secondary,
                child: Text(CouiLocalizations.of(context).buttonCancel),
              ),
              Button(
                onPressed: _handleDialogSave,
                variant: .primary,
                child: Text(CouiLocalizations.of(context).buttonSave),
              ),
            ],
            open: _dialogOpen,
            onClose: _handleDialogCancel,
            dialogStyle: resolved.dialogStyle,
          ),
        ],
      );
    }

    final attrs = <String, String>{...component.componentAttributes};
    if (!component.enabled) {
      attrs['aria-disabled'] = 'true';
    }
    if (hasError) {
      attrs['aria-invalid'] = 'true';
    }

    final rootChildren = <Component>[];
    if (currentLabel != null && currentLabel.isNotEmpty) {
      rootChildren.add(
        div(
          [
            Text(
              currentLabel,
              maxLines: component.labelMaxLines,
              overflow: component.labelOverflow,
            ),
          ],
          classes: resolved.label.className,
          styles: resolved.label.inlineStyles,
        ),
      );
      rootChildren.add(Gap(gapStyle: resolved.labelBottomGapStyle));
    }
    rootChildren.add(triggerSurface);
    if (hasError) {
      rootChildren.add(Gap(gapStyle: resolved.descriptionTopGapStyle));
      rootChildren.add(
        div(
          [Text(currentError)],
          classes: resolved.error.className,
          styles: resolved.error.inlineStyles,
        ),
      );
    } else if (currentDescription != null && currentDescription.isNotEmpty) {
      rootChildren.add(Gap(gapStyle: resolved.descriptionTopGapStyle));
      rootChildren.add(
        div(
          [Text(currentDescription)],
          classes: resolved.description.className,
          styles: resolved.description.inlineStyles,
        ),
      );
    }

    // Root container — `flex flex-col` for label / trigger / description
    // stack. Composed via `resolved.root` so the
    // `flex flex-col w-full` layout chrome lives in the resolver. The
    // inter-row gaps are inserted as `Gap` siblings between rows
    // (Flutter parity). No `overflow-hidden` (would clip the popover
    // when it wasn't portaled), no `relative` (Popover portals to the
    // overlay host so positioning isn't local).
    return div(
      rootChildren,
      id: component.id ?? _scopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: resolved.root.inlineStyles == null
          ? component.css
          : Styles.combine([resolved.root.inlineStyles!, ?component.css]),
      attributes: attrs,
      events: component.events,
    );
  }
}

// =============================================================================
// DateRangePicker — Web parity with Flutter `DateRangePicker`
// =============================================================================

/// Process-level counter for unique scope ids on the range picker.
int _coDateRangePickerIdCounter = 0;

/// Unified date-range picker for CoUI Web.
///
/// Implements [CoreDateRangePickerContract] (1:1 with Flutter
/// `DateRangePicker`). Renders a field-style trigger that opens a
/// [Calendar] in range selection mode, presented either as a
/// [Popover] under the trigger or a centred [Dialog] modal.
class DateRangePicker extends UiStatefulComponent
    implements
        CoreDateRangePickerContract<
          Component,
          CoreValueChanged<({String start, String end})?>?
        > {
  /// Creates a [DateRangePicker].
  const DateRangePicker({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.value,
    this.onChanged,
    this.placeholder,
    this.enabled = true,
    this.min,
    this.max,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.errorText,
    this.mode,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.popoverPlacement = CorePopoverPlacement.bottomStart,
    this.dialogTitle,
    this.dateRangePickerStyle,
  }) : assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  // === Contract fields ===

  @override
  final Component? placeholder;

  @override
  final bool enabled;

  @override
  final CoreValueChanged<({String start, String end})?>? onChanged;

  @override
  final String? min;

  @override
  final String? max;

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

  /// Placement of the popover panel relative to the trigger (popover
  /// mode only). Defaults to bottom-start — the picker-family
  /// convention (panel's left edge lines up with the trigger's).
  @override
  final CorePopoverPlacement popoverPlacement;

  /// The weekday the calendar's weeks start on — a `DateTime.monday`…
  /// `DateTime.sunday` value, Sunday by default. Forwarded to the inner
  /// `Calendar`; see [CoreCalendarContract.firstDayOfWeek].
  @override
  final int firstDayOfWeek;

  @override
  final Component? dialogTitle;

  @override
  final CoreDatePickerStyle? dateRangePickerStyle;

  // === Extended fields ===

  /// Current value (`(start, end)` ISO date pair).
  final ({String start, String end})? value;

  /// Per-date-cell state builder, forwarded to the inner `Calendar` so a
  /// caller can disable / mark individual days (Flutter
  /// `DateRangePicker.stateBuilder` parity — the callback type lives in
  /// `coui_core`, so both platforms take the same one).
  final CoreCalendarDateStateBuilder? stateBuilder;

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  final _popoverController = PopoverController();
  ({String start, String end})? _value;
  ({String start, String end})? _pending;
  bool _dialogOpen = false;
  late final String _scopeId;

  @override
  void initState() {
    super.initState();
    _value = component.value;
    _scopeId = 'co-date-range-picker-${_coDateRangePickerIdCounter++}';
  }

  String _formatIso(DateTime date) {
    final y = date.year.toString().padLeft(_kYearPadWidth, '0');
    final m = date.month.toString().padLeft(_kMonthDayPadWidth, '0');
    final d = date.day.toString().padLeft(_kMonthDayPadWidth, '0');
    return '$y-$m-$d';
  }

  DateTime? _parseIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parts = iso.split('-');
    if (parts.length != _kDateParts) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  ({String start, String end})? _rangeFromCalendarValue(CoreCalendarValue? v) {
    if (v is CoreRangeCalendarValue) {
      return (start: _formatIso(v.start), end: _formatIso(v.end));
    }
    return null;
  }

  CorePromptMode get _resolvedMode =>
      component.mode ?? .dialog; // Flutter default mirror.

  void handlePopoverPick(CoreCalendarValue? v) {
    // Calendar in range mode emits twice per pick cycle:
    //   1) first tap → `CoreSingleCalendarValue(start)` (intermediate)
    //   2) second tap → `CoreRangeCalendarValue(start, end)` (committed)
    // Only commit + close on the range emission; treat the
    // intermediate single-value as a no-op so the popover stays open
    // for the second tap.
    if (v is! CoreRangeCalendarValue && v != null) {
      return;
    }
    final next = _rangeFromCalendarValue(v);
    setState(() {
      _value = next;
    });
    // Brief delay so the user sees the committed range highlight
    // before the popover dismisses (shadcn-ui parity).
    unawaited(
      Future.delayed(_kPopoverDismissDelay, _popoverController.close),
    );
    final cb = component.onChanged;
    if (cb != null) cb(next);
  }

  void _handleDialogPick(CoreCalendarValue? v) {
    setState(() {
      _pending = _rangeFromCalendarValue(v);
    });
  }

  void _handleDialogSave() {
    final committed = _pending ?? _value;
    setState(() {
      _value = committed;
      _dialogOpen = false;
    });
    final cb = component.onChanged;
    if (cb != null) cb(committed);
  }

  void _handleDialogCancel() {
    setState(() {
      _dialogOpen = false;
      _pending = null;
    });
  }

  void _handleDialogOpen() {
    if (!component.enabled) return;
    setState(() {
      _pending = _value;
      _dialogOpen = true;
    });
  }

  Component _buildCalendar({
    required CoreValueChanged<CoreCalendarValue?> onChanged,
    required ({String start, String end})? value,
    required CoreCalendarStyle? calendarStyle,
  }) {
    return Calendar(
      onChanged: onChanged,
      selectionMode: .range,
      value: value == null
          ? null
          : (() {
              final s = _parseIso(value.start);
              final e = _parseIso(value.end);
              if (s == null || e == null) return null;
              return CoreCalendarValue.range(s, e);
            })(),
      firstDayOfWeek: component.firstDayOfWeek,
      stateBuilder: component.stateBuilder,
      minDate: _parseIso(component.min),
      maxDate: _parseIso(component.max),
      calendarStyle: calendarStyle,
    );
  }

  String _formatRangeDisplay(({String start, String end}) range) {
    return '${range.start} - ${range.end}';
  }

  // ─────────────────────────── lifecycle ────────────────────────────

  @override
  void didUpdateComponent(DateRangePicker oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.value != component.value) {
      _value = component.value;
    }
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final currentValue = _value;
    final hasValue = currentValue != null;
    final currentLabel = component.label;
    final currentDescription = component.description;
    final currentError = component.errorText;
    final hasError = currentError != null && currentError.isNotEmpty;
    final mode = _resolvedMode;

    final resolved = resolveDatePicker(
      context,
      datePickerStyle: component.dateRangePickerStyle,
      enabled: component.enabled,
    );

    // Range picker accepts a `Component?` placeholder so callers can inject
    // anything they want; the default placeholder is the single-date one.
    // The range trigger is the same read-only `TextField` as the single
    // picker's, with the range glyph in the suffix seat (see the single
    // picker for the error tone).
    final Component? fieldPlaceholder;
    if (hasValue) {
      fieldPlaceholder = null;
    } else if (component.placeholder != null) {
      fieldPlaceholder = component.placeholder;
    } else {
      // No dedicated range-placeholder localization member yet — reuses
      // the single-date placeholder in the interim.
      fieldPlaceholder = Text(
        CouiLocalizations.of(context).placeholderDatePicker,
      );
    }
    Component trigger = FormFieldHandleScope.boundary(
      child: TextField(
        onTap: (mode == .dialog && component.enabled)
            ? _handleDialogOpen
            : null,
        value: hasValue ? _formatRangeDisplay(currentValue) : '',
        placeholder: fieldPlaceholder,
        enabled: component.enabled,
        readOnly: true,
        showCursor: false,
        textFieldStyle: resolved.triggerStyle,
        suffix: Icon(
          LucideIcons.calendarRange,
          iconStyle: resolved.trailingIconStyle,
        ),
      ),
    );
    if (hasError && component.enabled) {
      trigger = ValidationStateScope(
        state: CoreValidationState.invalid,
        child: trigger,
      );
    }

    final Component triggerSurface;
    if (!component.enabled) {
      triggerSurface = trigger;
    } else if (mode == .popover) {
      triggerSurface = Popover(
        trigger: trigger,
        content: _buildCalendar(
          onChanged: handlePopoverPick,
          value: _value,
          calendarStyle: resolved.calendarStyle,
        ),
        placement: component.popoverPlacement,
        controller: _popoverController,
        popoverStyle: resolved.popoverStyle,
      );
    } else {
      // Always-mount the Dialog (see DatePicker comment) so the
      // portal entry survives open/close cycles instead of being
      // torn down on every dismiss.
      triggerSurface = div(
        [
          trigger,
          Dialog(
            title: component.dialogTitle,
            // Calendar root 가 `inline-flex` 라 dialog content
            // stretch 영역에서도 자기 자연 width 로 좌측 정렬됨.
            // `flex justify-center` wrapper 로 가운데 정렬.
            content: div(
              [
                _buildCalendar(
                  onChanged: _handleDialogPick,
                  value: _pending ?? _value,
                  calendarStyle: resolved.calendarStyle,
                ),
              ],
              classes: resolved.dialogContentWrap.className,
              styles: resolved.dialogContentWrap.inlineStyles,
            ),
            actions: [
              Button(
                onPressed: _handleDialogCancel,
                variant: .secondary,
                child: Text(CouiLocalizations.of(context).buttonCancel),
              ),
              Button(
                onPressed: _handleDialogSave,
                variant: .primary,
                child: Text(CouiLocalizations.of(context).buttonSave),
              ),
            ],
            open: _dialogOpen,
            onClose: _handleDialogCancel,
            dialogStyle: resolved.dialogStyle,
          ),
        ],
      );
    }

    final attrs = <String, String>{...component.componentAttributes};
    if (!component.enabled) attrs['aria-disabled'] = 'true';
    if (hasError) attrs['aria-invalid'] = 'true';

    final rootChildren = <Component>[];
    if (currentLabel != null && currentLabel.isNotEmpty) {
      rootChildren.add(
        div(
          [
            Text(
              currentLabel,
              maxLines: component.labelMaxLines,
              overflow: component.labelOverflow,
            ),
          ],
          classes: resolved.label.className,
          styles: resolved.label.inlineStyles,
        ),
      );
      rootChildren.add(Gap(gapStyle: resolved.labelBottomGapStyle));
    }
    rootChildren.add(triggerSurface);
    if (hasError) {
      rootChildren.add(Gap(gapStyle: resolved.descriptionTopGapStyle));
      rootChildren.add(
        div(
          [Text(currentError)],
          classes: resolved.error.className,
          styles: resolved.error.inlineStyles,
        ),
      );
    } else if (currentDescription != null && currentDescription.isNotEmpty) {
      rootChildren.add(Gap(gapStyle: resolved.descriptionTopGapStyle));
      rootChildren.add(
        div(
          [Text(currentDescription)],
          classes: resolved.description.className,
          styles: resolved.description.inlineStyles,
        ),
      );
    }

    return div(
      rootChildren,
      id: component.id ?? _scopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: resolved.root.inlineStyles == null
          ? component.css
          : Styles.combine([resolved.root.inlineStyles!, ?component.css]),
      attributes: attrs,
      events: component.events,
    );
  }
}

/// Chain sugar for merging a [CoreDatePickerStyle] patch into
/// [DateRangePicker.dateRangePickerStyle] without hand-reconstructing
/// every field. Mirrors the Flutter `DateRangePicker.withStyle`
/// extension so both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDatePickerStyle.merge` right-side-wins semantics).
extension DateRangePickerStyleChain on DateRangePicker {
  /// Returns a copy of this [DateRangePicker] with [patch] merged into
  /// [dateRangePickerStyle] (patch fields win on conflict).
  DateRangePicker withStyle(CoreDatePickerStyle patch) => .new(
    key: this.key,
    onClick: this.onClick,
    onChanged: this.onChanged,
    attributes: userAttributes,
    classes: this.classes,
    css: this.css,
    eventHandlers: this.eventHandlers,
    id: this.id,
    onChange: this.onChange,
    onInput: this.onInput,
    onKeyDown: this.onKeyDown,
    onKeyUp: this.onKeyUp,
    onMouseEnter: this.onMouseEnter,
    onMouseLeave: this.onMouseLeave,
    value: this.value,
    placeholder: this.placeholder,
    enabled: this.enabled,
    min: this.min,
    max: this.max,
    label: this.label,
    labelMaxLines: labelMaxLines,
    labelOverflow: labelOverflow,
    description: this.description,
    errorText: this.errorText,
    mode: this.mode,
    popoverPlacement: this.popoverPlacement,
    dialogTitle: this.dialogTitle,
    dateRangePickerStyle:
        (this.dateRangePickerStyle ?? const CoreDatePickerStyle()).merge(
          patch,
        ),
  );
}

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/overlay/coui_web_dom.dart';
import 'package:universal_web/web.dart' as web;

/// Which numeric segment a focus event belongs to.
///
/// The segments are built by one shared helper, so the focused face needs a
/// way to say *which* of them is edited — a single `bool` would mark all
/// three at once.
enum _TimeSegment { hour, minute, second }

/// Unified cross-platform time picker for CoUI Web.
///
/// Renders a bordered trigger resembling a text field with a trailing clock
/// icon. Clicking the trigger opens a [Popover] panel containing numeric
/// hour/minute (and optional seconds) fields separated by `:`, plus an
/// AM/PM toggle column when in 12-hour mode, and Cancel/Save action
/// buttons rendered with [Button].
///
/// Parameter names and semantics match the Flutter [TimePicker]
/// one-to-one. Per Epic #1302 원칙 6/7/8, semantic enums (`mode` /
/// `use24HourFormat`) and behaviour fields (`placeholder` / `enabled` /
/// `showSeconds` / `min` / `max` / `onChanged` / `dialogTitle` /
/// `errorText`) stay flat on the component. All chrome / dimensional /
/// nested-slot overrides flow through the single [timePickerStyle]
/// (a [CoreTimePickerStyle]):
///
/// ```text
/// design system default for time picker
///   → CoreTimePickerTheme.style
///   → component.timePickerStyle
/// ```
///
/// Values are exchanged as ISO time strings — `HH:MM` (or `HH:MM:SS`
/// when [showSeconds] is true).
///
/// ```dart
/// TimePicker(
///   value: '14:30',
///   onChanged: (time) => print('Selected: $time'),
/// )
/// ```
class TimePicker extends UiStatefulComponent
    implements CoreTimePickerContract<Component> {
  /// Creates a [TimePicker].
  const TimePicker({
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
    this.onChanged,
    this.value,
    this.placeholder,
    this.placeholderSegment = CoreTimePickerContract.defaultPlaceholderSegment,
    this.placeholderSeparator =
        CoreTimePickerContract.defaultPlaceholderSeparator,
    this.enabled = true,
    this.showSeconds = false,
    this.use24HourFormat,
    this.minuteInterval = CoreTimePickerContract.defaultMinuteInterval,
    this.min,
    this.max,
    this.mode,
    this.popoverPlacement = CorePopoverPlacement.bottomStart,
    this.dialogTitle,
    this.errorText,
    this.timePickerStyle,
  }) : assert(
         minuteInterval > 0 && Duration.minutesPerHour % minuteInterval == 0,
         'minuteInterval must divide an hour '
         '(1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60)',
       );

  // === Contract fields ===

  @override
  final String? value;

  @override
  final String? placeholder;

  @override
  final String placeholderSegment;

  @override
  final String placeholderSeparator;

  @override
  final bool enabled;

  @override
  final bool showSeconds;

  @override
  final bool? use24HourFormat;

  /// The step of the minute segment in minutes — a divisor of an hour.
  /// See [CoreTimePickerContract.minuteInterval] for what it decides.
  @override
  final int minuteInterval;

  @override
  final String? min;

  @override
  final String? max;

  @override
  final CoreValueChanged<String>? onChanged;

  /// Render shape — anchored popover (default) or centred modal dialog.
  ///
  /// When null, defaults to [CorePromptMode.popover].
  @override
  final CorePromptMode? mode;

  /// Placement of the popover panel relative to the trigger (popover
  /// mode only). Defaults to bottom-start — the picker-family
  /// convention (panel's left edge lines up with the trigger's).
  @override
  final CorePopoverPlacement popoverPlacement;

  /// Title widget rendered in the dialog header when [mode] is
  /// [CorePromptMode.dialog].
  @override
  final Component? dialogTitle;

  /// Optional error message — when non-null and non-empty, the trigger
  /// renders with the error border colour (parity with
  /// `TextField.errorText`).
  @override
  final String? errorText;

  /// Per-instance composite Style — covers popover / dialog / segment
  /// input / am-pm button slot styles plus label / description / error
  /// text styles. See [CoreTimePickerStyle] for the merge chain.
  @override
  final CoreTimePickerStyle? timePickerStyle;

  /// Returns a copy of this [TimePicker] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  TimePicker copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    CoreValueChanged<String>? onChanged,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    String? value,
    String? placeholder,
    String? placeholderSegment,
    String? placeholderSeparator,
    bool? enabled,
    bool? showSeconds,
    bool? use24HourFormat,
    int? minuteInterval,
    String? min,
    String? max,
    CorePromptMode? mode,
    CorePopoverPlacement? popoverPlacement,
    Component? dialogTitle,
    String? errorText,
    CoreTimePickerStyle? timePickerStyle,
  }) {
    return TimePicker(
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
      value: value ?? this.value,
      placeholder: placeholder ?? this.placeholder,
      placeholderSegment: placeholderSegment ?? this.placeholderSegment,
      placeholderSeparator: placeholderSeparator ?? this.placeholderSeparator,
      enabled: enabled ?? this.enabled,
      showSeconds: showSeconds ?? this.showSeconds,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      minuteInterval: minuteInterval ?? this.minuteInterval,
      min: min ?? this.min,
      max: max ?? this.max,
      mode: mode ?? this.mode,
      popoverPlacement: popoverPlacement ?? this.popoverPlacement,
      dialogTitle: dialogTitle ?? this.dialogTitle,
      errorText: errorText ?? this.errorText,
      timePickerStyle: timePickerStyle ?? this.timePickerStyle,
    );
  }

  @override
  State<TimePicker> createState() => _TimePickerState();

  /// Builds the `--:--` / `--:--:--` placeholder using the widget's
  /// [placeholderSegment] / [placeholderSeparator] — both default to
  /// [CoreTimePickerContract.defaultPlaceholderSegment] /
  /// [defaultPlaceholderSeparator] via the const constructor.
  static String _buildPlaceholderFormat({
    required bool withSeconds,
    required String segment,
    required String separator,
  }) {
    final base = '$segment$separator$segment';
    if (withSeconds) {
      return '$base$separator$segment';
    }
    return base;
  }

  /// Formats a stored 24h ISO time string into a display string.
  ///
  /// When [use24Hour] is true, the input is returned as-is. Otherwise the
  /// hour segment is converted to 12-hour format with an `AM`/`PM`
  /// suffix.
  static String _formatDisplayValue(String raw, {required bool use24Hour}) {
    if (use24Hour) return raw;
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]);
    if (hour == null) return raw;
    final isPm = hour >= IsoTime.maxHour12;
    int hour12 = hour % IsoTime.maxHour12;
    if (hour12 == 0) hour12 = IsoTime.maxHour12;
    final hh = IsoTime.padTwo(hour12);
    final minute = parts[1];
    final suffix = isPm ? 'PM' : 'AM';
    if (parts.length > 2) {
      final second = parts[2];
      return '$hh:$minute:$second $suffix';
    }
    return '$hh:$minute $suffix';
  }
}

/// Chain sugar for merging a [CoreTimePickerStyle] patch into
/// [TimePicker.timePickerStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `TimePicker.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTimePickerStyle.merge` right-side-wins semantics).
extension TimePickerStyleChain on TimePicker {
  /// Returns a copy of this [TimePicker] with [patch] merged into
  /// [timePickerStyle] (patch fields win on conflict).
  TimePicker withStyle(CoreTimePickerStyle patch) => copyWith(
    timePickerStyle: (timePickerStyle ?? const CoreTimePickerStyle()).merge(
      patch,
    ),
  );
}

class _TimePickerState extends State<TimePicker> {
  static String _formatDigits(int value) => IsoTime.padTwo(value);
  static _TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final second = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    return _TimeOfDay(hour: hour, minute: minute, second: second);
  }

  static String _formatTimeOfDay(_TimeOfDay tod, {required bool withSeconds}) {
    final h = IsoTime.padTwo(tod.hour);
    final m = IsoTime.padTwo(tod.minute);
    if (withSeconds) {
      final s = IsoTime.padTwo(tod.second);
      return '$h:$m:$s';
    }
    return '$h:$m';
  }

  static String _sanitizeDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 2) return digits;
    return digits.substring(0, 2);
  }

  final PopoverController _popoverController = PopoverController();

  /// Which segment currently holds focus, driving that segment's focused
  /// face.
  ///
  /// Plain focus, not `:focus-visible` — the Flutter twin takes the face on
  /// `FocusNode.hasFocus`, so gating this on keyboard-originated focus
  /// would make a pointer click mark one platform and not the other.
  _TimeSegment? _focusedSegment;

  /// Whether the dialog is currently shown — drives [Dialog.open] when
  /// [TimePicker.mode] is [CorePromptMode.dialog].
  bool _dialogOpen = false;

  late String _hourText;

  late String _minuteText;

  late String _secondText;

  late bool _pm;

  bool get _isEnabled => component.enabled;

  @override
  void initState() {
    super.initState();
    _syncFromValue();
  }

  void _syncFromValue() {
    final parsed = _parseTimeString(component.value);
    // Mirrors Flutter's `MediaQuery.alwaysUse24HourFormatOf` capability:
    // the browser locale decides the hour cycle (SSR stub answers 24h,
    // the hydrated client resolves the real `Intl` preference).
    final resolvedUse24Hour = component.use24HourFormat ?? !prefersHour12Format;

    final initialHour = parsed?.hour ?? 0;
    final initialMinute = parsed?.minute ?? 0;
    final initialSecond = parsed?.second ?? 0;

    bool pm = initialHour >= IsoTime.maxHour12;
    int displayHour = initialHour;
    if (!resolvedUse24Hour) {
      if (initialHour == 0) {
        displayHour = IsoTime.maxHour12;
        pm = false;
      } else if (initialHour > IsoTime.maxHour12) {
        displayHour = initialHour - IsoTime.maxHour12;
      } else if (initialHour == IsoTime.maxHour12) {
        displayHour = IsoTime.maxHour12;
        pm = true;
      }
    }
    _pm = pm;
    _hourText = _formatDigits(displayHour);
    _minuteText = _formatDigits(initialMinute);
    _secondText = _formatDigits(initialSecond);
  }

  _TimeOfDay _currentValue({required bool use24Hour}) {
    int hour = int.tryParse(_hourText) ?? 0;
    int minute = int.tryParse(_minuteText) ?? 0;
    int second = int.tryParse(_secondText) ?? 0;
    if (use24Hour) {
      hour = hour.clamp(0, IsoTime.maxHour24);
    } else {
      final hour12 = hour.clamp(0, IsoTime.maxHour12);
      int hour24 = hour12 % IsoTime.maxHour12;
      if (_pm) hour24 += IsoTime.maxHour12;
      hour = hour24;
    }
    // Clamps to :59 like every segment, then snaps to the interval; the top
    // of the hour wraps to :00 and the hour stays as typed.
    minute = CoreMinuteInterval.snap(
      minute,
      interval: component.minuteInterval,
    );
    second = second.clamp(0, IsoTime.maxSecond);
    return _TimeOfDay(hour: hour, minute: minute, second: second);
  }

  Component _buildPopoverContent({
    required BuildContext context,
    required bool showSeconds,
    required bool use24Hour,
    required ResolvedTimePicker resolved,
  }) {
    final localizations = CouiLocalizations.of(context);

    final segmentRow = Component.element(
      tag: 'div',
      classes: resolved.segmentRow.className,
      children: [
        _buildSegmentField(
          context,
          segment: .hour,
          value: _hourText,
          label: localizations.timeHour,
          ariaLabel: localizations.timeHour,
          onInput: handleHourChanged,
          resolved: resolved,
        ),
        _buildSeparator(context, resolved: resolved),
        _buildSegmentField(
          context,
          segment: .minute,
          value: _minuteText,
          label: localizations.timeMinute,
          ariaLabel: localizations.timeMinute,
          onInput: handleMinuteChanged,
          onKeyDown: EventHandlers.createKeyboardEventHandler(
            handleMinuteKeyDown,
          ),
          resolved: resolved,
        ),
        if (showSeconds) ...[
          _buildSeparator(context, resolved: resolved),
          _buildSegmentField(
            context,
            segment: .second,
            value: _secondText,
            label: localizations.timeSecond,
            ariaLabel: localizations.timeSecond,
            onInput: handleSecondChanged,
            resolved: resolved,
          ),
        ],
        if (!use24Hour) ...[
          // Horizontal `Gap` between the segment row and the AM/PM
          // column — mirrors the Flutter widget which inserts a `Gap`
          // with the same nested `dialogOuterGapStyle` slot.
          Gap(gapStyle: resolved.dialogOuterGapStyle),
          _buildAmPmToggle(localizations, resolved: resolved),
        ],
      ],
    );

    final actionRow = Component.element(
      tag: 'div',
      classes: resolved.actionRow.className,
      styles: resolved.actionRow.inlineStyles,
      children: [
        Button(
          onPressed: handleCancel,
          variant: .ghost,
          buttonStyle: resolved.actionButtonStyle,
          child: Text(localizations.buttonCancel),
        ),
        Button(
          onPressed: () =>
              handleSave(showSeconds: showSeconds, use24Hour: use24Hour),
          buttonStyle: resolved.actionButtonStyle,
          child: Text(localizations.buttonSave),
        ),
      ],
    );

    // The panel box (background / border / radius / padding) is drawn by
    // the composed `Popover` (→ `Popup`, popover mode) or `Dialog` (dialog
    // mode) — this content emits only the picker column, so no own surface
    // box (no double-stacked border / radius). The `role: dialog` + label
    // stay on the content so the picker is announced consistently in both
    // modes.
    return Component.element(
      tag: 'div',
      classes: resolved.popoverContent.className,
      attributes: {
        'role': 'dialog',
        'aria-label': CouiLocalizations.of(context).timePickerPopoverLabel,
      },
      children: [
        // The digits fill a fixed-size segment box, so they keep their
        // desktop size at every viewport width — the Flutter twin states
        // the same tier around the same row. Around the row alone: the
        // trigger and the action buttons do not fill a box of their own.
        TypographyTierScope(tier: .desktop, child: segmentRow),
        // Vertical `Gap` between the segment row and the action
        // row — mirrors the Flutter widget which inserts a `Gap`
        // with the same nested `actionRowGapStyle` slot.
        Gap(gapStyle: resolved.actionRowGapStyle),
        actionRow,
      ],
    );
  }

  Component _buildSegmentField(
    BuildContext context, {
    required _TimeSegment segment,
    required String value,
    required String label,
    required String ariaLabel,
    required CoreValueChanged<String> onInput,
    required ResolvedTimePicker resolved,
    EventCallback? onKeyDown,
  }) {
    // The edited segment wears its focused face (no ring) — selected by the
    // focus the widget tracks, like the Flutter twin's `hasFocus`.
    final focused = _focusedSegment == segment;
    return Component.element(
      tag: 'div',
      classes: resolved.segmentField.className,
      children: [
        Component.element(
          tag: 'input',
          classes: resolved.segmentInput.className,
          styles: focused
              ? resolved.segmentInputFocused.inlineStyles
              : resolved.segmentInput.inlineStyles,
          attributes: {
            'type': 'text',
            'inputmode': 'numeric',
            'pattern': '[0-9]*',
            'maxlength': '2',
            'value': value,
            'aria-label': ariaLabel,
            'autocomplete': 'off',
          },
          events: {
            'input': EventHandlers.createInputTargetEventHandler(
              (_, target) => onInput(target.value),
            ),
            // These two read nothing off the event, so they take the
            // raw `Object` callback rather than a typed helper: with no
            // `event.target` dispatch there is nothing for dart2js to
            // minify into a mangled name, which is the failure the
            // typed helpers exist to prevent. Routing them through one
            // anyway would add a `target is HTMLInputElement` test that
            // can only ever drop the event.
            'focus': (Object _) => handleSegmentFocus(segment),
            'blur': (Object _) => handleSegmentBlur(segment),
            // A segment that takes keys of its own (the minute's arrow
            // steps) states its handler; the others stay as they were.
            'keydown': ?onKeyDown,
          },
          children: const [],
        ),
        Component.element(
          tag: 'span',
          classes: resolved.segmentLabel.className,
          styles: resolved.segmentLabel.inlineStyles,
          children: [Text(label)],
        ),
      ],
    );
  }

  Component _buildSeparator(
    BuildContext context, {
    required ResolvedTimePicker resolved,
  }) {
    return Component.element(
      tag: 'div',
      classes: resolved.separator.className,
      styles: resolved.separator.inlineStyles,
      children: const [Text(':')],
    );
  }

  Component _buildAmPmToggle(
    CouiLocalizations localizations, {
    required ResolvedTimePicker resolved,
  }) {
    // The shared grouped toggle (a `surfaceContainerHigh` track with a raised
    // chosen face) — the am/pm choice is one control, not two buttons.
    return Component.element(
      tag: 'div',
      classes: resolved.amPmToggle.className,
      styles: resolved.amPmToggle.inlineStyles,
      children: [
        ToggleGroup<bool>(
          items: [
            CoreToggleGroupItem<bool, Component>(
              value: false,
              label: localizations.timeAM,
            ),
            CoreToggleGroupItem<bool, Component>(
              value: true,
              label: localizations.timePM,
            ),
          ],
          value: _pm,
          onChanged: (isPm) => handleAmPmChanged(isPm: isPm),
          size: CoreTimePickerContract.defaultAmPmToggleSize,
          direction: CoreTimePickerContract.defaultAmPmToggleDirection,
          toggleGroupStyle: resolved.amPmToggleStyle,
        ),
      ],
    );
  }

  void _handleDialogOpen() {
    if (!_isEnabled) return;
    setState(() => _dialogOpen = true);
  }

  @override
  void didUpdateComponent(covariant TimePicker oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.value != component.value) {
      _syncFromValue();
    }
  }

  void handleCancel() {
    if (_resolvedMode == .dialog) {
      setState(() => _dialogOpen = false);
    } else {
      _popoverController.close();
    }
  }

  void handleSave({required bool showSeconds, required bool use24Hour}) {
    final tod = _currentValue(use24Hour: use24Hour);
    final next = _formatTimeOfDay(tod, withSeconds: showSeconds);
    if (_resolvedMode == .dialog) {
      setState(() => _dialogOpen = false);
    } else {
      _popoverController.close();
    }
    component.onChanged?.call(next);
  }

  CorePromptMode get _resolvedMode => component.mode ?? .popover;

  void handleHourChanged(String raw) {
    final digits = _sanitizeDigits(raw);
    setState(() => _hourText = digits);
  }

  void handleMinuteChanged(String raw) {
    final digits = _sanitizeDigits(raw);
    setState(() => _minuteText = digits);
  }

  void handleSecondChanged(String raw) {
    final digits = _sanitizeDigits(raw);
    setState(() => _secondText = digits);
  }

  void handleAmPmChanged({required bool isPm}) {
    setState(() => _pm = isPm);
  }

  void handleSegmentFocus(_TimeSegment segment) {
    setState(() => _focusedSegment = segment);
  }

  /// Clears the ring unconditionally rather than only for the segment
  /// that blurred: the browser fires `blur` on the old element before
  /// `focus` on the new one, so a move between segments still ends with
  /// the new one ringed.
  ///
  /// Leaving the minute segment is also where a typed minute snaps to the
  /// nearest step of `minuteInterval` — the point where typing ends, so a
  /// half-typed `1` on its way to `15` is never rewritten under the cursor.
  /// It rewrites only when snapping actually moves the value, so the default
  /// interval (one minute) never touches what was typed.
  void handleSegmentBlur(_TimeSegment segment) {
    setState(() {
      _focusedSegment = null;
      if (segment == .minute) _snapMinuteText();
    });
  }

  void _snapMinuteText() {
    final typed = int.tryParse(_minuteText);
    if (typed == null) return;
    final snapped = CoreMinuteInterval.snap(
      typed,
      interval: component.minuteInterval,
    );
    if (snapped != typed.clamp(0, IsoTime.maxMinute)) {
      _minuteText = _formatDigits(snapped);
    }
  }

  /// ArrowUp / ArrowDown on the minute segment move it a step of
  /// `minuteInterval`. Any modifier leaves the key to the browser — Shift+Arrow
  /// selects text, Alt/Meta+Arrow moves the caret.
  void handleMinuteKeyDown(web.KeyboardEvent event) {
    if (event.ctrlKey || event.metaKey || event.altKey || event.shiftKey) {
      return;
    }
    final up = switch (event.key) {
      'ArrowUp' => true,
      'ArrowDown' => false,
      _ => null,
    };
    if (up == null) return;
    // The step replaces the caret move the browser would make.
    event.preventDefault();
    handleMinuteStep(up: up);
  }

  /// Moves the minute segment one step of `minuteInterval` — up or down from
  /// where it stands, wrapping at the ends of the hour without touching the
  /// hour segment.
  void handleMinuteStep({required bool up}) {
    final current = int.tryParse(_minuteText) ?? 0;
    final next = up
        ? CoreMinuteInterval.stepUp(current, interval: component.minuteInterval)
        : CoreMinuteInterval.stepDown(
            current,
            interval: component.minuteInterval,
          );
    setState(() => _minuteText = _formatDigits(next));
  }

  @override
  Component build(BuildContext context) {
    // Resolve composite Style through the Epic #1302 nested-merge chain.
    final resolved = resolveTimePicker(
      context,
      timePickerStyle: component.timePickerStyle,
      enabled: _isEnabled && FormFieldScope.maybeOf(context)?.disabled != true,
    );
    // Behaviour bits stay flat on the component.
    final resolvedShowSeconds = component.showSeconds;
    final resolvedUse24Hour = component.use24HourFormat ?? !prefersHour12Format;

    final errorText = component.errorText;
    final hasError = errorText != null && errorText.isNotEmpty;

    final currentValue = component.value;
    final hasValue = currentValue != null && currentValue.isNotEmpty;
    final displayText = hasValue
        ? TimePicker._formatDisplayValue(
            currentValue,
            use24Hour: resolvedUse24Hour,
          )
        : (component.placeholder ??
              TimePicker._buildPlaceholderFormat(
                withSeconds: resolvedShowSeconds,
                segment: component.placeholderSegment,
                separator: component.placeholderSeparator,
              ));

    final mode = _resolvedMode;

    // The trigger is a read-only `TextField` — the DatePicker / Select input
    // look (height 40, corner 10, `outline-variant` edge that turns `primary`
    // on focus, Regular 14 value, the clock in the suffix seat). `readOnly`
    // keeps the caret and the keyboard away while leaving it focusable and
    // tappable: the value is chosen in the panel, not typed. In popover mode
    // the wrapping `Popover` opens on the click; dialog mode opens its own.
    // Part of this composite: walled off from the enclosing `FormField`,
    // which is shown the composite's own value.
    final trigger = FormFieldHandleScope.boundary(
      child: TextField(
        onTap: (mode == .dialog && _isEnabled) ? _handleDialogOpen : null,
        value: hasValue ? displayText : '',
        placeholder: hasValue ? null : Text(displayText),
        enabled: _isEnabled,
        readOnly: true,
        showCursor: false,
        textFieldStyle: resolved.triggerStyle,
        errorText: _isEnabled && hasError ? errorText : null,
        suffix: Icon(LucideIcons.clock, iconStyle: resolved.trailingIconStyle),
      ),
    );

    // Trigger surface depends on mode (mirrors `DatePicker`).
    // Popover wraps the trigger in `Popover`; dialog renders the
    // trigger inline alongside an always-mounted `Dialog`.
    final Component triggerSurface;
    if (!_isEnabled) {
      triggerSurface = trigger;
    } else if (mode == .popover) {
      triggerSurface = Popover(
        trigger: trigger,
        content: _buildPopoverContent(
          context: context,
          showSeconds: resolvedShowSeconds,
          use24Hour: resolvedUse24Hour,
          resolved: resolved,
        ),
        placement: component.popoverPlacement,
        controller: _popoverController,
        popoverStyle: resolved.popoverStyle,
      );
    } else {
      triggerSurface = div([
        trigger,
        // The resolved nested `dialogStyle` slot is forwarded
        // straight to `Dialog(dialogStyle: …)` (render-only) —
        // mirrors `DatePicker`'s dialog branch.
        Dialog(
          title: component.dialogTitle,
          content: _buildPopoverContent(
            context: context,
            showSeconds: resolvedShowSeconds,
            use24Hour: resolvedUse24Hour,
            resolved: resolved,
          ),
          open: _dialogOpen,
          onClose: () => setState(() => _dialogOpen = false),
          dialogStyle: resolved.dialogStyle,
        ),
      ]);
    }

    // Root container — `grid w-full` mirrors `DatePicker` so the
    // trigger fills the inline axis (cross-axis stretch) regardless
    // of how the popover wrapper sizes its own flex item.
    return div(
      [triggerSurface],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}

/// Lightweight time-of-day value (avoids depending on the Web localizations
/// `TimeOfDay` alias to keep this file self-contained).
class _TimeOfDay {
  const _TimeOfDay({required this.hour, required this.minute, this.second = 0});

  final int hour;
  final int minute;
  final int second;
}

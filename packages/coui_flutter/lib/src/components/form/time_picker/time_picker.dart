import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';

/// Unified cross-platform time picker with token-based theming.
///
/// Renders a bordered trigger resembling a text field with a trailing clock
/// icon. Tapping the trigger opens an internal time picker popover with
/// direct numeric input, AM/PM toggle (in 12-hour mode) and optional
/// seconds support.
///
/// Trigger and popover visuals mirror the Web [TimePicker] one-to-one.
///
/// Per Epic #1302 원칙 6/7/8, semantic enums (`mode` / `use24HourFormat`)
/// and behaviour fields (`placeholder` / `enabled` / `showSeconds` /
/// `min` / `max` / `onChanged` / `dialogTitle` / `errorText`) stay flat
/// on the widget. All chrome / dimensional / nested-slot overrides flow
/// through the single [timePickerStyle] (a [CoreTimePickerStyle]):
///
/// ```text
/// design system default for time picker
///   → CoreTimePickerTheme.style
///   → widget.timePickerStyle
/// ```
///
/// Values are exchanged as ISO time strings — `HH:MM` (or `HH:MM:SS`
/// when [showSeconds] is true).
///
/// Example:
/// ```dart
/// TimePicker(
///   value: '14:30',
///   placeholder: 'Select time',
///   onChanged: (v) => print(v),
/// )
/// ```
class TimePicker extends StatefulWidget
    implements CoreTimePickerContract<Widget> {
  /// Creates a [TimePicker].
  const TimePicker({
    super.key,
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
  final ValueChanged<String>? onChanged;

  /// Render shape — anchored popover (default) or centred modal dialog.
  ///
  /// When null, defaults to [CorePromptMode.popover].
  @override
  final CorePromptMode? mode;

  /// Placement of the popover panel relative to the trigger (popover
  /// mode only). Defaults to bottom-start — the picker-family
  /// convention (DatePicker anchors the same way on both platforms).
  @override
  final CorePopoverPlacement popoverPlacement;

  /// Title widget rendered in the dialog header when [mode] is
  /// [CorePromptMode.dialog].
  @override
  final Widget? dialogTitle;

  /// Optional error message — when non-null, the trigger renders with the
  /// error border colour (parity with `TextField.errorText`).
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
    Key? key,
    ValueChanged<String>? onChanged,
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
    Widget? dialogTitle,
    String? errorText,
    CoreTimePickerStyle? timePickerStyle,
  }) {
    return TimePicker(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
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
}

/// Chain sugar for merging a [CoreTimePickerStyle] patch into
/// [TimePicker.timePickerStyle] without hand-reconstructing every field.
/// Mirrors the Web `TimePicker.withStyle` extension so both platforms
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
  /// Builds the `--:--` / `--:--:--` placeholder.
  ///
  /// Joins the widget's `placeholderSegment` / `placeholderSeparator`
  /// glyphs — both default to
  /// `CoreTimePickerContract.defaultPlaceholderSegment` /
  /// `defaultPlaceholderSeparator` via the const constructor.
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

  /// Parses an ISO time string (`HH:MM` or `HH:MM:SS`) into [TimeOfDay].
  static TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final second = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    return TimeOfDay(hour: hour, minute: minute, second: second);
  }

  /// Formats a [TimeOfDay] into an ISO time string.
  static String _formatTimeOfDay(TimeOfDay tod, {required bool withSeconds}) {
    final h = IsoTime.padTwo(tod.hour);
    final m = IsoTime.padTwo(tod.minute);
    if (withSeconds) {
      final s = IsoTime.padTwo(tod.second);
      return '$h:$m:$s';
    }
    return '$h:$m';
  }

  /// Reformats stored 24h ISO value to the display string for the trigger.
  static String _formatDisplayValue(
    String rawValue, {
    required bool use24Hour,
  }) {
    if (use24Hour) return rawValue;
    final tod = _parseTimeString(rawValue);
    if (tod == null) return rawValue;
    final isPm = tod.hour >= IsoTime.maxHour12;
    var hour12 = tod.hour % IsoTime.maxHour12;
    if (hour12 == 0) hour12 = IsoTime.maxHour12;
    final hh = IsoTime.padTwo(hour12);
    final mm = IsoTime.padTwo(tod.minute);
    final suffix = isPm ? 'PM' : 'AM';
    final parts = rawValue.split(':');
    if (parts.length > 2) {
      final ss = IsoTime.padTwo(tod.second);
      return '$hh:$mm:$ss $suffix';
    }
    return '$hh:$mm $suffix';
  }

  final PopoverController _popoverController = PopoverController();

  void _commit(TimeOfDay tod, {required bool withSeconds}) {
    widget.onChanged?.call(_formatTimeOfDay(tod, withSeconds: withSeconds));
    _popoverController.close();
  }

  Future<void> _openDialog(
    BuildContext context, {
    required bool showSeconds,
    required bool use24Hour,
    required int minuteInterval,
    required ResolvedTimePicker resolved,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (dialogContext) {
        // The dialog panel box (background / border / radius / padding) is
        // drawn by the composed `Dialog` component (mirrors `DatePicker`) —
        // the picker content (`_TimePickerPopoverContent`) no longer paints
        // its own surface, so there is no double-stacked box. `Dialog`
        // renders the title; the content emits only the picker column.
        return Dialog(
          title: widget.dialogTitle,
          content: _TimePickerPopoverContent(
            initialValue: _parseTimeString(widget.value),
            materialScheme: scheme,
            showSeconds: showSeconds,
            use24HourFormat: use24Hour,
            minuteInterval: minuteInterval,
            resolved: resolved,
            onCancel: () => Navigator.of(dialogContext).pop(),
            onSave: (tod) => Navigator.of(dialogContext).pop(tod),
          ),
          dialogStyle: resolved.dialogStyle,
        );
      },
    );
    if (result != null) {
      _commit(result, withSeconds: showSeconds);
    }
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Resolve composite Style through the nested-merge chain.
    final resolved = resolveTimePicker(
      context,
      timePickerStyle: widget.timePickerStyle,
      // The trigger field folds the ambient scope into its own `enabled`
      // (an enclosing `Fieldset(enabled: false)` wins); the text colours
      // handed to it follow the same answer.
      enabled:
          widget.enabled && FormFieldScope.maybeOf(context)?.disabled != true,
    );

    // Behaviour bits stay flat on the widget — `showSeconds` /
    // `use24HourFormat` are widget params (not on the Style).
    final resolvedShowSeconds = widget.showSeconds;
    final platformDefault = MediaQuery.alwaysUse24HourFormatOf(context);
    final resolvedUse24Hour = widget.use24HourFormat ?? platformDefault;

    final hasValue = widget.value != null && widget.value!.isNotEmpty;
    final displayText = hasValue
        ? _formatDisplayValue(widget.value!, use24Hour: resolvedUse24Hour)
        : (widget.placeholder ??
              _buildPlaceholderFormat(
                withSeconds: resolvedShowSeconds,
                segment: widget.placeholderSegment,
                separator: widget.placeholderSeparator,
              ));

    final errorText = widget.errorText;
    final hasError = errorText != null && errorText.isNotEmpty;

    final resolvedMode = widget.mode ?? .popover;

    // The trigger is a read-only `TextField` — the DatePicker / Select input
    // look (height 40, corner 10, `outline-variant` edge that turns `primary`
    // on focus, Regular 14 value, the clock in the suffix seat), filling the
    // width its parent gives it.
    // `readOnly` keeps the caret and the keyboard away while leaving it
    // focusable and tappable: the value is chosen in the panel, not typed.
    // Part of this composite: walled off from the enclosing `FormField`,
    // which is shown the composite's own value.
    final triggerButton = Data<FormFieldHandle>.boundary(
      child: TextField(
        onTap: widget.enabled
            ? () {
                if (resolvedMode == .dialog) {
                  unawaited(
                    _openDialog(
                      context,
                      showSeconds: resolvedShowSeconds,
                      use24Hour: resolvedUse24Hour,
                      minuteInterval: widget.minuteInterval,
                      resolved: resolved,
                    ),
                  );
                } else {
                  _popoverController.toggle();
                }
              }
            : null,
        value: hasValue ? displayText : '',
        placeholder: hasValue ? null : Text(displayText),
        enabled: widget.enabled,
        readOnly: true,
        showCursor: false,
        textFieldStyle: resolved.triggerStyle,
        errorText: widget.enabled && hasError ? errorText : null,
        suffix: Icon(
          LucideIcons.clock,
          // Forward the resolved content colour as a `CoreColor` slot so
          // `Icon`'s own resolver runs `scheme.resolve(...).toValue()`
          // once (C7/C8 — no widget-side colour materialisation).
          iconStyle: resolved.trailingIconStyle,
        ),
      ),
    );

    if (resolvedMode == .dialog) {
      return triggerButton;
    }

    final closePopover = _popoverController.close;
    void handleSaveTime(TimeOfDay tod) =>
        _commit(tod, withSeconds: resolvedShowSeconds);
    return Popover(
      trigger: triggerButton,
      content: _TimePickerPopoverContent(
        initialValue: _parseTimeString(widget.value),
        materialScheme: scheme,
        showSeconds: resolvedShowSeconds,
        use24HourFormat: resolvedUse24Hour,
        minuteInterval: widget.minuteInterval,
        resolved: resolved,
        onCancel: closePopover,
        onSave: handleSaveTime,
      ),
      placement: widget.popoverPlacement,
      controller: _popoverController,
      // `manual` so the trigger field's `onTap` (which toggles
      // `_popoverController`) is the single open/close source — without
      // this the `Popover`'s own default `.click` detection would also
      // toggle on the same tap, opening then immediately closing the
      // panel (double-toggle). Mirrors `DatePicker`.
      openTrigger: .manual,
      popoverStyle: resolved.popoverStyle,
    );
  }
}

class _TimePickerPopoverContent extends StatefulWidget {
  const _TimePickerPopoverContent({
    required this.materialScheme,
    required this.initialValue,
    required this.showSeconds,
    required this.use24HourFormat,
    required this.minuteInterval,
    required this.resolved,
    required this.onCancel,
    required this.onSave,
  });

  final ColorScheme materialScheme;
  final TimeOfDay? initialValue;
  final bool showSeconds;
  final bool use24HourFormat;
  final int minuteInterval;
  final ResolvedTimePicker resolved;
  final VoidCallback onCancel;
  final ValueChanged<TimeOfDay> onSave;

  @override
  State<_TimePickerPopoverContent> createState() =>
      _TimePickerPopoverContentState();
}

class _TimePickerPopoverContentState extends State<_TimePickerPopoverContent> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late TextEditingController _secondController;
  // One node per segment so each segment knows whether
  // it is the focused one. The segment fields are the picker's only tab
  // stops inside the panel, and without a ring on them a keyboard user
  // has no indication of which one they are typing into.
  late FocusNode _hourFocusNode;
  late FocusNode _minuteFocusNode;
  late FocusNode _secondFocusNode;
  // The segment the pointer is over (identified by its focus node, which is
  // already the segment's identity here). State DETECTION lives in the
  // widget; the layer it lays is the resolver's `segmentHoverLayerColor`.
  FocusNode? _hoveredSegment;
  late bool _pm;

  static String _formatDigits(int value) => IsoTime.padTwo(value);

  /// Repaints the segment rings when focus moves between segments.
  void handleSegmentFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handleSegmentHoverEnter(FocusNode segment) {
    setState(() => _hoveredSegment = segment);
  }

  void _handleSegmentHoverExit(FocusNode segment) {
    if (identical(_hoveredSegment, segment)) {
      setState(() => _hoveredSegment = null);
    }
  }

  @override
  void initState() {
    super.initState();
    final initialHour = widget.initialValue?.hour ?? 0;
    final initialMinute = widget.initialValue?.minute ?? 0;
    final initialSecond = widget.initialValue?.second ?? 0;
    _pm = initialHour >= IsoTime.maxHour12;
    var displayHour = initialHour;
    if (!widget.use24HourFormat) {
      if (initialHour == 0) {
        displayHour = IsoTime.maxHour12;
        _pm = false;
      } else if (initialHour > IsoTime.maxHour12) {
        displayHour = initialHour - IsoTime.maxHour12;
      } else if (initialHour == IsoTime.maxHour12) {
        displayHour = IsoTime.maxHour12;
        _pm = true;
      }
    }
    _hourController = TextEditingController(text: _formatDigits(displayHour));
    _minuteController = TextEditingController(
      text: _formatDigits(initialMinute),
    );
    _secondController = TextEditingController(
      text: _formatDigits(initialSecond),
    );
    _hourFocusNode = FocusNode()..addListener(handleSegmentFocusChanged);
    _minuteFocusNode = FocusNode()
      ..addListener(handleSegmentFocusChanged)
      ..addListener(handleMinuteFocusChanged);
    _secondFocusNode = FocusNode()..addListener(handleSegmentFocusChanged);
  }

  /// A minute typed into the segment snaps to the nearest step of
  /// `minuteInterval` once the segment is left — the point where "typing"
  /// ends, so a half-typed `1` on its way to `15` is never rewritten under
  /// the cursor. Rewrites only when snapping actually moves the value, so
  /// the default interval (one minute) never touches what was typed.
  void handleMinuteFocusChanged() {
    if (!mounted || _minuteFocusNode.hasFocus) return;
    final typed = int.tryParse(_minuteController.text);
    if (typed == null) return;
    final snapped = CoreMinuteInterval.snap(
      typed,
      interval: widget.minuteInterval,
    );
    if (snapped != typed.clamp(0, IsoTime.maxMinute)) {
      _minuteController.text = _formatDigits(snapped);
    }
  }

  /// Moves the minute segment one step of `minuteInterval` — up or down from
  /// where it stands, wrapping at the ends of the hour without touching the
  /// hour segment.
  void _stepMinute({required bool up}) {
    final current = int.tryParse(_minuteController.text) ?? 0;
    final next = up
        ? CoreMinuteInterval.stepUp(current, interval: widget.minuteInterval)
        : CoreMinuteInterval.stepDown(current, interval: widget.minuteInterval);
    final text = _formatDigits(next);
    _minuteController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  TimeOfDay _currentValue() {
    var hour = int.tryParse(_hourController.text) ?? 0;
    var minute = int.tryParse(_minuteController.text) ?? 0;
    var second = int.tryParse(_secondController.text) ?? 0;
    if (widget.use24HourFormat) {
      hour = hour.clamp(0, IsoTime.maxHour24);
    } else {
      final hour12 = hour.clamp(0, IsoTime.maxHour12);
      var hour24 = hour12 % IsoTime.maxHour12;
      if (_pm) hour24 += IsoTime.maxHour12;
      hour = hour24;
    }
    // Clamps to :59 like every segment, then snaps to the interval; the top
    // of the hour wraps to :00 and the hour stays as typed.
    minute = CoreMinuteInterval.snap(minute, interval: widget.minuteInterval);
    second = second.clamp(0, IsoTime.maxSecond);
    return TimeOfDay(hour: hour, minute: minute, second: second);
  }

  Widget _buildSegmentField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    Map<ShortcutActivator, VoidCallback>? shortcuts,
  }) {
    final theme = Theme.of(context);
    final scheme = widget.materialScheme;
    // A hovered segment wears the state layer over its tile — whichever
    // face the tile has, the edited segment's included.
    final hovered = identical(_hoveredSegment, focusNode);
    final focused = focusNode.hasFocus;
    final field = Data<FormFieldHandle>.boundary(
      child: TextField(
        // Chromeless centred segment via the unified Style slot —
        // the outer Container owns the boundary; value typography +
        // content colour flow through `valueStyle` (resolver already
        // folded the segment value style into `valueTypography`).
        textFieldStyle: CoreTextFieldStyle(
          backgroundColor: .transparent,
          borderColor: .transparent,
          // The inner field draws no border of its own — the outer
          // Container does — so its hover step is silenced too.
          hoverBorderColor: .transparent,
          focusBorderColor: .transparent,
          borderWidth: 0,
          padding: .zero,
          textAlign: .center,
          // `TextField` always composes its own `FocusOutline`;
          // `focusBorderColor` silences that ring's stroke and the
          // field's default gap band is transparent. The edited segment
          // is marked by the outer box's inside border instead: the
          // segments sit next to each other inside the popover, so a ring
          // outside one would cover its neighbour or be clipped at the
          // popover edge (the Material 3 time input marks its field the
          // same way). The trigger field's ring is another element.
          valueStyle: widget.resolved.valueTypography.copyWith(
            color: focused
                ? widget.resolved.segmentFocusedContentColor
                : widget.resolved.segmentContentColor,
          ),
        ),
        controller: controller,
        focusNode: focusNode,
        keyboardType: .number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
      ),
    );
    return Column(
      mainAxisSize: .min,
      spacing: widget.resolved.dialogLabelSpacing,
      children: [
        // The edited segment wears its focused face and an inside border in
        // place of its resting one — on Web the same element carries border,
        // fill and text colour, so the box here is the one surface that
        // changes. The border is inside, so the tile keeps its size and its
        // neighbours do not move.
        MouseRegion(
          onEnter: (_) => _handleSegmentHoverEnter(focusNode),
          onExit: (_) => _handleSegmentHoverExit(focusNode),
          child: Container(
            alignment: Alignment.center,
            decoration:
                buildTimePickerSegmentDecoration(
                  borderColor: scheme
                      .resolve(
                        focused
                            ? widget.resolved.segmentFocusedBorderColor
                            : widget.resolved.segmentBorderColor,
                      )
                      .toValue(),
                  segmentBorderRadius: widget.resolved.segmentBorderRadius,
                  triggerBorderWidth: focused
                      ? widget.resolved.segmentFocusedBorderWidth
                      : widget.resolved.triggerBorderWidth,
                ).copyWith(
                  color: scheme
                      .resolve(
                        focused
                            ? widget.resolved.segmentFocusedSurfaceColor
                            : widget.resolved.segmentSurfaceColor,
                      )
                      .toValue(),
                ),
            // The state layer, over the tile's own shape and above its face.
            foregroundDecoration: hovered
                ? BoxDecoration(
                    color: widget.resolved.segmentHoverLayerColor,
                    borderRadius: widget.resolved.segmentBorderRadius,
                  )
                : null,
            width: widget.resolved.segmentSize,
            height: widget.resolved.segmentHeight,
            // Part of this composite: walled off from the enclosing
            // `FormField`, which is shown the composite's own value.
            //
            // A segment that takes keys of its own (the minute's arrow
            // steps) binds them on a focus ancestor of the field. Key
            // events bubble up from the focused field, so this binding
            // sees an arrow before the page-level shortcut that would
            // otherwise move focus to a neighbouring control.
            child: shortcuts == null
                ? field
                : CallbackShortcuts(bindings: shortcuts, child: field),
          ),
        ),
        Text(
          label,
          style: resolveTypographyRole(theme, widget.resolved.helperTypography)
              .copyWith(
                color: scheme.resolve(widget.resolved.labelColor).toValue(),
              ),
        ),
      ],
    );
  }

  /// The colon between two segments. The row aligns its children to the
  /// top, and the colon is shorter than a segment tile, so it stands in a
  /// box as tall as the tile and centres in it — the Web twin's `height:
  /// segmentHeight` + `align-items: center`.
  Widget _buildSeparator(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = widget.materialScheme;
    return Padding(
      padding: widget.resolved.separatorPadding,
      child: SizedBox(
        height: widget.resolved.segmentHeight,
        child: Center(
          child: Text(
            ':',
            // `toValue(theme:)`, not `resolveTypographyRole`: the role
            // carries a weight overlay, and the role lookup alone keeps
            // only a colour on top of the slot.
            style: widget.resolved.separatorTypography.toValue(
              theme: theme,
              color: scheme.resolve(widget.resolved.separatorColor).toValue(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    _secondFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    // The panel box (background / border / radius / padding) is drawn by
    // the composed `Popup` (popover mode) or `Dialog` (dialog mode) — this
    // content widget only emits the picker column, so no own surface box
    // (no double-stacked border / radius). The title (dialog mode) is
    // rendered by the `Dialog` component, not here.
    //
    // The content names itself — the Web twin puts `role="dialog"` and the
    // same localised label on the same element, in both modes, so a screen
    // reader announces the picker the same way on either platform.
    return CoUISemantics(
      role: .dialog,
      label: localizations.timePickerPopoverLabel,
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          // The digits fill a fixed-size segment box, so they keep their
          // desktop size at every viewport width — the Web twin states the
          // same tier around the same row. Stated inside the panel content so
          // it holds in the popover and the dialog alike.
          TypographyTierScope(
            tier: .desktop,
            child: Builder(
              builder: (context) => Row(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  _buildSegmentField(
                    context: context,
                    controller: _hourController,
                    focusNode: _hourFocusNode,
                    label: localizations.timeHour,
                  ),
                  _buildSeparator(context),
                  _buildSegmentField(
                    context: context,
                    controller: _minuteController,
                    focusNode: _minuteFocusNode,
                    label: localizations.timeMinute,
                    shortcuts: {
                      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                          _stepMinute(up: true),
                      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                          _stepMinute(up: false),
                    },
                  ),
                  if (widget.showSeconds) ...[
                    _buildSeparator(context),
                    _buildSegmentField(
                      context: context,
                      controller: _secondController,
                      focusNode: _secondFocusNode,
                      label: localizations.timeSecond,
                    ),
                  ],
                  if (!widget.use24HourFormat) ...[
                    Gap(gapStyle: widget.resolved.dialogOuterGapStyle),
                    _AmPmToggle(
                      onChanged: (value) => setState(() => _pm = value),
                      isPm: _pm,
                      am: localizations.timeAM,
                      pm: localizations.timePM,
                      toggleStyle: widget.resolved.amPmToggleStyle,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Gap(gapStyle: widget.resolved.actionRowGapStyle),
          Row(
            mainAxisAlignment: .end,
            spacing: widget.resolved.separatorPadding.left,
            children: [
              Button(
                onPressed: widget.onCancel,
                variant: .ghost,
                buttonStyle: widget.resolved.actionButtonStyle,
                child: Text(localizations.buttonCancel),
              ),
              Button(
                onPressed: () => widget.onSave(_currentValue()),
                buttonStyle: widget.resolved.actionButtonStyle,
                child: Text(localizations.buttonSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The am/pm choice — one grouped toggle beside the segments.
///
/// A column (AM above PM) as tall as a segment tile; the segment row's
/// `crossAxisAlignment: .start` puts its top on the tiles' top.
class _AmPmToggle extends StatelessWidget {
  const _AmPmToggle({
    required this.isPm,
    required this.am,
    required this.pm,
    required this.onChanged,
    this.toggleStyle,
  });

  final bool isPm;
  final String am;
  final String pm;
  final ValueChanged<bool> onChanged;
  final CoreToggleGroupStyle? toggleStyle;

  @override
  Widget build(BuildContext context) {
    // The shared grouped toggle (a `surfaceContainerHigh` track with a raised
    // chosen face) — the am/pm choice is one control, not two buttons.
    return ToggleGroup<bool>(
      items: [
        CoreToggleGroupItem<bool, Widget>(value: false, label: am),
        CoreToggleGroupItem<bool, Widget>(value: true, label: pm),
      ],
      value: isPm,
      onChanged: onChanged,
      size: CoreTimePickerContract.defaultAmPmToggleSize,
      direction: CoreTimePickerContract.defaultAmPmToggleDirection,
      toggleGroupStyle: toggleStyle,
    );
  }
}

/// One editable segment of a time value.
enum TimePart {
  /// The hour segment.
  hour,

  /// The minute segment.
  minute,

  /// The second segment.
  second,
}

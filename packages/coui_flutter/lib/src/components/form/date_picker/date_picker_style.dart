import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedDatePicker
// ═══════════════════════════════════════════════════

/// Resolver output for `DatePicker` / `DateRangePicker`.
///
/// Widget tree (the widget only **selects** a paint-ready style by
/// runtime state and renders — it resolves nothing itself):
///
/// ```text
/// Column
///   ├─ Text (label)            // labelTextStyle | labelDisabledTextStyle (by enabled)
///   ├─ Gap (labelBottomGapStyle)
///   ├─ TextField (trigger, read-only) // triggerStyle; the value / placeholder / error edge live in the field
///   ├─ Gap (descriptionTopGapStyle)
///   └─ Text (error | description) // errorTextStyle | descriptionTextStyle
/// ```
///
/// The text styles are fully paint-ready (typography role + resolved
/// colour + per-instance override baked in) so the widget never calls
/// `resolveTypographyRole` / `scheme.resolve` itself. The slot styles
/// ([triggerStyle] / [popoverStyle] / [dialogStyle] / [calendarStyle]) are
/// forwarded as-is for each child component's resolver.
class ResolvedDatePicker {
  /// Creates a [ResolvedDatePicker].
  const ResolvedDatePicker({
    required this.triggerStyle,
    required this.popoverStyle,
    required this.dialogStyle,
    required this.calendarStyle,
    required this.trailingIconStyle,
    required this.customValueTextStyle,
    required this.labelTextStyle,
    required this.labelDisabledTextStyle,
    required this.descriptionTextStyle,
    required this.errorTextStyle,
    required this.labelBottomGapStyle,
    required this.descriptionTopGapStyle,
  });

  /// Nested popover style for popover-mode picker.
  final CorePopoverStyle? popoverStyle;

  /// Nested dialog style for dialog-mode picker.
  final CoreDialogStyle? dialogStyle;

  /// Nested calendar style applied to the inline calendar grid.
  final CoreCalendarStyle? calendarStyle;

  /// The trigger field's chrome — [CoreDatePickerStyle.defaultTriggerStyle]
  /// with the error edge, the value / placeholder colours and the value role
  /// folded in, then the per-instance `triggerStyle` on top. A disabled
  /// picker leaves the two text colours out so the field's own disabled tone
  /// applies. Forwarded raw to the composed read-only `TextField`, which
  /// resolves and scales it.
  final CoreTextFieldStyle triggerStyle;

  /// Paint-ready trailing (calendar) icon style — the trigger's
  /// `trailingIconStyle` override chained onto the 16-px design-system
  /// default. The widget reads this straight; the single and range
  /// triggers pick their own glyph (`calendar` / `calendarRange`).
  final CoreIconStyle trailingIconStyle;

  /// Paint-ready text style handed to a caller-supplied value widget (the
  /// range picker's `builder`) that sits in the trigger field's placeholder
  /// seat: the value colour and any `valueTypography` the caller wrote, so
  /// the widget does not read as the placeholder. Disabled leaves the colour
  /// out, so the field's own disabled tone applies. A plain date string is
  /// the field's own `value`, not this.
  final TextStyle customValueTextStyle;

  /// Paint-ready label text style while enabled (label typography +
  /// content colour + `labelStyle` override).
  final TextStyle labelTextStyle;

  /// Paint-ready label text style while disabled (label typography +
  /// placeholder colour + `labelStyle` override).
  final TextStyle labelDisabledTextStyle;

  /// Paint-ready description / helper text style (helper typography +
  /// description colour + `descriptionStyle` override).
  final TextStyle descriptionTextStyle;

  /// Paint-ready error text style (helper typography + error colour +
  /// `errorStyle` override).
  final TextStyle errorTextStyle;

  /// Resolved nested [CoreGapStyle] slot for the vertical gap between
  /// the label row and the trigger row. Forwarded straight to `Gap`,
  /// which owns its own scaling.
  final CoreGapStyle labelBottomGapStyle;

  /// Resolved nested [CoreGapStyle] slot for the vertical gap between
  /// the trigger row and the description / error text row. Forwarded
  /// straight to `Gap`, which owns its own scaling.
  final CoreGapStyle descriptionTopGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDatePicker] for the given [context].
///
/// Walks the nested-merge chain in a single pass:
///
/// ```text
/// design system default for date picker
///   → theme.coreComponentTheme.datePicker.style
///   → widget.datePickerStyle
/// ```
///
/// then bakes every trigger / label / helper text style to a paint-ready
/// `TextStyle` (typography role + resolved colour + per-instance
/// override) so the widget renders without resolving anything.
ResolvedDatePicker resolveDatePicker(
  BuildContext context, {
  CoreDatePickerStyle? datePickerStyle,
  bool enabled = true,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final datePickerTheme = theme.coreComponentTheme?.datePicker;

  // Layer per-instance CoreDatePickerStyle:
  //   theme.style → widget.datePickerStyle.
  final merged = resolveStyleChain(const CoreDatePickerStyle(), [
    datePickerTheme?.style,
    datePickerStyle,
  ]);

  // Field-trigger convention default (`triggerSizing: .expand`) with the
  // per-instance override merged on top — single Core source instead of
  // widget-side `copyWith`.
  final popoverStyle = CoreDatePickerStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );

  // The trigger is a read-only `TextField` (the TimePicker / Select input
  // look), so everything about its box — height 40, corner 10, the
  // `outline-variant` edge, the `primary` focus edge, the Regular 14 value —
  // is the field's own `md` row. One Core function folds the picker's own
  // decisions (the error edge, the value / placeholder colours, an explicit
  // value role) under the per-instance `triggerStyle`; a disabled picker
  // leaves the two text colours out so the field's disabled tone applies.
  final triggerStyle = enabled
      ? merged.effectiveTriggerStyle
      : merged.effectiveDisabledTriggerStyle;

  // Nested child-component slots — the picker's (empty) partial with the
  // per-instance override merged on top, forwarded raw so `Dialog` /
  // `Calendar` fill their own defaults (no field-by-field reach).
  final dialogStyle = CoreDatePickerStyle.defaultDialogStyle.merge(
    merged.dialogStyle,
  );
  final calendarStyle = CoreDatePickerStyle.defaultCalendarStyle.merge(
    merged.calendarStyle,
  );

  // Nested `CoreGapStyle` slots — merge the design-system defaults with
  // the per-instance overrides and forward raw (pre-scaling) to `Gap`,
  // which runs its own resolve / scaling step.
  final labelBottomGapStyle = CoreDatePickerStyle.defaultLabelBottomGapStyle
      .merge(merged.labelBottomGapStyle);
  final descriptionTopGapStyle = CoreDatePickerStyle
      .defaultDescriptionTopGapStyle
      .merge(merged.descriptionTopGapStyle);

  // Resolved content / placeholder / helper colours (flat slots).
  final contentColor = scheme
      .resolve(merged.contentColor ?? CoreDatePickerStyle.defaultContentColor)
      .toValue();
  final placeholderColor = scheme
      .resolve(
        merged.placeholderColor ?? CoreDatePickerStyle.defaultPlaceholderColor,
      )
      .toValue();
  // A disabled picker paints its description `disabledDescriptionColor` —
  // the helper line recedes with the field, the way the error text does.
  final descriptionColor = scheme
      .resolve(
        enabled
            ? (merged.descriptionColor ??
                  CoreDatePickerStyle.defaultDescriptionColor)
            : (merged.disabledDescriptionColor ??
                  CoreDatePickerStyle.defaultDisabledDescriptionColor),
      )
      .toValue();
  // A disabled picker paints its error text `disabledErrorColor`: disabled
  // outranks the error (the field cannot be fixed, so no live error colour).
  final errorColor = scheme
      .resolve(
        enabled
            ? (merged.errorColor ?? CoreDatePickerStyle.defaultErrorColor)
            : (merged.disabledErrorColor ??
                  CoreDatePickerStyle.defaultDisabledErrorColor),
      )
      .toValue();

  // Per-slot Core typography — token-backed design-system role merged
  // with the per-instance text-style override. `.toValue(theme:, color:)`
  // (the single Flutter EMIT primitive) materialises the role through the
  // active theme and applies the resolved flat colour, so no
  // `resolveTypographyRole` / `applyCoreTextStyle` two-step assembly.
  // The nested override's own `.color` wins over the flat slot colour
  // (mirrors the prior `applyCoreTextStyle` precedence + the Web
  // resolver 1:1).
  final labelCore = CoreDatePickerStyle.defaultLabelStyle.merge(
    merged.labelStyle,
  );
  final descriptionCore = CoreDatePickerStyle.defaultDescriptionStyle.merge(
    merged.descriptionStyle,
  );
  final errorCore = CoreDatePickerStyle.defaultErrorStyle.merge(
    merged.errorStyle,
  );

  // Effective flat colours for the override-bearing slots — the nested
  // override's `.color` (resolved through the scheme) wins, else the slot
  // colour resolved above.
  final labelColor = merged.labelStyle?.color != null
      ? scheme.resolve(merged.labelStyle!.color!).toValue()
      : contentColor;
  final labelDisabledColor = merged.labelStyle?.color != null
      ? scheme.resolve(merged.labelStyle!.color!).toValue()
      : placeholderColor;
  final resolvedDescriptionColor = merged.descriptionStyle?.color != null
      ? scheme.resolve(merged.descriptionStyle!.color!).toValue()
      : descriptionColor;
  final resolvedErrorColor = merged.errorStyle?.color != null
      ? scheme.resolve(merged.errorStyle!.color!).toValue()
      : errorColor;

  // Paint-ready trigger / label / helper styles — every composition
  // (`.merge`, `.toValue(theme:, color:)`) lands in a local var so the
  // return literal stays a clean mapping. This resolver has no scaled
  // dimensional prop, so the return is bare references with no `* scaling`
  // at all (Anti-Pattern B — see 55-scaling-and-gap.md).
  // A disabled picker leaves the glyph untinted: the trigger field's own
  // disabled foreground applies to it the way it does to the value text.
  final trailingIconRung =
      merged.trailingIconStyle ?? CoreDatePickerStyle.defaultTrailingIconStyle;
  final trailingIconStyle = enabled
      ? trailingIconRung
      : trailingIconRung.withoutColor;
  // The text style of a caller-supplied value widget in the field's
  // placeholder seat (range `builder`). No role of its own: the size comes
  // from the field, the colour from the value colour while enabled.
  final customValueTextStyle = (merged.valueTypography ?? const CoreTextStyle())
      .toValue(color: enabled ? contentColor : null, theme: theme);
  final labelTextStyle = labelCore.toValue(color: labelColor, theme: theme);
  final labelDisabledTextStyle = labelCore.toValue(
    color: labelDisabledColor,
    theme: theme,
  );
  final descriptionTextStyle = descriptionCore.toValue(
    color: resolvedDescriptionColor,
    theme: theme,
  );
  final errorTextStyle = errorCore.toValue(
    color: resolvedErrorColor,
    theme: theme,
  );

  return ResolvedDatePicker(
    triggerStyle: triggerStyle,
    popoverStyle: popoverStyle,
    dialogStyle: dialogStyle,
    calendarStyle: calendarStyle,
    trailingIconStyle: trailingIconStyle,
    customValueTextStyle: customValueTextStyle,
    labelTextStyle: labelTextStyle,
    labelDisabledTextStyle: labelDisabledTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    errorTextStyle: errorTextStyle,
    labelBottomGapStyle: labelBottomGapStyle,
    descriptionTopGapStyle: descriptionTopGapStyle,
  );
}

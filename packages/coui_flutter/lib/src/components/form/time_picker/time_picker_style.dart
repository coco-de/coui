import 'package:coui_flutter/coui_flutter.dart';

/// Flutter-side style helpers for [TimePicker]. The per-instance
/// composite Style ([CoreTimePickerStyle]) is resolved through
/// [resolveTimePicker]; all default values are sourced from
/// `CoreTimePickerStyle.default*` (Core single source).

/// Builds the segment field decoration.
BoxDecoration buildTimePickerSegmentDecoration({
  required Color borderColor,
  required BorderRadius segmentBorderRadius,
  required double triggerBorderWidth,
}) {
  return BoxDecoration(
    border: .all(color: borderColor, width: triggerBorderWidth),
    borderRadius: segmentBorderRadius,
  );
}

// ═══════════════════════════════════════════════════
// ResolvedTimePicker
// ═══════════════════════════════════════════════════

/// Resolver output for `TimePicker`.
///
/// Single struct that the widget reads — every chrome / dimensional /
/// nested-slot override has been merged through:
///
/// ```text
/// design system default for time picker
///   → theme.coreComponentTheme.timePicker.style
///   → widget.timePickerStyle
/// ```
///
/// All slot styles ([popoverStyle] / [dialogStyle] / [segmentInputStyle] /
/// [amPmToggleStyle] / [labelStyle] / [descriptionStyle] / [errorStyle])
/// are forwarded as-is so each child component's resolver can run its
/// own merge chain on top.
class ResolvedTimePicker {
  /// Creates a [ResolvedTimePicker].
  const ResolvedTimePicker({
    required this.trailingIconStyle,
    required this.triggerStyle,
    required this.popoverStyle,
    required this.dialogStyle,
    required this.segmentInputStyle,
    required this.amPmToggleStyle,
    required this.actionButtonStyle,
    required this.labelStyle,
    required this.descriptionStyle,
    required this.errorStyle,
    required this.segmentBorderColor,
    required this.segmentHoverLayerColor,
    required this.segmentSurfaceColor,
    required this.segmentContentColor,
    required this.segmentFocusedSurfaceColor,
    required this.segmentFocusedContentColor,
    required this.segmentFocusedBorderColor,
    required this.segmentFocusedBorderWidth,
    required this.labelColor,
    required this.contentColor,
    required this.valueTypography,
    required this.helperTypography,
    required this.segmentBorderRadius,
    required this.triggerHeight,
    required this.triggerBorderWidth,
    required this.segmentSize,
    required this.segmentHeight,
    required this.dialogLabelSpacing,
    required this.dialogOuterGapStyle,
    required this.actionRowGapStyle,
    required this.separatorPadding,
    required this.separatorTypography,
    required this.separatorColor,
  });

  /// Paint-ready trailing (clock) icon style — the trigger's
  /// `trailingIconStyle` override chained onto the design-system default
  /// (16px, from `CoreTimePickerStyle.defaultTrailingIconStyle`) with the
  /// resolved content colour overlaid. The widget forwards this straight
  /// to `Icon(iconStyle: …)` and never chains a fallback itself.
  final CoreIconStyle trailingIconStyle;

  /// The trigger field's chrome — [CoreTimePickerStyle.defaultTriggerStyle]
  /// with the trigger height, the value / placeholder colours and (for the
  /// deprecated `errorTriggerStyle`) the error edge folded in, then the
  /// per-instance `triggerStyle` on top. A disabled picker leaves the two
  /// text colours out so the field's own disabled tone applies. Forwarded
  /// raw to the composed read-only `TextField`, which resolves and scales it.
  final CoreTextFieldStyle triggerStyle;

  /// Nested popover style for popover-mode picker. Carries the panel-box
  /// chrome as a nested `panelStyle` (`CorePopupStyle`) — the floating
  /// surface (background / border / radius / padding) is drawn by the
  /// composed `Popup`, not the picker content.
  final CorePopoverStyle? popoverStyle;

  /// Nested dialog style for dialog-mode picker — the dialog panel box
  /// is drawn by the composed `Dialog` component (not the picker
  /// content). Forwarded raw.
  final CoreDialogStyle? dialogStyle;

  /// Nested text-field style applied to each hour / minute / second
  /// segment input.
  final CoreTextFieldStyle? segmentInputStyle;

  /// Style of the am/pm `ToggleGroup`. Raw-forwarded.
  final CoreToggleGroupStyle amPmToggleStyle;

  /// Nested button style merged into the Cancel / Save action buttons
  /// (single shared slot, mirroring `CoreDialogStyle.actionButtonStyle`).
  final CoreButtonStyle? actionButtonStyle;

  /// Label text style.
  final CoreTextStyle? labelStyle;

  /// Description / helper text style.
  final CoreTextStyle? descriptionStyle;

  /// Error text style.
  final CoreTextStyle? errorStyle;

  /// Resolved segment input border colour token.
  final CoreColor segmentBorderColor;

  /// Paint-ready state layer laid over a segment tile while the pointer is
  /// over it — the layer colour (`onSurface` by default) at the ramp's hover
  /// weight. The widget lays it over the tile's own shape on whichever face
  /// the tile wears, the edited segment's included; the face colour and the
  /// border are not touched.
  final Color segmentHoverLayerColor;

  /// Resolved segment input fill / surface colour token.
  final CoreColor segmentSurfaceColor;

  /// Resolved segment input content text colour token.
  final CoreColor segmentContentColor;

  /// Resolved fill token of the segment being edited.
  final CoreColor segmentFocusedSurfaceColor;

  /// Resolved text colour token on the edited segment's face.
  final CoreColor segmentFocusedContentColor;

  /// Resolved border colour token of the segment being edited — drawn
  /// inside the tile in place of its resting border.
  final CoreColor segmentFocusedBorderColor;

  /// Resolved width of the edited segment's inside border (logical px).
  final double segmentFocusedBorderWidth;

  /// Resolved segment label / description text colour token.
  final CoreColor labelColor;

  /// Resolved trigger content text colour token.
  final CoreColor contentColor;

  /// Resolved trigger value / segment numeric typography role.
  final CoreTextStyle valueTypography;

  /// Resolved helper / segment-label typography role.
  final CoreTextStyle helperTypography;

  /// Resolved segment input border radius (paint-ready).
  final BorderRadius segmentBorderRadius;

  /// Resolved trigger height (logical px, scaling applied) — the height
  /// the trigger `Button` paints when the caller does not override
  /// `popoverStyle.triggerStyle.height`. The widget does not read this:
  /// the pre-scaling value is folded into [popoverStyle]'s `triggerStyle`
  /// and `Button` scales it itself.
  final double triggerHeight;

  /// Resolved trigger / segment border width (logical px).
  final double triggerBorderWidth;

  /// Resolved width of each numeric segment field (logical px).
  final double segmentSize;

  /// Resolved height of each numeric segment field (logical px) — also the
  /// height of the AM/PM toggle box beside it.
  final double segmentHeight;

  /// Resolved uniform spacing between the segment field and its label
  /// (Flutter `Column.spacing`) and between the AM/PM stacked toggle
  /// buttons (Flutter `Column.spacing`). Scaling pre-applied.
  final double dialogLabelSpacing;

  /// Nested [CoreGapStyle] slot forwarded to the `Gap` widget
  /// rendered between the segment row and the AM/PM column. Merged
  /// with [CoreTimePickerStyle.defaultDialogOuterGapStyle]. `Gap`
  /// self-scales, so this slot carries raw (pre-scaling) values.
  final CoreGapStyle dialogOuterGapStyle;

  /// Nested [CoreGapStyle] slot forwarded to the `Gap` widget
  /// rendered between the optional title and the segment row, and
  /// between the segment row and the action button row. Merged with
  /// [CoreTimePickerStyle.defaultActionRowGapStyle]. `Gap`
  /// self-scales, so this slot carries raw (pre-scaling) values.
  final CoreGapStyle actionRowGapStyle;

  /// Resolved padding around the segment separator glyph (paint-ready
  /// Flutter `EdgeInsets`, scaling pre-applied).
  final EdgeInsets separatorPadding;

  /// Resolved segment separator (`:`) typography role.
  final CoreTextStyle separatorTypography;

  /// Resolved segment separator (`:`) colour token.
  final CoreColor separatorColor;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTimePicker] for the given [context].
///
/// Walks the nested-merge chain in a single pass:
///
/// ```text
/// design system default for time picker
///   → theme.coreComponentTheme.timePicker.style
///   → widget.timePickerStyle
/// ```
ResolvedTimePicker resolveTimePicker(
  BuildContext context, {
  CoreTimePickerStyle? timePickerStyle,
  bool enabled = true,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final timePickerTheme = theme.coreComponentTheme?.timePicker;

  // Layer per-instance CoreTimePickerStyle:
  //   theme.style → widget.timePickerStyle.
  final merged = resolveStyleChain(const CoreTimePickerStyle(), [
    timePickerTheme?.style,
    timePickerStyle,
  ]);

  // Paint-ready conversions (fallback + toValue()); scaling applied in return.
  final segmentBorderRadius =
      (merged.segmentBorderRadius ??
              CoreTimePickerStyle.defaultSegmentBorderRadius)
          .toValue(geometry: theme.geometry);
  // Trigger height — pre-scaling when handed to the trigger field below
  // (`resolveTextField` multiplies its own height by `theme.scaling`, so a
  // pre-scaled value would scale twice); the scaled copy is the resolved
  // field.
  final triggerHeight =
      merged.triggerHeight ?? CoreTimePickerStyle.defaultTriggerHeight;
  final scaledTriggerHeight = triggerHeight * scaling;
  final triggerBorderWidth =
      merged.triggerBorderWidth ??
      CoreTimePickerStyle.defaultTriggerBorderWidth;
  final segmentFocusedBorderColor =
      merged.segmentFocusedBorderColor ??
      CoreTimePickerStyle.defaultSegmentFocusedBorderColor;
  // A stroke, so it takes the geometry's stroke floor like the resting
  // border beside it.
  final segmentFocusedBorderWidth = theme.geometry.stroke(
    merged.segmentFocusedBorderWidth ??
        CoreTimePickerStyle.defaultSegmentFocusedBorderWidth,
    scaling: scaling,
  );
  final segmentSize =
      (merged.segmentSize ?? CoreTimePickerStyle.defaultSegmentSize) * scaling;
  final segmentHeight =
      (merged.segmentHeight ?? CoreTimePickerStyle.defaultSegmentHeight) *
      scaling;
  // Segment hover layer — the state-layer colour at the hover weight,
  // resolved against the active scheme here so the widget only chooses
  // whether to lay it.
  final segmentHoverLayerColor = theme.colorScheme
      .resolve(
        (merged.segmentStateLayerColor ??
                CoreTimePickerStyle.defaultSegmentStateLayerColor)
            .scaleAlpha(
              (merged.segmentStateLayer ??
                      CoreTimePickerStyle.defaultSegmentStateLayer)
                  .hover,
            ),
      )
      .toValue();
  final dialogLabelSpacing =
      theme.geometry.space(
        merged.dialogLabelSpacing ??
            CoreTimePickerStyle.defaultDialogLabelSpacing,
      ) *
      scaling;
  final separatorPadding =
      ((merged.separatorPadding ?? CoreTimePickerStyle.defaultSeparatorPadding)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final separatorTypography = CoreTimePickerStyle.defaultSeparatorTypography
      .merge(merged.separatorTypography);
  final separatorColor =
      merged.separatorColor ?? CoreTimePickerStyle.defaultSeparatorColor;

  // ─── Panel surface chrome ─────────────────────────────────────────
  // The picker's floating surface (background / border / radius /
  // padding) is a single panel box drawn by the composed `Popup`
  // (popover mode) or `Dialog` (dialog mode) — NOT by the picker content
  // itself. Popover-mode chrome flows through the nested
  // `popoverStyle.panelStyle` (a `CorePopupStyle`, the single source of
  // truth): `CoreTimePickerStyle.defaultPopoverStyle` carries the
  // TimePicker-specific overrides (radius16 / outlineVariant / padding16)
  // and `Popup` fills the rest; the caller's `popoverStyle` override
  // merges on top. Dialog-mode chrome is the `Dialog` component's own
  // panel ([dialogStyle], forwarded raw).
  //
  final popoverStyle = CoreTimePickerStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );

  // ─── Trigger field ────────────────────────────────────────────────
  // The trigger is a read-only `TextField` (the DatePicker / Select input
  // look), so everything about its box — height 40, corner 10, the
  // `outline-variant` edge, the `primary` focus edge, the Regular 14 value
  // — is the field's own `md` row. This folds in only what is the picker's
  // decision: an explicit height, the value colour, the placeholder tone
  // (the clock takes the same one) and, for the deprecated
  // `errorTriggerStyle`, its border colour as the field's error edge. A
  // disabled picker leaves the two text colours out so the field's own
  // disabled tone applies. `triggerStyle` is the per-instance override and
  // wins on top. One Core function (`effectiveTriggerStyle`) so both
  // platforms fold identically.
  // guard-nested-override: triggerHeight — `merged.triggerHeight` is folded
  // into the field's `height` by `effectiveTriggerStyle`.
  final triggerStyle = enabled
      ? merged.effectiveTriggerStyle
      : merged.effectiveDisabledTriggerStyle;

  // Trailing (clock) icon — the top-level override wins, else the
  // trigger's nested override, else the 16-px design-system default. The
  // value colour (`contentColor`) is the text's colour, not the glyph's, so
  // it never reaches the icon. A disabled picker leaves the clock untinted:
  // the trigger field's own disabled foreground applies to the glyph the way
  // it does to the text.
  final trailingIconRung =
      merged.trailingIconStyle ?? CoreTimePickerStyle.defaultTrailingIconStyle;
  final trailingIconStyle = enabled
      ? trailingIconRung
      : trailingIconRung.withoutColor;

  // The am/pm toggle sits on the panel: its track is the slot default's
  // one step up, the rest is the composed ToggleGroup's (raw-forward).
  final amPmToggleStyle = CoreTimePickerStyle.defaultAmPmToggleStyle.merge(
    merged.amPmToggleStyle,
  );
  return ResolvedTimePicker(
    trailingIconStyle: trailingIconStyle,
    triggerStyle: triggerStyle,
    popoverStyle: popoverStyle,
    dialogStyle: merged.dialogStyle,
    segmentInputStyle: merged.segmentInputStyle,
    amPmToggleStyle: amPmToggleStyle,
    actionButtonStyle: merged.actionButtonStyle,
    labelStyle: merged.labelStyle,
    descriptionStyle: merged.descriptionStyle,
    errorStyle: merged.errorStyle,
    // Segment border colour folds the nested `segmentInputStyle.borderColor`
    // override (matches the segment decoration in the widget) before the
    // flat `segmentBorderColor` / design-system default.
    segmentBorderColor:
        merged.segmentInputStyle?.borderColor ??
        merged.segmentBorderColor ??
        CoreTimePickerStyle.defaultSegmentBorderColor,
    segmentHoverLayerColor: segmentHoverLayerColor,
    segmentSurfaceColor:
        merged.segmentSurfaceColor ??
        CoreTimePickerStyle.defaultSegmentSurfaceColor,
    segmentContentColor:
        merged.segmentContentColor ??
        CoreTimePickerStyle.defaultSegmentContentColor,
    segmentFocusedSurfaceColor:
        merged.segmentFocusedSurfaceColor ??
        CoreTimePickerStyle.defaultSegmentFocusedSurfaceColor,
    segmentFocusedContentColor:
        merged.segmentFocusedContentColor ??
        CoreTimePickerStyle.defaultSegmentFocusedContentColor,
    segmentFocusedBorderColor: segmentFocusedBorderColor,
    segmentFocusedBorderWidth: segmentFocusedBorderWidth,
    labelColor: merged.labelColor ?? CoreTimePickerStyle.defaultLabelColor,
    contentColor:
        merged.contentColor ?? CoreTimePickerStyle.defaultContentColor,
    // Value typography folds the nested `segmentInputStyle.valueStyle`
    // override (matches `_buildSegmentField`) before the flat
    // `valueTypography` / design-system default.
    valueTypography:
        merged.segmentInputStyle?.valueStyle ??
        merged.valueTypography ??
        CoreTimePickerStyle.defaultValueTypography,
    helperTypography:
        merged.helperTypography ?? CoreTimePickerStyle.defaultHelperTypography,
    segmentBorderRadius: segmentBorderRadius * scaling,
    triggerHeight: scaledTriggerHeight,
    triggerBorderWidth: theme.geometry.stroke(
      triggerBorderWidth,
      scaling: scaling,
    ),
    // Nested `CoreGapStyle` slots — merge the design-system default
    // with the per-instance override and forward the resulting slot
    // straight to `Gap` / `Button.iconLabelGapStyle`. `Gap` /
    // `Button` self-scale, so we forward raw (pre-scaling) values.
    segmentSize: segmentSize,
    segmentHeight: segmentHeight,
    dialogLabelSpacing: dialogLabelSpacing,
    dialogOuterGapStyle: CoreTimePickerStyle.defaultDialogOuterGapStyle.merge(
      merged.dialogOuterGapStyle,
    ),
    actionRowGapStyle: CoreTimePickerStyle.defaultActionRowGapStyle.merge(
      merged.actionRowGapStyle,
    ),
    separatorPadding: separatorPadding,
    separatorTypography: separatorTypography,
    separatorColor: separatorColor,
  );
}

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedColorPicker
// ═══════════════════════════════════════════════════

/// Resolver output for `ColorPicker`.
///
/// Single struct that the widget reads — every chrome / dimensional /
/// nested-slot override has been merged through:
///
/// ```text
/// design system default for color picker (CoreColorPickerStyle.defaultX)
///   → theme.coreComponentTheme.colorPicker.style
///   → widget.colorPickerStyle
/// ```
///
/// All slot styles are forwarded as-is so each child component's
/// resolver can run its own merge chain on top.
class ResolvedColorPicker {
  /// Creates a [ResolvedColorPicker].
  const ResolvedColorPicker({
    required this.swatchSize,
    required this.hexInputWidth,
    required this.swatchGapStyle,
    required this.popoverWidth,
    required this.popoverSpacing,
    required this.sliderHeight,
    required this.modeInputSpacing,
    required this.modeInputLabelGapStyle,
    required this.actionRowGapStyle,
    required this.eyeDropperIconStyle,
    required this.recentSwatchSize,
    required this.recentSwatchSpacing,
    required this.recentColumns,
    required this.swatchBorderRadius,
    required this.sliderBorderRadius,
    required this.recentSwatchBorderRadius,
    required this.saturationValueBorderRadius,
    required this.pickMarkerSize,
    required this.pickMarkerBorderColor,
    required this.pickMarkerBorderWidth,
    required this.pickMarkerShadow,
    required this.hueMarkerBorderColor,
    required this.hueMarkerBorderWidth,
    required this.emptySwatchDashLength,
    required this.emptySwatchDashSpacing,
    required this.borderColor,
    required this.borderWidth,
    required this.disabledBorderColor,
    required this.selectedRingColor,
    required this.recentSwatchBorderWidth,
    required this.recentSwatchSelectedBorderWidth,
    required this.transitionDuration,
    required this.popoverStyle,
    required this.dialogStyle,
    required this.swatchButtonStyle,
    required this.recentSwatchClickableStyle,
    required this.hexInputStyle,
    required this.modeTabsStyle,
    required this.modeInputLabelTextStyle,
    required this.triggerBackgroundColor,
    required this.triggerBorderColor,
    required this.triggerBorderWidth,
    required this.triggerBorderRadius,
    required this.triggerPadding,
    required this.triggerSpacing,
    required this.triggerMinWidth,
    required this.triggerValueTextStyle,
    required this.triggerPlaceholderTextStyle,
    required this.triggerChevronIconStyle,
    required this.recentTitleTextStyle,
    required this.recentTitleGapStyle,
    required this.modeHexInputFlex,
    required this.compareSwatchSize,
    required this.compareBorderRadius,
    required this.compareBorderColor,
    required this.compareBorderWidth,
    required this.inlinePanelStyle,
    @Deprecated(
      'Read by nothing — the hue-bar handle is filled with the current '
      'colour (since 0.190); this goes with '
      'CoreColorPickerStyle.hueMarkerFillColor.',
    )
    this.hueMarkerFillColor,
    @Deprecated(
      'Read by nothing — ColorPicker draws no label (since 0.185). Wrap the '
      'picker in a FormField with a label instead; this goes with '
      'CoreColorPickerStyle.labelStyle.',
    )
    this.labelStyle,
    @Deprecated(
      'Read by nothing — ColorPicker draws no description (since 0.185). Wrap '
      'the picker in a FormField with a description instead; this goes with '
      'CoreColorPickerStyle.descriptionStyle.',
    )
    this.descriptionStyle,
    @Deprecated(
      'Read by nothing — ColorPicker draws no error text (since 0.185). Wrap '
      'the picker in a FormField that shows the error instead; this goes with '
      'CoreColorPickerStyle.errorStyle.',
    )
    this.errorStyle,
  });

  /// Trigger swatch button width/height (logical px).
  final double swatchSize;

  /// Hex input field width (logical px).
  final double hexInputWidth;

  /// Nested [CoreGapStyle] for the swatch → hex-input spacer —
  /// forwarded to `Gap(gapStyle: …)`.
  final CoreGapStyle swatchGapStyle;

  /// Popover panel width (logical px).
  final double popoverWidth;

  /// Vertical spacing between popover sections (logical px). Paint-ready
  /// — flows directly into `Column.spacing`.
  final double popoverSpacing;

  /// Hue / alpha slider track height (logical px).
  final double sliderHeight;

  /// Horizontal spacing between RGB / HSL / HSV mode input cells
  /// (logical px). Paint-ready — flows directly into `Row.spacing`.
  final double modeInputSpacing;

  /// Nested [CoreGapStyle] for the 1-off spacer between a mode input
  /// cell's label and its number field — forwarded to
  /// `Gap(gapStyle: …)` inside `_ModeInputCell`.
  final CoreGapStyle modeInputLabelGapStyle;

  /// Nested [CoreGapStyle] for the gap between Cancel / Save buttons
  /// in the action row — forwarded to `Gap(gapStyle: …)`.
  final CoreGapStyle actionRowGapStyle;

  /// Nested [CoreIconStyle] for the eye-dropper button icon in the
  /// action row — forwarded to `Icon(iconStyle: …)`.
  final CoreIconStyle eyeDropperIconStyle;

  /// Recent-color swatch side length (logical px).
  final double recentSwatchSize;

  /// Spacing (logical px) between recent-color swatches — raw
  /// primitive driving `Wrap.spacing/runSpacing`.
  final double recentSwatchSpacing;

  /// Recent-colors grid column count.
  final int recentColumns;

  /// Paint-ready corner radius for the trigger swatch button.
  final BorderRadius swatchBorderRadius;

  /// Paint-ready corner radius for the hue / alpha slider bars.
  final BorderRadius sliderBorderRadius;

  /// Paint-ready corner radius for a recent-color swatch.
  final BorderRadius recentSwatchBorderRadius;

  /// Side (scaling pre-applied) of the picked-point handle on the
  /// saturation/value area and the hue bar.
  final double pickMarkerSize;

  /// Paint-ready handle ring colour.
  final Color pickMarkerBorderColor;

  /// Handle ring width (geometry-bent, scaling pre-applied).
  final double pickMarkerBorderWidth;

  /// Shadow under both picked-point handles (scaling pre-applied, tinted
  /// with the palette's `shadow` colour).
  final List<BoxShadow> pickMarkerShadow;

  /// The deprecated `CoreColorPickerStyle.hueMarkerFillColor`, resolved
  /// and carried as is. Nothing reads it — the hue-bar handle is filled
  /// with the current colour.
  @Deprecated(
    'Read by nothing — the hue-bar handle is filled with the current '
    'colour (since 0.190); this goes with '
    'CoreColorPickerStyle.hueMarkerFillColor.',
  )
  final Color? hueMarkerFillColor;

  /// Paint-ready border colour of the hue-bar handle.
  final Color hueMarkerBorderColor;

  /// Border width of the hue-bar handle (geometry-bent, scaling
  /// pre-applied).
  final double hueMarkerBorderWidth;

  /// Dash length (scaling pre-applied) of the empty swatch's outline.
  final double emptySwatchDashLength;

  /// Dash gap (scaling pre-applied) of the empty swatch's outline.
  final double emptySwatchDashSpacing;

  /// Paint-ready corner radius for the 2D saturation/value area inside
  /// the popover.
  final BorderRadius saturationValueBorderRadius;

  /// Paint-ready border colour (`outline` token by default) for the
  /// trigger swatch, the 2D saturation/value area, and the hue / alpha
  /// slider tracks.
  final Color borderColor;

  /// Border stroke width (geometry-bent, scaling pre-applied) for the
  /// trigger swatch, the 2D saturation/value area, and the hue / alpha
  /// slider tracks.
  final double borderWidth;

  /// Paint-ready border colour (`disabledOutline` token by default,
  /// #3469) for the trigger swatch when disabled.
  final Color disabledBorderColor;

  /// Paint-ready ring colour (`primary` token by default) highlighting
  /// the currently-selected recent-color swatch.
  final Color selectedRingColor;

  /// Border stroke width (geometry-bent, scaling pre-applied) for an
  /// unselected recent-color swatch.
  final double recentSwatchBorderWidth;

  /// Border stroke width (geometry-bent, scaling pre-applied) for the
  /// currently-selected recent-color swatch.
  final double recentSwatchSelectedBorderWidth;

  /// Chrome transition duration — already merged against
  /// `CoreColorPickerStyle.transitionDuration` /
  /// [CoreColorPickerStyle.defaultTransitionDuration]. Drives the
  /// swatch / recent-swatch / slider hover-focus colour transitions
  /// (Flutter widget reads it via `AnimatedContainer.duration` or the
  /// equivalent `WidgetState` animation).
  final Duration transitionDuration;

  /// Nested popover style for popover-mode picker — raw-forwarded (the
  /// `Popover`'s own resolver fills the rest).
  final CorePopoverStyle popoverStyle;

  /// Nested dialog style for dialog-mode picker.
  final CoreDialogStyle? dialogStyle;

  /// Nested button style applied to each swatch button.
  final CoreButtonStyle? swatchButtonStyle;

  /// Nested style for the composed recent-color swatch `Clickable` —
  /// raw-forwarded (the Clickable's own resolver fills the rest).
  final CoreClickableStyle recentSwatchClickableStyle;

  /// Nested text-field style applied to the hex input — raw-forwarded
  /// (the `TextField`'s own resolver fills the rest).
  final CoreTextFieldStyle hexInputStyle;

  /// Nested style for the composed mode-tabs `ToggleGroup` — raw-forwarded
  /// (the group's own resolver fills the rest).
  final CoreToggleGroupStyle modeTabsStyle;

  /// Paint-ready text style of a mode input cell's channel caption.
  final TextStyle modeInputLabelTextStyle;

  /// Paint-ready fill of the field-shaped trigger.
  final Color triggerBackgroundColor;

  /// Paint-ready border colour of the field-shaped trigger.
  final Color triggerBorderColor;

  /// Border width (scaled) of the field-shaped trigger.
  final double triggerBorderWidth;

  /// Corner radius (scaled) of the field-shaped trigger.
  final BorderRadius triggerBorderRadius;

  /// Inner padding (scaled) of the field-shaped trigger.
  final EdgeInsetsGeometry triggerPadding;

  /// Spacing (scaled) between the trigger's swatch, text and chevron.
  final double triggerSpacing;

  /// Minimum width (scaled) of the field-shaped trigger.
  final double triggerMinWidth;

  /// Paint-ready text style of the trigger's hex value.
  final TextStyle triggerValueTextStyle;

  /// Paint-ready text style of the trigger's placeholder.
  final TextStyle triggerPlaceholderTextStyle;

  /// Style of the trigger's chevron, raw-forwarded to `Icon`.
  final CoreIconStyle triggerChevronIconStyle;

  /// Paint-ready text style of the recent-colours title.
  final TextStyle recentTitleTextStyle;

  /// Gap between the recent-colours title and the swatches.
  final CoreGapStyle recentTitleGapStyle;

  /// Flex weight of the HEX input cell against each channel cell.
  final int modeHexInputFlex;

  /// Side (scaled) of each half of the inline comparison cell.
  final double compareSwatchSize;

  /// Corner radius (scaled) of the inline comparison cell.
  final BorderRadius compareBorderRadius;

  /// Paint-ready border colour of the inline comparison cell.
  final Color compareBorderColor;

  /// Border width (scaled) of the inline comparison cell.
  final double compareBorderWidth;

  /// Style of the inline presentation's panel box, raw-forwarded to `Popup`.
  final CorePopupStyle inlinePanelStyle;

  /// The deprecated `CoreColorPickerStyle.labelStyle`, carried as is.
  /// Nothing reads it — `ColorPicker` draws no label.
  @Deprecated(
    'Read by nothing — ColorPicker draws no label (since 0.185). Wrap the '
    'picker in a FormField with a label instead; this goes with '
    'CoreColorPickerStyle.labelStyle.',
  )
  final CoreTextStyle? labelStyle;

  /// The deprecated `CoreColorPickerStyle.descriptionStyle`, carried as
  /// is. Nothing reads it — `ColorPicker` draws no description.
  @Deprecated(
    'Read by nothing — ColorPicker draws no description (since 0.185). Wrap '
    'the picker in a FormField with a description instead; this goes with '
    'CoreColorPickerStyle.descriptionStyle.',
  )
  final CoreTextStyle? descriptionStyle;

  /// The deprecated `CoreColorPickerStyle.errorStyle`, carried as is.
  /// Nothing reads it — `ColorPicker` draws no error text.
  @Deprecated(
    'Read by nothing — ColorPicker draws no error text (since 0.185). Wrap '
    'the picker in a FormField that shows the error instead; this goes with '
    'CoreColorPickerStyle.errorStyle.',
  )
  final CoreTextStyle? errorStyle;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedColorPicker] for the given [context].
///
/// Walks the nested-merge chain in a single pass:
///
/// ```text
/// design system default for color picker (CoreColorPickerStyle.defaultX)
///   → theme.coreComponentTheme.colorPicker.style
///   → widget.colorPickerStyle
/// ```
ResolvedColorPicker resolveColorPicker(
  BuildContext context, {
  CoreColorPickerStyle? colorPickerStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final colorPickerTheme = theme.coreComponentTheme?.colorPicker;

  // Layer per-instance CoreColorPickerStyle:
  //   theme.style → widget.colorPickerStyle.
  final merged = resolveStyleChain(const CoreColorPickerStyle(), [
    colorPickerTheme?.style,
    colorPickerStyle,
  ]);

  // Trigger swatch size — nested `swatchButtonStyle.width` slot wins
  // (height tracks width since the swatch is square), else flat
  // `swatchSize`, else design-system default.
  final swatchSize =
      (merged.swatchButtonStyle?.width ??
          merged.swatchSize ??
          CoreColorPickerStyle.defaultSwatchSize) *
      scaling;
  // Swatch corner radius — nested `swatchButtonStyle.borderRadius` slot
  // wins, else flat `swatchBorderRadius`, else design-system default.
  // Precedence: nested `swatchButtonStyle.borderRadius` slot > flat
  // `swatchBorderRadius` > design-system default. Paint-ready (Epic #1603
  // C9) so the widget reads a Flutter [BorderRadius].
  final swatchBorderRadius =
      ((merged.swatchButtonStyle?.borderRadius ??
              merged.swatchBorderRadius ??
              CoreColorPickerStyle.defaultSwatchBorderRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;

  // Flat dimensional props — paint-ready (toValue() / fallback) here,
  // `* scaling` deferred to the return literal (single-signature rule).
  final hexInputWidth =
      (merged.hexInputWidth ?? CoreColorPickerStyle.defaultHexInputWidth) *
      scaling;
  final popoverWidth =
      (merged.popoverWidth ?? CoreColorPickerStyle.defaultPopoverWidth) *
      scaling;
  final popoverSpacing =
      theme.geometry.space(
        merged.popoverSpacing ?? CoreColorPickerStyle.defaultPopoverSpacing,
      ) *
      scaling;
  final sliderHeight =
      (merged.sliderHeight ?? CoreColorPickerStyle.defaultSliderHeight) *
      scaling;
  final modeInputSpacing =
      theme.geometry.space(
        merged.modeInputSpacing ?? CoreColorPickerStyle.defaultModeInputSpacing,
      ) *
      scaling;
  final recentSwatchSize =
      (merged.recentSwatchSize ??
          CoreColorPickerStyle.defaultRecentSwatchSize) *
      scaling;
  final recentSwatchSpacing =
      theme.geometry.space(
        merged.recentSwatchSpacing ??
            CoreColorPickerStyle.defaultRecentSwatchSpacing,
      ) *
      scaling;
  final sliderBorderRadius =
      ((merged.sliderBorderRadius ??
              CoreColorPickerStyle.defaultSliderBorderRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final recentSwatchBorderRadius =
      ((merged.recentSwatchBorderRadius ??
              CoreColorPickerStyle.defaultRecentSwatchBorderRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final pickMarkerSize =
      (merged.pickMarkerSize ?? CoreColorPickerStyle.defaultPickMarkerSize) *
      scaling;
  final pickMarkerBorderWidth = theme.geometry.stroke(
    merged.pickMarkerBorderWidth ??
        CoreColorPickerStyle.defaultPickMarkerBorderWidth,
    scaling: scaling,
  );
  final pickMarkerBorderColor = theme.colorScheme
      .resolve(
        merged.pickMarkerBorderColor ??
            CoreColorPickerStyle.defaultPickMarkerBorderColor,
      )
      .toValue();
  final pickMarkerShadow =
      (merged.pickMarkerShadow ?? CoreColorPickerStyle.defaultPickMarkerShadow)
          .toValue(
            base: theme.colorScheme
                .resolve(const CoreColor.token(CoreColors.shadow))
                .toValue(),
            geometry: theme.geometry,
            scale: scaling,
          );
  // Deprecated fill, carried as is (nothing paints it): the handle takes the
  // current colour now.
  // ignore: deprecated_member_use
  final deprecatedHueFill = merged.hueMarkerFillColor;
  final hueMarkerFillColor = deprecatedHueFill == null
      ? null
      : theme.colorScheme.resolve(deprecatedHueFill).toValue();
  final hueMarkerBorderColor = theme.colorScheme
      .resolve(
        merged.hueMarkerBorderColor ??
            CoreColorPickerStyle.defaultHueMarkerBorderColor,
      )
      .toValue();
  final hueMarkerBorderWidth = theme.geometry.stroke(
    merged.hueMarkerBorderWidth ??
        CoreColorPickerStyle.defaultHueMarkerBorderWidth,
    scaling: scaling,
  );
  final emptySwatchDashLength =
      (merged.emptySwatchDashLength ??
          CoreColorPickerStyle.defaultEmptySwatchDashLength) *
      scaling;
  final emptySwatchDashSpacing =
      (merged.emptySwatchDashSpacing ??
          CoreColorPickerStyle.defaultEmptySwatchDashSpacing) *
      scaling;
  // 2D saturation/value area corner radius — paint-ready (no scaling,
  // intentionally fixed to the design grid).
  final saturationValueBorderRadius =
      (merged.saturationValueBorderRadius ??
              CoreColorPickerStyle.defaultSaturationValueBorderRadius)
          .toValue(geometry: theme.geometry);
  // Border stroke widths — routed through `theme.geometry.stroke(...)`
  // so a surface style's `strokeFloor` (e.g. neo-brutalism) reaches the
  // swatch / saturation-value / slider borders and the recent-swatch
  // ring, matching the sibling radii above.
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreColorPickerStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final recentSwatchBorderWidth = theme.geometry.stroke(
    merged.recentSwatchBorderWidth ??
        CoreColorPickerStyle.defaultRecentSwatchBorderWidth,
    scaling: scaling,
  );
  final recentSwatchSelectedBorderWidth = theme.geometry.stroke(
    merged.recentSwatchSelectedBorderWidth ??
        CoreColorPickerStyle.defaultRecentSwatchSelectedBorderWidth,
    scaling: scaling,
  );

  // Chrome colours — Flutter EMIT: scheme.resolve(token).toValue() so
  // dark-mode lookups resolve. Both default to the single-source Core
  // tokens (outline / primary).
  final borderColor = theme.colorScheme
      .resolve(merged.borderColor ?? CoreColorPickerStyle.defaultBorderColor)
      .toValue();
  final disabledBorderColor = theme.colorScheme
      .resolve(
        merged.disabledBorderColor ??
            CoreColorPickerStyle.defaultDisabledBorderColor,
      )
      .toValue();
  final selectedRingColor = theme.colorScheme
      .resolve(
        merged.selectedRingColor ??
            CoreColorPickerStyle.defaultSelectedRingColor,
      )
      .toValue();

  // Nested CoreGapStyle / CoreIconStyle slots — design-system default
  // merged with the per-instance override (composite merge), raw-forwarded
  // to the child Gap / Icon resolvers. Synthesis lives in locals so the
  // return literal stays a bare mapping.
  final swatchGapStyle = CoreColorPickerStyle.defaultSwatchGapStyle.merge(
    merged.swatchGapStyle,
  );
  final modeInputLabelGapStyle = CoreColorPickerStyle
      .defaultModeInputLabelGapStyle
      .merge(
        merged.modeInputLabelGapStyle,
      );
  final actionRowGapStyle = CoreColorPickerStyle.defaultActionRowGapStyle.merge(
    merged.actionRowGapStyle,
  );
  final eyeDropperIconStyle = CoreColorPickerStyle.defaultEyeDropperIconStyle
      .merge(
        merged.eyeDropperIconStyle,
      );
  final recentColumns =
      merged.recentColumns ?? CoreColorPickerStyle.defaultRecentColumns;
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreColorPickerStyle.defaultTransitionDuration,
  );
  // Nested Clickable slot for the recent-color swatch — partial default
  // merged with the override, raw-forwarded (the Clickable's own resolver
  // fills the rest, including the focus ring).
  final recentSwatchClickableStyle = CoreColorPickerStyle
      .defaultRecentSwatchClickableStyle
      .merge(
        merged.recentSwatchClickableStyle,
      );
  // Popover / hex-input slots — same shape as the Clickable slot above:
  // this component's partial default merged with the caller's override,
  // then raw-forwarded so each child's own resolver fills its own
  // defaults.
  final popoverStyle = CoreColorPickerStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );
  final hexInputStyle = CoreColorPickerStyle.defaultHexInputStyle.merge(
    merged.hexInputStyle,
  );
  final modeTabsStyle = CoreColorPickerStyle.defaultModeTabsStyle.merge(
    merged.modeTabsStyle,
  );
  final modeInputLabelTextStyle = CoreColorPickerStyle
      .defaultModeInputLabelStyle
      .merge(merged.modeInputLabelStyle)
      .toValue(theme: theme);

  // Field-shaped trigger — paint-ready.
  final triggerBackgroundColor = theme.colorScheme
      .resolve(
        merged.triggerBackgroundColor ??
            CoreColorPickerStyle.defaultTriggerBackgroundColor,
      )
      .toValue();
  final triggerBorderColor = theme.colorScheme
      .resolve(
        merged.triggerBorderColor ??
            CoreColorPickerStyle.defaultTriggerBorderColor,
      )
      .toValue();
  final triggerBorderWidth = theme.geometry.stroke(
    merged.triggerBorderWidth ?? CoreColorPickerStyle.defaultTriggerBorderWidth,
    scaling: scaling,
  );
  final triggerBorderRadius =
      ((merged.triggerBorderRadius ??
              CoreColorPickerStyle.defaultTriggerBorderRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final triggerPadding =
      ((merged.triggerPadding ?? CoreColorPickerStyle.defaultTriggerPadding)
          .toGeometry(geometry: theme.geometry)) *
      scaling;
  final triggerSpacing =
      theme.geometry.space(
        merged.triggerSpacing ?? CoreColorPickerStyle.defaultTriggerSpacing,
      ) *
      scaling;
  final triggerMinWidth =
      (merged.triggerMinWidth ?? CoreColorPickerStyle.defaultTriggerMinWidth) *
      scaling;
  final triggerValueTextStyle = CoreColorPickerStyle
      .defaultTriggerValueTextStyle
      .merge(merged.triggerValueTextStyle)
      .toValue(theme: theme);
  final triggerPlaceholderTextStyle = CoreColorPickerStyle
      .defaultTriggerPlaceholderTextStyle
      .merge(merged.triggerPlaceholderTextStyle)
      .toValue(theme: theme);
  final triggerChevronIconStyle = CoreColorPickerStyle
      .defaultTriggerChevronIconStyle
      .merge(merged.triggerChevronIconStyle);

  // Panel sections.
  final recentTitleTextStyle = CoreColorPickerStyle.defaultRecentTitleTextStyle
      .merge(merged.recentTitleTextStyle)
      .toValue(theme: theme);
  final recentTitleGapStyle = CoreColorPickerStyle.defaultRecentTitleGapStyle
      .merge(merged.recentTitleGapStyle);
  final modeHexInputFlex =
      merged.modeHexInputFlex ?? CoreColorPickerStyle.defaultModeHexInputFlex;

  // Inline presentation — comparison cell + panel box.
  final compareSwatchSize =
      (merged.compareSwatchSize ??
          CoreColorPickerStyle.defaultCompareSwatchSize) *
      scaling;
  final compareBorderRadius =
      ((merged.compareBorderRadius ??
              CoreColorPickerStyle.defaultCompareBorderRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final compareBorderColor = theme.colorScheme
      .resolve(
        merged.compareBorderColor ??
            CoreColorPickerStyle.defaultCompareBorderColor,
      )
      .toValue();
  final compareBorderWidth = theme.geometry.stroke(
    merged.compareBorderWidth ?? CoreColorPickerStyle.defaultCompareBorderWidth,
    scaling: scaling,
  );
  final inlinePanelStyle = CoreColorPickerStyle.defaultInlinePanelStyle.merge(
    merged.inlinePanelStyle,
  );

  return ResolvedColorPicker(
    swatchSize: swatchSize,
    hexInputWidth: hexInputWidth,
    swatchGapStyle: swatchGapStyle,
    popoverWidth: popoverWidth,
    popoverSpacing: popoverSpacing,
    sliderHeight: sliderHeight,
    modeInputSpacing: modeInputSpacing,
    modeInputLabelGapStyle: modeInputLabelGapStyle,
    actionRowGapStyle: actionRowGapStyle,
    eyeDropperIconStyle: eyeDropperIconStyle,
    recentSwatchSize: recentSwatchSize,
    recentSwatchSpacing: recentSwatchSpacing,
    recentColumns: recentColumns,
    swatchBorderRadius: swatchBorderRadius,
    sliderBorderRadius: sliderBorderRadius,
    recentSwatchBorderRadius: recentSwatchBorderRadius,
    saturationValueBorderRadius: saturationValueBorderRadius,
    pickMarkerSize: pickMarkerSize,
    pickMarkerBorderColor: pickMarkerBorderColor,
    pickMarkerBorderWidth: pickMarkerBorderWidth,
    pickMarkerShadow: pickMarkerShadow,
    // Deprecated, carried as is — nothing paints it.
    hueMarkerFillColor: hueMarkerFillColor,
    hueMarkerBorderColor: hueMarkerBorderColor,
    hueMarkerBorderWidth: hueMarkerBorderWidth,
    emptySwatchDashLength: emptySwatchDashLength,
    emptySwatchDashSpacing: emptySwatchDashSpacing,
    borderColor: borderColor,
    borderWidth: borderWidth,
    disabledBorderColor: disabledBorderColor,
    selectedRingColor: selectedRingColor,
    recentSwatchBorderWidth: recentSwatchBorderWidth,
    recentSwatchSelectedBorderWidth: recentSwatchSelectedBorderWidth,
    transitionDuration: transitionDuration,
    popoverStyle: popoverStyle,
    dialogStyle: merged.dialogStyle,
    swatchButtonStyle: merged.swatchButtonStyle,
    recentSwatchClickableStyle: recentSwatchClickableStyle,
    hexInputStyle: hexInputStyle,
    modeTabsStyle: modeTabsStyle,
    modeInputLabelTextStyle: modeInputLabelTextStyle,
    triggerBackgroundColor: triggerBackgroundColor,
    triggerBorderColor: triggerBorderColor,
    triggerBorderWidth: triggerBorderWidth,
    triggerBorderRadius: triggerBorderRadius,
    triggerPadding: triggerPadding,
    triggerSpacing: triggerSpacing,
    triggerMinWidth: triggerMinWidth,
    triggerValueTextStyle: triggerValueTextStyle,
    triggerPlaceholderTextStyle: triggerPlaceholderTextStyle,
    triggerChevronIconStyle: triggerChevronIconStyle,
    recentTitleTextStyle: recentTitleTextStyle,
    recentTitleGapStyle: recentTitleGapStyle,
    modeHexInputFlex: modeHexInputFlex,
    compareSwatchSize: compareSwatchSize,
    compareBorderRadius: compareBorderRadius,
    compareBorderColor: compareBorderColor,
    compareBorderWidth: compareBorderWidth,
    inlinePanelStyle: inlinePanelStyle,
    // The three text slots never had an effect and are deprecated; they
    // are still carried as is until they are removed.
    // ignore: deprecated_member_use
    labelStyle: merged.labelStyle,
    // Deprecated, carried as is — see labelStyle.
    // ignore: deprecated_member_use
    descriptionStyle: merged.descriptionStyle,
    // Deprecated, carried as is — see labelStyle.
    // ignore: deprecated_member_use
    errorStyle: merged.errorStyle,
  );
}

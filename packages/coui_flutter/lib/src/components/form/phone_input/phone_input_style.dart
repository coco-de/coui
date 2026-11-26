import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedPhoneInput
// ═══════════════════════════════════════════════════

/// Resolver output for `PhoneInput`.
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus token fallback and type conversion.
/// Dimensional values are post-scaling (`theme.scaling` already
/// applied) so the widget consumes them directly.
class ResolvedPhoneInput {
  /// Creates a [ResolvedPhoneInput].
  const ResolvedPhoneInput({
    required this.borderRadius,
    required this.maxWidth,
    required this.flagGapStyle,
    required this.countryGapStyle,
    required this.height,
    required this.borderWidth,
    required this.padding,
    required this.inputFieldPadding,
    required this.selectorPadding,
    required this.dropdownItemPadding,
    required this.dropdownItemGapStyle,
    required this.popupMaxWidth,
    required this.popupMaxHeight,
    required this.popoverTopOffset,
    required this.chevronIconStyleEnabled,
    required this.chevronIconStyleDisabled,
    required this.flagSize,
    required this.dropdownFlagSize,
    required this.disabledOpacity,
    required this.popupBorderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.focusBorderColor,
    required this.hoverBorderColor,
    required this.hoverColor,
    required this.surfaceOpacity,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.dividerStyle,
    required this.dialCodeTextStyleEnabled,
    required this.dialCodeTextStyleDisabled,
    required this.bodyTextStyle,
    required this.dropdownDialCodeTextStyle,
    required this.numberFieldStyle,
    required this.searchFieldStyle,
    required this.popoverStyle,
    required this.boxShadow,
    required this.flagBorderRadius,
    required this.separatorHeight,
    required this.dropdownListPadding,
    required this.dropdownItemBorderRadius,
    required this.dropdownCheckIconStyle,
    required this.searchIconStyle,
  });

  /// Resolved outer border radius (default fallback applied).
  final BorderRadius borderRadius;

  /// Resolved maximum width of the phone-number field (logical px,
  /// post-scaling).
  final double maxWidth;

  /// Resolved nested gap style between flag and dial code inside the
  /// selector — forwarded to `Gap(gapStyle: …)`. `Gap` self-scales,
  /// so this slot carries raw (pre-scaling) values.
  final CoreGapStyle flagGapStyle;

  /// Resolved nested gap style between the country selector and the
  /// input field — forwarded to `Gap(gapStyle: …)`. `Gap`
  /// self-scales, so this slot carries raw (pre-scaling) values.
  final CoreGapStyle countryGapStyle;

  /// Resolved outer container height (logical px, post-scaling).
  final double height;

  /// Resolved outer border stroke width (logical px, pre-scaling —
  /// borders typically render unscaled to match Web `border` 1px).
  final double borderWidth;

  /// Resolved outer container padding override (logical px,
  /// post-scaling). `null` when no [CorePhoneInputStyle.padding] override
  /// is provided so the widget can keep its default zero-padding row
  /// layout (selector and field sit flush against the border).
  final EdgeInsets? padding;

  /// Resolved inner padding of the phone-number input field (logical
  /// px, post-scaling).
  final EdgeInsetsGeometry inputFieldPadding;

  /// Resolved country selector trigger padding (logical px,
  /// post-scaling).
  final EdgeInsetsGeometry selectorPadding;

  /// Resolved dropdown / search item padding (logical px,
  /// post-scaling).
  final EdgeInsets dropdownItemPadding;

  /// Resolved nested gap style between dropdown-item flag and country
  /// name — forwarded to `Gap(gapStyle: …)`. `Gap` self-scales, so
  /// this slot carries raw (pre-scaling) values.
  final CoreGapStyle dropdownItemGapStyle;

  /// Resolved maximum width of the country picker popup (logical px,
  /// post-scaling).
  final double popupMaxWidth;

  /// Resolved maximum height of the country picker popup (logical px,
  /// post-scaling).
  final double popupMaxHeight;

  /// Resolved vertical offset between the trigger and the popup
  /// (logical px, post-scaling).
  final double popoverTopOffset;

  /// Selector chevron icon style — enabled state. The base chevron slot
  /// with the `onSurface` colour token baked on. Raw forward to `Icon`,
  /// which resolves the token + runs its own scaling.
  final CoreIconStyle chevronIconStyleEnabled;

  /// Selector chevron icon style — disabled state (`onSurfaceVariant`).
  final CoreIconStyle chevronIconStyleDisabled;

  /// Resolved flag emoji font size in the selector (logical px,
  /// post-scaling).
  final double flagSize;

  /// Resolved flag emoji font size inside dropdown items (logical px,
  /// post-scaling).
  final double dropdownFlagSize;

  /// Resolved opacity applied to the component when disabled.
  final double disabledOpacity;

  /// Resolved popup surface border radius (Core type — forwarded to the
  /// `Card` surface, which applies scaling).
  final CoreBorderRadius popupBorderRadius;

  /// Resolved outer container background fill (the `surface` token).
  final Color backgroundColor;

  /// Resolved outer container border colour (the `outline` token).
  final Color borderColor;

  /// Resolved outer container border colour while an inner field is focused
  /// (the `primary` token) — the outer container owns the focus boundary.
  final Color focusBorderColor;

  /// Resolved outer container border colour while the pointer is over the
  /// field (the `onSurface` token). The widget picks it only when the field
  /// is enabled, hovered and not focused — `disabled > focus > hover > rest`.
  /// Passes through the same surface-stroke seat as [borderColor], so a
  /// material that draws its own edge suppresses the hover hairline too.
  final Color hoverBorderColor;

  /// Resolved hover / selected background for the selector trigger and
  /// the picker rows (the `surfaceContainerHigh` token by default).
  final Color hoverColor;

  /// The active style's content-role material opacity, or `null` when the
  /// style states no material — regardless of whether the fill is
  /// actually painted.
  ///
  /// Unlike [surfaceBlur] and its siblings (which additionally gate on the
  /// fill actually being painted), the widget reads this one on its own:
  /// it decides whether the fill *can* turn translucent at all, which in
  /// turn decides whether the box shadow has to move off
  /// `BoxDecoration.boxShadow` and onto `InjectedCast`
  /// (`core/theme-axis-composition.md` — "그림자는 두 플랫폼이 다른 곳에
  /// 칠한다"). Every non-glass preset leaves this `null`, so those four
  /// keep painting the shadow the original way — byte-identical to the
  /// preset-render baseline.
  final double? surfaceOpacity;

  /// Backdrop blur sigma for the outer container, `null` when the active
  /// theme states no material or the field paints no fill of its own to
  /// blur behind (a transparent `backgroundColor` override — e.g. the
  /// `PhoneInput.transparent` chrome preset) — see [backgroundColor].
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Divider slot between the selector and the input (and inside the
  /// picker) — token colour + raw thickness. Forwarded straight to
  /// `Divider(dividerStyle: …)`, which resolves the token + scales the
  /// thickness itself.
  final CoreDividerStyle dividerStyle;

  /// Selector dial-code label [TextStyle] — enabled state (`labelLarge`
  /// + medium weight + the `onSurface` colour).
  final TextStyle dialCodeTextStyleEnabled;

  /// Selector dial-code label [TextStyle] — disabled state
  /// (`onSurfaceVariant`).
  final TextStyle dialCodeTextStyleDisabled;

  /// Paint-ready `bodySmall` [TextStyle] for the country-name labels.
  final TextStyle bodyTextStyle;

  /// Resolved muted dropdown text style (paint-ready) — the `bodySmall`
  /// typography role overlaid with the merged `dropdownDialCodeTextStyle`
  /// slot and the resolved `onSurfaceVariant` colour. Drives both the
  /// dropdown-item dial-code text and the "No results" empty hint (same
  /// muted hint, no state branch).
  final TextStyle dropdownDialCodeTextStyle;

  /// Resolved phone-number field style (chromeless default overlaid with
  /// the resolved placeholder colour and nested caller override) — forwarded
  /// to the number `TextField`.
  final CoreTextFieldStyle numberFieldStyle;

  /// Resolved dropdown search-field style (chromeless default merged with the
  /// caller override) — raw-forwarded to the search `TextField`.
  final CoreTextFieldStyle searchFieldStyle;

  /// Resolved country-dropdown popover style (`triggerSizing: expand` default
  /// merged with the caller override) — raw-forwarded to the `Popover`.
  final CorePopoverStyle popoverStyle;

  /// The active surface style's injected cast, or empty under a
  /// style that injects none.
  ///
  /// This control draws its own box rather than composing
  /// `OutlinedContainer`, so the opt-in is restated. Empty under
  /// every style that casts nothing, so the widget paints it
  /// unconditionally.
  final List<BoxShadow> boxShadow;

  /// Flag corner radius — the flag in the selector and in the list rows
  /// (already bent and scaled).
  final BorderRadius flagBorderRadius;

  /// Height of the hairline between the selector and the number (already
  /// scaled).
  final double separatorHeight;

  /// Padding of the country list inside the panel (already scaled).
  final EdgeInsets dropdownListPadding;

  /// Country row corner radius (already bent and scaled).
  final BorderRadius dropdownItemBorderRadius;

  /// Selected-country check glyph — raw-forwarded to `Icon`.
  final CoreIconStyle dropdownCheckIconStyle;

  /// Search glyph in front of the country search field — raw-forwarded to
  /// `Icon`.
  final CoreIconStyle searchIconStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedPhoneInput] for the given [context].
///
/// Walks the nested-merge chain plus token fallback in a single pass:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.phoneInput.style
///   → widget.phoneInputStyle
/// ```
ResolvedPhoneInput resolvePhoneInput(
  BuildContext context, {
  bool enabled = true,
  CorePhoneInputStyle? phoneInputStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final phoneInputTheme = theme.coreComponentTheme?.phoneInput;

  final merged = resolveStyleChain(const CorePhoneInputStyle(), [
    phoneInputTheme?.style,
    phoneInputStyle,
  ]);

  // ─── Stage1 RESOLVE — Core values (merge + default fallback) ───
  final borderRadiusCore =
      merged.borderRadius ?? CorePhoneInputStyle.defaultBorderRadius;
  final popupBorderRadiusCore =
      merged.popupBorderRadius ?? CorePhoneInputStyle.defaultPopupBorderRadius;
  final selectorPaddingCore =
      merged.selectorPadding ?? CorePhoneInputStyle.defaultSelectorPadding;
  final inputFieldPaddingCore =
      merged.inputFieldPadding ?? CorePhoneInputStyle.defaultInputFieldPadding;
  final dropdownItemPaddingCore =
      merged.dropdownItemPadding ??
      CorePhoneInputStyle.defaultDropdownItemPadding;
  final paddingCore = merged.padding;

  // Nested gap-style slots — `Gap` self-scales so we forward raw
  // (pre-scaling) values.
  final flagGapStyleCore = CorePhoneInputStyle.defaultFlagGapStyle.merge(
    merged.flagGapStyle,
  );
  final countryGapStyleCore = CorePhoneInputStyle.defaultCountryGapStyle.merge(
    merged.countryGapStyle,
  );
  final dropdownItemGapStyleCore = CorePhoneInputStyle
      .defaultDropdownItemGapStyle
      .merge(merged.dropdownItemGapStyle);

  // Raw (un-bent) — forwarded as-is to the nested `Divider` slot below,
  // which self-scales/self-bends via its own resolver. The container's
  // OWN border (used directly by the widget) needs the bent value
  // instead — see `borderWidth` below.
  final borderWidthCore =
      merged.borderWidth ?? CorePhoneInputStyle.defaultBorderWidth;
  final borderWidth = theme.geometry.stroke(borderWidthCore, scaling: scaling);
  final separatorColorCore =
      merged.separatorColor ?? CorePhoneInputStyle.defaultSeparatorColor;
  final disabledDialCodeColorCore =
      merged.disabledDialCodeColor ??
      CorePhoneInputStyle.defaultDisabledDialCodeColor;
  final placeholderColorCore =
      merged.placeholderColor ?? CorePhoneInputStyle.defaultPlaceholderColor;
  final hoverBorderColorCore =
      merged.hoverBorderColor ?? CorePhoneInputStyle.defaultHoverBorderColor;

  // Muted dropdown text — `bodySmall` role + `onSurfaceVariant` colour
  // live in `defaultDropdownDialCodeTextStyle`; layer the per-instance
  // slot over it. Drives both the dropdown-item dial code and the
  // "No results" empty hint (same muted hint, no state branch).
  final dropdownDialCodeTextStyleCore = CorePhoneInputStyle
      .defaultDropdownDialCodeTextStyle
      .merge(merged.dropdownDialCodeTextStyle);
  // Dial-code label — `labelLarge` + medium weight + the `onSurface`
  // colour live in `defaultDialCodeTextStyle`; layer the per-instance slot
  // over it. The disabled state reuses the same role + weight and swaps the
  // colour to `disabledDialCodeColorCore`.
  final dialCodeTextStyleCore = CorePhoneInputStyle.defaultDialCodeTextStyle
      .merge(merged.dialCodeTextStyle);
  final bodyTextStyleCore = CorePhoneInputStyle.defaultBodyTextStyle.merge(
    merged.bodyTextStyle,
  );

  // Selector chevron per state — base slot + the per-state label colour.
  final chevronBaseCore = CorePhoneInputStyle.defaultChevronIconStyle.merge(
    merged.chevronIconStyle,
  );
  final chevronColorCore =
      merged.chevronColor ?? CorePhoneInputStyle.defaultChevronColor;
  final disabledChevronColorCore =
      merged.disabledChevronColor ??
      CorePhoneInputStyle.defaultDisabledChevronColor;
  final chevronIconStyleEnabledCore = chevronBaseCore.merge(
    CoreIconStyle(color: chevronColorCore),
  );
  final chevronIconStyleDisabledCore = chevronBaseCore.merge(
    CoreIconStyle(color: disabledChevronColorCore),
  );

  // ─── Stage2 EMIT — paint-ready Flutter values (theme-dependent) ───
  final borderRadius = borderRadiusCore.toValue(geometry: theme.geometry);
  final padding = paddingCore?.toValue(geometry: theme.geometry);
  final paddingScaled = padding == null ? null : padding * scaling;
  final inputFieldPadding =
      inputFieldPaddingCore.toGeometry(geometry: theme.geometry) * scaling;
  final selectorPadding =
      selectorPaddingCore.toGeometry(geometry: theme.geometry) * scaling;
  final dropdownItemPadding =
      dropdownItemPaddingCore.toValue(geometry: theme.geometry) * scaling;
  final maxWidth =
      (merged.maxWidth ?? CorePhoneInputStyle.defaultMaxWidth) * scaling;
  // The box is a row of the control ladder (the md rung, the row of the
  // text field beside it): it moves a rung under the theme density. A
  // caller's own height is a statement and stays as stated.
  final height =
      (merged.height ??
          theme.geometry.controlHeight(CorePhoneInputStyle.defaultHeight)) *
      scaling;
  final popupMaxWidth =
      (merged.popupMaxWidth ?? CorePhoneInputStyle.defaultPopupMaxWidth) *
      scaling;
  final popupMaxHeight =
      (merged.popupMaxHeight ?? CorePhoneInputStyle.defaultPopupMaxHeight) *
      scaling;
  final popoverTopOffset =
      (merged.popoverTopOffset ?? CorePhoneInputStyle.defaultPopoverTopOffset) *
      scaling;
  final flagSize =
      (merged.flagSize ?? CorePhoneInputStyle.defaultFlagSize) * scaling;
  final dropdownFlagSize =
      (merged.dropdownFlagSize ?? CorePhoneInputStyle.defaultDropdownFlagSize) *
      scaling;
  final disabledOpacity =
      merged.disabledOpacity ?? CorePhoneInputStyle.defaultDisabledOpacity;

  // The field draws its own box directly (the outer `Container` in
  // `phone_input.dart`) rather than composing `OutlinedContainer` — the
  // inner number `TextField` is deliberately chromeless
  // ([CorePhoneInputStyle.chromelessFieldStyle]) so the outer box owns the
  // single visible boundary, and a wrap here would move that boundary to
  // a different element than the one the focus swap rings. A glass
  // style's material reaches it the same way it reaches a card — through
  // the content-layer seat, folded into the fill below.
  final material = theme.surfaceFor(.content, depth: SurfaceDepth.of(context));
  final surfaceOpacity = material?.opacityIn(theme);
  final backgroundColorCore = enabled
      ? merged.backgroundColor ?? CorePhoneInputStyle.defaultBackgroundColor
      : merged.disabledBackgroundColor ??
            CorePhoneInputStyle.defaultDisabledBackgroundColor;
  final backgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? backgroundColorCore
            : backgroundColorCore.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  final hasFill = backgroundColor.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheen = hasFill ? resolveSurfaceSheen(theme) : null;
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the field's
  // hairline so the box doesn't draw a second boundary on top of it.
  // Applied to the idle, focus and hover border colours so whichever the
  // widget picks stays consistent.
  final borderColor = resolveSurfaceStroke(
    theme,
    scheme
        .resolve(
          enabled
              ? merged.borderColor ?? CorePhoneInputStyle.defaultBorderColor
              : merged.disabledBorderColor ??
                    CorePhoneInputStyle.defaultDisabledBorderColor,
        )
        .toValue(),
  );
  final focusBorderColor = resolveSurfaceStroke(
    theme,
    scheme
        .resolve(
          merged.focusBorderColor ??
              CorePhoneInputStyle.defaultFocusBorderColor,
        )
        .toValue(),
  );
  final hoverBorderColor = resolveSurfaceStroke(
    theme,
    scheme.resolve(hoverBorderColorCore).toValue(),
  );
  final hoverColor = scheme
      .resolve(merged.hoverColor ?? CorePhoneInputStyle.defaultHoverColor)
      .toValue();

  // Divider — token colour + raw thickness; `Divider` self-scales.
  final dividerStyle = CoreDividerStyle(
    color: separatorColorCore,
    thickness: borderWidthCore,
  );

  // Per-state dial-code label (single primitive — `.toValue(theme:)`
  // materialises the role + resolves its colour). Enabled uses the slot's
  // own `onSurface`; disabled overrides the colour.
  final disabledDialCodeColor = scheme
      .resolve(disabledDialCodeColorCore)
      .toValue();
  final dialCodeTextStyleEnabled = dialCodeTextStyleCore.toValue(theme: theme);
  final dialCodeTextStyleDisabled = dialCodeTextStyleCore.toValue(
    color: disabledDialCodeColor,
    theme: theme,
  );
  final bodyTextStyle = bodyTextStyleCore.toValue(theme: theme);
  final dropdownDialCodeTextStyle = dropdownDialCodeTextStyleCore.toValue(
    theme: theme,
  );
  // Nested child-component Style slots — merged with their Core defaults and
  // raw-forwarded (the child TextField / Popover resolve them). The
  // top-level `placeholderColor` convenience field overlays both the
  // number field and the search field's placeholder tone (applied before
  // the per-instance `searchFieldStyle` override so a caller-supplied
  // nested placeholder style still wins for its respective field).
  final placeholderOverlay = CorePhoneInputStyle.placeholderFieldStyle(
    enabled
        ? placeholderColorCore
        : merged.disabledPlaceholderColor ??
              CorePhoneInputStyle.defaultDisabledPlaceholderColor,
  );
  final numberFieldStyle = CorePhoneInputStyle.defaultNumberFieldStyle
      .merge(placeholderOverlay)
      .merge(merged.numberFieldStyle);
  final searchFieldStyle = CorePhoneInputStyle.defaultSearchFieldStyle
      .merge(placeholderOverlay)
      .merge(merged.searchFieldStyle);
  final popoverStyle = CorePhoneInputStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );
  // Flag corner, the hairline's height and the country list's own chrome —
  // the same values the item picker's panel states.
  final flagBorderRadius =
      (merged.flagBorderRadius ?? CorePhoneInputStyle.defaultFlagBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final separatorHeight =
      (merged.separatorHeight ?? CorePhoneInputStyle.defaultSeparatorHeight) *
      scaling;
  final dropdownListPadding =
      (merged.dropdownListPadding ??
              CorePhoneInputStyle.defaultDropdownListPadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  final dropdownItemBorderRadius =
      (merged.dropdownItemBorderRadius ??
              CorePhoneInputStyle.defaultDropdownItemBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final dropdownCheckIconStyle = CorePhoneInputStyle
      .defaultDropdownCheckIconStyle
      .merge(merged.dropdownCheckIconStyle);
  final searchIconStyle = CorePhoneInputStyle.defaultSearchIconStyle.merge(
    merged.searchIconStyle,
  );

  // The style injects its cast into surfaces that state no shadow of
  // their own — empty under every style that injects none.
  final boxShadow = resolveInjectedCast(theme);

  return ResolvedPhoneInput(
    boxShadow: boxShadow,
    borderRadius: borderRadius,
    maxWidth: maxWidth,
    flagGapStyle: flagGapStyleCore,
    countryGapStyle: countryGapStyleCore,
    height: height,
    borderWidth: borderWidth,
    padding: paddingScaled,
    inputFieldPadding: inputFieldPadding,
    selectorPadding: selectorPadding,
    dropdownItemPadding: dropdownItemPadding,
    dropdownItemGapStyle: dropdownItemGapStyleCore,
    popupMaxWidth: popupMaxWidth,
    popupMaxHeight: popupMaxHeight,
    popoverTopOffset: popoverTopOffset,
    // Raw forward — `Icon`'s own resolver resolves the colour token +
    // applies `theme.scaling`.
    chevronIconStyleEnabled: chevronIconStyleEnabledCore,
    chevronIconStyleDisabled: chevronIconStyleDisabledCore,
    flagSize: flagSize,
    dropdownFlagSize: dropdownFlagSize,
    disabledOpacity: disabledOpacity,
    popupBorderRadius: popupBorderRadiusCore,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    focusBorderColor: focusBorderColor,
    hoverBorderColor: hoverBorderColor,
    hoverColor: hoverColor,
    surfaceOpacity: surfaceOpacity,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    dividerStyle: dividerStyle,
    dialCodeTextStyleEnabled: dialCodeTextStyleEnabled,
    dialCodeTextStyleDisabled: dialCodeTextStyleDisabled,
    bodyTextStyle: bodyTextStyle,
    dropdownDialCodeTextStyle: dropdownDialCodeTextStyle,
    numberFieldStyle: numberFieldStyle,
    searchFieldStyle: searchFieldStyle,
    popoverStyle: popoverStyle,
    flagBorderRadius: flagBorderRadius,
    separatorHeight: separatorHeight,
    dropdownListPadding: dropdownListPadding,
    dropdownItemBorderRadius: dropdownItemBorderRadius,
    dropdownCheckIconStyle: dropdownCheckIconStyle,
    searchIconStyle: searchIconStyle,
  );
}

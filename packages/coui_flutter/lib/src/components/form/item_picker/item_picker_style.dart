import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedItemPicker
// ═══════════════════════════════════════════════════

/// Resolver output for `ItemPicker`.
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus token lookup and type conversion.
class ResolvedItemPicker {
  /// Creates a [ResolvedItemPicker].
  const ResolvedItemPicker({
    required this.containerStyle,
    required this.hoveredContainerStyle,
    required this.maxHeight,
    required this.searchHeight,
    required this.searchFieldStyle,
    required this.searchIconStyle,
    required this.searchDividerStyle,
    required this.selectedColor,
    required this.optionHoverColor,
    required this.optionTextStyle,
    required this.optionSelectedTextStyle,
    required this.optionHoverTextStyle,
    required this.checkIconStyle,
    required this.titleTextStyle,
    required this.emptyTextStyle,
    required this.titlePadding,
    required this.itemsPadding,
    required this.optionPadding,
    required this.optionSpacing,
    required this.optionBorderRadius,
    required this.emptyPadding,
    required this.clickableStyle,
  });

  /// Composed-`OutlinedContainer` chrome for the picker panel box
  /// (pre-EMIT `CoreOutlinedContainerStyle`) — fill / border / radius /
  /// cast / material all flow through the composed primitive rather
  /// than a hand-rolled `Container` + independently-derived `SurfaceBlur`
  /// (the material / cast the primitive already resolves internally).
  /// `role` is left unset (`.content` — this box sits in the flow, not
  /// mounted over content), so no separate field carries it.
  final CoreOutlinedContainerStyle containerStyle;

  /// The same panel chrome as [containerStyle] with the border swapped to
  /// `hoverBorderColor` — what the composed `OutlinedContainer` is given
  /// while the pointer is over an enabled picker (`disabled > hover >
  /// rest`; the picker has no container-level focus or error state).
  final CoreOutlinedContainerStyle hoveredContainerStyle;

  /// Picker items scroll-area maximum height (logical px, scaled).
  final double maxHeight;

  /// Search-field height (logical px, already scaled).
  final double searchHeight;

  /// Nested chrome of the composed search `TextField` —
  /// [CoreItemPickerStyle.defaultSearchFieldStyle] (the picker frame's
  /// corner, so the field is no rounder than the box it sits in) merged
  /// with the per-instance `searchFieldStyle`. Raw-forwarded to
  /// `TextField(textFieldStyle: …)`, whose resolver fills the rest.
  final CoreTextFieldStyle searchFieldStyle;

  /// Search glyph in front of the search field — the design default merged
  /// with the per-instance override, the colour swapped to the disabled
  /// tone while the picker is disabled. Raw-forwarded to `Icon`.
  final CoreIconStyle searchIconStyle;

  /// `Divider` chrome closing the search row — raw-forwarded to
  /// `Divider(dividerStyle:)`.
  final CoreDividerStyle searchDividerStyle;

  /// Selected option background colour.
  final Color selectedColor;

  /// Option hover background colour.
  final Color optionHoverColor;

  /// Paint-ready option label text style for the resting state
  /// (`bodyMedium` + `onSurface`).
  final TextStyle optionTextStyle;

  /// Paint-ready option label text style for the selected state
  /// (`bodyMedium` + selected text colour).
  final TextStyle optionSelectedTextStyle;

  /// Paint-ready option label text style for the hover state
  /// (`bodyMedium` + hover text colour).
  final TextStyle optionHoverTextStyle;

  /// Selected-option check-icon style — raw size + the selected text
  /// colour token baked in. Forwarded straight to `Icon`, which
  /// resolves the colour + applies `theme.scaling`.
  final CoreIconStyle checkIconStyle;

  /// Picker title text style — paint-ready. The `labelSmall` typography
  /// role overlaid with the resolved `titleTextStyle` slot (`onSurfaceSubtle`
  /// colour by default).
  final TextStyle titleTextStyle;

  /// Empty-state text style — paint-ready. The `bodySmall` typography
  /// role overlaid with the resolved `emptyTextStyle` slot
  /// (`onSurfaceVariant` colour by default).
  final TextStyle emptyTextStyle;

  /// Picker title padding (already scaled).
  final EdgeInsets titlePadding;

  /// Picker items scroll-area padding (already scaled).
  final EdgeInsets itemsPadding;

  /// Option row padding (already scaled).
  final EdgeInsets optionPadding;

  /// Inter-option spacing (logical px, scaling pre-applied). Flows
  /// directly into `GridView.count` `mainAxisSpacing` / `crossAxisSpacing`
  /// (grid layout) and `Row.spacing` between the selected-check icon and
  /// the option label — both are native paint-API arguments that consume
  /// raw doubles, so the widget reads this value directly without
  /// re-multiplying by scaling.
  final double optionSpacing;

  /// Option row corner radius (already scaled).
  final BorderRadius optionBorderRadius;

  /// Empty-state padding (already scaled).
  final EdgeInsets emptyPadding;

  /// Nested [CoreClickableStyle] slot for the composed per-option
  /// `Clickable` — `CoreItemPickerStyle.defaultClickableStyle` merged with
  /// the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// resolveItemPicker — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedItemPicker] for the given [context].
///
/// Walks the nested-merge chain plus token / dimensional fallback:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.itemPicker.style
///   → widget.itemPickerStyle
/// ```
ResolvedItemPicker resolveItemPicker(
  BuildContext context, {
  bool enabled = true,
  CoreItemPickerStyle? itemPickerStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final pickerTheme = theme.coreComponentTheme?.itemPicker;

  final merged = resolveStyleChain(const CoreItemPickerStyle(), [
    pickerTheme?.style,
    itemPickerStyle,
  ]);

  // ─── EMIT Stage 2 (Flutter) — colour ─────────────────
  final selectedColor = scheme
      .resolve(merged.selectedColor ?? CoreItemPickerStyle.defaultSelectedColor)
      .toValue();
  final optionHoverColor = scheme
      .resolve(
        merged.optionHoverColor ?? CoreItemPickerStyle.defaultOptionHoverColor,
      )
      .toValue();

  // A disabled picker says so in its own token — the option text, the
  // check, the title and the empty-state line take
  // `disabledForegroundColor`, in every state: a disabled row has no hover
  // step and its selected mark is as inert as the rest.
  final disabledForegroundColor =
      merged.disabledForegroundColor ??
      CoreItemPickerStyle.defaultDisabledForegroundColor;
  final disabledTextStyle = enabled
      ? null
      : CoreTextStyle(color: disabledForegroundColor);

  // ─── Title / empty typography (paint-ready TextStyle) ─
  // Single primitive — `default.merge(override).toValue(theme:)`
  // materialises the token role then resolves the slot's own colour
  // through the active scheme; the disabled colour goes on last.
  final titleTextStyle = CoreItemPickerStyle.defaultTitleTextStyle
      .merge(merged.titleTextStyle)
      .merge(disabledTextStyle)
      .toValue(theme: theme);
  final emptyTextStyle = CoreItemPickerStyle.defaultEmptyTextStyle
      .merge(merged.emptyTextStyle)
      .merge(disabledTextStyle)
      .toValue(theme: theme);

  // ─── Option label typography (paint-ready, per state) ─
  // The `bodyMedium` + `onSurface` resting role lives in
  // `defaultOptionTextStyle`; the selected / hover slots overlay only
  // their colour on top of that same role. Single primitive
  // `default.merge(overlay).toValue(theme:)` per state.
  final optionTextStyle = CoreItemPickerStyle.defaultOptionTextStyle
      .merge(merged.optionTextStyle)
      .merge(disabledTextStyle)
      .toValue(theme: theme);
  final optionSelectedTextStyle = CoreItemPickerStyle.defaultOptionTextStyle
      .merge(CoreItemPickerStyle.defaultSelectedTextStyle)
      .merge(merged.selectedTextStyle)
      .merge(disabledTextStyle)
      .toValue(theme: theme);
  final optionHoverTextStyle = CoreItemPickerStyle.defaultOptionTextStyle
      .merge(CoreItemPickerStyle.defaultOptionHoverTextStyle)
      .merge(merged.optionHoverTextStyle)
      .toValue(theme: theme);

  // Selected-option check icon — raw size (Icon scales) + the selected
  // text colour *token* (Icon resolves it; no widget-side round-trip).
  final checkIconStyle = CoreIconStyle(
    size: merged.checkIconSize ?? CoreItemPickerStyle.defaultCheckIconSize,
    color: enabled
        ? merged.checkColor ?? CoreItemPickerStyle.defaultCheckColor
        : disabledForegroundColor,
  );

  // ─── Dimensional props (paint-ready, scaling pre-applied) ────
  // `* scaling` is Stage2 EMIT — it produces the paint-ready scaled
  // value, so it lives in the local (the return literal stays bare).
  final maxHeight =
      (merged.maxHeight ?? CoreItemPickerStyle.defaultMaxHeight) * scaling;
  // The search row is a row of the control ladder (the composed field's
  // own md rung): it moves a rung under the theme density, with every other
  // md field. A caller's own height is a statement and stays as stated.
  //
  // One exception, kept in step with Web: a `searchFieldStyle` that states
  // a height of its own. The row still beats it, but Web can only beat it
  // with a forwarded length — which no density reaches — so the row holds
  // the authored rung here too rather than let the two platforms part.
  final fieldStatesHeight =
      merged.searchFieldStyle?.height != null ||
      merged.searchFieldStyle?.minHeight != null;
  final searchHeight =
      (merged.searchHeight ??
          (fieldStatesHeight
              ? CoreItemPickerStyle.defaultSearchHeight
              : theme.geometry.controlHeight(
                  CoreItemPickerStyle.defaultSearchHeight,
                ))) *
      scaling;
  final titlePadding =
      (merged.titlePadding ?? CoreItemPickerStyle.defaultTitlePadding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final itemsPadding =
      (merged.itemsPadding ?? CoreItemPickerStyle.defaultItemsPadding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final optionPadding =
      (merged.optionPadding ?? CoreItemPickerStyle.defaultOptionPadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  // Inter-option spacing — paint-ready scalar (`Wrap.spacing` / grid
  // `mainAxisSpacing` / `crossAxisSpacing` / `Row.spacing` all consume
  // raw doubles). Per-instance override wins, else the design-system
  // default. Scaling applied once here so the widget reads a paint-ready
  // value (no widget-side `* scaling` Anti-C).
  final optionSpacing =
      theme.geometry.space(
        merged.optionSpacing ?? CoreItemPickerStyle.defaultOptionSpacing,
      ) *
      scaling;
  final optionBorderRadius =
      (merged.optionBorderRadius ??
              CoreItemPickerStyle.defaultOptionBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final emptyPadding =
      (merged.emptyPadding ?? CoreItemPickerStyle.defaultEmptyPadding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  // Nested search-field slot — the partial default (the frame's corner)
  // merged with the override, raw-forwarded (the TextField's own
  // resolver fills the rest; the row height stays `searchHeight`).
  final searchFieldStyle = CoreItemPickerStyle.defaultSearchFieldStyle.merge(
    merged.searchFieldStyle,
  );
  // Nested search glyph / divider slots — defaults merged with the
  // override, raw-forwarded (`Icon` / `Divider` resolve their own chrome).
  // A disabled picker takes the disabled tone unless the override states one.
  final searchIconBase = CoreItemPickerStyle.defaultSearchIconStyle.merge(
    merged.searchIconStyle,
  );
  final searchIconStyle = enabled || merged.searchIconStyle?.color != null
      ? searchIconBase
      : searchIconBase.merge(
          const CoreIconStyle(
            color: CoreItemPickerStyle.defaultDisabledSearchIconColor,
          ),
        );
  final searchDividerStyle = CoreItemPickerStyle.defaultSearchDividerStyle
      .merge(merged.searchDividerStyle);
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreItemPickerStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT ──────────
  // The panel is the box `Card` / `Alert` compose, not a hand-rolled
  // decoration + independently-derived `SurfaceBlur` — passing Core
  // values (not resolved ones) is what keeps the scheme-resolve /
  // geometry / scaling / material / cast bend applied exactly once,
  // by `OutlinedContainer` itself. No `width` / `height` — the panel
  // sizes to its content, so both stay unset ("size to child", per
  // `CoreOutlinedContainerStyle.width`'s doc). No `padding` either —
  // the title / items / empty sections carry their own padding.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor:
        merged.backgroundColor ?? CoreItemPickerStyle.defaultBackgroundColor,
    borderColor: merged.borderColor ?? CoreItemPickerStyle.defaultBorderColor,
    borderRadius:
        merged.borderRadius ?? CoreItemPickerStyle.defaultBorderRadius,
    borderWidth: merged.borderWidth ?? CoreItemPickerStyle.defaultBorderWidth,
    elevation: merged.elevation ?? CoreItemPickerStyle.defaultElevation,
  );
  // Hover swaps the border colour only — every other field is the resting
  // chrome, so a hovered picker is never a different box.
  final hoveredContainerStyle = containerStyle.copyWith(
    borderColor:
        merged.hoverBorderColor ?? CoreItemPickerStyle.defaultHoverBorderColor,
  );

  return ResolvedItemPicker(
    containerStyle: containerStyle,
    hoveredContainerStyle: hoveredContainerStyle,
    maxHeight: maxHeight,
    searchHeight: searchHeight,
    searchFieldStyle: searchFieldStyle,
    searchIconStyle: searchIconStyle,
    searchDividerStyle: searchDividerStyle,
    selectedColor: selectedColor,
    optionHoverColor: optionHoverColor,
    optionTextStyle: optionTextStyle,
    optionSelectedTextStyle: optionSelectedTextStyle,
    optionHoverTextStyle: optionHoverTextStyle,
    checkIconStyle: checkIconStyle,
    titleTextStyle: titleTextStyle,
    emptyTextStyle: emptyTextStyle,
    titlePadding: titlePadding,
    itemsPadding: itemsPadding,
    optionPadding: optionPadding,
    optionSpacing: optionSpacing,
    optionBorderRadius: optionBorderRadius,
    emptyPadding: emptyPadding,
    clickableStyle: clickableStyle,
  );
}

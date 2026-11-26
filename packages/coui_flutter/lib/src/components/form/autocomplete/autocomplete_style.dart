import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedAutocomplete
// ═══════════════════════════════════════════════════

/// Resolver output for `Autocomplete`.
///
/// Single struct that the widget reads — every chrome / dimensional /
/// nested-slot override has been merged through:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.autocomplete.style
///   → widget.autocompleteStyle
/// ```
///
/// Widget tree:
///
/// ```text
/// Popover (popoverStyle — owns the panel surface chrome)
///   ├─ trigger Input
///   └─ panel ConstrainedBox(maxHeight: dropdownMaxHeight)
///         └─ SingleChildScrollView → Column
///              └─ option row — uses dropdownTextStyle / optionHover* /
///                 optionBorderRadius / optionPadding
/// ```
///
/// The suggestion-panel box (background / border / radius / shadow /
/// padding) is owned by the composed `Popover` → `Popup`, so
/// `Autocomplete` declares no panel chrome of its own — it flows through
/// [popoverStyle]`.panelStyle` (a `CorePopupStyle`, the single source of
/// truth). [popoverStyle] is raw-forwarded so the `Popover` resolver
/// merges it through its own chain.
class ResolvedAutocomplete {
  /// Creates a [ResolvedAutocomplete].
  const ResolvedAutocomplete({
    required this.popoverStyle,
    required this.dropdownTextStyle,
    required this.matchTextStyle,
    required this.optionHoverColor,
    required this.optionHoverTextStyle,
    required this.dropdownMaxHeight,
    required this.optionBorderRadius,
    required this.optionPadding,
  });

  /// Nested popover style — raw-forwarded to the wrapping [Popover] so
  /// the trigger↔panel gap / panel chrome / animation cascade through
  /// the same merge chain as a standalone popover. `null` leaves the
  /// panel at the `Popup` defaults.
  final CorePopoverStyle? popoverStyle;

  /// Resolved suggestion / option text style (enabled / non-hovered)
  /// already carrying the resolved text colour.
  final TextStyle dropdownTextStyle;

  /// Resolved text style of the part of a label that matches the query
  /// (SemiBold `onSurface` by default). Laid over the label's base style.
  final TextStyle matchTextStyle;

  /// Resolved option hover background colour.
  final Color optionHoverColor;

  /// Resolved option text style applied when the option is hovered —
  /// already carrying the resolved hover text colour.
  final TextStyle optionHoverTextStyle;

  /// Suggestion-list maximum height (already scaled). Constrains the
  /// option list, not the panel box.
  final double dropdownMaxHeight;

  /// Option row border radius (paint-ready; radius is not scaled,
  /// matching the resting-corner convention of the reference resolvers).
  final BorderRadius optionBorderRadius;

  /// Option row padding (already scaled).
  final EdgeInsets optionPadding;
}

// ═══════════════════════════════════════════════════
// resolveAutocomplete — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAutocomplete] for [Autocomplete].
///
/// All chrome / dimensional overrides flow through the single
/// [autocompleteStyle] slot.
ResolvedAutocomplete resolveAutocomplete(
  BuildContext context, {
  CoreAutocompleteStyle? autocompleteStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final acTheme = theme.coreComponentTheme?.autocomplete;

  final merged = resolveStyleChain(const CoreAutocompleteStyle(), [
    acTheme?.style,
    autocompleteStyle,
  ]);

  // ─── Nested popover slot (raw-forward) ────────────────
  // The wrapping `Popover` (→ `Popup`) owns the suggestion-panel box, so
  // `Autocomplete` declares no panel chrome of its own — the panel
  // (background / border / radius / shadow / padding) flows entirely
  // through `popoverStyle.panelStyle` (a `CorePopupStyle`) and is filled
  // by `Popup`'s defaults unless the caller overrides it.
  final popoverStyle = CoreAutocompleteStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );

  // ─── Stage 2 EMIT (colour) ────────────────────────────
  // `scheme.resolve(c).toValue()` materialises the token through the
  // active scheme so light/dark tracks.
  final optionHoverColor = scheme
      .resolve(
        merged.optionHoverColor ??
            CoreAutocompleteStyle.defaultOptionHoverColor,
      )
      .toValue();

  // ─── Stage 2 EMIT (typography) ────────────────────────
  // `default.merge(override).toValue(theme:)` — single primitive
  // materialises the token role and resolves its slot colour through the
  // active scheme.
  final dropdownTextStyle = CoreAutocompleteStyle.defaultDropdownTextStyle
      .merge(merged.dropdownTextStyle)
      .toValue(theme: theme);
  final optionHoverTextStyle = CoreAutocompleteStyle.defaultOptionHoverTextStyle
      .merge(merged.optionHoverTextStyle)
      .toValue(theme: theme);
  final matchTextStyle = CoreAutocompleteStyle.defaultMatchTextStyle
      .merge(merged.matchTextStyle)
      .toValue(theme: theme);

  // ─── Stage 2 EMIT (dimensional) ───────────────────────
  // `* scaling` is Stage 2 EMIT — done in the local so the return literal
  // stays a bare mapping.
  final dropdownMaxHeight =
      (merged.dropdownMaxHeight ??
          CoreAutocompleteStyle.defaultDropdownMaxHeight) *
      scaling;
  final optionBorderRadius =
      (merged.optionBorderRadius ??
              CoreAutocompleteStyle.defaultOptionBorderRadius)
          .toValue(geometry: theme.geometry);
  final optionPadding =
      (merged.optionPadding ?? CoreAutocompleteStyle.defaultOptionPadding)
          .toValue(geometry: theme.geometry) *
      scaling;

  return ResolvedAutocomplete(
    popoverStyle: popoverStyle,
    dropdownTextStyle: dropdownTextStyle,
    matchTextStyle: matchTextStyle,
    optionHoverColor: optionHoverColor,
    optionHoverTextStyle: optionHoverTextStyle,
    dropdownMaxHeight: dropdownMaxHeight,
    optionBorderRadius: optionBorderRadius,
    optionPadding: optionPadding,
  );
}

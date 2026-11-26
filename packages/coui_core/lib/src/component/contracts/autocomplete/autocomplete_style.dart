/// Per-instance style for `Autocomplete`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/popover/popover_style.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Autocomplete` should render.
///
/// `Autocomplete` composes the unified `Popover` for its suggestion
/// dropdown (the input is the trigger; the suggestion list is the
/// floating panel), mirroring `Select`. The panel **box** chrome
/// (background / border / radius / padding / shadow) is therefore not
/// declared here — it flows through [popoverStyle]`.panelStyle` (a
/// `CorePopupStyle`, the single source of truth for the floating panel
/// box). This style carries only the option-list constraint
/// ([dropdownMaxHeight]) and the per-option-row chrome.
///
/// Behavioural / semantic fields (`suggestions`, `value`, `placeholder`,
/// `enabled`, `required`, `name`, `mode`, callbacks) stay flat on the
/// widget / contract.
///
/// ```text
/// design system default
///   → CoreAutocompleteTheme.style                // 프로젝트 공통
///   → parent component slot override
///   → widget.autocompleteStyle                   // 인스턴스별
/// ```
@immutable
class CoreAutocompleteStyle implements CoreStyle<CoreAutocompleteStyle> {
  /// Creates a [CoreAutocompleteStyle].
  const CoreAutocompleteStyle({
    this.popoverStyle,
    this.dropdownTextStyle,
    this.matchTextStyle,
    this.dropdownMaxHeight,
    this.optionHoverColor,
    this.optionHoverTextStyle,
    this.optionBorderRadius,
    this.optionPadding,
  });

  /// Default popover style — field-trigger convention: the trigger
  /// fills the available inline axis instead of shrink-wrapping (each
  /// platform would otherwise settle on a different "natural" input
  /// width). Partial on purpose — the panel box flows through
  /// `Popup`'s own defaults; the per-instance [popoverStyle] merges on
  /// top.
  static const CorePopoverStyle defaultPopoverStyle = CorePopoverStyle(
    triggerSizing: .expand,
    placementOffset: CoreSpace.space4,
    panelStyle: CorePopupStyle(padding: CorePopupStyle.defaultListPadding),
  );

  // ─── Design-system defaults ────────────────────

  /// Default option hover background colour token — the opaque
  /// `surfaceContainerHigh` tone, a neutral step off the panel rather than
  /// an accent fill (CoUI's accent is the `primary` colour).
  static const CoreColor defaultOptionHoverColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default text style for the part of a suggestion label that does **not**
  /// match the query (enabled state) — token-backed reference to the
  /// `bodyMedium` slot (Regular) in `onSurfaceVariant`, so the matched part
  /// ([defaultMatchTextStyle]) reads as the foreground. Colour lives in the
  /// nested [CoreTextStyle] slot.
  static const CoreTextStyle defaultDropdownTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default text style for the part of a suggestion label that matches the
  /// query — `bodyMedium` in SemiBold `onSurface`. Applied wherever the match
  /// sits in the label (start, middle or end); see `CoreAutocompleteMatch`.
  static final CoreTextStyle defaultMatchTextStyle = const CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default text style for the non-matching part of an option label while
  /// the row is accented (pointer hover or keyboard highlight) — the same
  /// `bodyMedium` / `onSurfaceVariant` as the resting label: the accent is
  /// the [defaultOptionHoverColor] fill, not a text colour change, so the
  /// matched part ([defaultMatchTextStyle]) stays the only thing that reads
  /// as foreground, told apart by weight. Colour lives in the nested
  /// [CoreTextStyle] slot.
  static const CoreTextStyle defaultOptionHoverTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default suggestion-list maximum height before internal scrolling
  /// kicks in (logical px). Constrains the option **list** (the widget's
  /// own `ConstrainedBox` content), not the panel box — the box is sized
  /// and clipped by the composed `Popover` → `Popup`.
  static const double defaultDropdownMaxHeight = CoreSpace.space240;

  /// Default option row border radius — the control step an `ItemPicker`
  /// option row takes.
  static const CoreBorderRadius defaultOptionBorderRadius =
      CoreBorderRadius.all(CoreRadiusRole.control);

  /// Default option row padding — the same inset an `ItemPicker` option row
  /// takes, so a suggestion reads as one of its rows.
  static const CoreEdgeInsets defaultOptionPadding = CoreEdgeInsets.all(
    CoreSpace.space8,
  );

  // ── Slot Styles (nested) ─────────────────────

  /// Style for the `Popover` that wraps the input (trigger) and the
  /// suggestion panel. Sets the gap between input and panel, and the
  /// panel box's border, corners, shadow and padding (through
  /// `popoverStyle.panelStyle`, a `CorePopupStyle`). `null` leaves the
  /// panel at the design-system `Popup` defaults.
  final CorePopoverStyle? popoverStyle;

  /// Suggestion / option text style override (enabled / non-hovered) for the
  /// part of the label that does not match the query.
  /// Text colour is carried via [CoreTextStyle.color] inside this slot.
  final CoreTextStyle? dropdownTextStyle;

  /// Text style override for the part of the label that matches the query
  /// (SemiBold `onSurface` by default). Merged over the label's base style,
  /// so a caller states only what differs.
  final CoreTextStyle? matchTextStyle;

  // ── Suggestion list ──────────────────────────

  /// Suggestion-list maximum height override (logical px). Constrains
  /// the option list, not the panel box (which is owned by the composed
  /// `Popover`). Defaults to [defaultDropdownMaxHeight].
  final double? dropdownMaxHeight;

  // ── Option-row chrome ────────────────────────

  /// Option hover background colour override.
  final CoreColor? optionHoverColor;

  /// Option text style override applied when the option is hovered.
  /// Text colour is carried via [CoreTextStyle.color] inside this slot.
  final CoreTextStyle? optionHoverTextStyle;

  /// Option row border radius override.
  final CoreBorderRadius? optionBorderRadius;

  /// Option row padding override.
  final CoreEdgeInsets? optionPadding;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are merged
  /// recursively.
  @override
  CoreAutocompleteStyle merge(CoreAutocompleteStyle? other) {
    if (other == null) return this;
    return CoreAutocompleteStyle(
      popoverStyle: _mergePopover(popoverStyle, other.popoverStyle),
      dropdownTextStyle: _mergeText(dropdownTextStyle, other.dropdownTextStyle),
      matchTextStyle: _mergeText(matchTextStyle, other.matchTextStyle),
      dropdownMaxHeight: other.dropdownMaxHeight ?? dropdownMaxHeight,
      optionHoverColor: other.optionHoverColor ?? optionHoverColor,
      optionHoverTextStyle: _mergeText(
        optionHoverTextStyle,
        other.optionHoverTextStyle,
      ),
      optionBorderRadius: other.optionBorderRadius ?? optionBorderRadius,
      optionPadding: other.optionPadding ?? optionPadding,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreAutocompleteStyle copyWith({
    CorePopoverStyle? popoverStyle,
    CoreTextStyle? dropdownTextStyle,
    CoreTextStyle? matchTextStyle,
    double? dropdownMaxHeight,
    CoreColor? optionHoverColor,
    CoreTextStyle? optionHoverTextStyle,
    CoreBorderRadius? optionBorderRadius,
    CoreEdgeInsets? optionPadding,
  }) {
    return CoreAutocompleteStyle(
      popoverStyle: popoverStyle ?? this.popoverStyle,
      dropdownTextStyle: dropdownTextStyle ?? this.dropdownTextStyle,
      matchTextStyle: matchTextStyle ?? this.matchTextStyle,
      dropdownMaxHeight: dropdownMaxHeight ?? this.dropdownMaxHeight,
      optionHoverColor: optionHoverColor ?? this.optionHoverColor,
      optionHoverTextStyle: optionHoverTextStyle ?? this.optionHoverTextStyle,
      optionBorderRadius: optionBorderRadius ?? this.optionBorderRadius,
      optionPadding: optionPadding ?? this.optionPadding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAutocompleteStyle &&
          runtimeType == other.runtimeType &&
          popoverStyle == other.popoverStyle &&
          dropdownTextStyle == other.dropdownTextStyle &&
          matchTextStyle == other.matchTextStyle &&
          dropdownMaxHeight == other.dropdownMaxHeight &&
          optionHoverColor == other.optionHoverColor &&
          optionHoverTextStyle == other.optionHoverTextStyle &&
          optionBorderRadius == other.optionBorderRadius &&
          optionPadding == other.optionPadding;

  @override
  int get hashCode => Object.hash(
    popoverStyle,
    dropdownTextStyle,
    matchTextStyle,
    dropdownMaxHeight,
    optionHoverColor,
    optionHoverTextStyle,
    optionBorderRadius,
    optionPadding,
  );

  static CorePopoverStyle? _mergePopover(
    CorePopoverStyle? base,
    CorePopoverStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

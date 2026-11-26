import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedObjectInput
// ═══════════════════════════════════════════════════

/// Resolver output for `ObjectInput`.
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus token lookup and type conversion.
class ResolvedObjectInput {
  /// Creates a [ResolvedObjectInput].
  const ResolvedObjectInput({
    required this.focusedContainerStyle,
    required this.hoveredContainerStyle,
    required this.unfocusedContainerStyle,
    required this.disabledContainerStyle,
    required this.fieldSpacing,
    required this.separatorPadding,
    required this.charWidth,
    required this.separatorTextStyle,
    required this.disabledSeparatorTextStyle,
    required this.fieldInputVariant,
    required this.fieldInputSize,
    required this.fieldInputStyle,
    required this.shortFieldMaxWidth,
    required this.mediumFieldMaxWidth,
    required this.longFieldMaxWidth,
  });

  /// Chrome for the outer container while focused — same fill /
  /// radius / border-width / padding as [unfocusedContainerStyle],
  /// border colour swapped to `focusBorderColor`. `surfaceBlur` is
  /// left unset: the fill is a real, opaque design token and no
  /// glyph rides on it, only the composed per-field `TextField`s'
  /// typed text / caret and the separator text (already carrying
  /// their own colour) — so there is no fill-less-box or glyph-
  /// contrast risk in letting a material preset reach it.
  final CoreOutlinedContainerStyle focusedContainerStyle;

  /// Chrome for the outer container while the pointer is over it (and it
  /// is neither focused nor disabled) — same fill / radius / border-width /
  /// padding as [unfocusedContainerStyle], border colour swapped to
  /// `hoverBorderColor`. The widget picks it only for an enabled, unfocused
  /// container (`disabled > focus > hover > rest`).
  final CoreOutlinedContainerStyle hoveredContainerStyle;

  /// Chrome for the outer container while unfocused — fill =
  /// `backgroundColor` token, border = `borderColor` token. Same
  /// `surfaceBlur`-unset reasoning as [focusedContainerStyle].
  final CoreOutlinedContainerStyle unfocusedContainerStyle;

  /// Chrome for the outer container while disabled — fill and border swapped
  /// to their own tokens rather than the enabled pair dimmed by an opacity
  /// (an alpha is not a forced value in a colour-forcing accessibility mode).
  /// Disabled outranks focus and hover: a field that cannot be edited does not
  /// claim the focus ring.
  final CoreOutlinedContainerStyle disabledContainerStyle;

  /// Gap between the container's children (logical px, already density-bent
  /// and scaled).
  final double fieldSpacing;

  /// Padding around the field separator text (already scaled).
  final EdgeInsets separatorPadding;

  /// Per-character intrinsic field width (logical px, already scaled).
  final double charWidth;

  /// Field separator text style (typography role + colour, paint-ready).
  final TextStyle separatorTextStyle;

  /// Field separator text style while disabled — [separatorTextStyle] with
  /// the colour swapped to the disabled foreground.
  final TextStyle disabledSeparatorTextStyle;

  /// Variant of the composed per-field `TextField` (`plain`: the outer
  /// container owns the single boundary).
  final CoreTextFieldVariant fieldInputVariant;

  /// Size row of the composed per-field `TextField` (`lg`).
  final CoreComponentSize fieldInputSize;

  /// Chromeless per-field input style raw-forwarded to the composed unified
  /// `TextField` (transparent border/bg, zero padding, centred, mono value
  /// style) — the outer container owns the single visual boundary.
  final CoreTextFieldStyle fieldInputStyle;

  /// Max-width for short fields (1–2 chars) (logical px, already scaled).
  final double shortFieldMaxWidth;

  /// Max-width for medium fields (3–4 chars) (logical px, already scaled).
  final double mediumFieldMaxWidth;

  /// Max-width for long fields (5+ chars) (logical px, already scaled).
  final double longFieldMaxWidth;

  /// Returns the bucket max-width (logical px, scaled) for a field with
  /// the given [maxLength] — short (≤[shortFieldMaxChars]), medium
  /// (≤[mediumFieldMaxChars]), or long, or `null` when the field is
  /// unbounded.
  ///
  /// The two bucket boundaries are widget-plane behaviour (they pick
  /// which width applies and paint nothing), so they arrive as arguments
  /// from `ObjectInput.shortFieldMaxChars` / `mediumFieldMaxChars`
  /// instead of being resolved here — only the three widths are chrome.
  double? fieldMaxWidthFor(
    int? maxLength, {
    required int shortFieldMaxChars,
    required int mediumFieldMaxChars,
  }) {
    if (maxLength == null) return null;
    if (maxLength <= shortFieldMaxChars) return shortFieldMaxWidth;
    if (maxLength <= mediumFieldMaxChars) return mediumFieldMaxWidth;
    return longFieldMaxWidth;
  }
}

// ═══════════════════════════════════════════════════
// resolveObjectInput — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedObjectInput] for the given [context].
///
/// Walks the nested-merge chain plus token / dimensional fallback:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.objectInput.style
///   → widget.objectInputStyle
/// ```
ResolvedObjectInput resolveObjectInput(
  BuildContext context, {
  CoreObjectInputStyle? objectInputStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final inputTheme = theme.coreComponentTheme?.objectInput;

  final merged = resolveStyleChain(const CoreObjectInputStyle(), [
    inputTheme?.style,
    objectInputStyle,
  ]);

  // Stage1 RESOLVE — merge chain + named default fallback (raw Core
  // tokens; `OutlinedContainer` runs scheme.resolve / geometry / scaling
  // itself for whatever flows through `containerStyle`).
  final backgroundColorCore =
      merged.backgroundColor ?? CoreObjectInputStyle.defaultBackgroundColor;
  final borderColorCore =
      merged.borderColor ?? CoreObjectInputStyle.defaultBorderColor;
  final hoverBorderColorCore =
      merged.hoverBorderColor ?? CoreObjectInputStyle.defaultHoverBorderColor;
  final focusBorderColorCore =
      merged.focusBorderColor ?? CoreObjectInputStyle.defaultFocusBorderColor;
  final containerBorderRadiusCore =
      merged.borderRadius ?? CoreObjectInputStyle.defaultBorderRadius;
  final containerBorderWidthCore =
      merged.borderWidth ?? CoreObjectInputStyle.defaultBorderWidth;
  final containerPaddingCore =
      merged.padding ?? CoreObjectInputStyle.defaultPadding;
  final disabledBackgroundColorCore =
      merged.disabledBackgroundColor ??
      CoreObjectInputStyle.defaultDisabledBackgroundColor;
  final disabledBorderColorCore =
      merged.disabledBorderColor ??
      CoreObjectInputStyle.defaultDisabledBorderColor;
  final disabledSeparatorColorCore =
      merged.disabledSeparatorColor ??
      CoreObjectInputStyle.defaultDisabledSeparatorColor;
  // The box is a row of the control ladder (the lg rung, the row of the
  // text field beside it): it moves a rung under the theme density. A
  // caller's own height is a statement and stays as stated.
  final height =
      (merged.height ??
          theme.geometry.controlHeight(CoreObjectInputStyle.defaultHeight)) *
      scaling;
  final fieldSpacing =
      theme.geometry.space(
        merged.fieldSpacing ?? CoreObjectInputStyle.defaultFieldSpacing,
      ) *
      scaling;

  // ─── EMIT Stage 2 (Flutter) — typography ───
  // Single primitive — `default.merge(override).toValue(theme:)`
  // materialises the role / font and resolves the colour through the
  // active scheme in one step (no `theme.typography.resolve` role
  // hardcode, no hand-rolled colour overlay).
  final separatorTextStyle = CoreObjectInputStyle.defaultSeparatorTextStyle
      .merge(merged.separatorTextStyle)
      .toValue(theme: theme);
  final disabledSeparatorTextStyle = CoreObjectInputStyle
      .defaultSeparatorTextStyle
      .merge(merged.separatorTextStyle)
      .copyWith(color: disabledSeparatorColorCore)
      .toValue(theme: theme);
  // ─── Field input style (nested child-component slot, raw-forwarded) ──
  // Chain the Core default (chromeless — the outer container owns the
  // boundary and the focus ring; centred, token-backed monospace value)
  // with the instance override. The composed unified `TextField` resolves
  // the value / placeholder typography through the active scheme.
  final fieldInputStyle = CoreObjectInputStyle.defaultFieldInputStyle.merge(
    merged.fieldInputStyle,
  );

  // ─── EMIT Stage 2 (Flutter) — dimensional (paint-ready, scaled) ───
  final separatorPadding =
      (merged.separatorPadding ?? CoreObjectInputStyle.defaultSeparatorPadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  final charWidth =
      (merged.charWidth ?? CoreObjectInputStyle.defaultCharWidth) * scaling;
  final shortFieldMaxWidth =
      (merged.shortFieldMaxWidth ??
          CoreObjectInputStyle.defaultShortFieldMaxWidth) *
      scaling;
  final mediumFieldMaxWidth =
      (merged.mediumFieldMaxWidth ??
          CoreObjectInputStyle.defaultMediumFieldMaxWidth) *
      scaling;
  final longFieldMaxWidth =
      (merged.longFieldMaxWidth ??
          CoreObjectInputStyle.defaultLongFieldMaxWidth) *
      scaling;

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per state ──
  // The outer box is a composed `OutlinedContainer` rather than a
  // hand-rolled decoration: passing Core values (not resolved ones)
  // keeps the scheme-resolve / geometry / scaling bend applied
  // exactly once — `OutlinedContainer` runs those steps itself. The
  // bundles share fill / radius / width / padding; only the border
  // colour swaps between focused, hovered and unfocused.
  final unfocusedContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundColorCore,
    borderColor: borderColorCore,
    borderRadius: containerBorderRadiusCore,
    borderWidth: containerBorderWidthCore,
    padding: containerPaddingCore,
    height: height,
  );
  final hoveredContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundColorCore,
    borderColor: hoverBorderColorCore,
    borderRadius: containerBorderRadiusCore,
    borderWidth: containerBorderWidthCore,
    padding: containerPaddingCore,
    height: height,
  );
  final focusedContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundColorCore,
    borderColor: focusBorderColorCore,
    borderRadius: containerBorderRadiusCore,
    borderWidth: containerBorderWidthCore,
    padding: containerPaddingCore,
    height: height,
  );

  final disabledContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: disabledBackgroundColorCore,
    borderColor: disabledBorderColorCore,
    borderRadius: containerBorderRadiusCore,
    borderWidth: containerBorderWidthCore,
    padding: containerPaddingCore,
    height: height,
  );

  return ResolvedObjectInput(
    focusedContainerStyle: focusedContainerStyle,
    hoveredContainerStyle: hoveredContainerStyle,
    unfocusedContainerStyle: unfocusedContainerStyle,
    disabledContainerStyle: disabledContainerStyle,
    fieldSpacing: fieldSpacing,
    separatorPadding: separatorPadding,
    charWidth: charWidth,
    separatorTextStyle: separatorTextStyle,
    disabledSeparatorTextStyle: disabledSeparatorTextStyle,
    fieldInputVariant: CoreObjectInputStyle.defaultFieldInputVariant,
    fieldInputSize: CoreObjectInputStyle.defaultFieldInputSize,
    fieldInputStyle: fieldInputStyle,
    shortFieldMaxWidth: shortFieldMaxWidth,
    mediumFieldMaxWidth: mediumFieldMaxWidth,
    longFieldMaxWidth: longFieldMaxWidth,
  );
}

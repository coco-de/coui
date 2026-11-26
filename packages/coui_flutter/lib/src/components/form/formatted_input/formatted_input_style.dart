import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedFormattedInput
// ═══════════════════════════════════════════════════

/// Resolver output for `FormattedInput`.
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus token lookup and type conversion.
///
/// `FormattedInput` renders one continuous `TextField` (DDR-01) instead of
/// a row of per-segment boxes, so the only dimensional chrome left is the
/// outer container's own fill / padding / border — carried pre-EMIT in
/// [focusedContainerStyle] / [unfocusedContainerStyle] and composed via
/// `OutlinedContainer` — there is no per-segment width or inter-segment
/// gap to resolve anymore (DDR-07). [segmentInputStyle] is the sole
/// other nested slot, raw-forwarded to that single composed `TextField`.
///
/// surface:content — draws its own box (composes `OutlinedContainer`
/// rather than being drawn inside a parent panel), on the page rather
/// than floating over it.
class ResolvedFormattedInput {
  /// Creates a [ResolvedFormattedInput].
  const ResolvedFormattedInput({
    required this.focusedContainerStyle,
    required this.hoveredContainerStyle,
    required this.unfocusedContainerStyle,
    required this.disabledContainerStyle,
    required this.contentSpacing,
    required this.segmentInputVariant,
    required this.segmentInputSize,
    required this.segmentInputStyle,
    required this.disabledSegmentInputStyle,
  });

  /// Chrome for the outer container while focused — same fill / radius
  /// / border-width / padding as [unfocusedContainerStyle], border
  /// colour swapped to `focusBorderColor`. `surfaceBlur` is left
  /// unset: the fill is a real, opaque design token and no glyph
  /// rides on it, only the composed `TextField`'s typed text / caret
  /// (already carrying its own colour) — so there is no fill-less-box
  /// or glyph-contrast risk in letting a material preset reach it.
  final CoreOutlinedContainerStyle focusedContainerStyle;

  /// Chrome for the outer container while the pointer is over it (and it is
  /// neither focused nor disabled) — same fill / radius / border-width /
  /// padding / height as [unfocusedContainerStyle], border colour swapped to
  /// `hoverBorderColor`. The widget picks it only for an enabled, unfocused
  /// container (`disabled > focus > hover > rest`).
  final CoreOutlinedContainerStyle hoveredContainerStyle;

  /// Chrome for the outer container while unfocused — fill =
  /// `backgroundColor` token, border = `borderColor` token. Same
  /// `surfaceBlur`-unset reasoning as [focusedContainerStyle].
  final CoreOutlinedContainerStyle unfocusedContainerStyle;

  /// Chrome for the outer container while disabled — fill and border
  /// swapped to their own tokens rather than the enabled pair dimmed by
  /// an opacity.
  ///
  /// A third pre-baked bundle rather than a runtime blend because the
  /// three states are mutually exclusive: one bundle per state is O(n),
  /// and the widget only has to select. (The combinatorial case — hover ×
  /// focus × disabled — is what `WidgetStateProperty` exists for; this is
  /// not that.)
  final CoreOutlinedContainerStyle disabledContainerStyle;

  /// Gap between the `leading` / field / `trailing` children (logical px,
  /// already density-bent and scaled).
  final double contentSpacing;

  /// Variant of the composed `TextField` (`plain`: the outer container owns
  /// the single boundary).
  final CoreTextFieldVariant segmentInputVariant;

  /// Size row of the composed `TextField` (`lg`).
  final CoreComponentSize segmentInputSize;

  /// Style raw-forwarded to the single composed `TextField` while disabled —
  /// [segmentInputStyle] with the value / placeholder colours restated as the
  /// disabled foreground (a caller-stated text colour wins in every state, so
  /// the disabled colour has to travel with the style).
  final CoreTextFieldStyle disabledSegmentInputStyle;

  /// Chromeless style raw-forwarded to the single composed unified
  /// `TextField` (transparent border/bg, zero padding, centred, mono value
  /// + dim placeholder) — the outer container owns the single visual
  /// boundary.
  final CoreTextFieldStyle segmentInputStyle;
}

// ═══════════════════════════════════════════════════
// resolveFormattedInput — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFormattedInput] for the given [context].
///
/// Walks the nested-merge chain plus token / dimensional fallback:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.formattedInput.style
///   → widget.formattedInputStyle
/// ```
ResolvedFormattedInput resolveFormattedInput(
  BuildContext context, {
  CoreFormattedInputStyle? formattedInputStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final inputTheme = theme.coreComponentTheme?.formattedInput;

  final merged = resolveStyleChain(const CoreFormattedInputStyle(), [
    inputTheme?.style,
    formattedInputStyle,
  ]);

  // Stage1 RESOLVE — merge chain + named default fallback (raw Core
  // tokens; `OutlinedContainer` runs scheme.resolve / geometry / scaling
  // itself for whatever flows through `containerStyle`).
  final backgroundColorCore =
      merged.backgroundColor ?? CoreFormattedInputStyle.defaultBackgroundColor;
  final borderColorCore =
      merged.borderColor ?? CoreFormattedInputStyle.defaultBorderColor;
  final hoverBorderColorCore =
      merged.hoverBorderColor ??
      CoreFormattedInputStyle.defaultHoverBorderColor;
  final disabledForegroundColorCore =
      merged.disabledForegroundColor ??
      CoreFormattedInputStyle.defaultDisabledForegroundColor;
  final focusBorderColorCore =
      merged.focusBorderColor ??
      CoreFormattedInputStyle.defaultFocusBorderColor;
  final borderRadiusCore =
      merged.borderRadius ?? CoreFormattedInputStyle.defaultBorderRadius;
  final borderWidthCore =
      merged.borderWidth ?? CoreFormattedInputStyle.defaultBorderWidth;
  final paddingCore = merged.padding ?? CoreFormattedInputStyle.defaultPadding;
  final disabledBackgroundColorCore =
      merged.disabledBackgroundColor ??
      CoreFormattedInputStyle.defaultDisabledBackgroundColor;
  final disabledBorderColorCore =
      merged.disabledBorderColor ??
      CoreFormattedInputStyle.defaultDisabledBorderColor;

  // ─── Segment input style (nested child-component slot, raw-forwarded) ──
  // Chain the Core default (chromeless — outer container owns the boundary,
  // centred, token-backed monospace value / placeholder) with the instance
  // override. The composed unified `TextField` resolves the value /
  // placeholder typography and colour through the active scheme.
  final segmentInputStyle = CoreFormattedInputStyle.defaultSegmentInputStyle
      .merge(merged.segmentInputStyle);
  // A text colour the caller stated wins in every state, so while disabled
  // the disabled foreground is the one stated — unless the caller stated a
  // colour of their own for that slot.
  final disabledSegmentInputStyle = segmentInputStyle.merge(
    CoreTextFieldStyle(
      valueStyle: CoreTextStyle(
        color:
            segmentInputStyle.valueStyle?.color ?? disabledForegroundColorCore,
      ),
      placeholderStyle: CoreTextStyle(
        color:
            segmentInputStyle.placeholderStyle?.color ??
            disabledForegroundColorCore,
      ),
    ),
  );

  // The box is a row of the control ladder (the lg rung, the row of the
  // text field beside it): it moves a rung under the theme density. A
  // caller's own height is a statement and stays as stated.
  final height =
      (merged.height ??
          theme.geometry.controlHeight(CoreFormattedInputStyle.defaultHeight)) *
      scaling;
  final contentSpacing =
      theme.geometry.space(
        merged.contentSpacing ?? CoreFormattedInputStyle.defaultContentSpacing,
      ) *
      scaling;

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per state ──
  // The outer box is a composed `OutlinedContainer` rather than a
  // hand-rolled decoration: passing Core values (not resolved ones)
  // keeps the scheme-resolve / geometry / scaling bend applied
  // exactly once — `OutlinedContainer` runs those steps itself. Both
  // bundles share fill / radius / width / padding; only the border
  // colour swaps between focused and unfocused.
  final unfocusedContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundColorCore,
    borderColor: borderColorCore,
    borderRadius: borderRadiusCore,
    borderWidth: borderWidthCore,
    padding: paddingCore,
    height: height,
  );
  final hoveredContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundColorCore,
    borderColor: hoverBorderColorCore,
    borderRadius: borderRadiusCore,
    borderWidth: borderWidthCore,
    padding: paddingCore,
    height: height,
  );
  final focusedContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundColorCore,
    borderColor: focusBorderColorCore,
    borderRadius: borderRadiusCore,
    borderWidth: borderWidthCore,
    padding: paddingCore,
    height: height,
  );
  final disabledContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: disabledBackgroundColorCore,
    borderColor: disabledBorderColorCore,
    borderRadius: borderRadiusCore,
    borderWidth: borderWidthCore,
    padding: paddingCore,
    height: height,
  );

  return ResolvedFormattedInput(
    focusedContainerStyle: focusedContainerStyle,
    hoveredContainerStyle: hoveredContainerStyle,
    unfocusedContainerStyle: unfocusedContainerStyle,
    disabledContainerStyle: disabledContainerStyle,
    contentSpacing: contentSpacing,
    segmentInputVariant: CoreFormattedInputStyle.defaultSegmentInputVariant,
    segmentInputSize: CoreFormattedInputStyle.defaultSegmentInputSize,
    segmentInputStyle: segmentInputStyle,
    disabledSegmentInputStyle: disabledSegmentInputStyle,
  );
}

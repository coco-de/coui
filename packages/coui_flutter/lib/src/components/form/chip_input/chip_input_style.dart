import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedChipInput
// ═══════════════════════════════════════════════════

/// Resolver output for `ChipInput`.
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has been merged through:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.chipInput.style
///   → widget.chipInputStyle
/// ```
class ResolvedChipInput {
  /// Creates a [ResolvedChipInput].
  const ResolvedChipInput({
    required this.backgroundColor,
    required this.borderColor,
    required this.hoverBorderColor,
    required this.disabledBackgroundColor,
    required this.disabledBorderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.borderRadiusValue,
    required this.minHeight,
    required this.padding,
    required this.inputPadding,
    required this.chipSpacing,
    required this.chipStyle,
    required this.inputTextStyle,
    required this.focusOutlineStyle,
    required this.boxShadow,
    required this.surfaceOpacity,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
  });

  /// Resolved container background fill colour.
  final Color backgroundColor;

  /// Resolved container border stroke colour.
  final Color borderColor;

  /// Resolved container border stroke colour while the pointer is over the
  /// frame. The widget selects it only for an enabled, unfocused frame
  /// (`disabled > focus > hover > rest` — focus draws the ring and keeps
  /// [borderColor]).
  final Color hoverBorderColor;

  /// Resolved container fill while the frame is disabled — the widget
  /// selects it in place of [backgroundColor] (`disabledContainer` by
  /// default; a disabled frame states its own tokens, not an opacity wash).
  final Color disabledBackgroundColor;

  /// Resolved container border stroke colour while the frame is disabled.
  final Color disabledBorderColor;

  /// Container border stroke width (already scaled).
  final double borderWidth;

  /// Container border radius (paint-ready, scaling pre-applied) — passed
  /// straight to the container's [BoxDecoration.borderRadius].
  final BorderRadius borderRadius;

  /// Container border radius as a uniform scalar (scaling pre-applied) —
  /// consumed only by the frame's own [BorderRadius.circular]; the ring
  /// receives the un-bent `CoreBorderRadius` through [focusOutlineStyle]
  /// instead (its own resolver applies geometry + scaling).
  final double borderRadiusValue;

  /// Container minimum height (already scaled).
  final double minHeight;

  /// Container content padding (paint-ready, scaling pre-applied) — direction
  /// aware: the start and end insets follow the ambient text direction.
  final EdgeInsetsGeometry padding;

  /// Inset around the inline entry field (paint-ready, scaling pre-applied,
  /// direction aware) — applied outside the composed `TextField`.
  final EdgeInsetsGeometry inputPadding;

  /// Gap between chip badges (already scaled).
  final double chipSpacing;

  /// Nested [CoreChipStyle] slot for the composed `Chip` badges —
  /// `CoreChipInputStyle.defaultChipStyle` (compact pill divergences)
  /// merged with the per-instance override, raw-forwarded to
  /// `Chip(chipStyle:)`; the Chip's own resolver fills the rest.
  final CoreChipStyle chipStyle;

  /// Inline text-entry text style (paint-ready) — the `bodySmall`
  /// typography role overlaid with the merged `inputTextStyle` slot and
  /// bound to the resolved input foreground colour. Passed straight to
  /// the `EditableText`.
  final TextStyle inputTextStyle;

  /// Nested [CoreFocusOutlineStyle] slot for the frame's focus ring —
  /// raw-forwarded (Core values, not paint-ready) to the surrounding
  /// `FocusOutline`, whose own resolver is the single place
  /// `scheme.resolve`, `theme.geometry.borderRadius(...)` and `* scaling`
  /// run for the ring. Carries the frame's corner radius underneath the
  /// caller's slot; every other field stays null so `FocusOutline`'s
  /// resolver supplies its own default (matching Web's
  /// `focus-within:ring-*` classes, which fall back the same way).
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// The active surface style's injected cast, or empty under a
  /// style that injects none.
  ///
  /// This control draws its own box rather than composing
  /// `OutlinedContainer`, so the opt-in is restated. Empty under
  /// every style that casts nothing, so the widget paints it
  /// unconditionally.
  final List<BoxShadow> boxShadow;

  /// The active style's content-role material opacity, or `null` when the
  /// style states no material — regardless of whether the fill is
  /// actually painted.
  ///
  /// The widget reads this on its own (unlike [surfaceBlur] and its
  /// siblings, which additionally gate on the fill being painted): it
  /// decides whether the fill *can* turn translucent at all, which
  /// decides whether the box shadow has to move off
  /// `BoxDecoration.boxShadow` and onto `InjectedCast`
  /// (`core/theme-axis-composition.md` — "그림자는 두 플랫폼이 다른 곳에
  /// 칠한다"). Every non-glass preset leaves this `null`, so those four
  /// keep painting the shadow the original way — byte-identical to the
  /// preset-render baseline.
  final double? surfaceOpacity;

  /// Backdrop blur sigma for the frame, `null` when the active theme
  /// states no material or the frame paints no fill of its own to blur
  /// behind (an explicit transparent [backgroundColor] override) — see
  /// [backgroundColor].
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;
}

// ═══════════════════════════════════════════════════
// resolveChipInput — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedChipInput] for [ChipInput].
///
/// All chrome / dimensional overrides flow through the single
/// [chipInputStyle] slot.
ResolvedChipInput resolveChipInput(
  BuildContext context, {
  CoreChipInputStyle? chipInputStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final chipInputTheme = theme.coreComponentTheme?.chipInput;

  final merged = resolveStyleChain(const CoreChipInputStyle(), [
    chipInputTheme?.style,
    chipInputStyle,
  ]);

  // The frame draws its own box directly rather than composing
  // `OutlinedContainer` (the inline entry `TextField` is deliberately
  // chromeless — the frame owns the single visible boundary, and a wrap
  // here would move that boundary to a different element than the one
  // `FocusOutline` rings). A glass style's material reaches it the same
  // way it reaches a card — through the content-layer seat, folded into
  // the fill below.
  final material = theme.surfaceFor(.content, depth: SurfaceDepth.of(context));
  final surfaceOpacity = material?.opacityIn(theme);

  // ─── Stage 2 EMIT — Flutter colours (`scheme.resolve().toValue()`) ─
  final backgroundColorCore =
      merged.backgroundColor ?? CoreChipInputStyle.defaultBackgroundColor;
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
  // stroke: a material that draws its own edge suppresses the frame's
  // hairline so the box doesn't draw a second boundary on top of it.
  final borderColor = resolveSurfaceStroke(
    theme,
    scheme
        .resolve(merged.borderColor ?? CoreChipInputStyle.defaultBorderColor)
        .toValue(),
  );
  // Hover border — resolved exactly like the resting one (same scheme
  // lookup, same material-edge suppression), so a style that draws its own
  // edge suppresses the hover step with it.
  final hoverBorderColor = resolveSurfaceStroke(
    theme,
    scheme
        .resolve(
          merged.hoverBorderColor ?? CoreChipInputStyle.defaultHoverBorderColor,
        )
        .toValue(),
  );

  // Disabled fill / border — resolved the same way as the resting ones, so
  // a style that draws its own edge suppresses the disabled edge with it.
  final disabledBackgroundColor = scheme
      .resolve(
        merged.disabledBackgroundColor ??
            CoreChipInputStyle.defaultDisabledBackgroundColor,
      )
      .toValue();
  final disabledBorderColor = resolveSurfaceStroke(
    theme,
    scheme
        .resolve(
          merged.disabledBorderColor ??
              CoreChipInputStyle.defaultDisabledBorderColor,
        )
        .toValue(),
  );

  // ─── Inline input typography (paint-ready TextStyle) ───
  // Token-backed `bodySmall` role default (+ `onSurface` colour) merged
  // with the per-instance `inputTextStyle`, materialised in one step.
  final inputForegroundCore =
      merged.inputTextStyle?.color ??
      CoreChipInputStyle.defaultInputTextStyle.color!;
  final inputForegroundColor = scheme.resolve(inputForegroundCore).toValue();
  final inputTextStyle = CoreChipInputStyle.defaultInputTextStyle
      .merge(merged.inputTextStyle)
      .toValue(color: inputForegroundColor, theme: theme);

  // ─── Dimensional props (paint-ready, scaling pre-applied) ──────
  // Container radius is uniform (`CoreBorderRadius.all`), so the
  // top-left corner is canonical. Scale once into a scalar, reused by
  // the paint-ready [BorderRadius] and the `FocusOutline` corner.
  final borderRadiusCore =
      merged.borderRadius ?? CoreChipInputStyle.defaultBorderRadius;
  final borderRadiusValue =
      theme.geometry.borderRadius(borderRadiusCore).topLeft * scaling;
  final borderRadius = BorderRadius.circular(borderRadiusValue);
  // Nested FocusOutline slot, raw-forwarded — Stage1 RESOLVE only, since
  // FocusOutline's own resolver is where the colour resolve, the geometry
  // bend and the scaling factor are applied for the ring. The frame's own
  // corner radius sits under the caller's slot: the ring has to trace the
  // frame it surrounds, and that is the one value the child cannot
  // derive. Every other field stays null so FocusOutline's own defaults
  // win rather than being restated here.
  final focusOutlineStyle = CoreFocusOutlineStyle(
    borderRadius: borderRadiusCore,
  ).merge(merged.focusOutlineStyle);
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreChipInputStyle.defaultBorderWidth,
    scaling: scaling,
  );
  // The frame's floor is a row of the control ladder (the md rung, the row
  // of the text field beside it): it moves a rung under the theme density.
  // A caller's own minimum is a statement and stays as stated.
  final minHeight =
      (merged.minHeight ??
          theme.geometry.controlHeight(CoreChipInputStyle.defaultMinHeight)) *
      scaling;
  // `toGeometry` (not `toValue`): the default insets differ between start
  // and end because of what they are, so they follow the reading direction.
  final padding =
      (merged.padding ?? CoreChipInputStyle.defaultPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  final inputPadding =
      (merged.inputPadding ?? CoreChipInputStyle.defaultInputPadding)
          .toGeometry(geometry: theme.geometry) *
      scaling;
  final chipSpacing =
      theme.geometry.space(
        merged.chipSpacing ?? CoreChipInputStyle.defaultChipSpacing,
      ) *
      scaling;

  // Nested CoreChipStyle slot
  final chipStyle = CoreChipInputStyle.defaultChipStyle.merge(
    merged.chipStyle,
  );

  // The style injects its cast into surfaces that state no shadow of
  // their own — empty under every style that injects none.
  final boxShadow = resolveInjectedCast(theme);

  return ResolvedChipInput(
    boxShadow: boxShadow,
    surfaceOpacity: surfaceOpacity,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    hoverBorderColor: hoverBorderColor,
    disabledBackgroundColor: disabledBackgroundColor,
    disabledBorderColor: disabledBorderColor,
    borderWidth: borderWidth,
    borderRadius: borderRadius,
    borderRadiusValue: borderRadiusValue,
    minHeight: minHeight,
    padding: padding,
    inputPadding: inputPadding,
    chipSpacing: chipSpacing,
    chipStyle: chipStyle,
    inputTextStyle: inputTextStyle,
    focusOutlineStyle: focusOutlineStyle,
  );
}

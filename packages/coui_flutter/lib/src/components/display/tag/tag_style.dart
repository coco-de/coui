import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Tag`.
///
/// Widget tree (`tag.dart` builds):
///
/// ```text
/// InjectedCast (boxShadow)
///   └─ (optional) SurfaceBlur (surfaceBlur / surfaceSaturation /
///        │                     surfaceBackdropBrightness / surfaceSheen)
///        └─ Container (constraints, padding, decoration)
///             └─ Row (min, centred)
///                  └─ DefaultTextStyle (labelTextStyle)
///                       └─ child
/// ```
///
/// No focus, no gesture, no state: a tag is display only.
class ResolvedTag {
  /// Creates a [ResolvedTag].
  const ResolvedTag({
    required this.constraints,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.padding,
    required this.labelTextStyle,
    required this.boxShadow,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
  });

  /// The box's size rule (logical px, scaled) — at least
  /// [CoreTagStyle.minHeight] tall, as wide as its label.
  final BoxConstraints constraints;

  /// Resolved fill colour, with the surface material's share folded in.
  final Color backgroundColor;

  /// Resolved border stroke colour. `null` → no border drawn.
  final Color? borderColor;

  /// Border stroke width (logical px, scaled). Drawn inside the box.
  final double borderWidth;

  /// Border radius (scaled).
  final BorderRadius borderRadius;

  /// Padding around the label (logical px, scaled). Horizontal only by
  /// default.
  final EdgeInsets padding;

  /// Paint-ready label text style — the step's role with the emphasis's
  /// weight, the foreground colour, and the per-instance `labelStyle`
  /// overlay.
  final TextStyle labelTextStyle;

  /// The active surface style's injected cast, or empty under a style
  /// that injects none. The tag draws its own box rather than composing
  /// `OutlinedContainer`, so the opt-in is restated here, as `Badge` does.
  final List<BoxShadow> boxShadow;

  /// Backdrop blur sigma behind the box, or `null` when the active style
  /// states no material, when the tag paints no fill, or when it sits
  /// inside another surface (the nested token drops the pass).
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through the box, or null.
  final double? surfaceBackdropBrightness;

  /// Edge light along the box's contour, or null.
  final ResolvedSurfaceSheen? surfaceSheen;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTag] for the given [context].
///
/// Merge chain:
///
/// ```text
/// defaultsBySize[size] → defaultsByEmphasis[emphasis]
///   → CoreTagStyle.resting(color, emphasis)              // defaults
///   → CoreTagTheme.style
///   → CoreTagTheme.colorStyles[color]
///   → CoreTagTheme.emphasisStyles[emphasis]
///   → tagStyle
/// ```
///
/// A caller-stated field wins over the defaults; `labelStyle` merges field
/// by field onto the step's role.
ResolvedTag resolveTag(
  BuildContext context, {
  required CoreCategoryColor color,
  required CoreTagEmphasis emphasis,
  required CoreTagSize size,
  CoreTagStyle? tagStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final tagTheme = theme.coreComponentTheme?.tag;

  // ─── Merge chain ──────────────────────────────────────
  // Semantic identifiers (`color` / `emphasis` / `size`) come straight from
  // the widget — the theme cannot override them (render-only.md (c)). Web
  // resolves these identically, so the two platforms stay 1:1.
  final merged = resolveStyleChain(const CoreTagStyle(), [
    tagTheme?.style,
    tagTheme?.colorStyles?[color],
    tagTheme?.emphasisStyles?[emphasis],
    tagStyle,
  ]);

  // ─── Design-system defaults for this size × emphasis × hue ───
  final chrome = CoreTagStyle.defaultsBySize[size]!
      .merge(CoreTagStyle.defaultsByEmphasis[emphasis])
      .merge(CoreTagStyle.resting(color, emphasis));

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final restingFill = merged.backgroundColor ?? chrome.backgroundColor!;
  final ink = merged.foregroundColor ?? chrome.foregroundColor!;
  final stroke = merged.borderColor ?? chrome.borderColor;
  final corner = merged.borderRadius ?? chrome.borderRadius!;
  final labelStyle = chrome.labelStyle!.merge(merged.labelStyle);

  // ─── Stage 2 — EMIT: dimensions ───────────────────────
  final height = (merged.minHeight ?? chrome.minHeight!) * scaling;
  final constraints = BoxConstraints(minHeight: height);
  final padding =
      (merged.padding ?? chrome.padding!).toValue(geometry: theme.geometry) *
      scaling;
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreTagStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final borderRadius = corner.toValue(geometry: theme.geometry) * scaling;

  // ─── Stage 2 — EMIT: surface material ─────────────────
  // Whether this tag paints a fill. The surface material is a statement
  // about a filled box, so a caller-made transparent fill has no box to
  // make translucent, frost behind or light the edge of. The Web twin
  // carries the surface marker on the same answer.
  final hasFill = scheme.resolve(restingFill).toValue().a > 0;

  // Surface material at the content role — the seat a composing surface
  // reaches via `resolveOutlinedContainer`. Tag draws its own box (its Web
  // root is an inline `<span>`, which the primitive's `<div>` would break),
  // so it reads the seat here at its ambient nesting depth, the same
  // restatement `Badge` makes.
  final material = hasFill
      ? theme.surfaceFor(.content, depth: SurfaceDepth.of(context))
      : null;
  final surfaceOpacity = material?.opacityIn(theme);
  final surfaceBlur = material?.blurRadius;
  final surfaceSaturation = material?.saturation;
  final surfaceBackdropBrightness = material?.backdropBrightnessIn(theme);
  final surfaceSheen = material == null ? null : resolveSurfaceSheen(theme);

  // ─── Stage 2 — EMIT: colours ──────────────────────────
  // The material's share folds into the fill — the token's own alpha stays
  // a factor (`token alpha × share`).
  final backgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? restingFill
            : restingFill.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  final foregroundColor = scheme.resolve(ink).toValue();
  final strokeColor = stroke == null ? null : scheme.resolve(stroke).toValue();
  // The material's own edge treatment (when it states one) suppresses this
  // component's stroke colour — never its width, so the box keeps its size
  // across a style swap.
  final borderColor = strokeColor != null && material != null
      ? resolveSurfaceStroke(theme, strokeColor)
      : strokeColor;

  // ─── Label text style (size role + emphasis weight + foreground) ────
  // The `color:` override forces the hue's foreground when the per-instance
  // `labelStyle` carries no explicit colour, so the label tracks the hue.
  final labelTextStyle = labelStyle.toValue(
    color: merged.labelStyle?.color == null ? foregroundColor : null,
    theme: theme,
  );

  // The style's injected cast — the tag states no shadow of its own, so it
  // takes the style's, the way a composed `OutlinedContainer` would.
  final boxShadow = resolveInjectedCast(theme);

  return ResolvedTag(
    constraints: constraints,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth,
    borderRadius: borderRadius,
    padding: padding,
    labelTextStyle: labelTextStyle,
    boxShadow: boxShadow,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
  );
}

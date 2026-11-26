import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedKbd
// ═══════════════════════════════════════════════════

/// Resolver output for `Kbd`.
///
/// Single struct that the widget reads — every chrome / dimensional /
/// text-style override has been merged through:
///
/// ```text
/// design system default (CoreKbdStyle.defaultX static const)
///   → theme.coreComponentTheme.kbd.style
///   → widget.kbdStyle
/// ```
class ResolvedKbd {
  /// Creates a [ResolvedKbd].
  const ResolvedKbd({
    required this.keyMinSize,
    required this.keyPadding,
    required this.keySeparatorSpacing,
    required this.keyRadius,
    required this.keyBackgroundColor,
    required this.keyBorderColor,
    required this.keyBorderWidth,
    required this.keyTextStyle,
    required this.keyShadow,
    required this.keyRim,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
  });

  /// Minimum key-box square extent (scaled) — keeps narrow glyphs from
  /// shrinking the chip below the design square.
  final double keyMinSize;

  /// Padding inside each key box.
  final EdgeInsets keyPadding;

  /// Spacing between adjacent key boxes — fed to native `Row.spacing`
  /// (no `Gap` widget, just paint-ready double).
  final double keySeparatorSpacing;

  /// Border radius of key boxes.
  final BorderRadius keyRadius;

  /// Effective key background colour.
  final Color keyBackgroundColor;

  /// Effective key border colour.
  final Color keyBorderColor;

  /// Effective key border stroke width — floored by the active surface
  /// style's geometry (e.g. neo-brutalism's `strokeFloor`).
  final double keyBorderWidth;

  /// Text style applied to each key label.
  final TextStyle keyTextStyle;

  /// Shadow of each key box, already bent by the active surface style.
  ///
  /// Painted outside the box only (`InjectedCast`): the key fill can be
  /// translucent under a glass material, and a shadow drawn behind the box
  /// would show through it on this platform alone. Empty when the style
  /// states no shadow.
  final List<BoxShadow> keyShadow;

  /// The active surface style's inset rim for each key box, or empty under a
  /// style that states none (and for a key that casts no shadow).
  ///
  /// Drawn by `InsetShadow` over the box — `BoxDecoration` would paint it
  /// behind the fill, where it never shows.
  final List<BoxShadow> keyRim;

  // ── Surface material (the part the fill share cannot carry) ──

  /// Backdrop blur sigma behind each key cap, or `null` when the active
  /// style states no material, when the key paints no fill, or when it sits
  /// inside another surface (the nested token drops the pass).
  ///
  /// The Web twin gets the same frost from the style rule its key-cap
  /// marker selects; without this a key frosted on one platform and only
  /// faded on the other.
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through a key cap, or null.
  final double? surfaceBackdropBrightness;

  /// Edge light along each key cap's contour, or null.
  final ResolvedSurfaceSheen? surfaceSheen;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedKbd] for the given [context].
///
/// Priority (per-field):
/// `widget.kbdStyle` > `CoreKbdTheme.style` > `CoreKbdStyle.defaultX`
/// design-system defaults.
ResolvedKbd resolveKbd(
  BuildContext context, {
  CoreKbdStyle? kbdStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final kbdTheme = theme.coreComponentTheme?.kbd;

  final merged = resolveStyleChain(const CoreKbdStyle(), [
    kbdTheme?.style,
    kbdStyle,
  ]);
  final keyFill =
      merged.keyBackgroundColor ?? CoreKbdStyle.defaultKeyBackgroundColor;

  // Whether a key cap paints a fill. The surface material is a statement
  // about a filled box: handed to a key whose fill is transparent, it
  // frosts a backdrop behind nothing and draws an edge band around a box
  // that is not there. The Web twin carries the surface marker on the same
  // answer.
  final hasFill = scheme.resolve(keyFill).toValue().a > 0;

  // Surface material at the content role. Each key cap draws its own box
  // rather than composing `OutlinedContainer` — the Web twin's key-cap
  // element is a fixed `<span>` (a `Kbd` can sit inline in a sentence:
  // "press ⌘S to save"), and wrapping that in the primitive's `<div>`
  // breaks that flow (#4358) — so it reads the seat here, at the key's
  // ambient nesting depth, and draws all of it: the share folded into the
  // key fill below, and the frost, chroma, dimming, edge light and bend
  // around each cap ([ResolvedKbd.surfaceBlur] and its siblings).
  final material = hasFill
      ? theme.surfaceFor(.content, depth: SurfaceDepth.of(context))
      : null;
  final surfaceOpacity = material?.opacityIn(theme);

  /// Folds the active content-role material's opacity into [color].
  CoreColor materialFill(CoreColor color) =>
      surfaceOpacity == null ? color : color.scaleAlpha(surfaceOpacity);

  final keyMinSize =
      (merged.keyMinSize ?? CoreKbdStyle.defaultKeyMinSize) * scaling;
  final keyPadding = (merged.keyPadding ?? CoreKbdStyle.defaultKeyPadding)
      .toValue(geometry: theme.geometry);
  // Flat key↔key spacing — `Kbd` renders the keys via `Row.spacing`
  // (균등 분포), so the resolver emits a paint-ready `double` with scaling
  // applied here.
  final keySeparatorSpacing =
      theme.geometry.space(
        merged.keySeparatorSpacing ?? CoreKbdStyle.defaultKeySeparatorSpacing,
      ) *
      scaling;
  final keyRadius = (merged.keyRadius ?? CoreKbdStyle.defaultKeyRadius).toValue(
    geometry: theme.geometry,
  );

  // Chrome colours — read from CoreKbdStyle defaults single source.
  final keyBackgroundColor = scheme.resolve(materialFill(keyFill)).toValue();
  // The material's own edge treatment (when it states one) suppresses
  // this component's stroke colour — never its width. Only on a key that
  // takes the material: one with no fill keeps its stroke, as its Web twin
  // does — it carries no surface marker for the style rule to clear.
  final authoredKeyBorder = scheme
      .resolve(merged.keyBorderColor ?? CoreKbdStyle.defaultKeyBorderColor)
      .toValue();
  final keyBorderColor = material == null
      ? authoredKeyBorder
      : resolveSurfaceStroke(theme, authoredKeyBorder);

  // The rest of the material — the part `materialFill` cannot carry. A
  // nested key (inside another surface) gets the nested token, whose
  // backdrop pass is dropped and whose edge stays.
  final surfaceBlur = material?.blurRadius;
  final surfaceSaturation = material?.saturation;
  final surfaceBackdropBrightness = material?.backdropBrightnessIn(theme);
  final surfaceSheen = material == null ? null : resolveSurfaceSheen(theme);
  // Routed through the geometry seat so a surface style's `strokeFloor`
  // (e.g. neo-brutalism) reaches it, matching Web's `border` utility
  // which floors via the same `--coui-stroke-width-1` variable.
  //
  // A fully transparent border takes no width: `Border.all` insets the box by
  // `width` even when the colour cannot be seen, so a border that is not there
  // would still grow the key (and `0` is not floored — the floor lifts only a
  // drawn stroke). Read from the **authored** colour, before the material
  // suppression above, the way `OutlinedContainer` does: a material that merely
  // suppresses an opaque stroke keeps the key's box, and reading the suppressed
  // colour would turn a paint change into a layout change on this platform
  // alone.
  final keyBorderWidth = authoredKeyBorder.a == 0
      ? 0.0
      : theme.geometry.stroke(
          merged.keyBorderWidth ?? CoreKbdStyle.defaultKeyBorderWidth,
        );

  // ─── Label typography (EMIT Stage 2, Flutter) ──────
  // Single primitive — `default.merge(override).toValue(theme:)`
  // materialises the size-aware token role and resolves its colour
  // through the active scheme in one step (badge 모범). No hand-rolled
  // `typography.resolve` + `.copyWith(color: scheme.resolve(...))`
  // assembly; the merged default already carries the colour token, so
  // no `color:` override is passed.
  final keyTextStyle = CoreKbdStyle.defaultKeyTextStyle
      .merge(merged.keyTextStyle)
      .toValue(theme: theme);

  // The key states its own shadow (none by default), so the active surface
  // style bends a stack stated there (blur / offset) rather than contributing
  // its injected cast. Tinted by the `shadow` token like every other
  // shadow-bearing resolver. Inset layers are dropped: the paint site draws
  // outer shadows only.
  final shadowBase = scheme
      .resolve(const CoreColor.token(CoreColors.shadow))
      .toValue();
  final keyShadowLayers = merged.keyShadow ?? CoreKbdStyle.defaultKeyShadow;
  final keyShadow = keyShadowLayers
      .where((layer) => !layer.inset)
      .toList()
      .toValue(base: shadowBase, geometry: theme.geometry);
  // The key's fill is a surface of its own, which is what the rim belongs on;
  // it decorates a key that casts and never raises a flat one.
  final keyRim = resolveSurfaceRim(context, stack: keyShadowLayers);

  return ResolvedKbd(
    keyShadow: keyShadow,
    keyRim: keyRim,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    keyMinSize: keyMinSize,
    keyPadding: keyPadding,
    keySeparatorSpacing: keySeparatorSpacing,
    keyRadius: keyRadius,
    keyBackgroundColor: keyBackgroundColor,
    keyBorderColor: keyBorderColor,
    keyBorderWidth: keyBorderWidth,
    keyTextStyle: keyTextStyle,
  );
}

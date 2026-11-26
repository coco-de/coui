import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Badge`.
///
/// Widget tree (`badge.dart` builds):
///
/// ```text
/// (optional) TouchTarget + Clickable                 // when onPressed != null
///   └─ (optional) FocusOutline (focusOutlineStyle)   // when onPressed != null
///        └─ InjectedCast (boxShadow)
///             └─ (optional) SurfaceBlur (surfaceBlur / surfaceSaturation /
///                  │                     surfaceBackdropBrightness /
///                  │                     surfaceSheen)
///                  └─ AnimatedContainer (constraints, padding, decoration,
///                       │                transitionDuration, curve)
///                       │  // fill = hover / pressed wash while interactive
///                       └─ Row (min, centred)            // * skipped for dot
///                            ├─ leading dot (leadingDotSize, leadingDotColor)
///                            │                           // * when showDot
///                            ├─ Gap (iconLabelGapStyle)
///                            ├─ IconTheme (iconSize, iconColor)   // leading
///                            ├─ Gap (iconLabelGapStyle)
///                            ├─ DefaultTextStyle (labelTextStyle)
///                            │    └─ child
///                            ├─ Gap (iconLabelGapStyle)
///                            └─ IconTheme (iconSize, iconColor)   // trailing
/// ```
///
/// Carries paint-ready values; the widget never has to spell out the
/// fallback chain inline.
class ResolvedBadge {
  /// Creates a [ResolvedBadge].
  const ResolvedBadge({
    required this.constraints,
    required this.leadingDotSize,
    required this.leadingDotColor,
    required this.backgroundColor,
    required this.hoverBackgroundColor,
    required this.pressedBackgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.padding,
    required this.iconLabelGapStyle,
    required this.iconSize,
    required this.labelTextStyle,
    required this.transitionDuration,
    required this.boxShadow,
    required this.focusOutlineStyle,
    required this.curve,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
  });

  /// The box's size rule (logical px, scaled), by form:
  ///
  /// - [CoreBadgeForm.label] — at least [CoreBadgeStyle.minHeight] tall,
  ///   as wide as its content.
  /// - [CoreBadgeForm.count] — the same height, and never narrower than it
  ///   is tall, so a single digit stays a circle.
  /// - [CoreBadgeForm.dot] — a square of [CoreBadgeStyle.dotSize].
  ///
  /// One value rather than three the widget would choose between, so the
  /// widget hands it to the box without a branch.
  final BoxConstraints constraints;

  /// Diameter of the status dot drawn before the content when the badge's
  /// `showDot` is on (logical px, scaled). The dot paints
  /// [leadingDotColor].
  final double leadingDotSize;

  /// Resolved colour of the leading status dot — the style's
  /// `leadingDotColor` when it states one (the `outlined` status tones
  /// do), else [foregroundColor].
  final Color? leadingDotColor;

  /// Resolved background fill colour at rest.
  final Color backgroundColor;

  /// The fill while an interactive badge is hovered — the badge's own
  /// foreground laid over [backgroundColor] at the state layer's hover
  /// weight. Only painted when the badge is interactive
  /// (`onPressed != null`).
  final Color hoverBackgroundColor;

  /// The fill while an interactive badge is pressed — the same wash at the
  /// state layer's pressed weight.
  final Color pressedBackgroundColor;

  /// Resolved foreground (label / leading dot) colour, or `null` for a
  /// [CoreBadgeForm.dot] badge whose style states none — a dot has no
  /// content to colour.
  final Color? foregroundColor;

  /// Resolved border stroke colour. `null` → no border drawn.
  final Color? borderColor;

  /// Resolved icon tint applied to leading / trailing slots.
  final Color? iconColor;

  /// Border stroke width (logical px, scaled).
  final double borderWidth;

  /// Border radius (scaled).
  final BorderRadius borderRadius;

  /// Padding around the content row (logical px, scaled). Horizontal only
  /// by default; zero for [CoreBadgeForm.dot].
  final EdgeInsets padding;

  /// Nested [CoreGapStyle] forwarded straight to `Gap(gapStyle: …)` for
  /// the spacers between the leading dot, the leading slot, the label and
  /// the trailing slot. `Gap` self-applies `theme.scaling`, so the
  /// resolver passes this through without multiplying.
  final CoreGapStyle iconLabelGapStyle;

  /// Leading / trailing icon size (logical px, scaled).
  final double iconSize;

  /// Paint-ready label text style — the step's role with the form's
  /// weight, the foreground colour, and the per-instance `labelStyle`
  /// overlay.
  final TextStyle labelTextStyle;

  /// Chrome transition duration (driven by
  /// [CoreBadgeStyle.transitionDuration]).
  final Duration transitionDuration;

  /// The shape the chrome change takes over time.
  ///
  /// Paired with the duration beside it rather than left to the framework.
  /// Flutter's implicit animations default to `Curves.linear` and a CSS
  /// transition utility has a curve of its own — same length, different
  /// shape, so side by side one pane slides at a constant rate while the
  /// other eases in and out. Both platforms name the same `CoreEasing`
  /// alias instead: the Web twin writes it as the badge's inline
  /// `transition-timing-function`, on every badge, as this box animates
  /// every badge.
  final Curve curve;

  /// The active surface style's injected cast, or empty under a style
  /// that injects none.
  ///
  /// The badge draws its own box rather than composing
  /// `OutlinedContainer` — it swaps its fill on hover and press, which the
  /// container has no slot for — so the opt-in is restated here. Empty
  /// under every style that casts nothing, so the widget can paint it
  /// unconditionally.
  final List<BoxShadow> boxShadow;

  /// Nested [CoreFocusOutlineStyle] slot — the design-system default
  /// merged with the per-instance override, with the badge's own corner
  /// underneath. Forwarded raw to `FocusOutline(focusOutlineStyle: …)`,
  /// which runs its own resolve / scaling step. Only consumed when the
  /// badge is interactive (`onPressed != null`).
  final CoreFocusOutlineStyle focusOutlineStyle;

  // ── Surface material (the part the fill share cannot carry) ──

  /// Backdrop blur sigma behind the box, or `null` when the active style
  /// states no material, when this badge paints no fill at rest, or when
  /// it sits inside another surface (the nested token drops the pass).
  ///
  /// The Web twin gets the same frost from the style rule its surface
  /// marker selects; without this the badge frosted on one platform and
  /// only faded on the other.
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

/// Resolves [ResolvedBadge] for the given [context].
///
/// Merge chain:
///
/// ```text
/// defaultsBySize[size] → defaultsByForm[form]
///   → defaultsByTone[tone].restingStyleFor(variant, form)   // defaults
///   → CoreBadgeTheme.style
///   → CoreBadgeTheme.toneStyles[tone]
///   → CoreBadgeTheme.variantStyles[variant]
///   → badgeStyle
/// ```
///
/// A caller-stated field wins over the defaults; the nested slots
/// (`labelStyle` / `iconStyle` / `iconLabelGapStyle` /
/// `focusOutlineStyle`) merge field by field onto them. `xl2` has no row of
/// its own and resolves as `xl`.
ResolvedBadge resolveBadge(
  BuildContext context, {
  required CoreBadgeTone tone,
  required CoreBadgeVariant variant,
  required CoreBadgeForm form,
  required CoreComponentSize size,
  CoreBadgeStyle? badgeStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final badgeTheme = theme.coreComponentTheme?.badge;

  // ─── Merge chain ──────────────────────────────────────
  // Semantic identifiers (`tone` / `variant` / `form` / `size`) come
  // straight from the widget — the theme cannot override them
  // (render-only.md (c)). Web resolves these identically, so the two
  // platforms stay 1:1.
  final merged = resolveStyleChain(const CoreBadgeStyle(), [
    badgeTheme?.style,
    badgeTheme?.toneStyles?[tone],
    badgeTheme?.variantStyles?[variant],
    badgeStyle,
  ]);

  // ─── Design-system defaults for this size × form × tone × variant ───
  // The step, what the form changes on top of it, and the tone's resting
  // colours at this strength — three Core tables, one style.
  final sizeRow = CoreBadgeStyle.defaultsBySize[size]!;
  final chrome = sizeRow
      .merge(CoreBadgeStyle.defaultsByForm[form])
      .merge(
        CoreBadgeStyle.defaultsByTone[tone]!.restingStyleFor(variant, form),
      );

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final restingFill = merged.backgroundColor ?? chrome.backgroundColor!;
  // `null` only for a dot whose style states no foreground — a dot has no
  // content to colour, and so no ink to wash with.
  final ink = merged.foregroundColor ?? chrome.foregroundColor;
  final stroke = merged.borderColor ?? chrome.borderColor;
  final corner = merged.borderRadius ?? chrome.borderRadius!;
  final stateLayer = merged.stateLayer ?? CoreBadgeStyle.defaultStateLayer;
  final labelStyle = chrome.labelStyle!.merge(merged.labelStyle);
  final iconStyle = chrome.iconStyle!.merge(merged.iconStyle);
  // Nested CoreGapStyle slot — forwarded raw to `Gap(gapStyle: …)`, which
  // self-applies `theme.scaling`.
  final iconLabelGapStyle = chrome.iconLabelGapStyle!.merge(
    merged.iconLabelGapStyle,
  );
  // Focus-ring slot — the badge's own corner laid underneath so the ring
  // follows the badge (a rounded rectangle around a label, a pill around a
  // count), as on Web where the ring is drawn on the badge's own box. The
  // raw `CoreBorderRadius` goes in, not the paint-ready one, so
  // `FocusOutline` scales it exactly once. A caller's
  // `focusOutlineStyle.borderRadius` still wins.
  final focusOutlineStyle = CoreFocusOutlineStyle(borderRadius: corner)
      .merge(CoreBadgeStyle.defaultFocusOutlineStyle)
      .merge(merged.focusOutlineStyle);

  // ─── Stage 2 — EMIT: dimensions ───────────────────────
  final height = (merged.minHeight ?? chrome.minHeight!) * scaling;
  final dotSize = (merged.dotSize ?? chrome.dotSize!) * scaling;
  // The form's size rule, as one value the widget hands to the box. A
  // count is never narrower than it is tall; a dot is the step's square.
  final constraints = switch (form) {
    CoreBadgeForm.label => BoxConstraints(minHeight: height),
    CoreBadgeForm.count => BoxConstraints(minWidth: height, minHeight: height),
    CoreBadgeForm.dot => BoxConstraints.tightFor(
      width: dotSize,
      height: dotSize,
    ),
  };
  final leadingDotSize =
      (merged.leadingDotSize ?? chrome.leadingDotSize!) * scaling;
  // A dot pads nothing — padding would make the box the padding's size
  // instead of the step's, which is the one thing the dot form exists to
  // state. Resolved here rather than selected in the widget so both
  // platforms read the same decision from the same place.
  final padding = form == CoreBadgeForm.dot
      ? EdgeInsets.zero
      : (merged.padding ?? chrome.padding!).toValue(
              geometry: theme.geometry,
            ) *
            scaling;
  final iconSize = iconStyle.size! * scaling;
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreBadgeStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final borderRadius = corner.toValue(geometry: theme.geometry) * scaling;
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreBadgeStyle.defaultTransitionDuration,
  );
  // The same alias the Web twin names for this element's CSS transition.
  // Chrome moving between states is `move`.
  final curve = CoreEasing.move.toValue();

  // ─── Stage 2 — EMIT: surface material ─────────────────
  // Whether this badge paints a fill at rest. The surface material is a
  // statement about a filled box, so a badge whose resting fill is
  // transparent (`outlined`, the fill token at opacity 0) has no box to
  // make translucent, frost behind or light the edge of. The Web twin
  // carries the surface marker on the same answer.
  final hasFill = scheme.resolve(restingFill).toValue().a > 0;

  // Surface material at the content role — the same seat every composing
  // surface reaches via `resolveOutlinedContainer`. Badge draws its own box
  // rather than composing that primitive (its Web root is a `<span>`, and
  // wrapping it in the primitive's `<div>` breaks the inline flow a badge
  // sits in — #4358), so it reads the seat here, at this badge's ambient
  // nesting depth, and draws all of it: the share folded into the resting
  // and washed fills below, and the frost, chroma, dimming, edge light and
  // bend around the box.
  final material = hasFill
      ? theme.surfaceFor(.content, depth: SurfaceDepth.of(context))
      : null;
  final surfaceOpacity = material?.opacityIn(theme);

  /// Folds the active content-role material's opacity into [color] — the
  /// token's own alpha stays a factor (`token alpha × share`).
  CoreColor materialFill(CoreColor color) =>
      surfaceOpacity == null ? color : color.scaleAlpha(surfaceOpacity);

  // The rest of the material — the part `materialFill` cannot carry. A
  // nested badge (inside another surface) gets the nested token, whose
  // backdrop pass is dropped and whose edge stays.
  final surfaceBlur = material?.blurRadius;
  final surfaceSaturation = material?.saturation;
  final surfaceBackdropBrightness = material?.backdropBrightnessIn(theme);
  final surfaceSheen = material == null ? null : resolveSurfaceSheen(theme);

  // ─── Stage 2 — EMIT: colours ──────────────────────────
  // State layer — the badge's own foreground laid over its resting fill at
  // the ramp's weight (`CoreStateLayer`), blended against the
  // scheme-resolved colours and bridged back to a raw `CoreColor` so the
  // material share folds into it like any other fill. The ink's own alpha
  // is dropped — the rung's weight is the blend ratio — matching the Web
  // twin's `color-mix(in srgb, ink W%, fill)`.
  //
  // Pre-baked as two flat colours the widget SELECTS (strongest wins), the
  // shape `widget/render-only.md` names for mutually exclusive states. No
  // focus wash: focus draws the ring, and a wash on top of it would make a
  // focused badge read as a hovered one.
  CoreColor washed(double weight) {
    if (ink == null) return restingFill;
    final blended = Color.alphaBlend(
      scheme.resolve(ink).toValue().withValues(alpha: weight),
      scheme.resolve(restingFill).toValue(),
    );
    return CoreColor(blended.toARGB32());
  }

  final backgroundColor = scheme.resolve(materialFill(restingFill)).toValue();
  final hoverBackgroundColor = scheme
      .resolve(materialFill(washed(stateLayer.hover)))
      .toValue();
  final pressedBackgroundColor = scheme
      .resolve(materialFill(washed(stateLayer.pressed)))
      .toValue();
  final foregroundColor = ink == null ? null : scheme.resolve(ink).toValue();
  final dotInk = merged.leadingDotColor ?? chrome.leadingDotColor;
  final leadingDotColor = dotInk == null
      ? foregroundColor
      : scheme.resolve(dotInk).toValue();
  final strokeColor = stroke == null ? null : scheme.resolve(stroke).toValue();
  // The material's own edge treatment (when it states one) suppresses this
  // component's stroke colour — never its width, so the box does not shrink
  // by 1px per side on a style swap that is supposed to change paint alone.
  // Only on a badge that takes the material: one that rests unfilled keeps
  // its stroke, as its Web twin does — it carries no surface marker for the
  // style rule to clear.
  final borderColor = strokeColor != null && material != null
      ? resolveSurfaceStroke(theme, strokeColor)
      : strokeColor;
  final iconTint = iconStyle.color;
  final iconColor = iconTint != null
      ? scheme.resolve(iconTint).toValue()
      : foregroundColor;

  // ─── Label text style (size role + form weight + foreground) ────
  // `style.toValue(theme:)` materialises the size-aware token role and
  // resolves its colour through the active scheme. The `color:` override
  // forces the badge foreground when the per-instance `labelStyle` carries
  // no explicit colour, so the label tracks the tone.
  final labelTextStyle = labelStyle.toValue(
    color: merged.labelStyle?.color == null ? foregroundColor : null,
    theme: theme,
  );

  // The style's injected cast — the badge states no shadow of its own, so
  // it takes the style's, the way a composed `OutlinedContainer` would.
  // Empty under every style that injects none.
  final boxShadow = resolveInjectedCast(theme);

  return ResolvedBadge(
    constraints: constraints,
    leadingDotSize: leadingDotSize,
    leadingDotColor: leadingDotColor,
    backgroundColor: backgroundColor,
    hoverBackgroundColor: hoverBackgroundColor,
    pressedBackgroundColor: pressedBackgroundColor,
    foregroundColor: foregroundColor,
    borderColor: borderColor,
    iconColor: iconColor,
    borderWidth: borderWidth,
    borderRadius: borderRadius,
    padding: padding,
    iconLabelGapStyle: iconLabelGapStyle,
    iconSize: iconSize,
    labelTextStyle: labelTextStyle,
    transitionDuration: transitionDuration,
    boxShadow: boxShadow,
    focusOutlineStyle: focusOutlineStyle,
    curve: curve,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
  );
}

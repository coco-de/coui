import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show listEquals;

// ═══════════════════════════════════════════════════
// Surface material — shared across every surface primitive
// ═══════════════════════════════════════════════════

/// Paint-ready edge sheen: colours resolved against the active scheme,
/// width already scaled.
///
/// Separate from [CoreSurfaceEdgeSheen] because that one is the theme's
/// *statement* — platform-neutral, unscaled, holding colour tokens. This
/// is what a painter can use without asking anything else a question,
/// which is the line `widget/render-only.md` draws.
@immutable
class ResolvedSurfaceSheen {
  /// Creates a paint-ready sheen.
  const ResolvedSurfaceSheen({
    required this.width,
    required this.lightColor,
    required this.darkColor,
    required this.fade,
    this.bevel = const [],
    this.rimWidth = 0,
    this.rimColor = const Color(0x00000000),
    this.rimProfile,
  });

  /// Band thickness in logical pixels, scaling applied.
  final double width;

  /// Colour of the horizontal runs, resolved.
  final Color lightColor;

  /// Colour of the vertical runs, resolved.
  final Color darkColor;

  /// Corner fade, already clamped through `effectiveFade`.
  final double fade;

  /// The edge wall, resolved to paint-ready inset layers.
  ///
  /// Empty for a material whose edge is only a band.
  final List<BoxShadow> bevel;

  /// The crest's stroke width in logical pixels, scaling applied. Zero
  /// draws no rim.
  final double rimWidth;

  /// The rim's colour at full strength — the highlight slot, resolved.
  /// The per-point opacity comes from [rimProfile] at paint time.
  final Color rimColor;

  /// The lobe the rim's opacity follows around the contour.
  ///
  /// Carried as the Core statement rather than pre-baked, and this is the
  /// one place the render-only line bends on purpose: the stops depend on
  /// the box the painter is handed, which no resolver knows. What the
  /// painter does with it is call `rimSweep` — the same call the Web
  /// runtime makes — and hand the result to a gradient. It decides
  /// nothing.
  final CoreSurfaceEdgeBevel? rimProfile;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedSurfaceSheen &&
          width == other.width &&
          lightColor == other.lightColor &&
          darkColor == other.darkColor &&
          fade == other.fade &&
          listEquals(bevel, other.bevel) &&
          rimWidth == other.rimWidth &&
          rimColor == other.rimColor &&
          rimProfile == other.rimProfile;

  @override
  int get hashCode => Object.hash(
    width,
    lightColor,
    darkColor,
    fade,
    Object.hashAll(bevel),
    rimWidth,
    rimColor,
    rimProfile,
  );
}

/// The active style's edge sheen in paint-ready form, or null for none.
///
/// One implementation for all six surfaces rather than the same three
/// lines in each resolver. The blur this rides beside had two
/// implementations until recently, and the second one is exactly how a
/// `Card` and a `Dock` came to draw different glass under one preset.
ResolvedSurfaceSheen? resolveSurfaceSheen(
  ThemeData theme, {
  CoreSurfaceRole role = CoreSurfaceRole.content,
}) {
  // The role's own band when the active style states one, the flat field
  // otherwise. The fallback is not dead weight: a theme built by hand
  // (`ThemeData(surfaceSheen: …)`, which the tests do) carries the flat
  // field and no token, and a surface under it should still be edged.
  final sheen = theme.surfaceFor(role)?.sheen ?? theme.surfaceSheen;
  if (sheen == null) return null;

  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final highlight = scheme
      .resolve(const CoreColor.token(CoreColors.surfaceHighlight))
      .toValue();
  final bevel = sheen.bevel;
  final drawsRim = bevel?.drawsRim ?? false;

  return ResolvedSurfaceSheen(
    width: sheen.width * scaling,
    lightColor: scheme.resolve(sheen.lightColor).toValue(),
    darkColor: scheme.resolve(sheen.darkColor).toValue(),
    fade: sheen.effectiveFade,
    // The crest, in the same highlight the wall is painted in — one light,
    // one colour, so the rim can never read as lit by something else.
    rimWidth: drawsRim ? bevel!.rimWidth * scaling : 0,
    rimColor: highlight,
    rimProfile: drawsRim ? bevel : null,
    // The same highlight slot `resolveSurfaceRim` draws its layers in, and
    // for the same reason: it is the one colour in the palette that is
    // brighter than the surface in both modes, so a wall painted with it
    // never inverts when the theme flips.
    //
    // The identity geometry constraint is deliberate. The style's shadow
    // transform bends what a *component* authored; this stack is the
    // style's own statement, so running its own transform over it would
    // scale a blur it already chose.
    bevel: (bevel?.toLayers() ?? const <CoreShadowLayer>[]).toValue(
      base: highlight,
      geometry: const CoreSurfaceGeometryConstraint(),
    ),
  );
}

/// The stroke a surface paints once the active material has had its say.
///
/// A material that draws its own edge (`CoreSurfaceToken.drawsOwnEdge`)
/// makes the component's resting stroke a second boundary on the same
/// pixels, so the colour goes and the box stays.
///
/// **Colour only, and the width is decided before the suppression.** Both
/// halves matter and the second is the subtle one: Flutter collapses a
/// transparent border's width to keep it out of layout, so a caller that
/// asked this for a width *after* suppressing would silently trade a paint
/// change for 1px per side — while Web, which only overrides the colour,
/// kept its box. That 2px would be a cross-platform divergence nothing in
/// either suite measures.
///
/// Shared rather than repeated because the two surfaces that resolve their
/// own stroke would otherwise disagree, and the one that was written second
/// is the one that would be missed — which is how a `Card` and a `Popup`
/// came to draw different glass before.
///
/// Takes the role for the same reason [resolveSurfaceSheen] does, and it
/// is the same role: suppression is what a band *pays for*. A surface that
/// draws no band must keep the stroke it always had, or it is left with no
/// boundary at all.
///
/// Reading the flat field alone made that pairing impossible to state. The
/// flat field is the content role's, so once one role became a standard
/// material the answer was false for every surface — and a floating panel
/// then drew its band **and** kept its stroke, two boundaries on the same
/// pixels. The fallback stays for a theme built by hand, exactly as the
/// sheen resolver keeps one.
Color resolveSurfaceStroke(
  ThemeData theme,
  Color authored, {
  CoreSurfaceRole role = CoreSurfaceRole.content,
}) => (theme.surfaceFor(role)?.drawsOwnEdge ?? theme.surfaceDrawsOwnEdge)
    ? const Color(0x00000000)
    : authored;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `OutlinedContainer`.
///
/// Widget tree (`co_outlined_container` decides which optional branches
/// render):
///
/// ```text
/// optional ClipRRect (when surfaceBlur > 0)
///   └─ optional Stacks (backdrop blur + body)
///        └─ optional CustomPaint (when borderStyle == dashed | dotted)
///             └─ AnimatedContainer (background colour | gradient, border,
///                                   radius, boxShadow,
///                                   width, height, clipBehavior)
///                  └─ AnimatedContainer (padding, inner radius)
///                       └─ child
/// ```
///
/// Every field is a paint-ready Flutter value: colours are already run
/// through `scheme.resolve(...).toValue()`, the border radius / padding
/// are Flutter geometry types, and the elevation has been materialised
/// into a [BoxShadow] stack. The widget reads each field straight onto a
/// Flutter primitive without re-running any merge / token / colour
/// resolution (Epic #1603 C9/C11 — render-only widget).
class ResolvedOutlinedContainer {
  /// Creates a [ResolvedOutlinedContainer].
  const ResolvedOutlinedContainer({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
    required this.borderWidth,
    required this.dashLength,
    required this.dashSpacing,
    required this.borderStyle,
    required this.boxShadow,
    required this.insetBoxShadow,
    required this.padding,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.width,
    required this.height,
    required this.duration,
    required this.curve,
    required this.clipBehavior,
    this.backgroundGradient,
    this.refraction,
  });

  /// Background fill colour (alpha already includes `surfaceOpacity`).
  ///
  /// Not painted while [backgroundGradient] is set.
  final Color backgroundColor;

  /// Background gradient, or `null` for the solid [backgroundColor].
  ///
  /// When set it is painted **instead of** the colour. Every stop's alpha
  /// already includes `surfaceOpacity`, and the stops are resolved through
  /// the active scheme like every other colour here.
  final Gradient? backgroundGradient;

  /// Border stroke colour.
  final Color borderColor;

  /// Outer border radius.
  final BorderRadius borderRadius;

  /// Border stroke width (already scaled).
  final double borderWidth;

  /// Dash segment length when the border style is dashed (already
  /// scaled — the dash painter consumes it directly).
  final double dashLength;

  /// Gap between dash segments (already scaled).
  final double dashSpacing;

  /// Border style — solid / dashed / dotted / none.
  final CoreOutlinedContainerBorderStyle borderStyle;

  /// Paint-ready drop-shadow stack — the elevation preset already
  /// mapped to Flutter [BoxShadow]s (tinted by the active scheme's
  /// shadow colour). Empty for `elevation == none`.
  final List<BoxShadow> boxShadow;

  /// Shadows drawn over the surface rather than behind it.
  ///
  /// Separate because Flutter paints `BoxDecoration` shadows before the
  /// background, so a layer left in that list is covered by the surface
  /// and only shows where it spills past the edge — which is the
  /// opposite of what an inset layer is for. These are painted by a
  /// foreground painter clipped to the surface instead.
  final List<BoxShadow> insetBoxShadow;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  /// Backdrop blur sigma (logical px). When > 0 a `BackdropFilter`
  /// layer is inserted.
  final double? surfaceBlur;

  /// Chroma lift for the backdrop, or null/`1.0` for none.
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  ///
  /// Rides the same backdrop pass as [surfaceSaturation].
  final double? surfaceBackdropBrightness;

  /// Light running along the surface's edge, or null for none.
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Edge bending the surface's material asks for, or null for none.
  ///
  /// Resolved here, with the rest of the material, rather than read off the
  /// ambient theme by the widget: a surface that names its own
  /// `surfaceStyle` takes this from that material, so a glass pane inside an
  /// opaque theme still bends and an opaque pane inside a glass one does
  /// not. A caller's own request to the widget still wins over this.
  final CoreSurfaceRefraction? refraction;

  /// Explicit width (logical px). `null` = intrinsic.
  final double? width;

  /// Explicit height (logical px). `null` = intrinsic.
  final double? height;

  /// Animation duration for chrome property changes.
  final Duration duration;

  /// The shape of that change over time.
  ///
  /// Paired with [duration] rather than left to the framework, because the
  /// framework's default is `Curves.linear` and the Web twin's is not.
  /// Same length, different shape: side by side one pane slides at a
  /// constant rate while the other eases in and out, which reads as the
  /// two being out of step even though they start and finish together.
  final Curve curve;

  /// Clip behaviour applied to the chrome.
  final Clip clipBehavior;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedOutlinedContainer] for the given [context].
///
/// Merge chain (Epic #1302):
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.outlinedContainer.style
///   → widget.containerStyle
/// ```
///
/// Each layer can override any subset of [CoreOutlinedContainerStyle]
/// fields; the file-private slot helpers below fill in design-system
/// defaults for any slot that remains null.
ResolvedOutlinedContainer resolveOutlinedContainer(
  BuildContext context, {
  CoreOutlinedContainerStyle? containerStyle,
  CoreSurfaceRole role = .defaultRole,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final outlinedTheme = theme.coreComponentTheme?.outlinedContainer;

  // ─── Merge chain ──────────────────────────────────────
  // `merge(other)` returns a copy with non-null fields from `other`
  // overriding `this`, so chaining outward gives last-wins precedence.
  final merged = resolveStyleChain(const CoreOutlinedContainerStyle(), [
    outlinedTheme?.style,
    containerStyle,
  ]);

  // The material is the one thing this surface can take from somewhere other
  // than the surrounding theme: a `surfaceStyle` names the preset whose
  // material it draws, and everything else (palette, geometry, density)
  // still comes from `theme`. Null hands back the surrounding theme, so a
  // surface that states nothing reads exactly what it always read.
  final materialTheme = resolveSurfaceTheme(context, merged.surfaceStyle);

  // ─── Resolved chrome (paint-ready Flutter values) ─────
  // Background / border colours route through `CoreOutlinedContainerStyle
  // .defaultXxx` (single source — no `cs.surface` / `cs.outlineVariant`
  // here) and are materialised via `scheme.resolve(token).toValue()` so
  // they track the **active** scheme — `.toValue()` alone would fall back
  // to the light-default ARGB table and ignore dark-mode switches (#1601).
  final backgroundToken =
      merged.backgroundColor ??
      CoreOutlinedContainerStyle.defaultBackgroundColor;
  // `surfaceOpacity` multiplies into the background's alpha — applied on
  // the CoreColor (preserving the token) before scheme resolution.
  //
  // Falls back to the theme so a translucent surface can be a theme-level
  // decision rather than something every caller restates. The Web resolver
  // has always read the theme here; this side did not, which made a
  // theme-wide surface treatment reach one platform only.
  // 이 박스는 기본적으로 콘텐츠층에 앉지만, 자기가 뜬다는 근거를 가진
  // 호출자는 [role] 로 그것을 말한다 — 그 판단은 박스가 아니라 그것을
  // 합성한 컴포넌트만 할 수 있다. 깊이는 트리에서 오고(ambient), 그
  // 깊이가 어떤 재질이 되는지는 축이 정한다 — 컴포넌트는 둘 다 모른다.
  final material = materialTheme.surfaceFor(
    role,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity =
      merged.surfaceOpacity ?? material?.opacityIn(materialTheme);
  final backgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? backgroundToken
            : backgroundToken.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  // A gradient fill replaces the colour rather than layering on it, and the
  // surface's translucency dims it stop by stop.
  final backgroundGradient = merged.backgroundGradient?.toValue(
    scheme: scheme,
    alphaScale: surfaceOpacity ?? 1,
  );

  final borderToken =
      merged.borderColor ?? CoreOutlinedContainerStyle.defaultBorderColor;
  final authoredBorderColor = scheme.resolve(borderToken).toValue();
  // When the resolved border colour is fully transparent the border is
  // invisible — collapse its width to 0 so it doesn't eat the child's
  // layout (`Border.all` insets the box by `width` even when alpha == 0).
  // Mirrors `CoreCardStyle.filled` variant handling. `* scaling` (Stage2
  // EMIT) is applied here in the local var, never in the return literal.
  //
  // Read from the **authored** colour, deliberately, and before the
  // material suppression below. A variant that authored transparent (Card
  // `filled`) still collapses; a surface whose opaque stroke is merely
  // suppressed keeps its box. Reading the suppressed colour instead would
  // turn a paint change into a 1px-per-side layout change on Flutter while
  // Web — which only overrides the colour — kept its box, and nothing in
  // the suite would have caught the 2px.
  // An explicit none style likewise has no painted border and must not
  // reserve space, regardless of the authored colour.
  final preserveBorder =
      merged.preserveTransparentBorder ??
      CoreOutlinedContainerStyle.defaultPreserveTransparentBorder;
  final borderWidth =
      merged.borderStyle == CoreOutlinedContainerBorderStyle.none ||
          (!preserveBorder && authoredBorderColor.a == 0)
      ? 0.0
      : theme.geometry.stroke(
          merged.borderWidth ?? CoreOutlinedContainerStyle.defaultBorderWidth,
          scaling: scaling,
        );
  final borderColor = resolveSurfaceStroke(
    materialTheme,
    authoredBorderColor,
    role: role,
  );
  final dashLength =
      (merged.dashLength ?? CoreOutlinedContainerStyle.defaultDashLength) *
      scaling;
  final dashSpacing =
      (merged.dashSpacing ?? CoreOutlinedContainerStyle.defaultDashSpacing) *
      scaling;
  // Flutter treats a solid or custom-painted zero-width stroke as a
  // device-pixel hairline. Core's zero width means no border (as in CSS
  // and SVG), including when a transparent authored colour collapses it.
  final borderStyle = borderWidth == 0
      ? CoreOutlinedContainerBorderStyle.none
      : merged.borderStyle ?? CoreOutlinedContainerStyle.defaultBorderStyle;
  // `* scaling` here, like the border width above. Two different steps are
  // in play and both have to run: `geometry` bends the corner (the surface
  // style squaring it under a brutal preset, the density moving it a rung),
  // `scaling` is the app's size factor. The geometry bend happens inside
  // `toValue`; the size factor is this multiplication.
  final radius =
      _resolveBorderRadius(
        geometry: theme.geometry,
        widget: merged.borderRadius?.toValue(geometry: theme.geometry),
      ) *
      scaling;
  // `toGeometry`, not `toValue`: a caller may hand this a directional
  // inset (Alert does), and flattening one to physical sides throws by
  // design — the padding field here is already EdgeInsetsGeometry.
  //
  // `* scaling` for the same reason as the radius: 41 components hand this
  // one a Core value precisely so that the bend runs here, once. It ran on
  // the border and not on this.
  final pad =
      _resolvePadding(
        geometry: theme.geometry,
        widget: merged.padding?.toGeometry(geometry: theme.geometry),
      ) *
      scaling;
  final elevation =
      merged.elevation ?? CoreOutlinedContainerStyle.defaultElevation;
  final clip = _resolveClipBehavior(
    merged.clipBehavior ?? CoreOutlinedContainerStyle.defaultClipBehavior,
  );
  final transitionDuration = resolveMotionDuration(
    context,
    merged.duration ?? CoreOutlinedContainerStyle.defaultDuration,
  );

  // Elevation → paint-ready BoxShadow stack. Resolved here (not in the
  // widget) so the surface's shadow colour runs through the active
  // scheme once and the widget stays render-only (C11). The shared
  // `CoreOutlinedContainerElevation.toValue` adapter mirrors the
  // Web `tailwindShadowClass`. The shadow base is
  // `merged.shadowBaseColor`, which is the palette's `shadow` token unless a
  // component states its own, resolved through the active scheme: a token
  // follows a dark-mode switch, a raw colour stays what it was stated as.
  final shadowBase = scheme
      .resolve(
        merged.shadowBaseColor ??
            CoreOutlinedContainerStyle.defaultShadowBaseColor,
      )
      .toValue();
  // An explicit stack wins outright rather than layering on top of the
  // elevation preset. Combining the two would make a hard offset shadow
  // arrive with the preset's soft ambient blur still under it, so the
  // look a caller asked for would only ever be approximated.
  final explicitShadow = merged.boxShadow;
  final coreShadow = explicitShadow ?? elevation.layers;
  // Split before converting, because the two halves are painted by
  // different machinery: an outer layer is a `BoxDecoration` shadow,
  // while an inset layer has to be drawn over the surface. Flutter's
  // `BoxShadow` carries no inset flag, so a widget handed one list would
  // have to infer the intent from a blur style — and the blur style is
  // not what makes a shadow inset.
  //
  // The active style has its say once, over the whole stack, and the
  // halves are taken from the result. Handing each half to the converter
  // separately would run the style's transform twice on two different
  // inputs — harmless while it maps layer to layer, and wrong the moment
  // it does anything to the stack as a whole, which is the direction a
  // style that wants to add a rim has to go.
  // A surface at rest elevation authors nothing, and this style boxes
  // surfaces as well as controls — the reference implementations show
  // panels, alerts and accordions all carrying the hard cast. Read
  // explicitly for the same reason Button does: the shared transform no
  // longer substitutes, so what gets boxed is a statement.
  //
  // An explicitly empty stack is left empty. "No shadow" is a thing a
  // caller can ask for, and answering it with the style's cast would
  // make that request unsayable.
  // The contributed cast takes the brightness's strength alone
  // (`strengthen`); an authored stack takes it inside the full bend.
  //
  // A style that pins its stack's alpha (`shadowStrengthens: false`) bends
  // through the same geometry with the brightness put back to light: the
  // surface style's blur / offset / mirror still reach it, the dark's
  // multiplier does not. The Web twin leaves `--coui-shadow-strength` out of
  // the same stack's colour term. The contributed cast is the style's, not
  // this stack, and keeps the strength.
  final strengthens =
      merged.shadowStrengthens ??
      CoreOutlinedContainerStyle.defaultShadowStrengthens;
  final authoredGeometry = strengthens
      ? theme.geometry
      : theme.geometry.copyWith(brightness: CoreBrightness.light);
  final bent = explicitShadow == null && coreShadow.isEmpty
      ? theme.geometry.strengthen(theme.geometry.controlShadow)
      : authoredGeometry.shadow(coreShadow);
  const applied = CoreSurfaceGeometryConstraint();
  final boxShadow = bent
      .where((l) => !l.inset)
      .toList()
      .toValue(base: shadowBase, geometry: applied);
  // The style's own rim rides the same inset list. `BoxShadow` carries
  // its colour, so one list holds layers drawn in two different tints —
  // which is the whole reason the rim travels beside the stack instead
  // of inside it.
  //
  // `applied` (identity) for the rim on purpose: the blur scale is a
  // derivation of what the *component* authored, and the rim is not
  // that. Running the style's transform over its own statement would
  // apply it twice.
  final insetBoxShadow = [
    ...bent
        .where((l) => l.inset)
        .toList()
        .toValue(base: shadowBase, geometry: applied),
    ...resolveSurfaceRim(context, stack: coreShadow),
  ];

  return ResolvedOutlinedContainer(
    backgroundColor: backgroundColor,
    backgroundGradient: backgroundGradient,
    borderColor: borderColor,
    borderRadius: radius,
    borderWidth: borderWidth,
    dashLength: dashLength,
    dashSpacing: dashSpacing,
    borderStyle: borderStyle,
    boxShadow: boxShadow,
    insetBoxShadow: insetBoxShadow,
    padding: pad,
    surfaceBlur: merged.surfaceBlur ?? material?.blurRadius,
    // No component-level override for these two: the style slot lets a
    // caller retune the blur it already had, while the material a
    // surface is made of is a decision the theme axis owns for every
    // surface at once.
    surfaceSaturation: material?.saturation,
    // Resolved for this theme's mode rather than read off the token: the
    // dimming is authored as a pair because a multiply helps in opposite
    // directions on the two sides of the palette (`CoreBackdropBrightness`).
    // Asking the theme is not branching on the axis — it is the same thing
    // every colour on this line already does through `scheme.resolve`.
    // Stated once, here, for all thirteen resolvers that make this call.
    surfaceBackdropBrightness: material?.backdropBrightnessIn(materialTheme),
    surfaceSheen: resolveSurfaceSheen(materialTheme, role: role),
    refraction: materialTheme.surfaceRefraction,
    width: merged.width,
    height: merged.height,
    duration: transitionDuration,
    // The same alias the Web resolver names for this element's CSS
    // transition. Chrome moving from one state to another is `move`; the
    // two platforms have to name the same one or they disagree in shape.
    curve: CoreEasing.move.toValue(),
    clipBehavior: clip,
  );
}

// ═══════════════════════════════════════════════════
// File-private slot helpers
// ═══════════════════════════════════════════════════

/// Resolves the border radius.
BorderRadius _resolveBorderRadius({
  required CoreSurfaceGeometryConstraint geometry,
  BorderRadiusGeometry? widget,
}) {
  if (widget != null) {
    return widget is BorderRadius ? widget : BorderRadius.zero;
  }

  return CoreOutlinedContainerStyle.defaultBorderRadius.toValue(
    geometry: geometry,
  );
}

/// Resolves the padding.
EdgeInsetsGeometry _resolvePadding({
  required CoreSurfaceGeometryConstraint geometry,
  EdgeInsetsGeometry? widget,
}) {
  return widget ??
      CoreOutlinedContainerStyle.defaultPadding.toValue(geometry: geometry);
}

/// Resolves the clip behaviour, mapping the core enum to Flutter [Clip].
Clip _resolveClipBehavior(CoreClipBehavior behavior) {
  return switch (behavior) {
    .none => .none,
    .hardEdge => .hardEdge,
    .antiAlias => .antiAlias,
    .antiAliasWithSaveLayer => .antiAliasWithSaveLayer,
  };
}

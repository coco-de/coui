import 'package:coui_core/src/surface/surface_backdrop_brightness.dart';
import 'package:coui_core/src/surface/surface_edge_sheen.dart';
import 'package:coui_core/src/surface/surface_opacity.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// Surface rendering type across design systems.
///
/// Determines how a component's background surface is rendered.
enum SurfaceType {
  /// Flat solid surface (CoUI Web default).
  flat,

  /// Tonal elevation surface with color tint shifts (M3 Expressive).
  tonalElevation,

  /// Translucent glass material with blur and refraction (Liquid Glass).
  glass,
}

/// Platform-independent surface token describing visual appearance.
@immutable
class CoreSurfaceToken {
  /// Creates a [CoreSurfaceToken] with the given fields.
  ///
  /// Prefer the named constructors ([CoreSurfaceToken.flat],
  /// [CoreSurfaceToken.tonalElevation], [CoreSurfaceToken.glass]) when
  /// constructing for a specific surface family.
  const CoreSurfaceToken({
    required this.type,
    this.elevation = 0,
    this.opacity = CoreSurfaceOpacity.opaque,
    this.blurRadius,
    this.saturation = identitySaturation,
    this.saturationInDarkMode,
    this.backdropBrightness = CoreBackdropBrightness.identity,
    this.sheen,
    this.drawsOwnEdge = false,
  }) : assert(
         !drawsOwnEdge || sheen != null,
         'A material that claims its own edge and paints no band leaves the '
         'surface with no boundary at all — the component stroke it '
         'suppresses was the only one there was.',
       );

  /// CoUI Web flat surface (fully opaque).
  const CoreSurfaceToken.flat()
    : type = SurfaceType.flat,
      elevation = 0,
      opacity = CoreSurfaceOpacity.opaque,
      blurRadius = null,
      saturation = identitySaturation,
      saturationInDarkMode = null,
      backdropBrightness = CoreBackdropBrightness.identity,
      sheen = null,
      drawsOwnEdge = false;

  /// M3E tonal elevation surface.
  const CoreSurfaceToken.tonalElevation({
    required this.elevation,
  }) : type = SurfaceType.tonalElevation,
       opacity = CoreSurfaceOpacity.opaque,
       blurRadius = null,
       saturation = identitySaturation,
       saturationInDarkMode = null,
       backdropBrightness = CoreBackdropBrightness.identity,
       sheen = null,
       drawsOwnEdge = false;

  /// Liquid Glass translucent surface.
  const CoreSurfaceToken.glass({
    required this.opacity,
    required double blur,
    this.saturation = identitySaturation,
    this.saturationInDarkMode,
    this.backdropBrightness = CoreBackdropBrightness.identity,
    this.sheen,
    this.drawsOwnEdge = false,
  }) : assert(
         !drawsOwnEdge || sheen != null,
         'A material that claims its own edge and paints no band leaves the '
         'surface with no boundary at all.',
       ),
       type = SurfaceType.glass,
       elevation = 0,
       blurRadius = blur;

  /// The surface rendering type.
  final SurfaceType type;

  /// M3E elevation level (0-5).
  final int elevation;

  /// How much of this surface's fill shows (0.0-1.0), stated per mode.
  ///
  /// The authored value is a pair — see [CoreSurfaceOpacity] for why one
  /// number cannot say it — and collapses to a scalar only at the seat
  /// that folds a recipe into a theme, or in the stylesheet rule the Web
  /// restates under both dark forms. A reader that wants a number asks one
  /// mode for it; there is deliberately no getter that picks for you.
  final CoreSurfaceOpacity opacity;

  /// Blur radius for glass surfaces.
  final double? blurRadius;

  /// How much this surface amplifies the chroma of what shows through it.
  ///
  /// `1.0` is identity. Above it, the backdrop reads as seen through a
  /// tinted material rather than through fog — which is the difference
  /// between a translucent panel and a blurred one, and it is why blur
  /// alone has never looked like glass.
  ///
  /// Rides the same backdrop pass as [blurRadius] on both platforms, so a
  /// surface turned opaque loses this along with the blur — one pass, not
  /// two features that could disagree. That coupling is structural and
  /// needs no branch of its own.
  ///
  /// **Web asks for that opacity; Flutter has nothing to ask with.** The
  /// stylesheet answers `prefers-reduced-transparency`, and because both
  /// ride one `backdrop-filter` the saturation goes with the blur there.
  /// Flutter's `AccessibilityFeatures` exposes no transparency signal at
  /// all, so on that side the kit takes the answer rather than reading
  /// it — `CoUIApp.reduceTransparency` feeds the same fold through
  /// [withoutTransparency]. See `CoreSurfaceA11yContract.usesTransparency`
  /// for why that asymmetry is recorded rather than waited on.
  ///
  /// This is the lift for both modes unless [saturationInDarkMode] states
  /// one of its own. Read it through [saturationFor], which is the question
  /// a renderer actually asks: how much, in the mode it is drawing.
  final double saturation;

  /// The chroma lift while the dark palette is active, or null for the same
  /// lift as [saturation].
  ///
  /// ## Why a deviation and not a second required number
  ///
  /// The fill and the dimming are authored as pairs because the preset has
  /// to answer for both modes — a fill that is right in light is too thin in
  /// dark, and the multiply helps in opposite directions. Saturation has no
  /// such obligation: one number has always been right for both, so every
  /// shipped material states one. A mode that wants its own lift — the dark
  /// backdrop reads dimmer, so the same multiplier looks flatter there —
  /// says so here, and every other mode keeps reading [saturation].
  ///
  /// Null is the shipped answer. A field that defaulted to a number would
  /// move every existing material by the amount of its default.
  ///
  /// Rides the backdrop pass with [saturation], on both platforms: the Web
  /// restates the filter list under the dark rules, Flutter picks the number
  /// when the theme hands the material out for its mode.
  final double? saturationInDarkMode;

  /// How much this surface dims what shows through it.
  ///
  /// `1.0` is identity. Below it the backdrop is darkened before the fill
  /// goes over it, which is what Apple's `regular` variant is defined to
  /// do — *"blurs and adjusts the luminosity of background content to
  /// maintain legibility of text and other foreground elements"*.
  ///
  /// ## Why a saturated fill needs this and alpha cannot supply it
  ///
  /// A control whose foreground is white keeps that foreground only while
  /// what sits behind the glass stays dark enough. Measured against white
  /// text over a light backdrop, fill alpha alone never gets there:
  ///
  /// | alpha | contrast at identity brightness |
  /// |---|---|
  /// | 0.4 | 1.88 |
  /// | 0.7 | 2.90 |
  /// | 0.9 | 3.94 |
  /// | 1.0 | 4.63 — but that is an opaque surface, not a material |
  ///
  /// The bar is not 4.5 but **4.63**: that is what the shipped *opaque*
  /// primary already measures, so the question a translucent variant has
  /// to answer is "no worse than today", not "above the floor".
  ///
  /// Dimming the backdrop clears it at alpha 0.65 / brightness 0.25 —
  /// 6.16 over a white page, 6.29 over a light card, 7.06 over a photo,
  /// 8.12 over dark UI.
  ///
  /// ## Why this is not just "turn the brightness down until it passes"
  ///
  /// Optimising for contrast alone picks alpha 0.20, which passes at 8.80
  /// and renders a **grey** button: with the dimming carrying the whole
  /// contrast burden the fill's own hue stops reading. The authored pair
  /// is the minimum alpha that holds contrast ≥ 4.63 *and* chroma ≥ 60%
  /// of the solid fill — the second condition is what keeps it a coloured
  /// control rather than a legible grey one.
  ///
  /// ## Transport
  ///
  /// Rides the same single backdrop pass as [blurRadius] and [saturation]
  /// on both platforms — one `backdrop-filter` list on Web, one composed
  /// `ImageFilter` on Flutter — so it goes away with them under
  /// [withoutTransparency] for the reason given there. Ordered after the
  /// chroma lift on both sides, because dimming an amplified backdrop and
  /// amplifying a dimmed one are different colours.
  final CoreBackdropBrightness backdropBrightness;

  /// Light running along this surface's edges, or null for none.
  ///
  /// See [CoreSurfaceEdgeSheen] for why this is distinct from
  /// `CoreSurfaceGeometryConstraint.highlightRim`.
  final CoreSurfaceEdgeSheen? sheen;

  /// Whether this material's own edge treatment **is** the boundary.
  ///
  /// A component draws a resting stroke because something has to say where
  /// the surface ends. A material that already draws that edge makes the
  /// stroke a second one — and here it is literally the same token twice on
  /// the same pixels: the sheen's vertical runs are `outline` at 25% and the
  /// card's border is `outline` at 100%, on an edge the band covers with
  /// `inset: 0` and an inherited radius. Two alphas of one colour on one
  /// edge is what reads as "a bordered box that happens to be blurred"
  /// rather than as a pane.
  ///
  /// This says nothing about shadows. A translucent pane needs its drop
  /// shadow to sit *above* the backdrop rather than smear into it, so the
  /// shadow is part of the material's depth, not chrome competing with it.
  ///
  /// Suppression is paint-only on both platforms: the border box stays and
  /// only its colour goes. That is not a detail — the surviving box is what
  /// a forced-colours fallback has to recolour, and on Web a zeroed width
  /// would grow the content box by 2px per axis at the exact moment a style
  /// swap is supposed to change paint alone.
  ///
  /// Setting this obliges the recipe to two things, enforced differently
  /// because Dart allows only one of them to be enforced well.
  ///
  /// It must state a [sheen] — a material that claims its own edge and
  /// paints no band leaves the surface with no boundary at all, since the
  /// stroke it suppressed was the only one. That is an assert here: both
  /// values are this constructor's own parameters.
  ///
  /// It must also stop claiming a stroke boundary in its a11y contract,
  /// which forced colours would preserve and this band is not. That one
  /// spans two objects, and a `const` initializer cannot read a property
  /// off another const value (`const_eval_property_access`), so it is a
  /// test over the preset table rather than an assert. The distinction
  /// matters to anyone adding a preset: the first mistake fails at the
  /// call site, the second only when the suite runs.
  final bool drawsOwnEdge;

  /// The saturation at which a surface amplifies nothing.
  static const double identitySaturation = 1;

  /// The brightness at which a surface dims nothing.
  ///
  /// The *resolved* value, which is what a renderer compares against to
  /// decide whether the pass is worth running. The authored value is a
  /// pair — see [CoreBackdropBrightness] for why one number cannot say
  /// it — and collapses to this scale at the seat that folds a recipe
  /// into a theme.
  static const double identityBrightness = CoreBackdropBrightness.identityValue;

  /// The chroma lift this material applies while drawing in [brightness].
  ///
  /// The one place the mode is turned into a number for saturation — the
  /// scalar twin of the `resolve` the paired terms carry. A reader that
  /// reads [saturation] directly draws the dark palette with the light
  /// lift whenever a material states a dark one of its own.
  double saturationFor(CoreBrightness brightness) =>
      brightness == CoreBrightness.dark
      ? saturationInDarkMode ?? saturation
      : saturation;

  /// Whether any term of this material is stated per mode through a
  /// deviation, so a seat can skip asking which mode it is in when none is.
  ///
  /// The mode of a Flutter theme is derived from its palette on every ask, so
  /// the question is not free; this is the cheap answer to "does the mode
  /// matter for this material at all". Terms authored as pairs
  /// ([opacity], [backdropBrightness]) are not counted — they are resolved
  /// where they are read, and have no scalar to collapse.
  bool get statesByMode =>
      saturationInDarkMode != null || (sheen?.statesByMode ?? false);

  /// This material as it draws in [brightness]: the deviations collapsed
  /// into the scalars they stand for, and no deviation left to ask about.
  ///
  /// Returns this very instance when [statesByMode] is false, so a seat that
  /// hands materials out through here costs nothing and compares equal for
  /// every style that states no per-mode term.
  ///
  /// The paired terms are carried untouched — the readers of those resolve
  /// them with the theme in hand and always have.
  CoreSurfaceToken atBrightness(CoreBrightness brightness) {
    if (!statesByMode) return this;

    return CoreSurfaceToken(
      type: type,
      elevation: elevation,
      opacity: opacity,
      blurRadius: blurRadius,
      saturation: saturationFor(brightness),
      backdropBrightness: backdropBrightness,
      sheen: sheen?.atBrightness(brightness),
      drawsOwnEdge: drawsOwnEdge,
    );
  }

  /// This surface with its transparency removed — the single statement
  /// of what "reduce transparency" means to a material, so the two
  /// platforms cannot answer it differently.
  ///
  /// The fill goes fully opaque and the backdrop pass goes away. Blur
  /// and saturation ride that one pass, so dropping it takes both: a
  /// surface that keeps amplifying chroma behind a backdrop nobody can
  /// see through is not a fallback, it is the same material with one
  /// symptom hidden.
  ///
  /// The edge band stays. It is decoration on a boundary rather than
  /// transparency, and removing it would take the surface's edge with
  /// it — a component that loses its boundary to an accessibility
  /// setting is worse off than one that kept a translucent fill.
  ///
  /// ## Who calls this, and why the two sides differ
  ///
  /// Web does not: its stylesheet answers
  /// `prefers-reduced-transparency` directly, and this method exists so
  /// a test can hold that CSS to the same statement rather than to a
  /// second copy of the rule.
  ///
  /// Flutter cannot read the preference at all — `AccessibilityFeatures`
  /// exposes no transparency signal, though the OS setting exists on
  /// Apple platforms. So the kit takes the answer instead of reading it:
  /// an app that obtains the signal by its own means hands it to
  /// `CoUIApp`, and the seat applies exactly this. That is the most this
  /// side can do, and it is more than never being able to trigger the
  /// fallback at all.
  CoreSurfaceToken withoutTransparency() => .new(
    type: type,
    elevation: elevation,
    // `opacity`, `blurRadius`, `saturation` and `backdropBrightness` are
    // left to their defaults on purpose — fully opaque, no backdrop pass,
    // no chroma lift, no dimming. Naming them here would restate the
    // constructor rather than the policy, and the policy is in this
    // method's doc.
    sheen: sheen,
    drawsOwnEdge: drawsOwnEdge,
  );

  /// Creates a copy with the given fields replaced.
  ///
  /// Exists so a seat can adjust one term without restating the rest.
  /// `withoutTransparency` above deliberately drops fields to their
  /// defaults and says so; this one preserves everything it is not
  /// given, which is the opposite contract and the reason both exist.
  ///
  /// Every field is listed, and that is enforced rather than remembered:
  /// `coui_lints`' `avoid_incomplete_copy_with` fails CI on a missing one.
  /// That matters here more than usual — this class has already lost a
  /// field to exactly this shape once, in `CoreSurfaceTuning.applyTo`,
  /// where a hand-enumerated rebuild silently reset a term the caller never
  /// mentioned.
  CoreSurfaceToken copyWith({
    SurfaceType? type,
    int? elevation,
    CoreSurfaceOpacity? opacity,
    double? blurRadius,
    double? saturation,
    double? saturationInDarkMode,
    CoreBackdropBrightness? backdropBrightness,
    CoreSurfaceEdgeSheen? sheen,
    bool? drawsOwnEdge,
  }) => CoreSurfaceToken(
    type: type ?? this.type,
    elevation: elevation ?? this.elevation,
    opacity: opacity ?? this.opacity,
    blurRadius: blurRadius ?? this.blurRadius,
    saturation: saturation ?? this.saturation,
    saturationInDarkMode: saturationInDarkMode ?? this.saturationInDarkMode,
    backdropBrightness: backdropBrightness ?? this.backdropBrightness,
    sheen: sheen ?? this.sheen,
    drawsOwnEdge: drawsOwnEdge ?? this.drawsOwnEdge,
  );

  /// Whether this surface has anything for the reduce-transparency
  /// fallback to remove.
  ///
  /// An opaque surface with no backdrop pass is already what the
  /// fallback would produce, so the seat can leave it exactly alone
  /// rather than rebuilding an identical token.
  bool get usesTransparency => !opacity.isOpaque || blurRadius != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceToken &&
          type == other.type &&
          elevation == other.elevation &&
          opacity == other.opacity &&
          blurRadius == other.blurRadius &&
          saturation == other.saturation &&
          saturationInDarkMode == other.saturationInDarkMode &&
          backdropBrightness == other.backdropBrightness &&
          sheen == other.sheen &&
          drawsOwnEdge == other.drawsOwnEdge;

  @override
  int get hashCode => Object.hash(
    type,
    elevation,
    opacity,
    blurRadius,
    saturation,
    saturationInDarkMode,
    backdropBrightness,
    sheen,
    drawsOwnEdge,
  );

  /// Serializes this surface token to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'elevation': elevation,
    'opacity': opacity.toJson(),
    'blurRadius': blurRadius,
    'saturation': saturation,
    if (saturationInDarkMode != null)
      'saturationInDarkMode': saturationInDarkMode,
    'backdropBrightness': backdropBrightness.toJson(),
    'sheen': sheen?.toJson(),
    'drawsOwnEdge': drawsOwnEdge,
  };

  @override
  String toString() {
    switch (type) {
      case .flat:
        return 'Surface.flat';
      case .tonalElevation:
        return 'Surface.tonal(elevation: $elevation)';
      case .glass:
        return 'Surface.glass(opacity: $opacity, blur: $blurRadius)';
    }
  }
}

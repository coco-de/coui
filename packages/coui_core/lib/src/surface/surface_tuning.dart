import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/surface/surface_body_shade.dart';
import 'package:coui_core/src/surface/surface_edge_bevel.dart';
import 'package:coui_core/src/surface/surface_edge_sheen.dart';
import 'package:coui_core/src/surface/surface_frost.dart';
import 'package:coui_core/src/surface/surface_opacity.dart';
import 'package:coui_core/src/surface/surface_recipe.dart';
import 'package:coui_core/src/surface/surface_refraction.dart';
import 'package:coui_core/src/surface/surface_role.dart';
import 'package:coui_core/src/surface/surface_token.dart';
import 'package:meta/meta.dart';

/// What an app is allowed to change about a surface style.
///
/// A preset ships one set of numbers — neo-brutalism's corners are capped at
/// one value, its cast is thrown one distance, its border has one floor. An
/// app that wants the same *style* with squarer corners and a heavier cast
/// has no way to say so, because the recipe container is a `const` table and
/// the seat reads it by id.
///
/// This is the narrow surface that opens. Deliberately narrow: exposing the
/// recipe's own `copyWith` would let an app reach [CoreSurfaceRecipe.a11y],
/// and that is not a decoration. A preset's `boundaryMechanism` is the
/// declaration components draw their forced-colours fallback from — an app
/// that could rewrite it would turn a statement into a lie, and the damage
/// would spread across every component at once while reading, in each
/// component's own review, as "that must be how it looks".
///
/// The same narrowness protects the other direction: the bounds below live
/// on *this* type rather than on the constraint types presets are written
/// in. So CoUI's own authoring is not constrained by them — mirrored
/// shadows and weight floors are stated at magnitudes no app-facing bound
/// would allow.
///
/// Which axes an app may reach is answered field by field below, not by
/// this paragraph. A field absent here is absent *today*, not by principle,
/// and the set is expected to grow.
///
/// Hue is absent for a different reason: it is already the app's. A colour
/// constraint never touches hue, so an app's blue stays that blue under any
/// preset, and a "pick your accent" knob here would be a second way to do
/// what swapping the palette already does.
@immutable
class CoreSurfaceTuning {
  /// Creates a tuning. Every field defaults to "say nothing", so a partial
  /// tuning bends only what it names and leaves the preset's own answer
  /// everywhere else.
  const CoreSurfaceTuning({
    this.radiusFloor,
    this.radiusCap,
    this.shadowOffsetX,
    this.shadowOffsetY,
    this.strokeFloor,
    this.surfaceOpacity,
    this.surfaceBlur,
    this.surfaceSaturation,
    this.surfaceSaturationInDarkMode,
    this.sheenWidth,
    this.sheenFade,
    this.rimWidth,
    this.rimIntensity,
    this.lightAngle,
    this.lightAngleInDarkMode,
    this.refractionModel,
    this.surfaceFrostBlur,
    this.surfaceFrostOpacity,
    this.surfaceFrostOpacityInDarkMode,
    this.surfaceBodyShade,
    this.surfaceBodyShadeInDarkMode,
    this.stageTintChroma = 0,
  }) : assert(
         rimWidth == null || rimWidth >= 0,
         'The rim is a stroke along the contour; zero turns it off, '
         'negative has nothing to mean.',
       ),
       assert(
         rimIntensity == null || (rimIntensity >= 0 && rimIntensity <= 1),
         'The rim intensity is a fraction of full strength.',
       ),
       assert(
         radiusFloor == null || radiusFloor >= 0,
         'A radius is a length; negative has no meaning.',
       ),
       assert(
         radiusCap == null || radiusCap >= 0,
         'A radius is a length; negative has no meaning.',
       ),
       assert(
         radiusFloor == null || radiusCap == null || radiusFloor <= radiusCap,
         'The radius range is stated floor-first; a floor above the cap has '
         'no values in it.',
       ),
       assert(
         shadowOffsetX == null || shadowOffsetX >= 0,
         'Down-and-right is this style’s statement; a cast thrown the other '
         'way is a different style wearing the name.',
       ),
       assert(
         shadowOffsetY == null || shadowOffsetY >= 0,
         'Down-and-right is this style’s statement; a cast thrown the other '
         'way is a different style wearing the name.',
       ),
       assert(
         stageTintChroma >= 0 && stageTintChroma <= maxStageTintChroma,
         'The page tint is bounded by what every brand hue clears — see '
         'CoreSurfaceTuning.maxStageTintChroma.',
       ),
       assert(
         strokeFloor == null || strokeFloor >= CoreStrokeWidth.stroke2,
         'A one-pixel floor is not a boundary under a style whose cast is a '
         'hard-edged second shape — it reads as that shadow’s edge. Below '
         'this the preset’s stated `boundaryMechanism` stops being true.',
       ),
       assert(
         surfaceOpacity == null ||
             (surfaceOpacity >= minSurfaceOpacity && surfaceOpacity < 1),
         'A fully opaque surface has no backdrop, so the blur and the '
         'saturation it pairs with become no-ops while the preset still '
         'declares `usesTransparency` — the style would be on and be '
         'nothing. The floor is where the fill stops covering enough of '
         'whatever is behind it for the preset’s contrast floor to mean '
         'anything.',
       ),
       assert(
         surfaceBlur == null ||
             (surfaceBlur >= 0 && surfaceBlur <= maxSurfaceBlur),
         'Past this the backdrop folds to a flat average and the surface '
         'reads as a tinted panel rather than as a material — the same '
         'nothing an opaque fill gives, arrived at from the other side.',
       ),
       assert(
         surfaceSaturation == null ||
             (surfaceSaturation >= CoreSurfaceToken.identitySaturation &&
                 surfaceSaturation <= maxSurfaceSaturation),
         'Below identity this drains colour out of what shows through, '
         'which is the opposite of the lift the material states; above the '
         'cap the backdrop stops reading as the same scene.',
       ),
       assert(
         surfaceSaturationInDarkMode == null ||
             (surfaceSaturationInDarkMode >=
                     CoreSurfaceToken.identitySaturation &&
                 surfaceSaturationInDarkMode <= maxSurfaceSaturation),
         'The dark lift is bounded like the light one, for the same reason: '
         'below identity it drains the colour the material states, and above '
         'the cap the backdrop stops reading as the same scene.',
       ),
       assert(
         lightAngle == null ||
             (lightAngle >= -maxLightAngle && lightAngle <= maxLightAngle),
         'A direction is a point on a circle: one full turn either way names '
         'every light there is, and a value outside that range is a number '
         'that was not meant as degrees.',
       ),
       assert(
         lightAngleInDarkMode == null ||
             (lightAngleInDarkMode >= -maxLightAngle &&
                 lightAngleInDarkMode <= maxLightAngle),
         'A direction is a point on a circle: one full turn either way names '
         'every light there is, and a value outside that range is a number '
         'that was not meant as degrees.',
       ),
       assert(
         surfaceFrostBlur == null ||
             (surfaceFrostBlur > 0 &&
                 surfaceFrostBlur <= CoreSurfaceFrost.maxSigma),
         'The cloud is a Gaussian: zero is no cloud, and past the cap it '
         'folds to a flat average and reads as a tinted panel rather than as '
         'a material.',
       ),
       assert(
         (surfaceFrostBlur == null) == (surfaceFrostOpacity == null),
         'A frost is a blur and the share it is laid down at. State both or '
         'neither: a blur with no share would have to invent one, and a '
         'share with no blur has nothing to apply to.',
       ),
       assert(
         surfaceFrostOpacity == null ||
             (surfaceFrostOpacity > 0 && surfaceFrostOpacity <= 1),
         'The share is a fraction of the cloud over the copy. Zero is no '
         'frost (state none) and past one is more cloud than there is.',
       ),
       assert(
         surfaceFrostOpacityInDarkMode == null ||
             (surfaceFrostBlur != null &&
                 surfaceFrostOpacityInDarkMode > 0 &&
                 surfaceFrostOpacityInDarkMode <= 1),
         'The dark share is bounded like the light one, and needs a frost to '
         'be the share of.',
       ),
       assert(
         surfaceBodyShade == null ||
             (surfaceBodyShade >= 0 &&
                 surfaceBodyShade <= CoreSurfaceBodyShade.maxStrength),
         'The shade is the share of itself that white loses: negative would '
         'lighten the backdrop and past one white goes below black.',
       ),
       assert(
         surfaceBodyShadeInDarkMode == null ||
             (surfaceBodyShadeInDarkMode >= 0 &&
                 surfaceBodyShadeInDarkMode <=
                     CoreSurfaceBodyShade.maxStrength),
         'The dark shade is bounded like the light one, for the same reason.',
       ),
       assert(
         sheenWidth == null || sheenWidth > 0,
         'A band with no thickness is not a subtle band, it is an absent '
         'one — state no width instead and keep the preset’s.',
       ),
       assert(
         sheenFade == null ||
             (sheenFade >= CoreSurfaceEdgeSheen.minFade &&
                 sheenFade <= CoreSurfaceEdgeSheen.maxFade),
         'Above the cap the two ends of a run overlap before either '
         'reaches full strength, so the run never reaches the colour it '
         'was given and the extra value means nothing.',
       );

  /// Lower bound of the range radii are redistributed into.
  ///
  /// Off-ladder values are safe: the transform snaps both bounds onto
  /// `CoreRadius.steps` before redistributing, so a hand-written 13 lands
  /// where 12 does rather than emitting a literal Web cannot resolve.
  final double? radiusFloor;

  /// Upper bound of that range. `0` squares every corner, including the
  /// fully-rounded sentinel — squaring is absolute and takes the pill with
  /// it.
  final double? radiusCap;

  /// How far the style throws its hard cast, horizontally.
  ///
  /// No upper bound. A large cast climbs over neighbouring controls and
  /// turns the press-shift derived from it into a jump, but both are
  /// consequences an app owns — neither breaks a contract, and a number
  /// invented to bound them would tell reviewers it had been considered
  /// when it had not.
  ///
  /// Negative is refused. Down-and-right is this style's statement; a cast
  /// thrown the other way is a different style wearing the name.
  ///
  /// Two scalars rather than the offset pair the constraint carries: a
  /// record's fields cannot be read in a constant expression, so the pair
  /// would push this check past compile time to a debug assert nobody
  /// meets until the app runs. The split also makes each axis independently
  /// omittable, which is how every other field here already behaves.
  final double? shadowOffsetX;

  /// How far the style throws its hard cast, vertically. See
  /// [shadowOffsetX].
  final double? shadowOffsetY;

  /// How much of the accent's hue the page background carries, as OKLch
  /// chroma.
  ///
  /// The page takes the accent's hue at this chroma and keeps its own
  /// lightness, so a near-white page becomes a barely-tinted one of the
  /// app's own colour. Container tones are left alone — a card, an input
  /// and a popover are told apart *by* those tones.
  ///
  /// Bounded above, and the bound is measured rather than chosen: the hue
  /// is the app's to pick, so the audit sweeps every hue at the maximum and
  /// the largest chroma that clears every pair at every hue is what this
  /// may be. See `check_contrast.dart`'s stage-tint sweep.
  ///
  /// In practice this is a dark-mode axis, by intent: the default light page
  /// (OKLch L 0.991) can hold only about 0.004 chroma in sRGB, so the tint
  /// is effectively invisible there. Lowering that page to make room was
  /// measured and rejected — it made the surface tone ladder collide or
  /// invert.
  ///
  /// High contrast drops this. The colour statement is skipped wholesale
  /// when the preference is on — a user who asked for legibility did not
  /// ask for the app's chosen cast — while the geometry above survives,
  /// because corners and casts are not contrast levers.
  final double stageTintChroma;

  /// Lower bound on a drawn border width.
  ///
  /// Bounded on both sides, but only one of them can be a compile-time
  /// check — see [applyTo] for why the upper bound is stated where the
  /// preset is known.
  final double? strokeFloor;

  /// Alpha of the surface's own fill.
  ///
  /// Stated rather than derived because it is half of the material: a blur
  /// behind an opaque fill is invisible, and translucency without a blur is
  /// just a lighter surface. The two travel together everywhere they are
  /// drawn, so an app that moves one usually means to move both.
  ///
  /// One number, for both modes. The preset states its fill as a pair
  /// (`CoreSurfaceOpacity`) because the two modes need different amounts;
  /// an app that states a fill has made the choice itself, so it gets
  /// exactly that fill in light and in dark rather than a shifted pair.
  final double? surfaceOpacity;

  /// Radius of the backdrop blur, in logical pixels.
  final double? surfaceBlur;

  /// Chroma multiplier applied to the backdrop on the same pass as
  /// [surfaceBlur], in both modes.
  final double? surfaceSaturation;

  /// The chroma multiplier while the dark palette is active, in place of
  /// [surfaceSaturation] there.
  ///
  /// A dark backdrop reads dimmer than a light one, so the multiplier that
  /// keeps a light panel from looking like fog can leave a dark one flat. An
  /// app that sees this states the dark lift here and keeps one number for
  /// everything else.
  ///
  /// Stating [surfaceSaturation] alone is a statement about both modes, and
  /// replaces a dark lift the preset states for itself. Stating this one
  /// alone leaves light exactly as the preset has it. Stating both gives
  /// light the first and dark this. To change only light, state
  /// [surfaceSaturation] and restate the dark value to keep — the preset's
  /// own lift is public on the recipe it ships.
  final double? surfaceSaturationInDarkMode;

  /// Thickness of the edge band, in logical pixels.
  final double? sheenWidth;

  /// How far along each run the band takes to reach full strength, as a
  /// fraction of that run's length measured from the corner.
  final double? sheenFade;

  /// Width of the lit crest along the contour, in logical pixels — the
  /// material's `CoreSurfaceEdgeBevel.rimWidth`. Zero turns the rim off.
  ///
  /// Here rather than on a component, because the rim is the material's
  /// and a card and a popover under one style are edged the same way. An
  /// app that wants a heavier crest on its cards wants it on its dialogs
  /// too, and this is the one place that says so for both.
  final double? rimWidth;

  /// How bright the crest is where the contour faces the light, 0 to 1 —
  /// the material's `CoreSurfaceEdgeBevel.rimIntensity`.
  final double? rimIntensity;

  /// Where the light that edges the material comes from, in degrees
  /// clockwise from the top — the material's `CoreSurfaceEdgeBevel
  /// .lightAngle`, in both modes.
  ///
  /// One light for the wall and the crest and for every surface made of the
  /// material: moving it for the card and not for the popover would light
  /// one scene from two directions. It lands on the nested materials too,
  /// which carry the same wall — a button inside a card is lit from where
  /// the card is.
  ///
  /// Stating this replaces a dark angle the preset states for itself, the way
  /// [surfaceSaturation] replaces a dark lift. Needs an edge bevel to
  /// apply to, like [rimWidth].
  final double? lightAngle;

  /// Where the light comes from while the dark palette is active, in place
  /// of [lightAngle] there. Stated alone it leaves light as the preset has
  /// it.
  final double? lightAngleInDarkMode;

  /// The law the rim bends light by — the `model` of the recipe's
  /// refraction, for every surface of the style.
  ///
  /// A look decision, not a quality knob: the two laws draw the same band
  /// with a different profile, and the second scales with `index - 1` where
  /// the first scales with `1 / index`, so a model moved to is judged at its
  /// `strength` again. The dome across the face is not affected.
  ///
  /// Null keeps the preset's law. Needs a style that bends at all — one
  /// that states no refraction has no law to set.
  final CoreRefractionModel? refractionModel;

  /// The Gaussian sigma of the cloud laid over the content behind every glass
  /// surface of the style, in logical pixels — the first half of a
  /// `CoreSurfaceFrost`. Null states no frost, which is every shipped style.
  ///
  /// A second backdrop pass per surface; see `CoreSurfaceFrost` for what it
  /// is and what it costs. The other half is [surfaceFrostOpacity], and the
  /// two are stated together or not at all.
  final double? surfaceFrostBlur;

  /// The share of the cloud over the lightly blurred copy, 0 to 1 (exclusive
  /// of zero), in both modes unless [surfaceFrostOpacityInDarkMode] states
  /// one of its own.
  final double? surfaceFrostOpacity;

  /// The share of the cloud while the dark palette is active, in place of
  /// [surfaceFrostOpacity] there. Needs a frost to be the share of.
  final double? surfaceFrostOpacityInDarkMode;

  /// How far white is pulled down under every glass surface of the style —
  /// the share of itself it loses, 0 to 1 — for both modes. The pull is by the
  /// pixel's own luminance squared (`CoreSurfaceBodyShade`), so dark content
  /// is barely touched.
  ///
  /// Stating this alone is a statement about both modes and replaces a dark
  /// shade the preset states for itself; stating [surfaceBodyShadeInDarkMode]
  /// alone leaves light as the preset has it, which for every shipped style
  /// is no shade.
  final double? surfaceBodyShade;

  /// The shade while the dark palette is active, in place of
  /// [surfaceBodyShade] there. Zero states none in dark.
  final double? surfaceBodyShadeInDarkMode;

  /// The least fill an app may ask a glass surface to keep.
  ///
  /// The preset's contrast answer is that the fill covers whatever is
  /// behind it by a known amount; a fill thin enough to stop doing that
  /// leaves text sitting on an arbitrary backdrop, and the accessibility
  /// claim the preset registers stops being about anything.
  static const double minSurfaceOpacity = 0.4;

  /// The most blur an app may ask for.
  static const double maxSurfaceBlur = 64;

  /// The most chroma lift an app may ask for.
  static const double maxSurfaceSaturation = 2;

  /// The furthest a light angle may be stated either way — one full turn.
  static const double maxLightAngle = 360;

  /// How deep a tint an app may *ask* for.
  ///
  /// **Not the contrast bound.** sRGB is: the constraint fits every
  /// request down to what the page's own lightness can actually hold, and
  /// `check_contrast.dart`'s sweep shows that ceiling clears every brand
  /// hue in both modes with margin — colour runs out before contrast does.
  /// Removing that fit makes the sweep fail, which is how we know the
  /// claim is load-bearing rather than decorative.
  ///
  /// So this is a sanity ceiling on the *request*, not a safety line. It
  /// exists because an unbounded field invites values with no meaning, not
  /// because a larger one would be unsafe.
  ///
  /// The number that matters in practice is not this one — it is the
  /// page's lightness. A near-white page (CoUI's light default sits at
  /// L≈0.99) holds almost no colour whatever is asked; a darker page holds
  /// several times as much. An app that wants the deep tinted background
  /// of the reference implementations gets there by choosing a less-white
  /// page, and this field then lands.
  static const double maxStageTintChroma = 0.12;

  /// A tuning that changes nothing.
  static const CoreSurfaceTuning none = CoreSurfaceTuning();

  /// A tuning that reads like the iOS 27 glass material, for an app to pass as
  /// its `surfaceTuning` (and, on the Web, as the glass style's entry in
  /// `ThemeConfig.surfaceTunings`).
  ///
  /// **An example look, not a style and not a default.** It adds no
  /// `CoreSurfaceStyleId`, so no Figma mode, no preset snapshot and no parity
  /// cell exists for it; an app that never passes it renders what it always
  /// rendered. It is one `const` value that states, in one place, the terms
  /// of the material the tuning fields can say: how much the backdrop's
  /// chroma is lifted in each mode, where the edge light comes from in each
  /// mode, the law the rim bends light by, the cloud laid over the content,
  /// and the dark material's pull on bright content. Apply it to
  /// `CoreSurfaceStyleId.liquidGlass`, the only style that draws a backdrop
  /// pass; elsewhere the material assertion in [applyTo] fails.
  ///
  /// ## Every number is a designer-judgement value (디자이너 판단 값)
  ///
  /// The numbers are starting points taken from a reference implementation of
  /// that material and judged against this kit's own bounds; none of them is
  /// derived from a measurement of the native material, and the alternative
  /// for each is a one-line change here.
  ///
  /// - `surfaceBlur: 0.6` — the light blur the copy of the content keeps its
  ///   edges under, so text beneath reads as pale ghosts. The preset's own
  ///   blur (4) softens the ghost into a haze.
  /// - `surfaceSaturation: 2` — the material lifts light chroma more than
  ///   this kit allows: the reference states 2.1 and [maxSurfaceSaturation]
  ///   is 2. The bound stays; raising it is a bound change, not made here.
  /// - `surfaceSaturationInDarkMode: 1.4` — the dark material lifts less than
  ///   the light one.
  /// - `lightAngle: 0` — lit from directly above in light (the preset's own
  ///   default is −45); `lightAngleInDarkMode: 180` — lit from directly
  ///   below in dark.
  /// - `refractionModel: paraxial` — the even fold of the rim band. Only the
  ///   law is a tuning field: the band's width, strength and index stay the
  ///   preset's, and this law's travel scales with `index − 1`, so it is
  ///   judged at that strength again.
  /// - `surfaceFrostBlur: 14` — the cloud's sigma, wide enough that nothing
  ///   in it is recognisable.
  /// - `surfaceFrostOpacity: 0.73` — the share of the cloud over the copy in
  ///   light; `surfaceFrostOpacityInDarkMode: 0.85` — a denser cloud in dark,
  ///   where the copy is fainter.
  /// - `surfaceBodyShadeInDarkMode: 0.28` — white comes out at 72% (184 of
  ///   255) under the dark material; light states none.
  ///
  /// **Not stated, on purpose.** `surfaceOpacity`: the native dark material
  /// is nearly clear (a fill near 12%), which is below
  /// [minSurfaceOpacity]; the bound exists so a text contrast floor is
  /// still about something. The preset keeps its own fill pair (0.5 light,
  /// 0.6 dark), so a dark surface is denser than the native one, and the pull
  /// on bright content is the body shade's rather than the fill's. Nothing
  /// here changes a colour token, so the contrast audit's palette claims are
  /// the base palette's.
  ///
  /// **What it costs.** The frost is one extra backdrop pass per glass
  /// surface (see `CoreSurfaceFrost`), which is the reason it is not a
  /// default. The shade rides the pass that exists.
  ///
  /// **Where it draws.** On the Web the frost and the shade are SVG filters
  /// named in the surface's `backdrop-filter` list. Chromium draws them;
  /// Safari draws nothing for such a list, the surface's own blur and
  /// saturation included (measured, Safari 27.0), so the stylesheet takes the
  /// two terms out of the list there and the glass keeps the rest of it —
  /// blur, saturation, brightness — without the frost and the shade.
  static const CoreSurfaceTuning ios27 = CoreSurfaceTuning(
    surfaceBlur: 0.6,
    surfaceSaturation: 2,
    surfaceSaturationInDarkMode: 1.4,
    lightAngle: 0,
    lightAngleInDarkMode: 180,
    refractionModel: CoreRefractionModel.paraxial,
    surfaceFrostBlur: 14,
    surfaceFrostOpacity: 0.73,
    surfaceFrostOpacityInDarkMode: 0.85,
    surfaceBodyShadeInDarkMode: 0.28,
  );

  /// Whether this tuning leaves the preset exactly as authored.
  bool get isIdentity =>
      radiusFloor == null &&
      radiusCap == null &&
      shadowOffsetX == null &&
      shadowOffsetY == null &&
      strokeFloor == null &&
      surfaceOpacity == null &&
      surfaceBlur == null &&
      surfaceSaturation == null &&
      surfaceSaturationInDarkMode == null &&
      sheenWidth == null &&
      sheenFade == null &&
      rimWidth == null &&
      rimIntensity == null &&
      lightAngle == null &&
      lightAngleInDarkMode == null &&
      refractionModel == null &&
      surfaceFrostBlur == null &&
      surfaceFrostOpacity == null &&
      surfaceFrostOpacityInDarkMode == null &&
      surfaceBodyShade == null &&
      surfaceBodyShadeInDarkMode == null &&
      stageTintChroma == 0;

  /// Folds this tuning into [recipe].
  ///
  /// The single place tuning becomes a recipe. Both platforms call it —
  /// a second fold would be free to order or omit a field differently, and
  /// the two screens would diverge in a way only a side-by-side reveals.
  ///
  /// Returns [recipe] itself when [isIdentity], so an app that tunes
  /// nothing gets the very same instance back. That matters beyond
  /// allocation: axis carriers are compared by value to decide rebuilds,
  /// and an equal-but-new instance is the shape that makes a parity
  /// baseline move for no visible reason.
  CoreSurfaceRecipe applyTo(CoreSurfaceRecipe recipe) {
    if (isIdentity) return recipe;

    // The upper bound cannot be a `const` assert above, because it is not a
    // constant: it is the preset's own focus ring, and presets differ (6
    // here, 3 elsewhere). Pinned to the narrowest shipped ring it would
    // reject this style's own authored floor; written as a literal it would
    // quietly stop matching the day a ring changes. So it is derived, and
    // checked where the preset is finally known.
    assert(
      () {
        final floor = strokeFloor;
        if (floor == null) return true;
        final ring =
            recipe.a11y.focusOutlineStyle.borderWidth ??
            CoreFocusRing.ringWidth;

        return floor < ring;
      }(),
      'A border at or above the focus ring swallows it: the ring stops '
      'reading as a separate indicator and becomes part of the boundary, '
      'which is the failure the preset acceptance gate names.',
    );

    final tunesLight = lightAngle != null || lightAngleInDarkMode != null;
    final statesMaterial =
        surfaceOpacity != null ||
        surfaceBlur != null ||
        surfaceSaturation != null ||
        surfaceSaturationInDarkMode != null ||
        sheenWidth != null ||
        sheenFade != null ||
        rimWidth != null ||
        rimIntensity != null ||
        tunesLight;
    final tunesRim = rimWidth != null || rimIntensity != null;
    final statesFrost = surfaceFrostBlur != null;
    final statesShade =
        surfaceBodyShade != null || surfaceBodyShadeInDarkMode != null;
    final statesFinish = statesFrost || statesShade;
    // Follow the material to every role that holds it.
    //
    // This file predates the role axis and read `recipe.surface` as "the
    // preset's material". That was true only while both roles were glass;
    // a style may state a standard content material and keep glass on the
    // functional layer, and a style may — as the shipped glass does — make
    // both roles the same glass. Tuning is a statement about *the
    // material*, so it lands on every role made of it: an app that tunes
    // the frost must not find its popovers moved and its cards left
    // behind, which is exactly what following one role would do.
    //
    // The recipe already wrote this rule down for its own emptiness check:
    // "Both roles, because a style is not a no-op if *either* material
    // draws. Reading only `surface` would prune a style whose floating
    // material is the interesting one."
    final contentSurface = recipe.surface;
    final functionalSurface = recipe.functionalSurface;
    final contentIsGlass = contentSurface?.type == SurfaceType.glass;
    final functionalIsGlass = functionalSurface?.type == SurfaceType.glass;
    final anyGlass =
        recipe.surfaceFor(CoreSurfaceRole.functional)?.type ==
            SurfaceType.glass ||
        contentIsGlass;
    final anySheen =
        recipe.surfaceFor(CoreSurfaceRole.functional)?.sheen != null ||
        contentSurface?.sheen != null;
    final anyWall =
        recipe.surfaceFor(CoreSurfaceRole.functional)?.sheen?.bevel != null ||
        contentSurface?.sheen?.bevel != null;

    // Which transport runs is the preset's statement, not the app's. A
    // material value on a style that draws no material would be written,
    // compared, serialised, and never drawn — the shape this axis has
    // shipped in before.
    assert(
      !statesMaterial || anyGlass,
      'Neither role of this preset draws a material, so a material value '
      'has nowhere to go. Tune the style that states one, or state none '
      'here.',
    );
    assert(
      (sheenWidth == null && sheenFade == null) || anySheen,
      'A band geometry with no band to apply it to. The preset states no '
      'edge sheen, and this cannot invent one — the colours it would need '
      'are deliberately not on this surface.',
    );
    assert(
      !tunesRim || anyWall,
      'A rim with no wall to be the crest of. The preset states no edge '
      'bevel, and this cannot invent one — the light it would need is '
      'stated on the wall.',
    );
    assert(
      !tunesLight || anyWall,
      'A light with no wall to shine on. The preset states no edge bevel, '
      'and the angle is a term of that wall — there is nothing here to '
      'point.',
    );
    assert(
      refractionModel == null || recipe.refraction != null,
      'A refraction model with no refraction to apply it to. The preset '
      'states no bend, so there is no law to set; state one on the style '
      'that bends, or none here.',
    );
    // Both terms act on the backdrop pass a glass material draws. A style
    // whose materials draw none (an opaque one, or a standard material) has
    // nothing for them to act on, and a value there would be written,
    // compared, serialised and never drawn.
    final drawsBackdropPass =
        contentSurface?.blurRadius != null ||
        functionalSurface?.blurRadius != null;
    assert(
      !statesFinish || drawsBackdropPass,
      'A frost or a body shade acts on the backdrop pass, and neither role of '
      'this preset draws one. Tune the style that blurs, or state none here.',
    );

    // Local so the null check promotes — a public field does not.
    final fill = surfaceOpacity;

    // One light for the wall, wherever the wall is drawn. A single statement
    // is a statement about both modes, so it replaces a dark angle the
    // preset states for itself; a dark statement alone leaves light as the
    // preset has it.
    CoreSurfaceEdgeBevel relight(CoreSurfaceEdgeBevel wall) => !tunesLight
        ? wall
        : wall.relit(
            angle: lightAngle ?? wall.lightAngle,
            angleInDarkMode:
                lightAngleInDarkMode ??
                (lightAngle != null ? null : wall.lightAngleInDarkMode),
          );

    CoreSurfaceToken? tune(CoreSurfaceToken surface) {
      if (!statesMaterial) return null;
      final authoredSheen = surface.sheen;
      final authoredWall = authoredSheen?.bevel;
      // The crest rides the wall: an app moving the rim moves the two
      // numbers on the bevel and nothing else about the light — and an app
      // moving the light moves the angle and nothing else about the rim.
      final rimmed = authoredWall == null || !tunesRim
          ? authoredWall
          : authoredWall.copyWith(
              rimWidth: rimWidth,
              rimIntensity: rimIntensity,
            );
      final wall = rimmed == null ? null : relight(rimmed);
      final tunesBand = sheenWidth != null || sheenFade != null;
      final sheen =
          authoredSheen == null || (!tunesBand && !tunesRim && !tunesLight)
          ? authoredSheen
          : authoredSheen.copyWith(
              width: sheenWidth,
              fade: sheenFade,
              bevel: wall,
            );

      return CoreSurfaceToken.glass(
        // An app that states a fill states it for both modes: the number
        // it chose is the number it gets, in light and in dark. Falling
        // back to the preset's own pair is the untuned path.
        opacity: fill == null ? surface.opacity : CoreSurfaceOpacity.same(fill),
        blur: surfaceBlur ?? surface.blurRadius ?? 0,
        saturation: surfaceSaturation ?? surface.saturation,
        // A single statement is about both modes and replaces a dark lift
        // the preset states; a dark statement stands alone otherwise.
        saturationInDarkMode:
            surfaceSaturationInDarkMode ??
            (surfaceSaturation != null ? null : surface.saturationInDarkMode),
        // Carried, not tunable. An app may move the fill, the frost
        // and the chroma; it may not move the term that keeps white
        // foregrounds legible on a saturated fill. But carrying it is
        // mandatory for the same reason `drawsOwnEdge` below is: this
        // constructor enumerates its fields, so anything not named
        // here is silently replaced by its default — a tuning that
        // touched only the opacity would hand back an undimmed
        // surface, with nothing in the tuning that mentions dimming.
        backdropBrightness: surface.backdropBrightness,
        sheen: sheen,
        // Same reason as `backdropBrightness` above, and a sharper
        // consequence: a tuning that named only the opacity would hand
        // the surface its component stroke back, so a tuned glass would
        // grow a border the untuned one does not have — with nothing in
        // the tuning that mentions borders.
        drawsOwnEdge: surface.drawsOwnEdge,
      );
    }

    // Only a role that *states* glass is rewritten. A functional slot the
    // preset left null keeps falling through to `surface`, so it follows
    // the content tuning without a token of its own being invented here.
    final tunedContent = contentIsGlass ? tune(contentSurface!) : null;
    final tunedFunctional = functionalIsGlass ? tune(functionalSurface!) : null;

    // The nested materials are the recipe's own table, and a tuning leaves
    // them alone — except for the light. Their wall is drawn (nesting drops
    // the backdrop pass and keeps the edge), and a wall lit from the preset's
    // angle inside a card lit from the app's is two suns in one scene. Only
    // the angle is carried over; the pass they dropped has no saturation to
    // tune.
    CoreSurfaceToken relightStep(CoreSurfaceToken step) {
      final sheen = step.sheen;
      final wall = sheen?.bevel;
      if (sheen == null || wall == null) return step;

      return step.copyWith(sheen: sheen.copyWith(bevel: relight(wall)));
    }

    final nested = recipe.nestedSurfaces;
    final tunedNested = !tunesLight || nested == null
        ? null
        : {
            for (final entry in nested.entries)
              entry.key: [for (final step in entry.value) relightStep(step)],
          };

    // Each axis is independently omittable, so a tuning that states only
    // one of them keeps the preset's answer for the other rather than
    // silently zeroing it. A style with no authored diagonal at all reads
    // as zero on the axis nobody named.
    final authored = recipe.geometry.shadowOffsetAdd;
    final offset = shadowOffsetX == null && shadowOffsetY == null
        ? null
        : (
            dx: shadowOffsetX ?? authored?.dx ?? 0,
            dy: shadowOffsetY ?? authored?.dy ?? 0,
          );

    // The preset authors `controlShadow` at the same magnitude as
    // `shadowOffsetAdd` so that a control casting nothing and one casting
    // something land at the same distance. Bending one and not the other
    // breaks that pairing — and breaks the press-squash the offset drives,
    // because the control would travel further than the shadow it vacates.
    //
    // Replaced rather than added to: the injected layer *is* the whole
    // cast for a control that authors none, so on a base of zero "throw it
    // this far" and "set the offset to this" are the same statement.
    // Per-axis, mirroring `offset` above — a tuning naming one axis keeps
    // the preset's answer for the other.
    final injected = offset == null || recipe.geometry.controlShadow.isEmpty
        ? null
        : [
            for (final l in recipe.geometry.controlShadow)
              (
                offsetX: shadowOffsetX ?? l.offsetX,
                offsetY: shadowOffsetY ?? l.offsetY,
                blurRadius: l.blurRadius,
                spreadRadius: l.spreadRadius,
                opacity: l.opacity,
                inset: l.inset,
              ),
          ];

    // The cloud and the shade are the style's, not a role's: they ride the
    // backdrop pass every glass role draws, so they are written once on the
    // recipe the way the bend is. A frost statement replaces the whole frost
    // (it is a blur and a share, stated together); a shade merges the way the
    // chroma lift does — a single statement is about both modes and replaces
    // a dark shade the preset states, a dark statement alone leaves light.
    final frost = surfaceFrostBlur == null || surfaceFrostOpacity == null
        ? null
        : CoreSurfaceFrost(
            sigma: surfaceFrostBlur!,
            opacity: surfaceFrostOpacity!,
            opacityInDarkMode: surfaceFrostOpacityInDarkMode,
          );
    final authoredShade = recipe.bodyShade;
    final bodyShade = !statesShade
        ? null
        : CoreSurfaceBodyShade(
            strength: surfaceBodyShade ?? authoredShade?.strength ?? 0,
            strengthInDarkMode:
                surfaceBodyShadeInDarkMode ??
                (surfaceBodyShade != null
                    ? null
                    : authoredShade?.strengthInDarkMode),
          );

    // Write back to every role it came from. `copyWith` keeps the
    // preset's answer for a null slot, so a role that is not glass is left
    // exactly as the preset stated it.
    return recipe.copyWith(
      frost: frost,
      bodyShade: bodyShade,
      surface: tunedContent,
      functionalSurface: tunedFunctional,
      nestedSurfaces: tunedNested,
      refraction: refractionModel == null
          ? null
          : recipe.refraction?.copyWith(model: refractionModel),
      colorConstraint: stageTintChroma == 0
          ? null
          : recipe.colorConstraint.copyWith(
              stageTintChroma: stageTintChroma,
            ),
      geometry: recipe.geometry.copyWith(
        radiusFloor: radiusFloor,
        radiusCap: radiusCap,
        strokeFloor: strokeFloor,
        shadowOffsetAdd: offset,
        controlShadow: injected,
      ),
    );
  }

  /// Creates a copy with modified values.
  CoreSurfaceTuning copyWith({
    double? radiusFloor,
    double? radiusCap,
    double? shadowOffsetX,
    double? shadowOffsetY,
    double? strokeFloor,
    double? surfaceOpacity,
    double? surfaceBlur,
    double? surfaceSaturation,
    double? surfaceSaturationInDarkMode,
    double? sheenWidth,
    double? sheenFade,
    double? rimWidth,
    double? rimIntensity,
    double? lightAngle,
    double? lightAngleInDarkMode,
    CoreRefractionModel? refractionModel,
    double? surfaceFrostBlur,
    double? surfaceFrostOpacity,
    double? surfaceFrostOpacityInDarkMode,
    double? surfaceBodyShade,
    double? surfaceBodyShadeInDarkMode,
    double? stageTintChroma,
  }) {
    return CoreSurfaceTuning(
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      surfaceSaturation: surfaceSaturation ?? this.surfaceSaturation,
      surfaceSaturationInDarkMode:
          surfaceSaturationInDarkMode ?? this.surfaceSaturationInDarkMode,
      sheenWidth: sheenWidth ?? this.sheenWidth,
      sheenFade: sheenFade ?? this.sheenFade,
      rimWidth: rimWidth ?? this.rimWidth,
      rimIntensity: rimIntensity ?? this.rimIntensity,
      lightAngle: lightAngle ?? this.lightAngle,
      lightAngleInDarkMode: lightAngleInDarkMode ?? this.lightAngleInDarkMode,
      refractionModel: refractionModel ?? this.refractionModel,
      surfaceFrostBlur: surfaceFrostBlur ?? this.surfaceFrostBlur,
      surfaceFrostOpacity: surfaceFrostOpacity ?? this.surfaceFrostOpacity,
      surfaceFrostOpacityInDarkMode:
          surfaceFrostOpacityInDarkMode ?? this.surfaceFrostOpacityInDarkMode,
      surfaceBodyShade: surfaceBodyShade ?? this.surfaceBodyShade,
      surfaceBodyShadeInDarkMode:
          surfaceBodyShadeInDarkMode ?? this.surfaceBodyShadeInDarkMode,
      radiusFloor: radiusFloor ?? this.radiusFloor,
      radiusCap: radiusCap ?? this.radiusCap,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      strokeFloor: strokeFloor ?? this.strokeFloor,
      stageTintChroma: stageTintChroma ?? this.stageTintChroma,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceTuning &&
          radiusFloor == other.radiusFloor &&
          radiusCap == other.radiusCap &&
          shadowOffsetX == other.shadowOffsetX &&
          shadowOffsetY == other.shadowOffsetY &&
          strokeFloor == other.strokeFloor &&
          surfaceOpacity == other.surfaceOpacity &&
          surfaceBlur == other.surfaceBlur &&
          surfaceSaturation == other.surfaceSaturation &&
          surfaceSaturationInDarkMode == other.surfaceSaturationInDarkMode &&
          sheenWidth == other.sheenWidth &&
          sheenFade == other.sheenFade &&
          rimWidth == other.rimWidth &&
          rimIntensity == other.rimIntensity &&
          lightAngle == other.lightAngle &&
          lightAngleInDarkMode == other.lightAngleInDarkMode &&
          refractionModel == other.refractionModel &&
          surfaceFrostBlur == other.surfaceFrostBlur &&
          surfaceFrostOpacity == other.surfaceFrostOpacity &&
          surfaceFrostOpacityInDarkMode ==
              other.surfaceFrostOpacityInDarkMode &&
          surfaceBodyShade == other.surfaceBodyShade &&
          surfaceBodyShadeInDarkMode == other.surfaceBodyShadeInDarkMode &&
          stageTintChroma == other.stageTintChroma;

  @override
  int get hashCode => Object.hashAll([
    radiusFloor,
    radiusCap,
    shadowOffsetX,
    shadowOffsetY,
    strokeFloor,
    surfaceOpacity,
    surfaceBlur,
    surfaceSaturation,
    surfaceSaturationInDarkMode,
    sheenWidth,
    sheenFade,
    rimWidth,
    rimIntensity,
    lightAngle,
    lightAngleInDarkMode,
    refractionModel,
    surfaceFrostBlur,
    surfaceFrostOpacity,
    surfaceFrostOpacityInDarkMode,
    surfaceBodyShade,
    surfaceBodyShadeInDarkMode,
    stageTintChroma,
  ]);
}

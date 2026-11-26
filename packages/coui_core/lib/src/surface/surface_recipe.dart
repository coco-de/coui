import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/surface/surface_a11y_contract.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/surface/liquid_morph_spring.dart';
import 'package:coui_core/src/surface/surface_backdrop_brightness.dart';
import 'package:coui_core/src/surface/surface_body_shade.dart';
import 'package:coui_core/src/surface/surface_color_constraint.dart';
import 'package:coui_core/src/surface/surface_edge_bevel.dart';
import 'package:coui_core/src/surface/surface_edge_sheen.dart';
import 'package:coui_core/src/surface/surface_frost.dart';
import 'package:coui_core/src/surface/surface_geometry_constraint.dart';
import 'package:coui_core/src/surface/surface_opacity.dart';
import 'package:coui_core/src/surface/surface_refraction.dart';
import 'package:coui_core/src/surface/surface_role.dart';
import 'package:coui_core/src/surface/surface_style_id.dart';
import 'package:coui_core/src/surface/surface_token.dart';
import 'package:coui_core/src/surface/surface_typography_constraint.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:meta/meta.dart';

/// How much the material amplifies the chroma of what shows through it.
///
/// No token scale to draw on — saturation has one authored value in this
/// kit and inventing a scale for it would be a scale with one step.
///
/// Raised with the fill and the blur, for the reason the field's own doc
/// gives: above 1 the backdrop reads as seen *through a tinted material*
/// rather than through fog, and that difference is what separates glass
/// from a blurred panel. At 40% fill there is enough backdrop coming
/// through for the lift to have something to act on.
const double _kGlassSaturation = 1.6;

/// How much of the glass fill shows, per mode.
///
/// One constant, referenced by the material and by its nested twin, because
/// the fill is a property of the glass and not of where the glass sits: a
/// nested surface that disagreed with its parent about the fill would be a
/// second material, and the nesting table's whole statement is that nesting
/// drops the backdrop pass and keeps the rest.
///
/// **Light 0.5, dark 0.6.** Dark is the mode that needs more of it. The
/// fill there is near-black, so every point of fill share taken from a
/// bright backdrop is a point of backdrop that no longer reaches the text;
/// and a panel that inverts the polarity (a tooltip fills with `onSurface`
/// and writes in `surface`) has its text sitting closest to the colour it
/// is drawn on when the fill is thin. Light is left exactly where it was.
///
/// Measured with the model in `backdrop_brightness_contrast_test.dart` —
/// the recipe's own chroma lift and dimming, text over the composited
/// panel, WCAG contrast — over seven backdrops (black, near-black, dark
/// grey, mid grey, a brand blue, a warm orange, white):
///
/// | dark mode                                | fill 0.5 | fill 0.6 |
/// |------------------------------------------|----------|----------|
/// | normal polarity, over white              | 6.51     | 7.99     |
/// | normal polarity, worst of the seven      | 6.51     | 7.99     |
/// | inverted polarity, over near-black       | 4.37     | 5.99     |
/// | inverted polarity, worst of the seven    | 4.19     | 5.81     |
///
/// At 0.5 the inverted cell over near-black is under AA (4.5); at 0.6 the
/// worst inverted cell clears it with room to spare.
const CoreSurfaceOpacity _kGlassOpacity = CoreSurfaceOpacity(
  light: CoreOpacity.opacity50,
  dark: CoreOpacity.opacity60,
);

/// The material a glass surface gets once it sits inside another one.
///
/// The same fill and the same edge band, and **no backdrop pass at all**.
///
/// ## Why none rather than a thinner one
///
/// Blurs compose by variance, so a frost inside another frost reads as
/// `sqrt(σ₁² + σ₂²)` rather than as σ — the inner box picks up the outer
/// pass on top of its own and stops reading as its own material. That is
/// not a prediction: it was found by walking the rendered catalog, on an
/// item card inside the column card that held it.
///
/// The screen that settled it was a heavier frost than the one shipping
/// now, where the doubling was severe enough to look like a rendering
/// fault. At σ-4 the same nesting composes to σ-5.7, which is a milder
/// version of the same direction — so a *graded* answer (Apple states
/// the same shape as a separate "thin material") is more available here
/// than it was, and is still not taken, because the value it would
/// replace came from looking at a screen and no graded value has been
/// looked at yet. Deriving over a measurement is the move this kit keeps
/// writing down as the mistake.
const CoreSurfaceToken _kNestedGlassFunctional = CoreSurfaceToken(
  type: SurfaceType.glass,
  opacity: _kGlassOpacity,
  saturation: _kGlassSaturation,
  drawsOwnEdge: true,
  sheen: _kGlassSheen,
);

/// The liquid-glass material both roles are made of.
///
/// One constant rather than two literals so a card and a popover cannot
/// drift apart by a field: the roles differ by where they sit (and by what
/// the nesting table gives them), not by their material.
///
/// Apple's split is `regular` (blurs *and adjusts the luminosity of
/// background content*) for floating things versus `clear` for things over
/// photos. This is the `regular` half: a half fill and a dimmed backdrop.
///
/// ## Why the luminosity term is a pair
///
/// Because one number provably cannot do it. Sweeping the two fills
/// over seven backdrops in both modes, the band of a single
/// mode-blind value that never lands below today is `[1.05, 1.40]`
/// — upward — and that band is hollow: `saturate(1.6)` preserves
/// neutrals, so a light page is already clipped at 255 and every
/// value in the band buys the same ΔE 0.67, under the ~2.3 where a
/// difference reads at a glance. Downward is where the authority
/// is, and downward is where the two modes disagree. See
/// [CoreBackdropBrightness].
///
/// ## The two values
///
/// **Light 0.92.** Puts the page-case separation at ΔE 3.50 and
/// lands the panel at 95% of the page's own level — nowhere near the
/// 74% grey that the control's 0.25 pair would have produced, which
/// is the failure this term was held back for. Text on the panel
/// does not pay: over every backdrop a light-mode panel plausibly
/// sits on, the worst case moves 8.63 → 8.31. It *improves* the
/// inverted-polarity surface (a tooltip fills with `onSurface` and
/// writes in `surface`): 3.28 → 3.76.
///
/// **Dark 0.60.** Has to travel four times further for half the
/// separation, because the term's authority is proportional to the
/// fill and the dark surface token is 24 where the light one is 252.
/// It buys ΔE 2.54 — and, more importantly, it repairs a failure
/// that was already shipping: a dark floating panel over a bright
/// backdrop gave its text 3.28, below AA, and now gives it 6.84.
///
/// ## What it costs, stated rather than rounded away
///
/// One cell is hurt by the dimming on a backdrop that mode actually sees:
/// an inverted-polarity panel in dark over near-black, because dimming an
/// already dark backdrop moves light text on a light fill the wrong way.
/// With the fill at 50% that cell measures 4.37 under the current palette
/// — below AA. The fill is what repairs it, which is why the fill is a
/// pair too (see [_kGlassOpacity]): at the dark fill of 60% the same cell
/// measures 5.99. It is pinned by a test rather than left to be
/// rediscovered.
///
/// ## What it used to leave open
///
/// While the content role was opaque, a dark content panel over a bright
/// backdrop sat at 2.46 and this term could not reach it — dimming the
/// content role would have collapsed the role separation. That
/// separation is gone by decision (both roles are this material), so the
/// content case *is* the floating case now and gets the same 6.84. The
/// cost moved rather than vanished: a content panel is translucent, and
/// its contrast is decided the same way the floating panel's is — by
/// `usesTransparency` and the reduce-transparency fold, not statically.
const CoreSurfaceToken _kGlassSurface = CoreSurfaceToken.glass(
  opacity: _kGlassOpacity,
  blur: CoreSize.size4,
  saturation: _kGlassSaturation,
  backdropBrightness: CoreBackdropBrightness(light: 0.92, dark: 0.6),
  drawsOwnEdge: true,
  sheen: _kGlassSheen,
);

/// The edge band both glass materials draw.
///
/// One value, referenced twice, because the band is a property of the
/// *style* rather than of either role — a floating panel and a card under
/// liquid glass are edged the same way. Two copies would be free to drift
/// into two different edges under one style name.
const CoreSurfaceEdgeSheen _kGlassSheen = CoreSurfaceEdgeSheen(
  // A boundary of the material, not a drawn border. One physical
  // pixel is the thinnest the stroke scale can say; the band
  // reads as an edge highlight because its colour is a glass
  // tint, not because it is hairline-thin.
  width: CoreStrokeWidth.stroke1,
  // The two runs need colours satisfying three conditions, and
  // together they rule out every absolute light or dark slot.
  //
  // 1. Emitted as a CSS variable — a name the stylesheet does not
  //    define invalidates the whole declaration, so the band would
  //    vanish on Web with nothing to say why.
  // 2. Keeps a usable distance from the surface in *both* modes.
  // 3. Differs from the other run by enough to read as a
  //    disagreement, without either becoming a drawn border.
  //
  // Condition (1) is the sharp one, and it rules out any slot a
  // palette leaves unfilled: Web drops the whole rule and Flutter
  // throws outright from `toValue`, so the band fails louder than
  // it would from a merely unflattering colour.
  //
  // Anything pinned to one end of the scale fails (2), and not by
  // a margin alpha can close. The light surface is very nearly
  // white and the dark one very nearly black, so a white run has
  // no headroom on the first and a black one none on the second:
  // measured against its own surface, white tops out at 1.02 and
  // black at 1.13 even at full strength. A run nobody can see is
  // not a subtle run — and since the lost one would be the
  // horizontal pair in light and the vertical pair in dark, the
  // band would appear to turn a quarter circle when the theme is
  // toggled.
  //
  // `shadow` is black in every mode, so it is pinned to one end
  // and fails (2) in dark like any other pinned slot.
  //
  // Both slots below are stated relative to the surface, so they
  // trade values between modes rather than losing one. The
  // treatment is the disagreement between the two runs, and here
  // that disagreement is a difference in weight — the vertical
  // pair is the heavier — rather than one lit and one shaded.
  //
  // The alphas are not free. In light the focus ring is a
  // mid-blue, so darkening a run to separate it from a near-white
  // surface also walks it toward the ring's luminance: visibility
  // and ring separation pull opposite ways, and the window where
  // both hold is roughly 1.2 to 1.5 against the surface. Sweeping
  // every slot-and-alpha combination against three requirements —
  // both runs visible, the runs far enough apart to read as a
  // disagreement, and neither run within 3:1 of the ring — leaves
  // seven usable pairs. The horizontal run is `outline` at 16%:
  // the pair that preceded it (`surfaceContainerHighest` at 40%)
  // put that run at 1.03 against `surfaceContainerHigh` in light,
  // under the visibility floor the readjudication test holds.
  //
  // Measured against the five fills of the surface family
  // (horizontal / vertical, composited over the fill they lie on):
  // 1.22/1.37 on `surface` in light and 1.27/1.49 in dark. The
  // weakest light fill, `surfaceContainerHigh`, is 1.20/1.34; the
  // weakest dark one is 1.24 (`surfaceContainerLowest`) on the
  // horizontal run and 1.44 (`surfaceContainerHigh`) on the
  // vertical. The vertical run leads on every fill. The nearest
  // ring approach is 6.79 (dark, `surfaceContainerHigh`, vertical).
  lightColor: CoreColor.token(
    CoreColors.outline,
    opacity: CoreOpacity.opacity16,
  ),
  // Heavier than the horizontal runs. Two runs of equal strength
  // read as a uniform outline, and uniform is what separates this
  // from `highlightRim`.
  darkColor: CoreColor.token(
    CoreColors.outline,
    opacity: CoreOpacity.opacity25,
  ),
  // The wall that makes the edge a thickness rather than a line.
  //
  // Stated as a light rather than as crescents, and the angle and
  // the strength are the same two numbers the design tool's glass
  // panel shows for the same look — upper left, most of full.
  //
  // Upper left is not a free choice. Every authored shadow token in
  // this kit casts straight down, so a wall lit from below would
  // disagree with the shadow on the same element, and the eye reads
  // that disagreement long before it can name it.
  bevel: CoreSurfaceEdgeBevel(
    thickness: CoreStrokeWidth.stroke2,
    lightAngle: -45,
    lightIntensity: 0.8,
    // The light that got *through* the edge, reaching into the
    // face. Without it the wall reads as a sticker on a flat panel;
    // with it the face reads as lying below the rim.
    glowSpread: CoreSize.size12,
    // The crest of the wall catching that same light: a thin bright
    // line along the whole contour, brightest on the arc that faces
    // upper-left. This is the part of the reference the crescents
    // could not give — they are soft and offset, so a pill's corners
    // stayed dark under them. One physical pixel, because it is a
    // reflection off an edge and not a stroke; near full strength at
    // the peak, because the reference's rim is the brightest thing on
    // the panel and a timid one reads as a border.
    //
    // Two pixels and full strength, retuned from one pixel at 0.9 after
    // the first capture: at one pixel the crest read on the pill's arc
    // and vanished on a card's straight edge at 1×, where the reference
    // keeps a visible bright line all the way round. Two pixels is where
    // the straight run reads as a reflection rather than as a border on
    // the same screen — and it is an app's to move: `CoreSurfaceTuning`
    // carries both numbers.
    rimWidth: CoreStrokeWidth.stroke2,
    rimIntensity: 1,
  ),
);

/// Everything one surface style is, in the form the theme axis consumes.
///
/// A recipe is deliberately small. The tempting shape is a component-theme
/// bundle per preset — a slot for each of the ~140 components — but that
/// makes the authoring surface the product of styles and components, and
/// nobody keeps that many hand-written entries in agreement. It also puts
/// the axis in a second place: a bundle competes with token resolution over
/// the same chrome fields, and which one wins becomes an accident of
/// implementation order.
///
/// So the recipe carries only what a style *is* — its colour statement, its
/// surface treatment, and the accessibility delta those two imply — and the
/// axis applies it where tokens resolve. Components never read it.
@immutable
class CoreSurfaceRecipe {
  /// Creates a recipe for one surface style.
  const CoreSurfaceRecipe({
    required this.id,
    required this.a11y,
    this.colorConstraint = const CoreSurfaceColorConstraint(),
    this.geometry = const CoreSurfaceGeometryConstraint(),
    this.typography = const CoreSurfaceTypographyConstraint(),
    this.surface,
    this.functionalSurface,
    this.nestedSurfaces,
    this.overlayMorph,
    this.refraction,
    this.frost,
    this.bodyShade,
  }) : assert(
         functionalSurface == null || surface != null,
         'A style that dresses only floating surfaces leaves every card in '
         'the content layer bare. State the content material too, or state '
         'neither.',
       );

  /// Which style this describes.
  final CoreSurfaceStyleId id;

  /// The accessibility delta this style owes, from the preset contract.
  final CoreSurfaceA11yContract a11y;

  /// How this style bends the app's palette. Identity by default.
  final CoreSurfaceColorConstraint colorConstraint;

  /// How this style bends geometry — corner radius and border weight.
  /// Identity by default.
  final CoreSurfaceGeometryConstraint geometry;

  /// How this style bends type. Identity by default.
  final CoreSurfaceTypographyConstraint typography;

  /// The surface treatment — translucency and blur.
  ///
  /// Null means the platform default opaque surface, which is what every
  /// style except glass wants.
  ///
  /// This is what a surface in the *content* layer gets. A floating one
  /// gets [functionalSurface] when the style states a second material,
  /// and this when it does not — see [surfaceFor].
  final CoreSurfaceToken? surface;

  /// The material a surface that floats above the content layer gets,
  /// or null to give it the same material as everything else.
  ///
  /// Not a second style — a second *statement within* one style. Apple
  /// draws the same line and gives it the same reason: a panel over
  /// content adjusts the luminosity of what is behind it so foreground
  /// text stays legible, while a face in the content layer stays out of
  /// the way.
  ///
  /// Nullable rather than required because most styles have one material
  /// or none, and forcing them to restate it twice is how the two copies
  /// drift. Null here does not mean "floating surfaces get nothing"; it
  /// means "this style makes no distinction", which [surfaceFor] resolves
  /// to [surface].
  ///
  /// The pairing is deliberate in the other direction too: a style may
  /// not state *only* this one. A functional material with no content
  /// material would mean the style dresses overlays and leaves every card
  /// bare — expressible, never intended, and silent if it happened. The
  /// constructor asserts against it.
  final CoreSurfaceToken? functionalSurface;

  /// The material each role gets once a surface sits inside another one,
  /// by depth. Null means this style does not thin with nesting.
  ///
  /// The list index is the depth **beyond the first**: entry 0 is a
  /// surface directly inside another, entry 1 one deeper, and so on. The
  /// last entry is the **floor** — anything deeper keeps it.
  ///
  /// ## Why it has to thin at all
  ///
  /// Nested backdrop filters *compose*. A glass button inside a glass
  /// card does not go opaque — it passes the card's backdrop straight
  /// through — but the two materials multiply, so repeating the outer
  /// values makes the inner one muddy rather than distinct. Apple states
  /// the same rule as a different material: *"When a button appears on
  /// top of a glass window, use the thin material as the button's
  /// background."*
  ///
  /// ## Why a floor, and why entries rather than a multiplier
  ///
  /// Thinning without a floor eventually reaches a material that is not
  /// there — a card inside a dialog inside a menu is only three deep, and
  /// each level is a real screen someone builds.
  ///
  /// A multiplier cannot express that floor. `theme-axis-composition.md`
  /// gives the general form: a scaling axis placed after a substituting
  /// one always wins, so the substitution can state a value but never a
  /// bound. Discrete entries state both, and the last one *is* the bound.
  ///
  /// ## What thins, and what deliberately does not
  ///
  /// The backdrop blur. Not the fill: the fill's alpha is what a contrast floor
  /// is computed against, and thinning it at depth would make legibility
  /// depend on how deeply a component happens to be nested — which no
  /// caller controls and no contrast audit could enumerate.
  final Map<CoreSurfaceRole, List<CoreSurfaceToken>>? nestedSurfaces;

  /// The morph an anchored overlay runs while it opens under this style.
  ///
  /// Null means overlays arrive the way they always have. A spring means
  /// they emerge from their trigger at that tempo.
  ///
  /// Here rather than on [CoreSurfaceToken] because the token is the
  /// surface *treatment* — translucency, blur, saturation, sheen — and
  /// every value on it folds into a paint field. A morph is not paint. The
  /// recipe is what one style *is*, and this is a sixth statement of that
  /// kind.
  ///
  /// A nullable spring rather than a flag plus a tempo elsewhere: two
  /// fields, one of which can contradict the other, has an undefined state
  /// the day someone sets the flag and forgets the spring.
  ///
  /// Deliberately **not** part of [statesNothing]. Both consumers of that
  /// predicate are about static output — skipping a dead CSS rule, pruning
  /// a redundant screenshot row — and a morph emits no CSS and makes no
  /// still-frame difference. The trap runs the other way too: a future
  /// style that stated *only* a morph would be pruned from the parity
  /// matrix and emit no rule, and be invisible for it.
  final CoreMorphSpring? overlayMorph;

  /// How strongly this style's surfaces bend what is behind their edge.
  ///
  /// Null means no bending, which is how every style but glass renders.
  ///
  /// ## Why this is on the axis after all
  ///
  /// `CoreSurfaceRefraction`'s own doc argued it could not be: the
  /// displacement it needs is computed from the element's own rounded
  /// rectangle, so it cannot be written once and read everywhere.
  ///
  /// That is true of the *map* and not of the *request*. What travels here
  /// is a bezel width and a fallback blur — two size-independent scalars,
  /// exactly like the blur radius beside them. Each surface still builds
  /// its own map from its own rectangle, which is what the Web runtime
  /// already does (it measures the element and rebuilds on resize, keyed
  /// by geometry). Putting the request on the axis does not move that work
  /// anywhere; it only stops every surface having to be told by hand.
  ///
  /// And the cost of leaving it off was measured: nothing in the kit
  /// passed `refraction` to anything, on either platform, so the shipped
  /// glass preset had translucency, blur, chroma and an edge band — and
  /// **zero refraction**, which is the dominant term in the material it is
  /// named after. The implementation existed on both platforms and no
  /// caller turned it on.
  final CoreSurfaceRefraction? refraction;

  /// The cloud this style lays over the content behind its glass, or null
  /// for none — which is how every shipped style renders.
  ///
  /// On the recipe rather than on the token, like [refraction] and for a
  /// like reason: it is a statement about how the *style* treats the pass its
  /// glass already draws, not about one role's fill, and a style that said
  /// it per role would be free to give a card and a popover different
  /// clouds. A surface that draws no backdrop pass — a surface nested in
  /// another, or an opaque one — has nothing for it to act on and draws none.
  ///
  /// See [CoreSurfaceFrost] for what it is and what it costs: one extra
  /// backdrop pass per surface that draws it.
  final CoreSurfaceFrost? frost;

  /// How far this style pulls a bright backdrop down under its glass, or null
  /// for none — which is how every shipped style renders.
  ///
  /// On the recipe for the reason [frost] is. See [CoreSurfaceBodyShade].
  final CoreSurfaceBodyShade? bodyShade;

  /// Structural equality for the nesting table.
  ///
  /// A `Map` of `List`s compares by identity, which is exactly wrong for
  /// a value type on a theme axis: the axis's whole contract is that a
  /// changed value produces an unequal object so the framework rebuilds —
  /// and, as much, that an unchanged one does not. A theme that carries the
  /// table compares it through here, because a tuning that states the light
  /// builds a fresh table for the same answer each time the app root is
  /// rebuilt.
  static bool nestedSurfacesEqual(
    Map<CoreSurfaceRole, List<CoreSurfaceToken>>? a,
    Map<CoreSurfaceRole, List<CoreSurfaceToken>>? b,
  ) => _nestedEquals(a, b);

  /// The hash mate of [nestedSurfacesEqual] — equal tables hash equal.
  static int nestedSurfacesHash(
    Map<CoreSurfaceRole, List<CoreSurfaceToken>>? table,
  ) => _nestedHash(table);

  static bool _nestedEquals(
    Map<CoreSurfaceRole, List<CoreSurfaceToken>>? a,
    Map<CoreSurfaceRole, List<CoreSurfaceToken>>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || other.length != entry.value.length) return false;
      for (var i = 0; i < other.length; i++) {
        if (other[i] != entry.value[i]) return false;
      }
    }

    return true;
  }

  /// The hash mate of [_nestedEquals] — equal tables must hash equal.
  static int _nestedHash(Map<CoreSurfaceRole, List<CoreSurfaceToken>>? m) {
    if (m == null) return 0;
    var hash = 0;
    // Order-independent, because a `Map`'s iteration order is not part of
    // its value: two tables built with the roles written in the opposite
    // order are the same table and have to hash the same.
    for (final entry in m.entries) {
      hash ^= Object.hash(entry.key, Object.hashAll(entry.value));
    }

    return hash;
  }

  /// The material a surface of [role] gets under this style.
  ///
  /// The single place the role is turned into a material. Components ask
  /// this with the role they declared; nothing else branches on the role,
  /// which is what keeps the axis out of component code.
  CoreSurfaceToken? surfaceFor(CoreSurfaceRole role, {int depth = 0}) {
    final base = switch (role) {
      CoreSurfaceRole.functional => functionalSurface ?? surface,
      CoreSurfaceRole.content => surface,
    };
    if (depth <= 0) return base;

    final steps = nestedSurfaces?[role];
    if (steps == null || steps.isEmpty) return base;

    // The floor. Clamping rather than running off the end is the whole
    // point of the last entry — a surface five deep keeps the material a
    // surface three deep got, instead of thinning into nothing.
    return steps[depth - 1 < steps.length ? depth - 1 : steps.length - 1];
  }

  /// The recipe for every style, including the baseline.
  ///
  /// Colour statements and surface treatments start at their neutral values
  /// here: the character of each style is settled by that style's own story,
  /// where the values can be reviewed against a rendered screen. What is
  /// fixed now is that each style has exactly one place to put them, and
  /// that the accessibility answers travel with them.
  static const Map<CoreSurfaceStyleId, CoreSurfaceRecipe> presets = {
    CoreSurfaceStyleId.defaultStyle: CoreSurfaceRecipe(
      id: .defaultStyle,
      a11y: .defaultSurface,
    ),
    CoreSurfaceStyleId.liquidGlass: CoreSurfaceRecipe(
      id: .liquidGlass,
      a11y: .liquidGlass,
      // Translucent with a backdrop blur. The a11y contract already states
      // what this costs: the ring offset goes transparent because an opaque
      // halo would defeat the material, and the style reports
      // `usesTransparency` so a reduce-transparency request can fall back
      // to an opaque surface where contrast is decidable again.
      // Saturation and the sheen are the half that makes this read as
      // glass rather than as something merely blurred — see their docs
      // on `CoreSurfaceToken` and `CoreSurfaceEdgeSheen`.
      // The content layer is glass too — the same material as the
      // functional layer.
      //
      // ## Why both roles, and why the same material
      //
      // This preset shipped for a while with the content layer opaque,
      // following Apple's guidance that glass belongs to the navigation
      // layer and content stays a standard material. Reviewed against the
      // reference on screen, that read as "the dock is glass and nothing
      // else is": a card beside a glass bar was a solid slab, and the style
      // read as a bar treatment rather than a material. The decision now
      // is the one the reference makes with its own cards and mini-player:
      // a panel is glass whatever it is for, and the two roles differ by
      // *where they sit*, not by what they are made of.
      //
      // What that costs is recorded rather than argued away. A dark
      // content panel over a bright backdrop cannot have its contrast
      // decided statically, which is why `usesTransparency` is declared
      // and a reduce-transparency request folds both roles to opaque. The
      // separation the roles used to carry — opaque against glass — is
      // given up by choice; the nesting table below is what keeps a panel
      // inside a panel from stacking a second backdrop pass.
      surface: _kGlassSurface,
      // What a surface inside another surface gets.
      //
      // ## The frost thins, and the number is derived
      //
      // Gaussian blurs compose by variance: a frost inside another frost
      // reads as `sqrt(σ₁² + σ₂²)`, not σ. So an inner surface that
      // restates the outer value is not "as frosted as the card" — it is
      // half again as frosted, and that is what reads as muddy.
      //
      // Running it the other way gives the entry: for the inner surface
      // to land near σ-14 — a little more than the card, so it reads as
      // its own pane rather than as part of one — it needs to *add*
      // sqrt(14² − 12²) ≈ 7. One entry, so that is also the floor: a
      // third level is already sitting on a backdrop two frosts deep and
      // has nothing left to add.
      //
      // The target (14) is the design choice here and the arithmetic is
      // not; a browser measurement of the composed result is what would
      // settle it, and until then it is stated rather than implied.
      //
      // ## The fill does not thin
      //
      // Deliberately. The fill's alpha is what a contrast floor is
      // computed against, so thinning it at depth would make legibility
      // depend on how deeply a component happens to be nested — which no
      // caller controls and no contrast audit could enumerate.
      nestedSurfaces: {
        // Both roles are glass, so both have a backdrop pass to drop and
        // both drop it the same way: no frost, the fill, the band and
        // the edge stay. A card in a dialog and a menu in a dialog are
        // the same situation — glass on glass — and get the same answer.
        //
        // Two entries rather than one shared key on purpose: the roles
        // are allowed to thin differently, and a preset that wants that
        // edits a line here rather than growing a branch in `surfaceFor`.
        // One written answer per role is what keeps the two platforms
        // from each deciding for themselves.
        CoreSurfaceRole.content: [_kNestedGlassFunctional],
        CoreSurfaceRole.functional: [_kNestedGlassFunctional],
      },
      // The same glass, named again so the role axis still has a slot to
      // point at. When a preset wants the floating layer to differ (a
      // heavier fill, a dimmer backdrop, its own edge) this is where it
      // says so; this one does not, by decision — see `surface` above.
      functionalSurface: _kGlassSurface,
      // The one style whose overlays emerge from their trigger rather than
      // arriving beside it. `fast` settles in ~740ms; that number is also
      // how long the panel's corners are outside its own hit-test path,
      // because a clip narrows hit testing along with painting.
      overlayMorph: CoreMorphSpring(speed: .fast),
      // The half of this material that was implemented on both platforms
      // and never switched on. Bending at the rim is what separates glass
      // from a blurred pane, and until this line nothing in the kit passed
      // a refraction to anything.
      // Four knobs, and they are deliberately not one: the band says *where*
      // the bending happens, the index says at what *angle*, the dial says
      // *how far*, and dispersion says how far apart the colours land. The
      // first three were welded together before — each renderer in its own
      // way — so widening the band also strengthened the bend, and only on
      // one platform.
      //
      // Bezel is a fraction of the shorter side, capped at 0.5 where the two
      // sides would meet and leave no flat interior. A third reads as a wide
      // rim on a card and stays proportional on a dialog, because the value
      // is stated as a fraction of the surface rather than in pixels.
      //
      // The index is window glass. Snell's law saturates above about 2, so
      // the room above this is small and the dial is what to reach for.
      //
      // Dispersion is kept low on purpose. It only shows where something
      // crosses the rim with a hard boundary, and a value high enough to see
      // on a flat backdrop puts a visible fringe on every letter that passes
      // under the edge.
      // Written in the design tool's own numbers, on its own 0–100 scale, so
      // this recipe and a Figma glass panel can be read side by side without
      // anyone converting anything in their head. The conversion happens once,
      // in the constructor.
      refraction: CoreSurfaceRefraction.figma(
        refraction: 80,
        depth: 27,
        dispersion: 50,
        // The dome. Not on the design tool's panel — a decision this kit
        // makes against the reference screen, where a line crossing under
        // the bar bows across the whole width and the content behind reads
        // a little larger. Eight percent is a magnification of about 1.09,
        // enough to see on a wide bar and not enough to make text behind a
        // card unreadable. Stated in this kit's own unit, see `lens`.
        lens: 0.08,
        fallbackBlurAdd: 4,
      ),
    ),
    CoreSurfaceStyleId.neoBrutalism: CoreSurfaceRecipe(
      id: .neoBrutalism,
      a11y: .neoBrutalism,
      // Corners capped small (not squared — the reference implementations
      // this style is drawn from keep a slight round, 4-6px, rather than a
      // true 0; full square reads as raw/unstyled rather than the
      // recognisable "neo-brutalism" look), a border no thinner than 4,
      // and that border pushed to the foreground's darkness. The focus
      // ring is 6 in this style's a11y contract for exactly this reason —
      // a ring that merely matched the border would read as part of it.
      colorConstraint: CoreSurfaceColorConstraint(outlineEmphasis: 1),
      geometry: CoreSurfaceGeometryConstraint(
        radiusCap: CoreRadius.radius6,
        strokeFloor: CoreStrokeWidth.stroke4,
        // The signature cast: no blur at all, and thrown down-and-right
        // rather than straight down. Every authored shadow's `offsetX` is
        // `0` — scaling it stays `0` — so the diagonal is stated outright
        // via `shadowOffsetAdd` instead of derived via `shadowOffsetScale`
        // (left at its identity value here). Matched to the border floor
        // so the cast reads as a continuation of the border's own weight,
        // not an arbitrary second number.
        shadowBlurScale: 0,
        shadowOffsetAdd: (
          dx: CoreStrokeWidth.stroke4,
          dy: CoreStrokeWidth.stroke4,
        ),
        // The nine authored stacks are soft ambient shadows (opacity
        // 0.03–0.12) — hard-edging one without this still leaves it
        // reading as barely there. This style's cast is meant to read as
        // a second solid shape, so the opacity is stated outright.
        shadowOpacityOverride: 1,
        // A plain control (Button at rest) casts nothing to bend — this
        // style's identity is that every control looks boxed, so it
        // contributes the cast outright rather than leaving flat controls
        // out of it. Same offset/blur/opacity statement as the bend above,
        // so a control that starts casting something (an explicit
        // elevation) and one that starts with nothing end up matching.
        controlShadow: [
          (
            offsetX: CoreStrokeWidth.stroke4,
            offsetY: CoreStrokeWidth.stroke4,
            blurRadius: 0,
            spreadRadius: 0,
            opacity: 1,
            inset: false,
          ),
        ],
        // The same argument the cast above makes, for the boundary.
        // Walking the rendered catalogue found 47 components with no
        // boundary anywhere under this style — `strokeFloor` can only
        // raise a width already being painted, and these paint none.
        // Boxing is what the style *is*, so it contributes the border
        // outright rather than deriving it from an absent one.
        //
        // What the style offers, not what every surface takes. Which
        // surfaces qualify is stated where they are drawn, because a
        // resolver cannot know how large it will render and this width
        // swallows a small enough part: a switch thumb spills out of its
        // own track and an 8px progress bar has no height left to fill.
        // Both are measured — see those two files for the numbers.
        //
        // At the floor, not above it: a contributed boundary that read
        // heavier than an authored one would sort the kit into two
        // weights with nothing behind the split.
        controlBorder: CoreStrokeWidth.stroke4,
      ),
      // Nothing thinner than semibold. The scale's hierarchy survives —
      // roles already heavier keep their own weight.
      typography: CoreSurfaceTypographyConstraint(
        weightFloor: CoreFontWeight.semiBold,
      ),
    ),
    CoreSurfaceStyleId.claymorphism: CoreSurfaceRecipe(
      id: .claymorphism,
      a11y: .claymorphism,
      // Soft and puffy: the cast spreads rather than sharpens. That is the
      // whole of what this style states for now.
      //
      // Pastel accents are deliberately absent. Desaturating and lifting a
      // filled surface reduces its contrast against the white foreground
      // it carries — measured, every pastel setting drops the worst accent
      // pair under 4.5:1, including one that only shifts chroma. Pastel is
      // therefore not expressible without also deciding what happens to the
      // foreground, and this constraint refuses to touch foregrounds on
      // purpose. Tracked separately rather than shipped as a style that
      // makes text harder to read.
      geometry: CoreSurfaceGeometryConstraint(
        // Puffy is mostly corners. A cap alone could only make things
        // sharper, so the range is what lets this material say the one
        // thing it is named for. Redistribution rather than a clamp —
        // a floor of 16 applied as a clamp would collapse the 4/8/16
        // ladder that 106 authored sites use into a single value.
        radiusFloor: CoreRadius.radius16,
        radiusCap: CoreRadius.radius32,
        shadowBlurScale: 1.6,
        // The rim is what makes this read as clay rather than as a card
        // with a soft shadow: light catching the top of a pressed,
        // rounded form. Drawn in the palette's surface highlight, so a
        // palette that states none still gets one derived from its own
        // surface instead of an undefined colour.
        //
        // One layer, not the two the sketch called for. The second was
        // to be a dark rim along the bottom, and the component's own
        // inset stack already draws in the shadow tint — a style adding
        // a second dark inset would be restating what the component can
        // already say.
        highlightRim: [
          (
            offsetX: 0,
            offsetY: 2,
            blurRadius: 6,
            spreadRadius: 0,
            opacity: 0.55,
            inset: true,
          ),
        ],
      ),
    ),
    CoreSurfaceStyleId.neumorphism: CoreSurfaceRecipe(
      id: .neumorphism,
      a11y: .neumorphism,
      // The defining constraint: a component surface is the page colour, so
      // the only thing separating them is the shadow. The a11y contract
      // carries the consequences — a forced-colours stroke fallback,
      // because a shadow-only boundary vanishes there, and a flattened
      // disabled state, because a recoloured foreground on an identical
      // background has nothing to contrast against.
      // Flattening the container tones onto the page leaves `outline` as
      // the only thing that could separate them, and at its authored value
      // it measures 2.14:1 against that surface — under the 3:1 a control
      // edge needs. So the same statement that flattens the tones also has
      // to make the boundary work harder.
      //
      // 0.5 is the smallest emphasis that clears 3:1 against *every*
      // surface tone in both modes, including the highest tone this style
      // deliberately leaves un-flattened (light 3.70, dark 4.37). Lower
      // values pass on the flattened tones and fail on that one, which is
      // exactly the kind of partial pass the audit exists to refuse.
      colorConstraint: CoreSurfaceColorConstraint(
        outlineEmphasis: 0.5,
        surfaceMatchesStage: true,
      ),
      // The signature of the style, and the reason a scale alone could not
      // produce it: soft UI reads as pressed out of the page because
      // light and shade arrive from opposite corners at once. The second
      // direction is not in the authored stack at any magnitude.
      //
      // It stays a derivation — the twin is the component's own layer
      // with its offset negated — so a flat component still casts
      // nothing and this style does not re-author 140 shadows.
      geometry: CoreSurfaceGeometryConstraint(
        shadowBlurScale: 2,
        shadowMirror: true,
      ),
    ),
  };

  /// The recipe for [id], falling back to the baseline.
  static CoreSurfaceRecipe of(CoreSurfaceStyleId id) =>
      presets[id] ?? presets[CoreSurfaceStyleId.defaultId]!;

  /// Whether this recipe changes nothing a consumer could observe — every
  /// constraint is identity and there is no material surface treatment.
  ///
  /// Single source for the "this style is a no-op" predicate: the Web
  /// stylesheet generator uses it to skip emitting a dead CSS rule
  /// (`ThemeConfig.surfaceStyleVariableBlocks`) and the parity pipeline uses
  /// it to prune a redundant matrix row (`kRedundantSurfaceStyles`). Two
  /// independent copies of this boolean expression would be free to drift —
  /// one updated for a new constraint field, the other not — and the drift
  /// would surface as a style silently mismatched between "no CSS rule" and
  /// "still captured for parity" or vice versa.
  bool get statesNothing => !statesTokenConstraint && !statesMaterial;

  /// Whether this style bends a token every component resolves — the
  /// palette, geometry, or type.
  ///
  /// The three constraints land at the token seat: on Web as `--coui-*`
  /// overrides under `[data-coui-style]` (`ThemeConfig
  /// .surfaceStyleVariableBlocks`), on Flutter folded into `ThemeData` by
  /// `applySurfaceStyle`. A component never reads them, so nothing about
  /// the component decides whether they arrive — a weight floor raises
  /// every label, a radius cap squares every corner, an outline emphasis
  /// recolours every stroke, marked surface or not.
  ///
  /// [statesMaterial] is the other half of the recipe and does **not**
  /// travel this way: translucency, blur and refraction land only on an
  /// element that carries the surface marker. That split is what the
  /// parity matrix reads to decide which combinations can be left
  /// uncaptured — a style that only states a material renders
  /// byte-identical to `defaultStyle` on a component with no marker
  /// anywhere in it, while a style that bends a token never does. It was
  /// measured the other way first: a pruning rule that treated every
  /// preset as marker-scoped was proven wrong on 1,406 of 2,528 pruned
  /// pairs in one night, the weight floor alone on 464 of them.
  bool get statesTokenConstraint =>
      !colorConstraint.isIdentity ||
      !geometry.isIdentity ||
      !typography.isIdentity;

  /// Whether either material actually draws — translucent or frosted.
  ///
  /// Both roles, because a style is not a no-op if *either* material
  /// draws. Reading only `surface` would prune a style whose floating
  /// material is the interesting one — the Web sheet would skip its rule
  /// and the parity matrix would drop its row, in both cases silently.
  bool get statesMaterial {
    bool draws(CoreSurfaceToken? m) =>
        m != null && (m.blurRadius != null || !m.opacity.isOpaque);
    return draws(surface) || draws(functionalSurface);
  }

  /// Creates a copy with modified values.
  CoreSurfaceRecipe copyWith({
    CoreSurfaceStyleId? id,
    CoreSurfaceA11yContract? a11y,
    CoreSurfaceColorConstraint? colorConstraint,
    CoreSurfaceGeometryConstraint? geometry,
    CoreSurfaceTypographyConstraint? typography,
    CoreSurfaceToken? surface,
    CoreSurfaceToken? functionalSurface,
    Map<CoreSurfaceRole, List<CoreSurfaceToken>>? nestedSurfaces,
    CoreMorphSpring? overlayMorph,
    CoreSurfaceRefraction? refraction,
    CoreSurfaceFrost? frost,
    CoreSurfaceBodyShade? bodyShade,
  }) {
    return CoreSurfaceRecipe(
      id: id ?? this.id,
      a11y: a11y ?? this.a11y,
      colorConstraint: colorConstraint ?? this.colorConstraint,
      geometry: geometry ?? this.geometry,
      typography: typography ?? this.typography,
      surface: surface ?? this.surface,
      functionalSurface: functionalSurface ?? this.functionalSurface,
      nestedSurfaces: nestedSurfaces ?? this.nestedSurfaces,
      overlayMorph: overlayMorph ?? this.overlayMorph,
      refraction: refraction ?? this.refraction,
      frost: frost ?? this.frost,
      bodyShade: bodyShade ?? this.bodyShade,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceRecipe &&
          id == other.id &&
          a11y == other.a11y &&
          colorConstraint == other.colorConstraint &&
          geometry == other.geometry &&
          typography == other.typography &&
          surface == other.surface &&
          functionalSurface == other.functionalSurface &&
          _nestedEquals(nestedSurfaces, other.nestedSurfaces) &&
          overlayMorph == other.overlayMorph &&
          refraction == other.refraction &&
          frost == other.frost &&
          bodyShade == other.bodyShade;

  @override
  int get hashCode => Object.hash(
    id,
    a11y,
    colorConstraint,
    geometry,
    typography,
    surface,
    functionalSurface,
    // Structural, not identity. A `Map` of `List`s hashes by
    // reference, so two recipes with equal nesting tables would land
    // in different buckets and compare unequal — the framework would
    // rebuild on every theme read, and worse, an author retuning the
    // table in place would compare *equal* and never rebuild at all.
    _nestedHash(nestedSurfaces),
    overlayMorph,
    refraction,
    frost,
    bodyShade,
  );
}

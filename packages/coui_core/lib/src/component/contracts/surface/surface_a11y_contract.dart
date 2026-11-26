import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:meta/meta.dart';

/// How a surface preset keeps its component boundaries when the platform
/// forces its own palette.
///
/// Forced-colours modes replace colours but do not create geometry: a
/// boundary drawn purely with shadow has nothing to force, so it disappears
/// rather than changing colour. Each preset therefore has to say which of
/// these it is, and a preset whose boundary is shadow-only owes a
/// forced-safe fallback.
enum CoreSurfaceBoundaryMechanism {
  /// A real stroke. Forced-colours recolours it, so the boundary survives.
  stroke,

  /// Carried on a property forced colours does not force — a shadow, or a
  /// gradient band a material paints as its own edge. Erased outright in
  /// that mode, so the preset must declare a stroke fallback for it.
  ///
  /// Named for the first case that needed it. The obligation, not the
  /// paint, is what this member selects: anything the mode refuses to
  /// recolour owes the same fallback, so a second member would duplicate
  /// an obligation set rather than distinguish one.
  shadow,

  /// Deliberately unbounded (ghost / flat surfaces). Owes no boundary, but
  /// still owes a focus indicator and a readable foreground.
  none,
}

/// How a surface preset signals the disabled state.
///
/// A recoloured foreground is the default, but two of the presets make it
/// unreliable: neumorphism paints the surface the same colour as the page,
/// and glass is translucent, so in both cases a recolour competes with
/// whatever is behind the element.
enum CoreSurfaceDisabledSignal {
  /// The dedicated disabled colour tokens carry it.
  colorTokens,

  /// The surface flattens (shadow / blur removed) so the control visibly
  /// stops being raised, in addition to the colour change.
  flattenedSurface,
}

/// The accessibility delta a surface preset owes on top of the global axes.
///
/// The global work already covers what every preset shares — focus wiring,
/// contrast auditing, reduced motion, high contrast, disabled colour
/// tokens. This type is only the part that is *specific to a preset*, and
/// it exists so that each of the four presets answers the same questions
/// once rather than each one re-litigating accessibility on its own.
///
/// The questions are the ones the presets actually get wrong:
///
/// * **Does the focus ring still read?** The default ring is 2px of
///   `focusRing` past a transparent 2px gap, so it reads against whatever
///   the control sits on. That assumption breaks in two directions: on
///   glass what the control sits on is arbitrary content seen through the
///   material, and on neo-brutalism a 2px ring sits beside a 4px black
///   border and loses to it.
/// * **Does the boundary survive forced colours?** Shadow is not forced, so
///   a shadow-only boundary vanishes entirely.
/// * **Is disabled still distinguishable?** Not if the recolour competes
///   with the page behind a translucent or same-coloured surface.
/// * **Does it depend on transparency?** Needed to answer a reduce
///   transparency preference.
@immutable
class CoreSurfaceA11yContract {
  /// Creates the accessibility contract for one surface preset.
  const CoreSurfaceA11yContract({
    required this.focusOutlineStyle,
    required this.boundaryMechanism,
    required this.disabledSignal,
    required this.usesTransparency,
    this.forcedColorsBoundary,
  }) : assert(
         boundaryMechanism != .shadow || forcedColorsBoundary != null,
         'A shadow-only boundary disappears in forced colours, so the preset '
         'must declare the stroke that replaces it.',
       );

  /// Focus ring override for this preset.
  ///
  /// Presets that leave the default ring legible supply an empty style; the
  /// resolver then falls through to `CoreFocusOutlineStyle`'s own defaults.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// What draws this preset's component boundary.
  final CoreSurfaceBoundaryMechanism boundaryMechanism;

  /// The stroke that replaces a shadow boundary under forced colours.
  ///
  /// Required exactly when [boundaryMechanism] is
  /// [CoreSurfaceBoundaryMechanism.shadow]. The assert guarantees the value
  /// exists; what makes it more than a note is the drawing path, and that
  /// lives on the Web side — a rule inside `@media (forced-colors: active)`
  /// that hands every surface this width. It carries `!important` because
  /// the surface primitive writes its border width inline, and an inline
  /// declaration outranks every selector.
  ///
  /// Deliberately asymmetric, and the asymmetry is the signal's, not the
  /// implementation's. Forced colours is a browser and OS mode with no
  /// Flutter equivalent, and Flutter does not erase shadows — a shadow
  /// boundary is still drawn there, so there is nothing for a fallback to
  /// stand in for. Flutter's nearest signal is high contrast, which asks
  /// for stronger colour rather than a substitute for a missing edge.
  final double? forcedColorsBoundary;

  /// How the preset makes a disabled control identifiable.
  final CoreSurfaceDisabledSignal disabledSignal;

  /// Whether the preset's surface is translucent.
  ///
  /// Also a warning sign for contrast: a translucent surface's effective
  /// contrast depends on whatever is behind it, which no static audit can
  /// settle.
  ///
  /// ## Where the reduce-transparency response actually lands
  ///
  /// **Web only, and by capability rather than by choice.** The two
  /// platforms are not symmetric here and cannot be made so from this
  /// side:
  ///
  /// * Web has `@media (prefers-reduced-transparency: reduce)`, and the
  ///   stylesheet answers it — a translucent preset emits an opaque fill
  ///   and drops its backdrop filter under that query.
  /// * Flutter has no handle at all. `AccessibilityFeatures` exposes
  ///   `reduceMotion`, `highContrast`, `invertColors`, `boldText`,
  ///   `accessibleNavigation` and `onOffSwitchLabels` — and nothing for
  ///   transparency, though the OS setting exists on Apple platforms. A
  ///   reader here would have nothing to read, so the kit **takes** the
  ///   answer instead: `CoUIApp.reduceTransparency` is supplied by an app
  ///   that obtained the signal by its own means, and `applySurfaceStyle`
  ///   applies `CoreSurfaceToken.withoutTransparency()` — the same
  ///   statement the Web query above writes as CSS.
  ///
  /// This is the documented exception to "an axis needs the same handle on
  /// both platforms": the capability is absent on one side, not merely
  /// unimplemented, so the asymmetry is recorded rather than waited on.
  /// What the seat buys is that the fallback is *reachable* on Flutter
  /// rather than structurally present and never triggerable — the shape
  /// this doc used to describe.
  ///
  /// This doc used to say the field "drives the reduce-transparency
  /// response" while nothing on either platform read the preference. That
  /// is the shape the acceptance gate names by hand — a declaration with
  /// no drawn path is a claim, not a pass — and it is why the sentence is
  /// now about where the response lands rather than that it exists.
  final bool usesTransparency;

  /// The baseline — an opaque surface with a stroke boundary needs no
  /// delta, so every field is the global default.
  static const CoreSurfaceA11yContract defaultSurface = CoreSurfaceA11yContract(
    focusOutlineStyle: CoreFocusOutlineStyle(),
    boundaryMechanism: .stroke,
    disabledSignal: .colorTokens,
    usesTransparency: false,
  );

  /// Neo-brutalism — a thick black border is the whole look.
  ///
  /// The ring has to out-weigh that border or it reads as part of it, so it
  /// widens past the border rather than matching the global 2px.
  static const CoreSurfaceA11yContract neoBrutalism = CoreSurfaceA11yContract(
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderWidth: CoreStrokeWidth.stroke6,
      offsetColor: CoreColor.token(CoreColors.surface),
    ),
    boundaryMechanism: .stroke,
    disabledSignal: .colorTokens,
    usesTransparency: false,
  );

  /// Liquid Glass — translucent surface over arbitrary content.
  ///
  /// An opaque offset band over glass paints a solid halo and defeats the
  /// material, so this preset states a transparent offset, and the ring
  /// itself thickens to stay visible without a band.
  ///
  /// The ring colour's contrast partner here is whatever content sits
  /// behind the glass, so no static value can guarantee 3:1 — that is the
  /// reason this preset also reports [usesTransparency], which lets a
  /// reduce-transparency preference fall back to an opaque surface where
  /// the guarantee holds again.
  ///
  /// The boundary is the material's own edge band, not a stroke: the
  /// surface sets `drawsOwnEdge`, so a component's resting stroke would be
  /// a second boundary on the same pixels and is suppressed. That band is
  /// a gradient — `background-image` on Web, a `foregroundPainter` on
  /// Flutter — and forced colours forces neither, so it is erased outright
  /// in the one mode a user turns on to see boundaries. Hence [.shadow],
  /// which is this repo's name for "carried on a property the mode does
  /// not force", and hence the fallback below, which is not optional: the
  /// constructor refuses the pair without it.
  ///
  /// The fallback earns its keep beyond the suppressed stroke. A variant
  /// that authored no border at all — `CoreCardStyle.filled` — has the
  /// band as its *only* edge, so without this it would have no boundary in
  /// forced colours whether or not anything was suppressed.
  static const CoreSurfaceA11yContract liquidGlass = CoreSurfaceA11yContract(
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderWidth: CoreStrokeWidth.stroke3,
      offsetColor: .transparent,
    ),
    boundaryMechanism: .shadow,
    forcedColorsBoundary: CoreStrokeWidth.stroke1,
    disabledSignal: .flattenedSurface,
    usesTransparency: true,
  );

  /// Neumorphism — no border, and the surface is the page colour.
  ///
  /// Its boundary is dual shadow and nothing else, which forced colours
  /// erases outright, so it owes a stroke fallback. For the same reason the
  /// focus ring is the only reliable edge the control has, and a disabled
  /// recolour would be competing with an identical background.
  static const CoreSurfaceA11yContract neumorphism = CoreSurfaceA11yContract(
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderWidth: CoreStrokeWidth.stroke3,
    ),
    boundaryMechanism: .shadow,
    disabledSignal: .flattenedSurface,
    usesTransparency: false,
    forcedColorsBoundary: CoreStrokeWidth.stroke1,
  );

  /// Claymorphism — soft inset highlights on an opaque surface.
  ///
  /// Opaque and softly bounded, so the global ring holds; the inset
  /// highlight is decoration rather than the boundary.
  static const CoreSurfaceA11yContract claymorphism = CoreSurfaceA11yContract(
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderWidth: CoreFocusRing.ringWidth,
    ),
    boundaryMechanism: .stroke,
    disabledSignal: .colorTokens,
    usesTransparency: false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceA11yContract &&
          focusOutlineStyle == other.focusOutlineStyle &&
          boundaryMechanism == other.boundaryMechanism &&
          forcedColorsBoundary == other.forcedColorsBoundary &&
          disabledSignal == other.disabledSignal &&
          usesTransparency == other.usesTransparency;

  @override
  int get hashCode => Object.hash(
    focusOutlineStyle,
    boundaryMechanism,
    forcedColorsBoundary,
    disabledSignal,
    usesTransparency,
  );
}

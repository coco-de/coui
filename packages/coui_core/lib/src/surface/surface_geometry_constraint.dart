import 'dart:math' as math;

import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/density.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// How a surface preset bends geometry without replacing it.
///
/// The twin of the colour constraint, and deliberately the same shape: a
/// preset states what it needs, and the value is derived from whatever the
/// component already authored. A preset does not carry a table of "this
/// component gets this radius" — that would be the preset re-authoring every
/// component, which is the thing the axis exists to avoid.
///
/// It bends *values*, not token names. A geometry re-point is a function of
/// the number — "corners go square", "borders get at least this thick" — so
/// unlike colour it needs no late-bound token identity to work. That
/// difference is why geometry is a transform applied where a value becomes
/// platform output, rather than a slot on the value type: a slot would have
/// to be threaded through every one of the hundreds of construction sites to
/// buy something the transform gets for free.
///
/// The transform also reaches values that are not on the token scale at all.
/// A caller who wrote a deliberate 13px corner still gets square corners
/// under a preset that caps radius, which a name-based mapping could never
/// do.
///
/// It also carries the theme's [density] — the second axis that bends
/// geometry, and the reason both live on one value: a corner can be moved
/// by both, and the order the two apply in is a decision that has to be
/// readable in one place ([radius]) rather than an accident of which
/// conversion ran first.
///
/// And it carries the theme's [brightness], for the one value geometry
/// draws differently in the dark — how strong a shadow is. The shadow's
/// shape is the same in both; its alpha is not ([CoreShadow.darkStrength]).
@immutable
class CoreSurfaceGeometryConstraint {
  /// Creates a constraint. The default is identity — it changes nothing,
  /// which is what a preset that makes no geometry statement declares.
  const CoreSurfaceGeometryConstraint({
    this.radiusFloor,
    this.radiusCap,
    this.strokeFloor,
    this.shadowBlurScale = 1,
    this.shadowOffsetScale = 1,
    this.shadowMirror = false,
    this.highlightRim = const [],
    this.shadowOffsetAdd,
    this.shadowOpacityOverride,
    this.controlShadow = const [],
    this.controlBorder,
    this.density = CoreDensity.defaultDensity,
    this.brightness = CoreBrightness.light,
    this.hairline = CoreStrokeWidth.stroke0_5,
    this.activeBoundary = CoreStrokeWidth.stroke1_5,
  }) : assert(
         controlBorder == null || controlBorder > 0,
         'A boundary with no thickness is not a subtle boundary, it is an '
         'absent one — state none instead.',
       ),
       assert(
         radiusFloor == null || radiusCap == null || radiusFloor <= radiusCap,
         'The radius range is stated floor-first; a floor above the cap has '
         'no values in it.',
       );

  /// Lower bound of the range a style redistributes radii into.
  ///
  /// A style that only caps can make corners sharper; it has no way to
  /// say "rounder", which is what a puffy material is mostly made of.
  /// Stating a floor with [radiusCap] gives the range.
  final double? radiusFloor;

  /// Upper bound of that range.
  ///
  /// `0` is the square case and short-circuits: every radius becomes 0,
  /// which is what a hard-edged material means and what this field did
  /// on its own before there was a range.
  ///
  /// The bounds are read on the authored ladder, before the size-scaling
  /// axis multiplies. That is deliberate: the range is a statement about
  /// *where on the scale* this material sits, not a promise about
  /// rendered pixels, so it stays true at any scaling — everything moves
  /// together, exactly as every other dimensional value does.
  final double? radiusCap;

  /// Lower bound on a *drawn* border width, in logical pixels.
  ///
  /// Null leaves widths untouched. A width of zero is never raised — see
  /// [stroke].
  final double? strokeFloor;

  /// Multiplies the blur of every shadow layer.
  ///
  /// Zero produces a hard edge — the shadow becomes a solid offset copy of
  /// the shape rather than a soft cast. That is a whole look on its own,
  /// and it is a derivation rather than a replacement: the layers, their
  /// directions and their opacities are the ones the component authored.
  final double shadowBlurScale;

  /// Multiplies the offset of every shadow layer.
  ///
  /// Amplifies how far the shadow is thrown without changing which way it
  /// goes, so a style can read as heavier without restating each stack.
  final double shadowOffsetScale;

  /// Whether each cast layer gets an opposite-facing twin.
  ///
  /// A soft-UI surface reads as pressed out of the page because light and
  /// shade arrive from opposite corners at once. One directional stack
  /// cannot be scaled into that — the second direction is not present in
  /// the authored value at any magnitude, which is why a scale could not
  /// express it and this is a separate statement.
  ///
  /// It is still a *derivation*, not a replacement. The twin is the
  /// authored layer with its offset negated and its tint taken from the
  /// surface highlight, so a component that casts nothing still casts
  /// nothing and one that casts a heavy shadow gets a heavy pair. A
  /// preset that replaced the stack outright would be re-authoring the
  /// shadow of every component in the kit, which is the per-preset
  /// bundle the axis rules forbid.
  ///
  /// Inset layers are left alone. They already describe light inside the
  /// shape, and mirroring one would put a cast shadow where a highlight
  /// was asked for.
  final bool shadowMirror;

  /// Inset layers the style *adds*, drawn in the palette's surface
  /// highlight rather than its shadow.
  ///
  /// Every other field here derives from what a component authored —
  /// scaling a blur, capping a radius. A rim is the one thing a style
  /// has to contribute outright: no component authors "light falling on
  /// me from above", and no amount of transforming a cast shadow
  /// produces one, because the whole stack shares a single tint and that
  /// tint is the shadow.
  ///
  /// Which is why these layers travel separately instead of being
  /// appended to the component's stack: they need a different colour,
  /// and [CoreShadowLayer] carries none.
  final List<CoreShadowLayer> highlightRim;

  /// A fixed offset added to every shadow layer, after [shadowOffsetScale].
  ///
  /// Every authored [CoreShadowLayer] in this kit casts straight down —
  /// `offsetX` is `0` on all nine tokens. A style whose signature is a
  /// shadow thrown to one side as well as down cannot say that by
  /// scaling: multiplying zero is still zero. This field states the
  /// diagonal directly instead of deriving it, applied after the scale so
  /// a style can still control *how far* the original cast reaches while
  /// stating *which way* separately.
  final ({double dx, double dy})? shadowOffsetAdd;

  /// Replaces every shadow layer's opacity outright.
  ///
  /// The nine authored stacks are soft ambient shadows — opacity from
  /// 0.03 to 0.15, tuned to read as a faint lift, not a shape. Scaling
  /// [shadowBlurScale] to zero turns that lift into a hard-edged
  /// silhouette, but the silhouette is still painted at ambient-shadow
  /// opacity and reads as barely there. A style whose hard edge is meant
  /// to read as a second solid shape needs the opacity stated outright —
  /// the same reasoning [shadowOffsetAdd] applies to direction: scaling
  /// an already-small number keeps it small.
  final double? shadowOpacityOverride;

  /// A shadow this style casts on controls that author none.
  ///
  /// Every field above bends a shadow the component already casts —
  /// scaling its blur, adding to its offset. A plain button casts none at
  /// rest; there is nothing there to bend. This is the shadow
  /// counterpart of [highlightRim]: a style whose whole identity depends
  /// on every control looking boxed has to contribute that shadow
  /// outright, not derive it from an empty list. Used only when the
  /// incoming stack is empty — a control that already casts something
  /// keeps bending its own shadow through the fields above instead of
  /// receiving this one on top of it.
  final List<CoreShadowLayer> controlShadow;

  /// A boundary this style contributes to a surface that draws none.
  ///
  /// [strokeFloor] can only raise a width that is already being painted.
  /// That is deliberate — several variants say "no border" by collapsing
  /// the width, and a floor that raised those would draw borders on the
  /// components that removed them on purpose — and it has a consequence
  /// that went unmeasured until the whole catalogue was walked: a
  /// component that draws no border *at all* is a component the floor can
  /// never reach. Forty-seven of them render with no boundary anywhere,
  /// and under a style whose entire identity is that everything is boxed
  /// they come out looking as though the style were off.
  ///
  /// This is the border counterpart of [controlShadow], which is itself
  /// the shadow counterpart of [highlightRim]. All three exist for the
  /// same reason and the reason is stated twice above: some things a
  /// style needs cannot be derived from what a component authored,
  /// because the component authored nothing. Deriving from an absent
  /// value returns the absence.
  ///
  /// A width and no colour. The colour is the palette's `outline`, which
  /// is where every bordered component in the kit already gets its own,
  /// and which the colour constraint's outline emphasis has already
  /// pushed toward the foreground for exactly this style. A second field
  /// here would be a second place for that decision to live, and the two
  /// would eventually disagree.
  ///
  /// Read by the surfaces that qualify rather than applied to all of
  /// them, for the reason [controlShadow] gives: the set that gets boxed
  /// should be stated rather than incidental. Qualifying is a rule and
  /// not a list — a surface qualifies when it paints its own fill and
  /// reads as one discrete object. A divider is a line, a label is text,
  /// and a layout primitive paints nothing; none of the three is boxed by
  /// any style, and boxing them here would be this axis re-authoring
  /// components rather than bending them.
  final double? controlBorder;

  /// The density the theme sets its spacing, control rows and their
  /// corners in.
  ///
  /// Not a style statement — no preset carries one, and tuning cannot set
  /// it. It rides here because the conversions that bend a value for the
  /// style are the only places Flutter can bend it for the density too, and
  /// two carriers would mean two arguments at every one of them.
  final CoreDensity density;

  /// The brightness the theme draws in.
  ///
  /// Not a style statement either, for the reason [density] gives: no
  /// preset carries one and tuning cannot set it. It rides here because the
  /// one conversion every authored shadow passes through ([shadow]) is the
  /// only place Flutter can strengthen a shadow for the dark, and a second
  /// carrier would be a second argument at every one of those call sites.
  ///
  /// Dark multiplies every cast layer's opacity by [CoreShadow.darkStrength]
  /// (capped at 1). Light leaves it alone.
  final CoreBrightness brightness;

  /// The width the hairline step ([CoreStrokeWidth.stroke0_5]) draws at on
  /// the screen the theme is drawn on — [CoreStrokeWidth.hairlineAt] its
  /// device pixel ratio.
  ///
  /// Not a style statement either, for the reason [density] gives. The
  /// default is the step's own 0.5, a dense screen's; the app folds the
  /// screen in ([atDevicePixelRatio]), and [stroke] reads it — the one place
  /// every Flutter stroke passes, so a hairline anywhere follows the screen
  /// the way Web's `--coui-stroke-width-0_5` does.
  final double hairline;

  /// The width the active boundary step ([CoreStrokeWidth.stroke1_5]) draws
  /// at on the screen the theme is drawn on —
  /// [CoreStrokeWidth.activeBoundaryAt] its device pixel ratio.
  ///
  /// Folded in and read the way [hairline] is: the default is the step's own
  /// 1.5, a dense screen's; [atDevicePixelRatio] folds the screen in, and
  /// [stroke] draws it — so an unchecked checkbox or radio frame follows the
  /// screen the way Web's `--coui-stroke-width-1_5` does.
  final double activeBoundary;

  /// How much this brightness multiplies a cast layer's opacity.
  double get _shadowStrength =>
      brightness == CoreBrightness.dark ? CoreShadow.darkStrength : 1;

  /// Whether this constraint leaves geometry untouched.
  ///
  /// Checked before doing any work so the default surface costs nothing and
  /// returns the caller's own instances unchanged.
  bool get isIdentity =>
      _bendsNothingButAlpha &&
      brightness == CoreBrightness.light &&
      hairline == CoreStrokeWidth.stroke0_5 &&
      activeBoundary == CoreStrokeWidth.stroke1_5;

  /// [isIdentity] with the brightness left out — true when the only thing
  /// this constraint changes is how strong a shadow is.
  ///
  /// The corner and inset fast paths read this rather than [isIdentity]:
  /// brightness moves no corner and no inset, so a dark theme on the
  /// default style still hands the caller's own instances back.
  bool get _bendsNothingButAlpha =>
      radiusFloor == null &&
      radiusCap == null &&
      strokeFloor == null &&
      shadowBlurScale == 1 &&
      shadowOffsetScale == 1 &&
      !shadowMirror &&
      highlightRim.isEmpty &&
      shadowOffsetAdd == null &&
      shadowOpacityOverride == null &&
      controlShadow.isEmpty &&
      controlBorder == null &&
      density == CoreDensity.standard;

  /// Moves one corner radius into the style's range, on the shared
  /// ladder.
  ///
  /// Two fixed points, for the same reason [stroke] leaves a zero width
  /// alone: both are statements, not magnitudes. `0` is a deliberately
  /// square corner — a divider, a full-bleed image — and a style that
  /// rounded those would be redrawing decisions it was not asked about.
  /// `9999` means "fully rounded"; it is a sentinel, and a *range* that
  /// pulled it down would turn every pill into a rounded rectangle. A
  /// cap of `0` is different in kind — squaring is absolute, and it
  /// takes the pill with it.
  ///
  /// Between them the value is *redistributed*, not clamped. Clamping
  /// looks equivalent and is not: 93% of authored radii in this
  /// repository are `4`, `8` or `16`, so a floor of 16 would collapse
  /// three distinct steps into one and a chip, a card and a dialog
  /// would come out equally round. Redistribution keeps the ladder the
  /// components actually wrote.
  ///
  /// The result always lands on [CoreRadius.steps]. On Web only ladder
  /// values resolve through the `--coui-radius-*` variables, so an
  /// off-ladder result would emit a literal and quietly drop that
  /// component out of every preset.
  double radius(double px) => _styleRadius(density.radius(px));

  /// [radius] for the style alone, on a value the density has already
  /// moved.
  ///
  /// Density first, then the style. The style's range is a statement about
  /// the material — "no corner sharper than this", "nothing rounder than
  /// that" — and applied last it holds whatever the density did. Applied
  /// first, a compact density could push a claymorphism corner back under
  /// the floor that makes it claymorphism.
  double _styleRadius(double px) {
    if (px <= 0) return 0;
    // Squaring is absolute and takes the pill with it — a hard-edged
    // material has no rounded ends, and that is what this case meant
    // before there was a range.
    if (radiusCap == 0) return 0;
    if (px >= CoreRadius.radius9999) return CoreRadius.radius9999;
    if (radiusFloor == null && radiusCap == null) return px;

    const steps = CoreRadius.steps;
    final last = steps.length - 1;
    final from = _nearestStep(px);
    final low = radiusFloor == null ? 0 : _nearestStep(radiusFloor!);
    final high = radiusCap == null ? last : _nearestStep(radiusCap!);
    final moved = low + (from / last) * (high - low);

    return steps[moved.round().clamp(0, last)];
  }

  /// Applies the cap to all four corners.
  ///
  /// Returns [value] itself when this constraint is identity, so the
  /// default path allocates nothing and equality-based rebuild checks
  /// upstream see the very same instance.
  CoreBorderRadius borderRadius(CoreBorderRadius value) {
    if (_bendsNothingButAlpha) return value;

    return CoreBorderRadius.only(
      topLeft: radius(value.topLeft),
      topRight: radius(value.topRight),
      bottomLeft: radius(value.bottomLeft),
      bottomRight: radius(value.bottomRight),
    );
  }

  /// The spacing step the theme's [density] draws where [px] was authored.
  ///
  /// The surface style states nothing about spacing, so this is the density
  /// alone. Applied before any size scaling, like every value here: it
  /// says where on the scale a value sits, not how many pixels it covers.
  double space(double px) => density.space(px);

  /// [space] on every side of [value].
  ///
  /// Returns [value] itself when this constraint is identity, so the default
  /// path allocates nothing — the same contract as [borderRadius].
  /// Directionality is preserved: a directional value stays directional.
  CoreEdgeInsets insets(CoreEdgeInsets value) {
    if (_bendsNothingButAlpha) return value;

    return value.copyWith(
      left: space(value.left),
      top: space(value.top),
      right: space(value.right),
      bottom: space(value.bottom),
    );
  }

  /// The height the theme's [density] draws for a control row authored at
  /// [px] — see `CoreDensity.controlHeight` for which values that is.
  double controlHeight(double px) => density.controlHeight(px);

  /// This constraint at [value] — itself when the density already is
  /// [value], so a theme that never states one keeps the preset instance.
  CoreSurfaceGeometryConstraint atDensity(CoreDensity value) =>
      value == density ? this : copyWith(density: value);

  /// This constraint at [value] — itself when the brightness already is
  /// [value], so a light theme keeps the preset instance.
  CoreSurfaceGeometryConstraint atBrightness(CoreBrightness value) =>
      value == brightness ? this : copyWith(brightness: value);

  /// This constraint on a screen of [devicePixelRatio] — itself when the
  /// hairline and the active boundary already draw at the widths that
  /// screen gives them.
  CoreSurfaceGeometryConstraint atDevicePixelRatio(double devicePixelRatio) {
    final hairlineWidth = CoreStrokeWidth.hairlineAt(devicePixelRatio);
    final activeBoundaryWidth = CoreStrokeWidth.activeBoundaryAt(
      devicePixelRatio,
    );

    return hairlineWidth == hairline && activeBoundaryWidth == activeBoundary
        ? this
        : copyWith(
            hairline: hairlineWidth,
            activeBoundary: activeBoundaryWidth,
          );
  }

  /// Applies the floor to a border width, after [scaling] — the two steps
  /// with half a pixel in them first drawn at the screen's width for them
  /// ([hairline], [activeBoundary]).
  ///
  /// Two behaviours that are easy to get wrong and are therefore fixed
  /// here rather than at each call site:
  ///
  /// A width of zero stays zero. Several variants express "no border" by
  /// collapsing the width, and a preset that raised those to its floor
  /// would draw borders on the components that had deliberately removed
  /// them — including the transparent-border collapse that exists so an
  /// invisible border does not eat layout.
  ///
  /// The floor is applied *after* scaling, not before. Applied before, a
  /// theme scaling below 1 would shrink the floored width back under the
  /// floor, so the preset's minimum would hold on some devices and not
  /// others.
  double stroke(double px, {double scaling = 1}) {
    if (px == 0) return 0;
    // The half-pixel steps draw at the width the screen gives them — one
    // whole pixel where the half would be a sub-pixel row — before anything
    // else bends them, as Web's variables do before a style's floor.
    final drawn = switch (px) {
      CoreStrokeWidth.stroke0_5 => hairline,
      CoreStrokeWidth.stroke1_5 => activeBoundary,
      _ => px,
    };
    final scaled = drawn * scaling;

    return strokeFloor == null ? scaled : math.max(scaled, strokeFloor!);
  }

  /// Applies the shadow transform to a whole stack.
  ///
  /// Pure: it bends what a component authored and never substitutes. An
  /// empty stack comes back empty — a component that wants the style's
  /// injected cast reads [controlShadow] itself.
  ///
  /// Returns [value] itself when nothing about shadows changes, so a style
  /// that only squares corners does not rebuild every stack it passes.
  ///
  /// Spread is deliberately untouched. Blur and offset describe how the
  /// light falls; spread changes the size of the shape being cast, and
  /// scaling it would make a heavy style quietly grow its components.
  ///
  /// Opacity meets two axes here, in this order: the style's
  /// [shadowOpacityOverride] *replaces* it, then the [brightness]
  /// *multiplies* it and caps it at 1. The multiplier comes last so the
  /// dark still strengthens a stated opacity; a hard-edged style that
  /// states 1 stays 1. Mirror twins copy the result, so a twin is as
  /// strong as the layer it follows.
  List<CoreShadowLayer> shadow(List<CoreShadowLayer> value) {
    // A component that authors nothing gets nothing back. The injected
    // cast used to be substituted here, which made it reach whatever
    // happened to resolve empty — on one platform only, because the other
    // reaches `controlShadow` through an explicit variable. Components
    // that want it now read [controlShadow] directly, so the set that
    // gets boxed is stated rather than incidental.
    if (value.isEmpty) return value;

    if (shadowBlurScale == 1 &&
        shadowOffsetScale == 1 &&
        !shadowMirror &&
        shadowOffsetAdd == null &&
        shadowOpacityOverride == null &&
        brightness == CoreBrightness.light) {
      return value;
    }

    final add = shadowOffsetAdd;
    final opacity = shadowOpacityOverride;
    final strength = _shadowStrength;
    final scaled = [
      for (final l in value)
        (
          offsetX: l.offsetX * shadowOffsetScale + (add?.dx ?? 0),
          offsetY: l.offsetY * shadowOffsetScale + (add?.dy ?? 0),
          blurRadius: l.blurRadius * shadowBlurScale,
          spreadRadius: l.spreadRadius,
          opacity: math.min<double>(1, (opacity ?? l.opacity) * strength),
          inset: l.inset,
        ),
    ];
    if (!shadowMirror) return scaled;

    // The twin follows its layer rather than being appended after the
    // whole stack, so a two-layer shadow keeps each pair adjacent and
    // composites in the order the author wrote.
    return [
      for (final l in scaled) ...[
        l,
        // Inset layers describe light inside the shape. Mirroring one
        // would put a cast shadow where a highlight was asked for, so
        // they pass through with no twin.
        if (!l.inset)
          (
            // `0 - x` rather than `-x`: negating a zero offset yields
            // negative zero, which survives all the way into the emitted
            // CSS as `-0rem`. Valid, and noise.
            offsetX: 0 - l.offsetX,
            offsetY: 0 - l.offsetY,
            blurRadius: l.blurRadius,
            spreadRadius: l.spreadRadius,
            opacity: l.opacity,
            inset: l.inset,
          ),
      ],
    ];
  }

  /// The [brightness] part of [shadow] alone, for a cast the style
  /// contributes outright ([controlShadow]).
  ///
  /// A contributed cast is not a component's authored stack — nothing in it
  /// is there to bend — but it is still a shadow on the page, and the dark
  /// draws it as strongly as every other one. Highlights (the rim, a bevel)
  /// are light, not shadow, and never pass through here.
  ///
  /// Returns [value] itself on a light theme.
  List<CoreShadowLayer> strengthen(List<CoreShadowLayer> value) {
    if (value.isEmpty || brightness == CoreBrightness.light) return value;
    final strength = _shadowStrength;

    return [
      for (final l in value)
        (
          offsetX: l.offsetX,
          offsetY: l.offsetY,
          blurRadius: l.blurRadius,
          spreadRadius: l.spreadRadius,
          opacity: math.min<double>(1, l.opacity * strength),
          inset: l.inset,
        ),
    ];
  }

  /// Creates a copy with modified values.
  CoreSurfaceGeometryConstraint copyWith({
    double? radiusFloor,
    double? radiusCap,
    double? strokeFloor,
    double? shadowBlurScale,
    double? shadowOffsetScale,
    bool? shadowMirror,
    List<CoreShadowLayer>? highlightRim,
    ({double dx, double dy})? shadowOffsetAdd,
    double? shadowOpacityOverride,
    List<CoreShadowLayer>? controlShadow,
    double? controlBorder,
    CoreDensity? density,
    CoreBrightness? brightness,
    double? hairline,
    double? activeBoundary,
  }) {
    return CoreSurfaceGeometryConstraint(
      radiusFloor: radiusFloor ?? this.radiusFloor,
      radiusCap: radiusCap ?? this.radiusCap,
      strokeFloor: strokeFloor ?? this.strokeFloor,
      shadowBlurScale: shadowBlurScale ?? this.shadowBlurScale,
      shadowOffsetScale: shadowOffsetScale ?? this.shadowOffsetScale,
      shadowMirror: shadowMirror ?? this.shadowMirror,
      highlightRim: highlightRim ?? this.highlightRim,
      shadowOffsetAdd: shadowOffsetAdd ?? this.shadowOffsetAdd,
      shadowOpacityOverride:
          shadowOpacityOverride ?? this.shadowOpacityOverride,
      controlShadow: controlShadow ?? this.controlShadow,
      controlBorder: controlBorder ?? this.controlBorder,
      density: density ?? this.density,
      brightness: brightness ?? this.brightness,
      hairline: hairline ?? this.hairline,
      activeBoundary: activeBoundary ?? this.activeBoundary,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceGeometryConstraint &&
          radiusFloor == other.radiusFloor &&
          radiusCap == other.radiusCap &&
          strokeFloor == other.strokeFloor &&
          shadowBlurScale == other.shadowBlurScale &&
          shadowOffsetScale == other.shadowOffsetScale &&
          shadowMirror == other.shadowMirror &&
          shadowOffsetAdd == other.shadowOffsetAdd &&
          shadowOpacityOverride == other.shadowOpacityOverride &&
          _sameRim(highlightRim, other.highlightRim) &&
          controlBorder == other.controlBorder &&
          _sameRim(controlShadow, other.controlShadow) &&
          density == other.density &&
          brightness == other.brightness &&
          hairline == other.hairline &&
          activeBoundary == other.activeBoundary;

  @override
  int get hashCode => Object.hash(
    radiusFloor,
    radiusCap,
    strokeFloor,
    shadowBlurScale,
    shadowOffsetScale,
    shadowMirror,
    shadowOffsetAdd,
    shadowOpacityOverride,
    Object.hashAll(highlightRim),
    Object.hashAll(controlShadow),
    controlBorder,
    density,
    brightness,
    hairline,
    activeBoundary,
  );

  /// The index on [CoreRadius.steps] closest to [px].
  ///
  /// A reverse lookup from value to scale position, which
  /// `core/design-tokens.md` discourages — under the exception it names:
  /// the source type has lost the key. [CoreBorderRadius] carries four
  /// raw doubles and no token, so there is nothing else to read.
  static int _nearestStep(double px) {
    const steps = CoreRadius.steps;
    var best = 0;
    for (var i = 1; i < steps.length; i++) {
      if ((steps[i] - px).abs() < (steps[best] - px).abs()) best = i;
    }

    return best;
  }
}

/// List equality for rim stacks.
///
/// A theme axis that swaps one rim for another has to be seen as a new
/// value, and identity comparison on a freshly built list would say the
/// two are different every rebuild while saying two equal literals are
/// different too.
bool _sameRim(List<CoreShadowLayer> a, List<CoreShadowLayer> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}

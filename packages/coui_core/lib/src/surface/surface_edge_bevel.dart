import 'dart:math' as math;

import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// The wall that makes a surface's edge a thickness rather than a line —
/// stated as a light and a depth, the way a designer states it.
///
/// ## Why this is two numbers and not four layers
///
/// The layers this produces were authored by hand first: four inset shadows
/// with offsets and alphas tuned against a screen. They worked, and nobody
/// could read them — the numbers said where crescents landed, not that the
/// light came from the upper left. Worse, "move the light" meant editing
/// four offsets consistently, which is the kind of edit that goes half-done.
///
/// A light has an angle and a strength. Those are the two things the Figma
/// panel this material is modelled on exposes, so they are the two things
/// stated here, and the layers are derived. A designer reading a Figma file
/// and a developer reading this recipe now compare the same numbers.
///
/// ## Why the derivation is in Core rather than in each renderer
///
/// Both platforms already draw a list of inset layers — Flutter through its
/// shared cut-out painter, the Web through the band element's `box-shadow` —
/// so the cheapest place to put the trigonometry is the one place that feeds
/// both. Deriving it twice would be the same duplication that let the two
/// refraction implementations disagree about direction, falloff and
/// magnitude at once.
@immutable
class CoreSurfaceEdgeBevel {
  /// Creates an edge bevel.
  const CoreSurfaceEdgeBevel({
    required this.thickness,
    required this.lightAngle,
    required this.lightIntensity,
    this.lightAngleInDarkMode,
    this.glowSpread = 0,
    this.rimWidth = 0,
    this.rimIntensity = 0,
  }) : assert(
         rimWidth >= 0,
         'A rim is a stroke along the contour; it has a width or it is not '
         'drawn.',
       ),
       assert(
         rimIntensity >= 0 && rimIntensity <= 1,
         'The rim intensity is a fraction of full strength.',
       ),
       assert(
         thickness >= 0,
         'A negative thickness would put the lit crescent on the far side, '
         'which is a light from the other direction — say that with the '
         'angle.',
       ),
       assert(
         lightIntensity >= 0 && lightIntensity <= 1,
         'The intensity is a fraction of full strength.',
       ),
       assert(
         glowSpread >= 0,
         'The interior glow reaches inward by this much; negative has no '
         'direction to reach in.',
       );

  /// How far the wall stands proud of the face, in logical pixels.
  ///
  /// Small on purpose — this is the near side of an edge, not a border. Two
  /// pixels already reads as a bevel because the light falls off across it;
  /// ten reads as a frame.
  final double thickness;

  /// Where the light comes *from*, in degrees clockwise from the top.
  ///
  /// Zero is directly above, ninety is from the right, and negative is
  /// counter-clockwise — so the upper left is `-45`, which is the same
  /// number the panel this models would show for the same look.
  ///
  /// Stated as where light comes from rather than where it goes because
  /// that is how every lighting control a designer touches is stated, and
  /// the inversion belongs in one derivation rather than in each reader's
  /// head.
  ///
  /// This is the angle for both modes unless [lightAngleInDarkMode] states
  /// one of its own. Read it through [lightAngleFor], or collapse the bevel
  /// with [atBrightness] once and read this: both ask the question a
  /// renderer actually has, which is where the light is in the mode it is
  /// drawing.
  final double lightAngle;

  /// Where the light comes from while the dark palette is active, in the
  /// same degrees as [lightAngle], or null for the same angle.
  ///
  /// ## Why the angle can differ at all
  ///
  /// The wall and the rim are drawn in the palette's surface highlight, and
  /// that slot is a white in light and a light grey in dark — the one colour
  /// brighter than the surface in both modes. A highlight on a near-black
  /// surface reads as a thin bright line wherever it lands, so the angle
  /// that keeps the crest on the corner arc in light can put a dark panel's
  /// brightest glint on an edge that reads as a border. A material that
  /// sees this states the dark angle; everything else keeps one light.
  ///
  /// A deviation rather than a second required number, for the reason
  /// `CoreSurfaceToken.saturationInDarkMode` gives: one angle has always
  /// been right for both modes, and null is the answer every shipped
  /// material gives.
  ///
  /// Both the wall ([toLayers]) and the rim ([rimSweep]) are derived from
  /// the collapsed angle, so they cannot be lit from two directions.
  final double? lightAngleInDarkMode;

  /// How strong that light is, 0 to 1.
  final double lightIntensity;

  /// How far the light that got *through* the edge reaches into the face.
  ///
  /// Zero draws only the edges. Without this the wall reads as a sticker on
  /// a flat panel; with it the face reads as lying below the rim.
  final double glowSpread;

  /// Width of the lit crest along the contour, in logical pixels. Zero
  /// draws no rim.
  ///
  /// ## What this is that the crescents are not
  ///
  /// The inset layers above are soft: a blurred crescent that says *there
  /// is a wall here*. The reference this material is modelled on has a
  /// second thing at the same edge — a thin bright line that runs along
  /// the whole contour and is brightest exactly where the outline faces
  /// the light, which on a rounded shape is the corner arcs. That is a
  /// specular reflection off the crest of the wall, and a blurred crescent
  /// cannot produce it: blur is what makes it soft, and it is offset,
  /// which is what keeps it off the corners.
  ///
  /// So the rim is stated as a stroke whose brightness is a function of
  /// the contour's normal — see [rimAlphaAt] — and both platforms draw
  /// that function around the same shape. It is why the band's corners
  /// glow on a pill and stay quiet on a square.
  final double rimWidth;

  /// How bright the rim is where the contour faces the light head-on,
  /// 0 to 1. The rest of the contour falls off from here.
  final double rimIntensity;

  /// The far side's share of the near side's strength.
  ///
  /// Not zero, because an edge lit from one side only reads as a shadow
  /// rather than as a thickness — a real bevel catches some light all the
  /// way round. Not equal either: equal sides are a uniform ring, which is
  /// what a rim is and this is not.
  ///
  /// Measured on a screen against a photographic backdrop rather than
  /// derived; the number that separated "thickness" from "outline" sat
  /// around here and the window was wide.
  static const double counterShare = 0.4;

  /// The interior glow's share, for the same reason and by the same method.
  static const double glowShare = 0.73;

  /// How quickly the rim falls off away from the light.
  ///
  /// The exponent of the specular lobe. One is a plain cosine and lights
  /// half the contour evenly; higher concentrates the highlight on the
  /// arc that faces the light. Two keeps the straight edges lit at about
  /// half the corner's strength, which is where a pill reads as one lit
  /// object rather than as four separate glints.
  static const double rimSharpness = 2;

  /// How many samples each corner arc gets in [rimSweep].
  ///
  /// The straight edges need none — their normal is constant, so the two
  /// arc ends that bracket them carry the whole edge by interpolation.
  /// The arcs are where the normal turns, and this is enough for the
  /// lobe to read as a curve rather than as a polyline.
  static const int rimArcSamples = 9;

  /// Whether the rim draws at all.
  bool get drawsRim => rimWidth > 0 && rimIntensity > 0;

  /// Where the light comes from while drawing in [brightness].
  double lightAngleFor(CoreBrightness brightness) =>
      brightness == CoreBrightness.dark
      ? lightAngleInDarkMode ?? lightAngle
      : lightAngle;

  /// Whether the light is stated per mode, so a seat can skip asking which
  /// mode it is in when it is not.
  bool get statesByMode => lightAngleInDarkMode != null;

  /// This bevel as it is lit in [brightness]: the angle collapsed into
  /// [lightAngle], with no per-mode statement left.
  ///
  /// Returns this very instance when the light is not stated per mode, so a
  /// seat that collapses every bevel it draws allocates nothing for the
  /// styles that never ask.
  CoreSurfaceEdgeBevel atBrightness(CoreBrightness brightness) {
    if (!statesByMode) return this;

    return relit(angle: lightAngleFor(brightness));
  }

  /// This bevel lit from [angle] in light and, when given, from
  /// [angleInDarkMode] in dark.
  ///
  /// Not [copyWith]: a null dark angle here **clears** a dark statement,
  /// which is the whole point — the copy that keeps the old dark angle when
  /// it is asked for a new light one lights a scene from two directions.
  /// Every other term is carried, and a field added to this class is added
  /// here beside its constructor rather than in a caller that enumerates it.
  CoreSurfaceEdgeBevel relit({
    required double angle,
    double? angleInDarkMode,
  }) => CoreSurfaceEdgeBevel(
    thickness: thickness,
    lightAngle: angle,
    lightAngleInDarkMode: angleInDarkMode,
    lightIntensity: lightIntensity,
    glowSpread: glowSpread,
    rimWidth: rimWidth,
    rimIntensity: rimIntensity,
  );

  /// The rim's opacity where the contour's outward normal points at
  /// [normalAngle] — degrees clockwise from the top, the same convention
  /// [lightAngle] uses.
  ///
  /// A specular lobe: full strength where the normal faces the light,
  /// falling off by [rimSharpness], with the far side catching
  /// [counterShare] of it so the rim runs all the way round the way a real
  /// edge does. The same function both renderers evaluate, so the rim
  /// cannot peak on one platform's corner and another's edge.
  double rimAlphaAt(double normalAngle) {
    if (!drawsRim) return 0;

    final lit = math.cos((normalAngle - lightAngle) * math.pi / 180);
    final near = math.pow(math.max(0, lit), rimSharpness).toDouble();
    final far = math.pow(math.max(0, -lit), rimSharpness).toDouble();

    return rimIntensity * (near + (far * counterShare));
  }

  /// The rim around a rounded rectangle of [width] by [height] with a
  /// corner [radius], as stops for a sweep about the box's centre.
  ///
  /// Each stop is the sweep angle of a point on the contour — degrees
  /// clockwise from the top — and the rim's opacity there. The list runs
  /// from 0 to 360 inclusive, non-decreasing, so a renderer can hand it to
  /// a sweep gradient (Flutter) or a conic gradient (CSS) as it is.
  ///
  /// Sampled along the contour rather than at even angles, because the
  /// place that matters — the corner arc — occupies almost no sweep on a
  /// wide bar with a small radius, and an even sweep would step straight
  /// over it. Every arc gets [rimArcSamples] stops; every straight edge is
  /// carried by the arc ends that bracket it, because its normal is
  /// constant. A square corner collapses its arc to one angle with the
  /// two edges' opacities on either side of it, which is the hard step a
  /// square corner actually has.
  ///
  /// Sweep and normal are different angles. On a straight edge every
  /// point has the same normal and a different sweep, and the mapping
  /// between them is exactly what the renderers must not each decide for
  /// themselves — so it is decided here, once.
  ///
  /// Lit from [lightAngle], like [toLayers]: collapse a per-mode bevel with
  /// [atBrightness] first.
  List<({double angle, double alpha})> rimSweep({
    required double width,
    required double height,
    required double radius,
  }) {
    if (!drawsRim || width <= 0 || height <= 0) return const [];

    final halfWidth = width / 2;
    final halfHeight = height / 2;
    final corner = radius.clamp(
      0.0,
      halfWidth < halfHeight ? halfWidth : halfHeight,
    );

    double sweepOf(double x, double y) {
      // Screen coordinates, y down; clockwise from the top.
      final degrees = math.atan2(x, -y) * 180 / math.pi;

      return degrees < 0 ? degrees + 360 : degrees;
    }

    final stops = <({double angle, double alpha})>[
      (angle: 0, alpha: rimAlphaAt(0)),
    ];
    // Corner centres in clockwise order from the top-right, each with the
    // normal range its arc turns through.
    final corners = <({double cx, double cy, double from})>[
      (cx: halfWidth - corner, cy: -(halfHeight - corner), from: 0),
      (cx: halfWidth - corner, cy: halfHeight - corner, from: 90),
      (cx: -(halfWidth - corner), cy: halfHeight - corner, from: 180),
      (cx: -(halfWidth - corner), cy: -(halfHeight - corner), from: 270),
    ];
    var last = 0.0;
    for (final c in corners) {
      for (var i = 0; i < rimArcSamples; i++) {
        final normal = c.from + (90 * i / (rimArcSamples - 1));
        final radians = normal * math.pi / 180;
        final x = c.cx + (corner * math.sin(radians));
        final y = c.cy - (corner * math.cos(radians));
        var angle = sweepOf(x, y);
        // The top-left arc's last point sits on the top edge, whose sweep
        // is 0 — read as 360 here so the list stays monotonic and the
        // closing stop below lands after it.
        if (angle < last) angle = 360;
        last = angle;
        stops.add((angle: angle, alpha: rimAlphaAt(normal)));
      }
    }
    if (last < 360) stops.add((angle: 360, alpha: rimAlphaAt(0)));

    return stops;
  }

  /// The direction light travels, as a unit vector in screen coordinates.
  ///
  /// Screen coordinates put y downward, so a light from above travels with
  /// positive y — which is why an inset layer offset downward lights the
  /// *top* edge. That inversion is the whole reason this is derived in one
  /// place instead of being spelled out per layer.
  ({double dx, double dy}) get _travel {
    final radians = lightAngle * math.pi / 180;

    return (dx: -math.sin(radians), dy: math.cos(radians));
  }

  /// The inset layers this bevel draws, in paint order.
  ///
  /// Both platforms consume this rather than the fields above, so a change
  /// to the derivation moves them together by construction.
  ///
  /// Lit from [lightAngle]: a bevel that states a dark angle is collapsed
  /// with [atBrightness] first, which is what both seats do before they
  /// ask.
  List<CoreShadowLayer> toLayers() {
    if (thickness <= 0 || lightIntensity <= 0) return const [];

    final travel = _travel;
    // Held tight to its own edge. A blur wide enough to be soft without this
    // washes across the whole face and stops reading as an edge at all.
    final blur = thickness * 0.67;
    final tuck = -thickness / 3;

    return [
      (
        offsetX: travel.dx * thickness,
        offsetY: travel.dy * thickness,
        blurRadius: blur,
        spreadRadius: tuck,
        opacity: lightIntensity,
        inset: true,
      ),
      (
        offsetX: -travel.dx * thickness,
        offsetY: -travel.dy * thickness,
        blurRadius: blur,
        spreadRadius: tuck,
        opacity: lightIntensity * counterShare,
        inset: true,
      ),
      if (glowSpread > 0)
        (
          offsetX: 0,
          offsetY: 0,
          blurRadius: glowSpread,
          spreadRadius: -glowSpread / 3,
          opacity: lightIntensity * glowShare,
          inset: true,
        ),
    ];
  }

  /// Creates a copy with modified values.
  CoreSurfaceEdgeBevel copyWith({
    double? thickness,
    double? lightAngle,
    double? lightAngleInDarkMode,
    double? lightIntensity,
    double? glowSpread,
    double? rimWidth,
    double? rimIntensity,
  }) => .new(
    thickness: thickness ?? this.thickness,
    lightAngle: lightAngle ?? this.lightAngle,
    lightAngleInDarkMode: lightAngleInDarkMode ?? this.lightAngleInDarkMode,
    lightIntensity: lightIntensity ?? this.lightIntensity,
    glowSpread: glowSpread ?? this.glowSpread,
    rimWidth: rimWidth ?? this.rimWidth,
    rimIntensity: rimIntensity ?? this.rimIntensity,
  );

  /// Serializes this bevel to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'thickness': thickness,
    'lightAngle': lightAngle,
    if (lightAngleInDarkMode != null)
      'lightAngleInDarkMode': lightAngleInDarkMode,
    'lightIntensity': lightIntensity,
    'glowSpread': glowSpread,
    'rimWidth': rimWidth,
    'rimIntensity': rimIntensity,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceEdgeBevel &&
          thickness == other.thickness &&
          lightAngle == other.lightAngle &&
          lightAngleInDarkMode == other.lightAngleInDarkMode &&
          lightIntensity == other.lightIntensity &&
          glowSpread == other.glowSpread &&
          rimWidth == other.rimWidth &&
          rimIntensity == other.rimIntensity;

  @override
  int get hashCode => Object.hash(
    thickness,
    lightAngle,
    lightAngleInDarkMode,
    lightIntensity,
    glowSpread,
    rimWidth,
    rimIntensity,
  );

  @override
  String toString() =>
      'CoreSurfaceEdgeBevel(thickness: $thickness, light: $lightAngle° '
      '${lightAngleInDarkMode == null ? '' : '(dark $lightAngleInDarkMode°) '}'
      'at $lightIntensity, glow: $glowSpread, rim: $rimWidth at '
      '$rimIntensity)';
}

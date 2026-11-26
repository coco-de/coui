/// The silhouette two surfaces make while one becomes the other.
///
/// A panel that opens out of its trigger reads as liquid when the two are
/// briefly one shape with a neck between them, rather than as a box that
/// fades in over a button. The neck is not drawn — it *emerges* from
/// merging two signed-distance fields with a smooth minimum, which is why
/// there is no geometry here describing one.
///
/// ## Why this is arithmetic and not a shader
///
/// The reference implementations of this effect run the merge in a fragment
/// shader, which on Flutter means `ImageFilter.shader` and therefore an
/// Impeller gate, a Skia fallback, and a quality tier. This repo does not
/// need any of that, because it is not asking the shader for glass — the
/// glass already exists, painted by the surface material. What is missing
/// is only the *shape*.
///
/// So the merge happens here, on the CPU, in platform-neutral Dart, and
/// each platform carves its existing glass into the result: Flutter with a
/// `ClipPath`, Web with `clip-path: path(…)`. Both were measured to keep
/// the backdrop intact — and on Web the obvious alternative does not: a
/// gooey `filter` on an ancestor establishes a new backdrop root, so the
/// panel samples the filtered ancestor instead of the page and renders
/// opaque.
///
/// The consequence worth stating plainly: the two platforms do not merely
/// agree on a design here, they run the same numbers. A divergence would
/// have to be a divergence in this file.
library;

import 'dart:math' as math;

import 'package:meta/meta.dart';

/// A point in the morph's own coordinate space.
///
/// Platform-neutral because `coui_core` cannot name `Offset` — and because
/// the outline this composes is consumed by a Flutter `Path` and a CSS
/// `path()` string, neither of which should be this file's concern.
@immutable
class CoreMorphPoint {
  /// Creates a point.
  const CoreMorphPoint(this.x, this.y);

  /// Horizontal position.
  final double x;

  /// Vertical position.
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMorphPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'CoreMorphPoint($x, $y)';
}

/// One of the two bodies a morph merges — a rounded rectangle.
///
/// Rounded rather than circular because both ends of a real morph are
/// surfaces: a trigger with the kit's corner radius, and a panel with its
/// own. A circle-only model would make the endpoints wrong in exactly the
/// frames a user looks at longest — the ones where the animation has
/// settled.
@immutable
class CoreMorphBlob {
  /// Creates a blob from its centre, half-extents and corner radius.
  const CoreMorphBlob({
    required this.centerX,
    required this.centerY,
    required this.halfWidth,
    required this.halfHeight,
    this.radius = 0,
  }) : assert(halfWidth >= 0 && halfHeight >= 0, 'extents are magnitudes'),
       assert(radius >= 0, 'a corner radius is a magnitude');

  /// Centre, horizontal.
  final double centerX;

  /// Centre, vertical.
  final double centerY;

  /// Half the width.
  final double halfWidth;

  /// Half the height.
  final double halfHeight;

  /// Corner radius, clamped to the shorter half-extent when sampled.
  final double radius;

  /// Signed distance from [x], [y] to this blob — negative inside.
  ///
  /// The standard rounded-box field: push the point into the first
  /// quadrant, subtract the extents, and measure the corner as a circle.
  double distanceTo(double x, double y) {
    final limit = math.min(halfWidth, halfHeight);
    final r = radius > limit ? limit : radius;
    final qx = (x - centerX).abs() - (halfWidth - r);
    final qy = (y - centerY).abs() - (halfHeight - r);
    final outerX = qx > 0 ? qx : 0.0;
    final outerY = qy > 0 ? qy : 0.0;
    final inner = qx > qy ? qx : qy;

    return math.sqrt((outerX * outerX) + (outerY * outerY)) +
        (inner < 0 ? inner : 0.0) -
        r;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMorphBlob &&
          centerX == other.centerX &&
          centerY == other.centerY &&
          halfWidth == other.halfWidth &&
          halfHeight == other.halfHeight &&
          radius == other.radius;

  @override
  int get hashCode =>
      Object.hash(centerX, centerY, halfWidth, halfHeight, radius);
}

/// The published smoothing coefficient. See [smoothUnion].
const double _kSmoothUnionCoefficient = 0.25;

/// Marching-squares corner bits, clockwise from the top-left.
const int _kTopLeft = 8;
const int _kTopRight = 4;
const int _kBottomRight = 2;
const int _kBottomLeft = 1;

/// Every corner inside. With `0` (every corner outside) these are the two
/// cells the boundary does not pass through.
const int _kAllCorners = _kTopLeft | _kTopRight | _kBottomRight | _kBottomLeft;

/// Merges two signed distances so the surfaces join with a neck.
///
/// The polynomial smooth minimum:
///
/// ```text
/// h = max(k - |d1 - d2|, 0) / k
/// smin = min(d1, d2) - h² · k · 0.25
/// ```
///
/// [smoothness] is the width of the band over which the two fields
/// influence each other. At `0` this is an ordinary union and the two
/// bodies meet at a crease; as it grows they reach for each other and the
/// neck appears before they touch — which is the whole effect.
///
/// The `0.25` is not derived from anything. It is the constant the
/// technique is published with, and it is here rather than in a caller so
/// that two platforms cannot pick different ones.
///
/// ## Its reach is `smoothness / 4`, and that is the number callers need
///
/// The pull is strongest where the two fields agree, and there it is
/// exactly `smoothness · 0.25`. So this bridges a gap of `g` only when
/// `smoothness > 4g` — a blend the width of the gap does nothing visible,
/// which is a surprising amount of nothing for a value that sounds like it
/// should.
///
/// That is why a morph moves its bodies as well as blending them. Reaching
/// across a whole overlay's travel would need a blend several times the
/// panel's size, and a blend that wide does not read as a neck — it reads
/// as the two bodies having been replaced by one balloon. The neck belongs
/// to the frames where the bodies are already close.
double smoothUnion(double d1, double d2, double smoothness) {
  if (smoothness <= 0) return math.min(d1, d2);

  final h = math.max(smoothness - (d1 - d2).abs(), 0) / smoothness;

  return math.min(d1, d2) - (h * h * smoothness * _kSmoothUnionCoefficient);
}

/// Two blobs and how strongly they reach for each other.
@immutable
class CoreLiquidMorphShape {
  /// Creates a shape.
  const CoreLiquidMorphShape({
    required this.anchor,
    required this.panel,
    required this.smoothness,
  }) : assert(smoothness >= 0, 'a blend width is a magnitude');

  /// The body the morph starts from — a trigger.
  final CoreMorphBlob anchor;

  /// The body it becomes — a panel.
  final CoreMorphBlob panel;

  /// Width of the band the two fields blend over. See [smoothUnion].
  final double smoothness;

  /// Signed distance to the merged silhouette — negative inside.
  double distanceTo(double x, double y) => smoothUnion(
    anchor.distanceTo(x, y),
    panel.distanceTo(x, y),
    smoothness,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreLiquidMorphShape &&
          anchor == other.anchor &&
          panel == other.panel &&
          smoothness == other.smoothness;

  @override
  int get hashCode => Object.hash(anchor, panel, smoothness);
}

/// The merged silhouette as a closed outline, in the shape's own space.
///
/// ## Why marching squares and not a formula
///
/// A smooth union has no closed-form boundary — that is the point of it.
/// The neck exists because two fields interfere, and the curve where their
/// interference crosses zero is not expressible as arcs and lines. So the
/// field is sampled on a grid and the zero crossing is walked.
///
/// ## Why the two platforms must share this and not merely agree
///
/// Any two implementations of "trace an isoline" produce slightly
/// different vertex sets, and slightly different is the whole failure mode:
/// the same panel, opening on two platforms, would neck at different rates
/// and nobody would be able to say which was right. Emitting one point list
/// and letting each platform spell it — a `Path` there, a `path()` string
/// here — makes a divergence impossible without editing this function.
///
/// ## What the grid resolution costs and buys
///
/// Cells per axis. The outline is walked once per frame while a morph
/// runs, so this is the knob that decides whether that is affordable. Too
/// coarse and the neck develops in visible steps; too fine and a phone
/// spends its frame budget here rather than on the blur it is also
/// compositing. The default is chosen to keep a cell under a device pixel
/// at the sizes overlays actually open at.
class CoreLiquidMorphOutline {
  const CoreLiquidMorphOutline._(this.contours);

  /// Traces [shape] over the box that contains both its blobs.
  ///
  /// [padding] widens that box, because a smooth union bulges *outside*
  /// both bodies near the join — a box drawn tight to the two rectangles
  /// clips the very feature this exists to produce.
  factory CoreLiquidMorphOutline.of(
    CoreLiquidMorphShape shape, {
    int resolution = defaultResolution,
    double padding = 0,
  }) {
    assert(
      resolution >= minimumResolution,
      'a grid this coarse cannot carry a neck',
    );

    final pad = padding + shape.smoothness;
    final left =
        math.min(
          shape.anchor.centerX - shape.anchor.halfWidth,
          shape.panel.centerX - shape.panel.halfWidth,
        ) -
        pad;
    final right =
        math.max(
          shape.anchor.centerX + shape.anchor.halfWidth,
          shape.panel.centerX + shape.panel.halfWidth,
        ) +
        pad;
    final top =
        math.min(
          shape.anchor.centerY - shape.anchor.halfHeight,
          shape.panel.centerY - shape.panel.halfHeight,
        ) -
        pad;
    final bottom =
        math.max(
          shape.anchor.centerY + shape.anchor.halfHeight,
          shape.panel.centerY + shape.panel.halfHeight,
        ) +
        pad;

    return _trace(shape, left, top, right, bottom, resolution);
  }

  /// The closed outline, in order. Empty when the field never crosses zero
  /// inside the sampled box — which cannot happen for a shape with a body
  /// in it, and is therefore a signal that the caller passed degenerate
  /// The closed loops the walk found, in path order within each loop.
  ///
  /// A list rather than one loop because the silhouette genuinely has two
  /// components for part of the flight: once the neck breaks, the trigger
  /// and the panel are separate closed curves. Returning only the first
  /// one — which is what this did — hands back whichever the grid scan
  /// reached first, and when that was the trigger's the panel was carved
  /// down to a **13 × 7 speck** for a frame. Measured in a browser; no
  /// test saw it, because every test asked whether *a* shape came back.
  ///
  /// Both platforms union subpaths under their default fill rule, so
  /// emitting all of them draws exactly what the field says is there.
  final List<List<CoreMorphPoint>> contours;

  /// Whether the walk found nothing to draw.
  bool get isEmpty => contours.isEmpty;

  /// Cells per axis when the caller does not choose.
  static const int defaultResolution = 96;

  /// Below this a cell is wider than the neck, so the feature the shape
  /// exists for is sampled away before it can be traced.
  static const int minimumResolution = 8;

  /// Two corner distances closer than this are treated as equal, and the
  /// crossing is placed at the midpoint rather than divided by ~zero.
  static const double _kDegenerateSpan = 1e-9;

  /// Half a cell — the midpoint of an edge, and the radius within which
  /// two crossings computed from opposite cells are the same point.
  static const double _kMidpoint = 0.5;

  /// Walks the zero crossing of [shape] over the sampled box.
  ///
  /// Marching squares, reduced to what an outline needs: for each cell the
  /// crossing segments are emitted, then the segments are chained into one
  /// loop. The crossing point on an edge is placed by linear interpolation
  /// of the two corner distances rather than at the midpoint — without
  /// that the outline is visibly faceted at any resolution cheap enough to
  /// run per frame.
  static CoreLiquidMorphOutline _trace(
    CoreLiquidMorphShape shape,
    double left,
    double top,
    double right,
    double bottom,
    int resolution,
  ) {
    final stepX = (right - left) / resolution;
    final stepY = (bottom - top) / resolution;
    if (stepX <= 0 || stepY <= 0) return const CoreLiquidMorphOutline._([]);

    // Sample once. The naive form asks the field four times per cell, and
    // the field is two rounded-box evaluations plus a smooth min — four
    // times per cell is four times the cost for values already computed by
    // the neighbouring cell.
    final grid = List.generate(
      resolution + 1,
      (j) => List.generate(
        resolution + 1,
        (i) => shape.distanceTo(left + (i * stepX), top + (j * stepY)),
        growable: false,
      ),
      growable: false,
    );

    CoreMorphPoint crossing(int i1, int j1, int i2, int j2) {
      final d1 = grid[j1][i1];
      final d2 = grid[j2][i2];
      final span = d1 - d2;
      // Guard the degenerate case rather than dividing by it: two equal
      // distances put the crossing at the midpoint, which is also the
      // limit the interpolation approaches.
      //
      // The clamp is bounds, not correction. An intersection lies between
      // the two samples by definition, so for every edge this function's
      // result is actually *consumed* on — the switch below only pairs
      // edges whose corners differ in sign — `t` is already in range and
      // the clamp changes nothing. It matters for the edges that are
      // computed and then discarded: those can have both corners on the
      // same side, and when `span` sits just above the degenerate guard
      // `t` runs away, putting the point far outside the cell. Today that
      // point is thrown away. The clamp keeps it in the cell so that a
      // future mask case which starts consuming such an edge fails by a
      // grid step instead of by an unbounded jump.
      final t = span.abs() < _kDegenerateSpan
          ? _kMidpoint
          : (d1 / span).clamp(0.0, 1.0);

      return CoreMorphPoint(
        left + ((i1 + ((i2 - i1) * t)) * stepX),
        top + ((j1 + ((j2 - j1) * t)) * stepY),
      );
    }

    final segments = <(CoreMorphPoint, CoreMorphPoint)>[];
    for (var j = 0; j < resolution; j++) {
      for (var i = 0; i < resolution; i++) {
        // Corner mask, clockwise from top-left. Inside is negative.
        var mask = 0;
        if (grid[j][i] < 0) mask |= _kTopLeft;
        if (grid[j][i + 1] < 0) mask |= _kTopRight;
        if (grid[j + 1][i + 1] < 0) mask |= _kBottomRight;
        if (grid[j + 1][i] < 0) mask |= _kBottomLeft;
        if (mask == 0 || mask == _kAllCorners) continue;

        final topEdge = crossing(i, j, i + 1, j);
        final rightEdge = crossing(i + 1, j, i + 1, j + 1);
        final bottomEdge = crossing(i, j + 1, i + 1, j + 1);
        final leftEdge = crossing(i, j, i, j + 1);

        // Each pair is a mask and its complement. A cell with one corner
        // inside and a cell with three produce the same boundary segment —
        // only which side is filled differs, and a closed outline does not
        // care.
        const oneCorner = _kBottomLeft;
        const twoAdjacent = _kBottomLeft | _kBottomRight;
        const twoOpposite = _kTopRight | _kBottomRight;
        switch (mask) {
          case oneCorner || const (_kAllCorners ^ oneCorner):
            segments.add((leftEdge, bottomEdge));
          case _kBottomRight || const (_kAllCorners ^ _kBottomRight):
            segments.add((bottomEdge, rightEdge));
          case twoAdjacent || const (_kAllCorners ^ twoAdjacent):
            segments.add((leftEdge, rightEdge));
          case _kTopRight || const (_kAllCorners ^ _kTopRight):
            segments.add((topEdge, rightEdge));
          case twoOpposite || const (_kAllCorners ^ twoOpposite):
            segments.add((topEdge, bottomEdge));
          case _kTopLeft || const (_kAllCorners ^ _kTopLeft):
            segments.add((leftEdge, topEdge));
          // The ambiguous saddles. Both readings are defensible and they
          // produce different topologies — one joins the bodies, the other
          // pinches them apart. Joining is chosen because this field is a
          // *union*: a saddle here means the two bodies are reaching, and
          // separating them would erase the neck at exactly the frames it
          // is supposed to appear in.
          case const (_kTopRight | _kBottomLeft):
            segments
              ..add((leftEdge, topEdge))
              ..add((bottomEdge, rightEdge));
          case const (_kTopLeft | _kBottomRight):
            segments
              ..add((topEdge, rightEdge))
              ..add((leftEdge, bottomEdge));
        }
      }
    }

    return CoreLiquidMorphOutline._(
      _chainAll(segments, math.min(stepX, stepY)),
    );
  }

  /// Chains unordered segments into every closed loop they form.
  ///
  /// Repeats [_chain] on whatever is left over until nothing is, so a
  /// silhouette that has broken into two bodies comes back as two loops
  /// rather than as whichever one the scan happened to reach first.
  static List<List<CoreMorphPoint>> _chainAll(
    List<(CoreMorphPoint, CoreMorphPoint)> segments,
    double step,
  ) {
    final contours = <List<CoreMorphPoint>>[];
    var remaining = segments;
    while (remaining.isNotEmpty) {
      final (loop, rest) = _chain(remaining, step);
      // A loop of one or two points is a scan artefact, not a shape.
      if (loop.length > 2) contours.add(loop);
      if (rest.length >= remaining.length) break;
      remaining = rest;
    }

    return contours;
  }

  /// Chains unordered segments into one closed loop.
  ///
  /// Marching squares emits segments in grid order, which is not path
  /// order — handing them to a renderer unchained draws a scribble that
  /// happens to cover the right pixels under a non-zero fill and the wrong
  /// ones under any other. The loop is walked by repeatedly taking the
  /// segment whose start is nearest the current end.
  static (List<CoreMorphPoint>, List<(CoreMorphPoint, CoreMorphPoint)>) _chain(
    List<(CoreMorphPoint, CoreMorphPoint)> segments,
    double step,
  ) {
    if (segments.isEmpty) return (const [], const []);

    // Skip the seed rather than removing it — `removeAt` returns the value
    // and mutates in place, and neither is what this needs.
    final remaining = [...segments.skip(1)];
    final seed = segments.first;
    final ordered = [seed.$1, seed.$2];

    // Two crossings computed on the same cell edge from opposite cells are
    // the same point in principle and differ in floating point, so "same
    // point" is a distance question. A cell is the natural scale for it.
    final tolerance = step * _kMidpoint;

    // Walked from both ends, because the seed is wherever the grid scan
    // happened to start — the middle of a contour, not one of its ends.
    // Forward-only, the far half comes back as a *separate* leftover, and
    // once every leftover became its own closed subpath that half was
    // drawn as a spurious loop. Measured in a browser: a silhouette with
    // two bodies was emitting up to five.
    for (final append in [true, false]) {
      while (remaining.isNotEmpty) {
        final tip = append ? ordered.last : ordered.first;
        var bestIndex = -1;
        var bestDistance = double.infinity;
        var bestFlipped = false;

        for (var k = 0; k < remaining.length; k++) {
          final (start, end) = remaining[k];
          final toStart = _distance(tip, start);
          if (toStart < bestDistance) {
            bestDistance = toStart;
            bestIndex = k;
            bestFlipped = false;
          }
          final toEnd = _distance(tip, end);
          if (toEnd < bestDistance) {
            bestDistance = toEnd;
            bestIndex = k;
            bestFlipped = true;
          }
        }

        // Nothing within a cell of the tip means this end of the walk is
        // done — either the loop closed or what is left belongs to a
        // second component. Stop rather than jumping: a jump would draw a
        // line across the gap between two bodies that have not merged yet,
        // which is the one artefact this whole shape exists to avoid.
        if (bestIndex < 0 || bestDistance > tolerance) break;

        final (start, end) = remaining.removeAt(bestIndex);
        final next = bestFlipped ? start : end;
        if (append) {
          ordered.add(next);
        } else {
          ordered.insert(0, next);
        }
      }
    }

    // What is left belongs to another component, and the caller walks it.
    return (ordered, remaining);
  }

  static double _distance(CoreMorphPoint a, CoreMorphPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;

    return math.sqrt((dx * dx) + (dy * dy));
  }
}

// The morph's silhouette, measured rather than eyeballed.
//
// Every assertion here is about a *property of the shape* — is there a
// neck, does it close, does it bulge outward — rather than about the
// numbers a particular resolution happens to produce. Pinning vertices
// would make this a golden file that fails on any tuning and proves
// nothing about whether the effect works.
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

CoreMorphBlob _blob(double cx, {double half = 30, double radius = 12}) =>
    CoreMorphBlob(
      centerX: cx,
      centerY: 60,
      halfWidth: half,
      halfHeight: half,
      radius: radius,
    );

/// Half-width of the merged body at the vertical centre line through [x].
///
/// Measured off the field directly rather than off the traced outline,
/// because a neck is a property of the field and the outline is one
/// sampling of it.
double _halfHeightAt(CoreLiquidMorphShape shape, double x) {
  var inside = 0.0;
  for (var y = 60.0; y < 200; y += 0.25) {
    if (shape.distanceTo(x, y) >= 0) break;
    inside = y - 60;
  }

  return inside;
}

void main() {
  group('the smooth union is the published one', () {
    test('at zero smoothness it is an ordinary minimum', () {
      // The degenerate case has to be exactly `min`, not `min` plus a term
      // that rounds to zero — a caller animating smoothness to 0 would
      // otherwise land on a shape that is almost but not quite the union.
      expect(smoothUnion(3, 7, 0), 3);
      expect(smoothUnion(-2, 5, 0), -2);
    });

    test('it never exceeds the plain minimum', () {
      // Smooth union only ever pulls the surface *outward* (more negative).
      // A positive term here would mean the join eats into both bodies,
      // which is a smooth intersection wearing the wrong name.
      for (final k in const [1.0, 8.0, 40.0]) {
        for (var d1 = -20.0; d1 <= 20; d1 += 3) {
          for (var d2 = -20.0; d2 <= 20; d2 += 3) {
            expect(
              smoothUnion(d1, d2, k),
              lessThanOrEqualTo(d1 < d2 ? d1 : d2),
              reason: 'k=$k d1=$d1 d2=$d2',
            );
          }
        }
      }
    });

    test('and it reaches furthest where the two fields agree', () {
      // The neck forms between the bodies because that is where `|d1-d2|`
      // is smallest. If the maximum pull were anywhere else the join would
      // appear beside the gap rather than in it.
      const k = 10.0;
      final atEqual = smoothUnion(5, 5, k) - 5;
      final atApart = smoothUnion(5, 12, k) - 5;

      expect(atEqual, lessThan(atApart));
      expect(atEqual, closeTo(-k * 0.25, 1e-9));
    });
  });

  group('two bodies make a neck before they touch', () {
    test('a gap that is empty without smoothing is bridged with it', () {
      // The whole effect in one assertion: at this separation the two
      // rounded boxes do not overlap, so a plain union has nothing at the
      // midpoint — and the smooth one does.
      //
      // The gap is 10 and the blend 28, because the pull is `k / 4`: a
      // blend merely as wide as the gap reaches a quarter of the way and
      // changes nothing. 28 is also the top of the range the reference
      // engine animates over, which is not a coincidence — it is what
      // bridges the distances two nearly-touching bodies leave.
      const gapMidpoint = 95.0;
      final apart = CoreLiquidMorphShape(
        anchor: _blob(60),
        panel: _blob(130),
        smoothness: 0,
      );
      final joined = CoreLiquidMorphShape(
        anchor: _blob(60),
        panel: _blob(130),
        smoothness: 28,
      );

      expect(
        apart.distanceTo(gapMidpoint, 60),
        greaterThan(0),
        reason: 'no bridge',
      );
      expect(
        joined.distanceTo(gapMidpoint, 60),
        lessThan(0),
        reason: 'bridged',
      );
    });

    test('and the bridge is narrower than either body — it is a neck', () {
      // Not merely "something is there". A blend wide enough to fill the
      // gap with a slab would also pass the test above while looking like
      // a rectangle, so the shape has to be *pinched* at the midpoint.
      final shape = CoreLiquidMorphShape(
        anchor: _blob(60),
        panel: _blob(130),
        smoothness: 28,
      );

      final atBody = _halfHeightAt(shape, 60);
      final atNeck = _halfHeightAt(shape, 95);

      expect(atNeck, greaterThan(0), reason: 'the neck exists');
      expect(
        atNeck,
        lessThan(atBody * 0.9),
        reason: 'a neck is a pinch, not a slab',
      );
    });

    test('and it thins as the bodies separate', () {
      // The property an animation rides: the neck has to be a continuous
      // function of the distance, or the morph steps rather than stretches.
      double neckAt(double separation) => _halfHeightAt(
        CoreLiquidMorphShape(
          anchor: _blob(60),
          panel: _blob(60 + separation),
          smoothness: 28,
        ),
        60 + (separation / 2),
      );

      final near = neckAt(66);
      final far = neckAt(70);

      expect(near, greaterThan(far));
      expect(far, greaterThan(0));
    });
  });

  group('the outline is a shape a renderer can use', () {
    CoreLiquidMorphShape shape({double smoothness = 28}) =>
        CoreLiquidMorphShape(
          anchor: _blob(60),
          panel: _blob(130),
          smoothness: smoothness,
        );

    test('it closes', () {
      // An open outline fills as a wedge across the gap between the two
      // bodies — the exact artefact this shape exists to avoid.
      final outline = CoreLiquidMorphOutline.of(shape());

      expect(outline.contours, hasLength(1), reason: 'merged is one body');
      final loop = outline.contours.single;
      expect(loop.length, greaterThan(64));
      final first = loop.first;
      final last = loop.last;
      expect(
        (first.x - last.x).abs() + (first.y - last.y).abs(),
        lessThan(6),
        reason: 'the walk did not return to where it started',
      );
    });

    test('every emitted point lands inside the sampled box', () {
      // `crossing()` is called on all four edges of every cell that is not
      // uniform, but only the edges whose corners differ in sign are
      // consumed. On the others both corners sit on the same side, and an
      // interpolation between them is an extrapolation — with `span` just
      // above the degenerate guard it puts the point arbitrarily far from
      // the cell.
      //
      // Those points are discarded today, so this passes with or without
      // the clamp. It is here for the day a new mask case starts consuming
      // an edge like that: without it the failure is a point somewhere off
      // in the plane and an outline that reads as a scribble, which the
      // neighbour test above would catch only by its own step bound. With
      // it the same mistake is off by a grid step.
      for (final smoothness in const [0.0, 1.0, 14.0, 28.0, 40.0]) {
        for (final separation in const [40.0, 70.0, 120.0]) {
          final morph = CoreLiquidMorphShape(
            anchor: _blob(60),
            panel: _blob(60 + separation),
            smoothness: smoothness,
          );
          final pad = smoothness;
          final left = 60 - 30 - pad;
          final right = 60 + separation + 30 + pad;
          final top = 60 - 30 - pad;
          final bottom = 60 + 30 + pad;

          for (final contour in CoreLiquidMorphOutline.of(morph).contours) {
            for (final point in contour) {
              expect(
                point.x,
                inInclusiveRange(left, right),
                reason:
                    'x escaped the sampled box at smoothness $smoothness, '
                    'separation $separation',
              );
              expect(
                point.y,
                inInclusiveRange(top, bottom),
                reason:
                    'y escaped the sampled box at smoothness $smoothness, '
                    'separation $separation',
              );
            }
          }
        }
      }
    });

    test('consecutive points are neighbours, not a scribble', () {
      // Marching squares emits in grid order, which is not path order.
      // Unchained, the point list covers the right pixels under a non-zero
      // fill and the wrong ones under any other — and no assertion about
      // its length would notice.
      final outline = CoreLiquidMorphOutline.of(shape());
      final points = outline.contours.single;

      var longest = 0.0;
      for (var i = 1; i < points.length; i++) {
        final dx = points[i].x - points[i - 1].x;
        final dy = points[i].y - points[i - 1].y;
        final step = (dx * dx) + (dy * dy);
        if (step > longest) longest = step;
      }

      // Two grid cells, generously. A scribble jumps the width of the box.
      expect(longest, lessThan(25 * 25));
    });

    test('it contains the neck the field says is there', () {
      // Ties the outline back to the field. A tracer that lost the neck
      // would still close and still have neighbourly points.
      final outline = CoreLiquidMorphOutline.of(shape());
      final nearMidline = outline.contours
          .expand((c) => c)
          .where(
            (p) => (p.x - 95).abs() < 6,
          );

      expect(nearMidline, isNotEmpty);
      // The neck's own edge, above and below the centre line.
      expect(nearMidline.any((p) => p.y < 60), isTrue);
      expect(nearMidline.any((p) => p.y > 60), isTrue);
    });

    test('and two bodies apart come back as two loops, neither spanning', () {
      // Two separate components are a real state — most of an opening
      // morph, once the neck breaks. Two things must hold, and only one of
      // them used to.
      //
      // Chaining across the gap would draw a bar between them that the
      // field does not contain. **And** returning only the loop the grid
      // scan reached first hands back whichever body that was — measured
      // in a browser, that was the trigger's, and the panel was carved
      // down to a 13 × 7 speck for a frame. Every test at the time asked
      // whether *a* shape came back.
      final split = CoreLiquidMorphOutline.of(shape(smoothness: 0));

      expect(
        split.contours,
        hasLength(2),
        reason:
            'two bodies apart are two loops — no more, no fewer. More '
            'means a contour fragmented and each fragment was closed into '
            'a loop of its own; fewer means one body was dropped.',
      );
      for (final loop in split.contours) {
        var longest = 0.0;
        for (var i = 1; i < loop.length; i++) {
          final dx = loop[i].x - loop[i - 1].x;
          final dy = loop[i].y - loop[i - 1].y;
          final step = (dx * dx) + (dy * dy);
          if (step > longest) longest = step;
        }
        expect(longest, lessThan(25 * 25), reason: 'chained across a gap');
      }

      // And each loop is one of the bodies, not a fragment of one.
      final spans = [
        for (final loop in split.contours)
          loop.map((p) => p.x).reduce(math.max) -
              loop.map((p) => p.x).reduce(math.min),
      ];
      for (final span in spans) {
        expect(span, greaterThan(40), reason: 'a loop is a scan fragment');
      }
    });
  });
}

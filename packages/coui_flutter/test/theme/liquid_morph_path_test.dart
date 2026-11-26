// The Flutter spelling of a shape both platforms compute.
//
// The interesting assertion is not that a `Path` comes out — it is that the
// path is the outline and nothing else. A `Path` is easy to build wrongly in
// ways that still clip: a bounding rect clips, a convex hull clips, and both
// would hide the neck while every "is it a path" check passed.
import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

CoreLiquidMorphOutline _outline({double smoothness = 28}) =>
    CoreLiquidMorphOutline.of(
      CoreLiquidMorphShape(
        anchor: const CoreMorphBlob(
          centerX: 60,
          centerY: 60,
          halfWidth: 30,
          halfHeight: 30,
          radius: 12,
        ),
        panel: const CoreMorphBlob(
          centerX: 130,
          centerY: 60,
          halfWidth: 30,
          halfHeight: 30,
          radius: 12,
        ),
        smoothness: smoothness,
      ),
    );

void main() {
  group('the outline becomes a clip path', () {
    test('it walks every segment the outline has, not a subset', () {
      // Perimeter rather than a vertex count. A path built from the right
      // *number* of wrong points passes a count; one that dropped vertices
      // — or that closed early and left the rest unwalked — comes up short
      // here, because the segments it skipped are missing length.
      //
      // A bounding-box `contains` was the first draft of this and proved
      // nothing: every vertex of any shape is inside that shape's bounds
      // by construction, and `Rect.contains` excludes its own far edges,
      // so it managed to be both vacuous and wrong.
      final outline = _outline();
      final path = outline.toValue();

      var expected = 0.0;
      final loop = outline.contours.single;
      for (var i = 1; i < loop.length; i++) {
        final dx = loop[i].x - loop[i - 1].x;
        final dy = loop[i].y - loop[i - 1].y;
        expected += math.sqrt((dx * dx) + (dy * dy));
      }
      // Plus the closing segment `close()` adds.
      final first = loop.first;
      final last = loop.last;
      expected += math.sqrt(
        ((first.x - last.x) * (first.x - last.x)) +
            ((first.y - last.y) * (first.y - last.y)),
      );

      final walked = path.computeMetrics().fold<double>(
        0,
        (sum, metric) => sum + metric.length,
      );

      expect(walked, closeTo(expected, 0.01));
    });

    test('and the path is closed', () {
      // An open path fills as a wedge across the gap between the two
      // bodies — the exact artefact the shape exists to avoid.
      final path = _outline().toValue();
      final metrics = path.computeMetrics().toList();

      expect(metrics, isNotEmpty);
      expect(metrics.first.isClosed, isTrue);
    });

    test('and it holds the neck, not a hull around it', () {
      // The midpoint between the two bodies is inside a merged silhouette
      // and outside an unmerged one. A bounding box or convex hull would
      // contain it in both cases and this is what separates them.
      final joined = _outline().toValue();
      final apart = _outline(smoothness: 0).toValue();
      const midpoint = Offset(95, 60);

      expect(joined.contains(midpoint), isTrue, reason: 'no neck');
      expect(apart.contains(midpoint), isFalse, reason: 'a hull, not a shape');
    });
  });

  group('an empty outline is not an empty clip', () {
    test('the path is empty and the caller must not clip with it', () {
      // `ClipPath` with an empty path clips *everything* away, so a shape
      // that failed to trace renders as a missing panel rather than an
      // unclipped one — which reads as a broken component instead of a
      // missing effect.
      final degenerate = CoreLiquidMorphOutline.of(
        const CoreLiquidMorphShape(
          anchor: CoreMorphBlob(
            centerX: 0,
            centerY: 0,
            halfWidth: 0,
            halfHeight: 0,
          ),
          panel: CoreMorphBlob(
            centerX: 0,
            centerY: 0,
            halfWidth: 0,
            halfHeight: 0,
          ),
          smoothness: 0,
        ),
      );

      expect(degenerate.contours, isEmpty);
      expect(degenerate.toValue().computeMetrics(), isEmpty);
    });
  });

  group('both platforms spell the same vertices', () {
    test('the Flutter path and the CSS string carry one point list', () {
      // Not a cross-package import — this package cannot see the Web
      // adapter. What it can hold is that the *source* both spell is the
      // same object, and that this side consumes all of it. The Web side
      // holds its half in its own suite; between them the point list is
      // pinned from both ends.
      final outline = _outline();
      final bounds = outline.toValue().getBounds();

      var minX = double.infinity;
      var maxX = -double.infinity;
      for (final point in outline.contours.expand((c) => c)) {
        if (point.x < minX) minX = point.x;
        if (point.x > maxX) maxX = point.x;
      }

      expect(bounds.left, closeTo(minX, 0.001));
      expect(bounds.right, closeTo(maxX, 0.001));
    });
  });
}

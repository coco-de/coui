// The Web spelling of a shape both platforms compute.
//
// The silhouette is Core's. What this file holds is that the Web half
// *spells* it without reinterpreting it — same vertices, same order, no
// smoothing pass of its own. A second interpretation here would make the
// two platforms disagree about a shape neither of them computed twice,
// which is the failure the shared outline exists to prevent.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:test/test.dart';

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
  group('the outline becomes a clip-path', () {
    test('it is a closed path, in the order the walk produced', () {
      final outline = _outline();
      final css = outline.toInlineCss();

      expect(css, startsWith('path("M '));
      expect(css, endsWith(' Z")'));
      // One move, one close, and a line per remaining vertex. A tracer that
      // lost its ordering would still produce a `path()` of the right shape
      // and the wrong outline, so the count is checked against the source
      // rather than against itself.
      expect(
        ' L '.allMatches(css).length,
        outline.contours.single.length - 1,
        reason: 'the spelling dropped or invented vertices',
      );
    });

    test(
      'and its numbers are the outline\'s, not a rounding of a rounding',
      () {
        final outline = _outline();
        final css = outline.toInlineCss();
        final first = outline.contours.single.first;

        expect(
          css,
          contains(
            'M ${first.x.toStringAsFixed(2)} ${first.y.toStringAsFixed(2)}',
          ),
        );
      },
    );

    test('and it carries the neck, not just the two bodies', () {
      // The whole point of the shape. A spelling that emitted only the
      // convex hull, or that clipped to a bounding box, would still be a
      // valid `path()` and would still close.
      final joined = _outline().toInlineCss();
      final apart = _outline(smoothness: 0).toInlineCss();

      expect(joined, isNot(apart));
    });
  });

  group('an empty outline is not an empty path', () {
    test('it produces no value at all', () {
      // The trap: `path("")` clips everything away, so a shape that failed
      // to trace would render as a *missing panel* rather than an
      // unclipped one — and a missing panel looks like a bug in the
      // component rather than in the shape.
      //
      // Returning empty forces the caller to omit the declaration, which
      // is the only safe reading of "there is no shape here".
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
      expect(degenerate.toInlineCss(), isEmpty);
      expect(degenerate.toInlineCss(), isNot(contains('path(')));
    });
  });
}

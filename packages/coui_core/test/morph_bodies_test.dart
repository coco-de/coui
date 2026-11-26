// The one subtraction both platforms make, made once.
//
// Each platform has a trigger rectangle and a panel origin in the same
// space, and rebasing one onto the other looks too small to share — which
// is why it was written twice before this existed. Two copies are free to
// disagree about which space they are in, which corner the origin names,
// or whether the centre was taken before or after the rebase, and the
// symptom of any of those is a neck pointing somewhere empty, on one
// platform, on some placements.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('the bodies land in the panel\'s own coordinates', () {
    test('a panel below its trigger has the trigger above zero', () {
      // The commonest placement, and the one where a sign error is
      // invisible: get it backwards and the neck points down into the
      // panel instead of up out of it, which still renders a shape.
      final bodies = morphBodies(
        triggerCenterX: 400,
        triggerCenterY: 300,
        triggerWidth: 120,
        triggerHeight: 40,
        // 8px below the trigger's bottom edge.
        panelOriginX: 340,
        panelOriginY: 328,
        panelWidth: 240,
        panelHeight: 160,
        radius: 8,
      );

      expect(bodies.anchor.centerX, 60);
      expect(bodies.anchor.centerY, -28);
      expect(bodies.anchor.halfWidth, 60);
      expect(bodies.anchor.halfHeight, 20);
    });

    test('and the panel body is always its own box from the origin', () {
      // Whatever space the caller measured in, the panel's box runs from
      // (0,0) to its size once rebased — so its centre is its half-extent.
      final bodies = morphBodies(
        triggerCenterX: 0,
        triggerCenterY: 0,
        triggerWidth: 10,
        triggerHeight: 10,
        panelOriginX: 1234,
        panelOriginY: -56,
        panelWidth: 240,
        panelHeight: 160,
        radius: 8,
      );

      expect(bodies.panel.centerX, bodies.panel.halfWidth);
      expect(bodies.panel.centerY, bodies.panel.halfHeight);
      expect(bodies.panel.halfWidth, 120);
      expect(bodies.panel.halfHeight, 80);
    });

    test('and only the difference matters, not the space', () {
      // Flutter measures in overlay-local coordinates and the Web in
      // viewport coordinates. That is safe precisely because the origin
      // cancels — and this is the assertion that says so, rather than a
      // comment claiming it.
      final overlayLocal = morphBodies(
        triggerCenterX: 100,
        triggerCenterY: 60,
        triggerWidth: 80,
        triggerHeight: 32,
        panelOriginX: 40,
        panelOriginY: 84,
        panelWidth: 200,
        panelHeight: 120,
        radius: 8,
      );
      const shift = 777.0;
      final viewport = morphBodies(
        triggerCenterX: 100 + shift,
        triggerCenterY: 60 + shift,
        triggerWidth: 80,
        triggerHeight: 32,
        panelOriginX: 40 + shift,
        panelOriginY: 84 + shift,
        panelWidth: 200,
        panelHeight: 120,
        radius: 8,
      );

      expect(viewport.anchor, overlayLocal.anchor);
      expect(viewport.panel, overlayLocal.panel);
    });

    test('and a placement to the side puts the trigger left of zero', () {
      final bodies = morphBodies(
        triggerCenterX: 100,
        triggerCenterY: 200,
        triggerWidth: 60,
        triggerHeight: 30,
        // Panel to the right of the trigger.
        panelOriginX: 138,
        panelOriginY: 140,
        panelWidth: 200,
        panelHeight: 120,
        radius: 8,
      );

      expect(bodies.anchor.centerX, lessThan(0));
      expect(
        bodies.anchor.centerY,
        inInclusiveRange(0, 120),
        reason: 'a side placement should straddle the panel vertically',
      );
    });
  });

  group('an unmeasured body stays unmeasured', () {
    test('a zero trigger produces a zero body, not a small one', () {
      // `ContextMenu` anchors to a point. The clip refuses a zero body on
      // both platforms; this makes sure nothing here quietly inflates one
      // into something the clip would accept.
      final bodies = morphBodies(
        triggerCenterX: 10,
        triggerCenterY: 10,
        triggerWidth: 0,
        triggerHeight: 0,
        panelOriginX: 0,
        panelOriginY: 0,
        panelWidth: 100,
        panelHeight: 100,
        radius: 8,
      );

      expect(bodies.anchor.halfWidth, 0);
      expect(bodies.anchor.halfHeight, 0);
    });
  });
}

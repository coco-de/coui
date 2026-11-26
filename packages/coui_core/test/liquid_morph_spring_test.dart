// The motion, held to what makes it a morph rather than a resize.
//
// The assertions are about *behaviour of the curve* — does it overshoot,
// does a neck open and close on its own, does the tempo knob change tempo
// without changing character. Pinning sampled values would make this a
// golden that breaks on any tuning and says nothing about whether the
// animation reads correctly.
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The spring sampled across its settling time.
List<double> _trace(CoreMorphSpring spring, {int steps = 200}) {
  final settle = spring.settleSeconds();

  return [
    for (var i = 0; i <= steps; i++) spring.at(settle * i / steps),
  ];
}

void main() {
  group('the spring is underdamped, which is the point', () {
    test('it starts at rest and arrives', () {
      const spring = CoreMorphSpring();

      expect(spring.at(0), 0);
      expect(spring.at(-1), 0, reason: 'before release there is no motion');
      expect(spring.at(spring.settleSeconds()), closeTo(1, 0.01));
    });

    test('and it overshoots on the way', () {
      // Without this the panel arrives politely and the whole effect is a
      // resize with a curve on it. The overshoot is what lets the body
      // trail the position and the neck stretch.
      final peak = _trace(
        const CoreMorphSpring(),
      ).reduce((a, b) => a > b ? a : b);

      expect(peak, greaterThan(1.02), reason: 'no overshoot, no morph');
      // And not so far that it reads as a bounce toy.
      expect(peak, lessThan(1.2));
    });

    test('and it settles rather than ringing', () {
      // One visible overshoot, not a series. Counting the crossings is how
      // "settles" is decided without pinning an amplitude.
      final trace = _trace(const CoreMorphSpring());
      var crossings = 0;
      for (var i = 1; i < trace.length; i++) {
        if ((trace[i - 1] - 1).sign != (trace[i] - 1).sign) crossings++;
      }

      expect(crossings, lessThanOrEqualTo(3));
    });

    test('a closing velocity hint changes the departure, not the arrival', () {
      // The recoil on close. It must leave faster without changing where
      // the spring ends up, or a closing morph would settle somewhere other
      // than shut.
      const plain = CoreMorphSpring();
      const kicked = CoreMorphSpring(initialVelocity: -2.5);

      expect(kicked.at(0.02), lessThan(plain.at(0.02)));
      expect(
        kicked.at(kicked.settleSeconds()),
        closeTo(1, 0.01),
        reason: 'the hint moved the target',
      );
    });
  });

  group('the tempo knob changes tempo, not character', () {
    test('faster speeds settle sooner', () {
      final times = [
        for (final speed in CoreMorphSpeed.values)
          CoreMorphSpring(speed: speed).settleSeconds(),
      ];

      for (var i = 1; i < times.length; i++) {
        expect(
          times[i],
          lessThan(times[i - 1]),
          reason: '${CoreMorphSpeed.values[i]} is not faster than its junior',
        );
      }
    });

    test('and every speed still overshoots', () {
      // The damping ratio is shared deliberately. If a speed stopped
      // overshooting it would stop being the same animation played at a
      // different rate — which is what a caller picking a tempo expects.
      for (final speed in CoreMorphSpeed.values) {
        final peak = _trace(
          CoreMorphSpring(speed: speed),
        ).reduce((a, b) => a > b ? a : b);

        expect(peak, greaterThan(1.02), reason: '$speed does not overshoot');
      }
    });

    test('and instant is a tempo, not the reduced-motion answer', () {
      // Measured: `instant` settles in ~0.47s. That is brisk, and it is
      // still an animation — so routing a reduced-motion request here
      // would hand someone who asked for less motion a spring.
      //
      // The kit's answer is elsewhere and it is stronger: a morph is
      // transition-tier motion, which `CoreReducedMotion` suppresses to
      // zero rather than speeding up. This pins the premise that makes
      // that necessary, so the day someone re-tunes `instant` toward zero
      // and decides it is close enough, this says what changed.
      final instant = const CoreMorphSpring(
        speed: CoreMorphSpeed.instant,
      ).settleSeconds();

      expect(instant, greaterThan(0.2));
      expect(
        CoreReducedMotion.isTransitionMotion(
          const Duration(milliseconds: 470),
        ),
        isTrue,
        reason:
            'a morph of this length is transition tier, so it is not '
            'made fast under reduced motion — it does not run',
      );
    });

    test('and each speed speaks the kit spring vocabulary', () {
      // Not a second spring type. An adapter reading `SpringMotion` and a
      // morph reading its own numbers would be two descriptions of one
      // motion, free to drift.
      for (final speed in CoreMorphSpeed.values) {
        expect(speed.motion.stiffness, speed.stiffness);
        expect(speed.motion.dampingRatio, CoreMorphSpeed.dampingRatio);
      }
    });
  });

  group('the silhouette is one blob before it is two', () {
    // Every assertion in this group corresponds to a defect the first
    // model shipped, each measured against real popover geometry.
    const anchor = CoreMorphBlob(
      centerX: 140,
      centerY: -28,
      halfWidth: 60,
      halfHeight: 20,
      radius: 8,
    );
    const panel = CoreMorphBlob(
      centerX: 140,
      centerY: 90,
      halfWidth: 140,
      halfHeight: 90,
      radius: 16,
    );

    /// Whether a point between the two centres is outside both bodies yet
    /// inside the merged field — a bridge someone can see.
    bool bridged(CoreLiquidMorphShape shape) {
      for (var i = 0; i <= 200; i++) {
        final t = i / 200;
        final x =
            shape.anchor.centerX +
            ((shape.panel.centerX - shape.anchor.centerX) * t);
        final y =
            shape.anchor.centerY +
            ((shape.panel.centerY - shape.anchor.centerY) * t);
        final nearest = math.min(
          shape.anchor.distanceTo(x, y),
          shape.panel.distanceTo(x, y),
        );
        if (nearest > 0 && shape.distanceTo(x, y) < 0) return true;
      }

      return false;
    }

    test('the first frame is the trigger, not the finished panel', () {
      // Shipped once. The old gate skipped the walk whenever the blend was
      // zero, and the blend was exactly zero at `t = 0` — so the opening
      // frame rendered the panel at **full size** and the second frame
      // snapped it small. A flash of the destination before the animation.
      final first = morphShapeAt(
        anchor: anchor,
        panel: panel,
        spring: const CoreMorphSpring(),
        seconds: 0,
      );

      expect(first.panel.halfWidth, closeTo(anchor.halfWidth, 0.01));
      expect(first.panel.halfHeight, closeTo(anchor.halfHeight, 0.01));
      expect(
        first.smoothness,
        greaterThan(0),
        reason: 'a zero here is what let the old gate skip the first frame',
      );
    });

    test('and the two bodies stay connected while the trigger is there', () {
      // The defect this replaces: the position curve overshot to 1.17 while
      // the size curve was at 0.44, so the panel arrived at its destination
      // still 44% grown and tore away after ~40ms. For the rest of the
      // flight it was a panel next to an unrelated shrinking dot.
      const spring = CoreMorphSpring();
      final settle = spring.settleSeconds();
      var connectedMs = 0.0;
      final step = settle * 1000 / 200;
      for (var i = 0; i <= 200; i++) {
        final shape = morphShapeAt(
          anchor: anchor,
          panel: panel,
          spring: spring,
          seconds: settle * i / 200,
        );
        final overlapping =
            shape.anchor.distanceTo(shape.panel.centerX, shape.panel.centerY) <
                0 ||
            shape.panel.distanceTo(
                  shape.anchor.centerX,
                  shape.anchor.centerY,
                ) <
                0;
        if (overlapping || bridged(shape)) connectedMs += step;
      }

      expect(
        connectedMs,
        greaterThan(200),
        reason: 'the old model managed 40ms of 955 — a morph nobody can see',
      );
    });

    test('and the neck closes before the trigger does', () {
      // Also shipped. The reach was capped rather than faded, so while the
      // trigger was a sub-pixel speck the union still pulled the panel's
      // near edge 4px out towards it — for the last 400ms — and that bulge
      // popped flat the instant the clip stopped.
      const spring = CoreMorphSpring();
      final settle = spring.settleSeconds();
      double bulgeAt(double seconds) {
        final shape = morphShapeAt(
          anchor: anchor,
          panel: panel,
          spring: spring,
          seconds: seconds,
        );
        final top = shape.panel.centerY - shape.panel.halfHeight;
        var bulge = 0.0;
        for (var i = 1; i <= 40; i++) {
          if (shape.distanceTo(shape.panel.centerX, top - (i / 2)) < 0) {
            bulge = i / 2;
          }
        }

        return bulge;
      }

      // Well before the spring settles, the panel is drawn as itself.
      expect(bulgeAt(settle * 0.5), 0);
      expect(bulgeAt(settle), 0);
    });

    test('and the same tuning works for a tooltip and for a sheet', () {
      // The reason the width is read off the gap rather than fixed: no
      // constant is right for both. The old fixed 28 bridged gaps up to
      // 14px, and a panel's gap grows with the panel.
      const spring = CoreMorphSpring();
      final settle = spring.settleSeconds();
      final geometries = {
        // Both centred under the same trigger, so the only thing that
        // varies is how big the panel is — which is exactly the axis a
        // fixed blend width cannot cover.
        'tooltip': const CoreMorphBlob(
          centerX: 140,
          centerY: 30,
          halfWidth: 70,
          halfHeight: 30,
        ),
        'sheet': const CoreMorphBlob(
          centerX: 140,
          centerY: 210,
          halfWidth: 160,
          halfHeight: 210,
        ),
      };
      for (final entry in geometries.entries) {
        var neckFrames = 0;
        for (var i = 0; i <= 100; i++) {
          if (bridged(
            morphShapeAt(
              anchor: anchor,
              panel: entry.value,
              spring: spring,
              seconds: settle * i / 100,
            ),
          )) {
            neckFrames++;
          }
        }

        expect(
          neckFrames,
          greaterThan(8),
          reason:
              'the neck for a ${entry.key} lasted under two frames — '
              'which is what the fixed 28px width managed',
        );
      }
    });

    test('and a vanished trigger leaves no thread behind', () {
      // A body with no area still has a field, so the union would keep
      // pulling a spike out of the panel towards a trigger that is no
      // longer drawn.
      const gone = CoreMorphBlob(
        centerX: 140,
        centerY: -28,
        halfWidth: 0,
        halfHeight: 0,
      );
      final shape = morphShapeAt(
        anchor: gone,
        panel: panel,
        spring: const CoreMorphSpring(),
        seconds: 0,
      );

      expect(shape.smoothness, 0);
    });
  });
}

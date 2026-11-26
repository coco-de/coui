// What a Drawer panel does when it is dragged past its dock: how far the far
// edge stretches for a pull, where a panel that is let go of is on its way
// back, and that none of it ever changes what dismisses. Pinned by one vector
// table (computed outside Dart) that the Flutter drawer, the Web drawer's
// markup and a real-Chrome probe of the Web drawer are held to as well, so a
// number that changes on one platform fails on the others.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter drawer test, the Web drawer
/// tests and the Chrome drawer probe.
const String kDrawerRubberBandVectorsPath =
    'test/fixtures/drawer_rubber_band_vectors.json';

/// The table is rounded to four decimals; a scale to six.
const double kStretchTolerance = 1e-4;
const double kScaleTolerance = 1e-6;

double _num(Object? value) => (value! as num).toDouble();

List<Map<String, Object?>> _cases(Map<String, Object?> section) =>
    (section['cases']! as List).cast<Map<String, Object?>>();

void main() {
  final doc =
      jsonDecode(File(kDrawerRubberBandVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final constants = doc['constants']! as Map<String, Object?>;
  final stretchCases = _cases(doc['stretch']! as Map<String, Object?>);
  final poseCases = _cases(doc['pose']! as Map<String, Object?>);
  final inverseCases = _cases(doc['inverse']! as Map<String, Object?>);
  final settle = doc['settle']! as Map<String, Object?>;
  final settleCases = _cases(settle);
  final gestures = doc['gestures']! as Map<String, Object?>;
  final gestureCases = _cases(gestures);

  test('the vector tables are not empty', () {
    expect(stretchCases, isNotEmpty);
    expect(poseCases, isNotEmpty);
    expect(inverseCases, isNotEmpty);
    expect(settleCases, isNotEmpty);
    expect(gestureCases, isNotEmpty);
  });

  group('the table is computed with the numbers Core ships', () {
    test('the reach and the tension', () {
      expect(_num(constants['reach']), CoreDrawerRubberBand.defaultReach);
      expect(_num(constants['tension']), CoreDrawerRubberBand.defaultTension);
    });

    test('the return takes the duration and follows the curve Core states', () {
      expect(
        Duration(milliseconds: constants['settleMs']! as int),
        CoreDrawerRubberBand.defaultSettleDuration,
      );
      expect(settle['durationMs'], constants['settleMs']);
      final easing = constants['easing']! as Map<String, Object?>;
      expect(CoreDrawerRubberBand.defaultSettleEasing, (
        x1: _num(easing['x1']),
        y1: _num(easing['y1']),
        x2: _num(easing['x2']),
        y2: _num(easing['y2']),
      ));
    });

    test(
      'the table is stated for a panel at the default release threshold',
      () {
        expect(
          _num(gestures['threshold']),
          CoreDrawerContract.defaultDragDismissThreshold,
        );
      },
    );
  });

  group('CoreDrawerRubberBand.stretchOf against the shared vectors', () {
    for (final c in stretchCases) {
      test(c['name']! as String, () {
        final overshoot = _num(c['overshoot']);
        final extent = _num(c['extent']);
        final stretch = CoreDrawerRubberBand.stretchOf(
          overshoot,
          extent: extent,
        );

        expect(stretch, closeTo(_num(c['stretch']), kStretchTolerance));
        expect(
          CoreDrawerRubberBand.scaleOf(stretch, extent: extent),
          closeTo(_num(c['scale']), kScaleTolerance),
        );
      });
    }
  });

  group('CoreDrawerRubberBand.poseOf against the shared vectors', () {
    for (final c in poseCases) {
      test(c['name']! as String, () {
        final pose = CoreDrawerRubberBand.poseOf(
          _num(c['pull']),
          extent: _num(c['extent']),
        );

        expect(pose.slide, closeTo(_num(c['slide']), kStretchTolerance));
        expect(pose.stretch, closeTo(_num(c['stretch']), kStretchTolerance));
        // At most one of the two is ever drawn.
        expect(pose.slide == 0 || pose.stretch == 0, isTrue);
      });
    }
  });

  group('CoreDrawerRubberBand.overshootOf against the shared vectors', () {
    for (final c in inverseCases) {
      test('${c['stretch']} of ${c['extent']}', () {
        expect(
          CoreDrawerRubberBand.overshootOf(
            _num(c['stretch']),
            extent: _num(c['extent']),
          ),
          closeTo(_num(c['overshoot']), 1e-3),
        );
      });
    }
  });

  group('CoreDrawerRubberBand.settleAt against the shared vectors', () {
    for (final c in settleCases) {
      final from = _num(c['from']);
      for (final sample in (c['samples']! as List).cast<List<Object?>>()) {
        test('$from px, ${sample[0]} ms after the release', () {
          expect(
            CoreDrawerRubberBand.settleAt(
              Duration(milliseconds: (sample[0]! as num).toInt()),
              from: from,
            ),
            closeTo(_num(sample[1]), kStretchTolerance),
          );
        });
      }
    }
  });

  group('the shape of the stretch', () {
    const extents = [120.0, 256.0, 300.0, 600.0, 1000.0];
    const overshoots = [
      0.0,
      0.001,
      1.0,
      5.0,
      12.5,
      30.0,
      60.0,
      100.0,
      250.0,
      500.0,
      1000.0,
      5000.0,
    ];

    test('is zero at no overshoot', () {
      for (final extent in extents) {
        expect(CoreDrawerRubberBand.stretchOf(0, extent: extent), 0);
      }
    });

    test('rises with the overshoot, strictly, at every extent', () {
      for (final extent in extents) {
        var previous = -1.0;
        for (final overshoot in overshoots) {
          final stretch = CoreDrawerRubberBand.stretchOf(
            overshoot,
            extent: extent,
          );
          expect(stretch, greaterThan(previous), reason: '$overshoot/$extent');
          previous = stretch;
        }
      }
    });

    test('gives less for each pixel than the pixel before it', () {
      for (final extent in extents) {
        const step = 4.0;
        var previousGain = double.infinity;
        for (var x = 0.0; x < 2000; x += 40) {
          final gain =
              CoreDrawerRubberBand.stretchOf(x + step, extent: extent) -
              CoreDrawerRubberBand.stretchOf(x, extent: extent);
          expect(gain, lessThan(previousGain), reason: '$x/$extent');
          previousGain = gain;
        }
      }
    });

    test('stays under the fraction of the extent, however far the pointer '
        'goes', () {
      for (final extent in extents) {
        final limit = CoreDrawerRubberBand.defaultReach * extent;
        for (final overshoot in overshoots) {
          expect(
            CoreDrawerRubberBand.stretchOf(overshoot, extent: extent),
            lessThan(limit),
            reason: '$overshoot/$extent',
          );
        }
        // And gets close to it: the bound is the curve's asymptote, not a
        // ceiling the curve never approaches.
        expect(
          CoreDrawerRubberBand.stretchOf(1000000, extent: extent),
          greaterThan(limit * 0.999),
        );
      }
    });

    test('is behind the pointer at every overshoot', () {
      for (final extent in extents) {
        for (final overshoot in overshoots.skip(1)) {
          expect(
            CoreDrawerRubberBand.stretchOf(overshoot, extent: extent),
            lessThan(overshoot),
            reason: '$overshoot/$extent',
          );
        }
      }
    });

    test('starts at the tension: the first pixel moves the edge by that '
        'much', () {
      final stretch = CoreDrawerRubberBand.stretchOf(0.001, extent: 300);

      expect(
        stretch / 0.001,
        closeTo(CoreDrawerRubberBand.defaultTension, 1e-3),
      );
    });

    test('is nothing for a pointer that has not passed the dock', () {
      expect(CoreDrawerRubberBand.stretchOf(-1, extent: 300), 0);
      expect(CoreDrawerRubberBand.stretchOf(-1000000000, extent: 300), 0);
    });

    test('is nothing for a panel with no extent', () {
      expect(CoreDrawerRubberBand.stretchOf(80, extent: 0), 0);
      expect(CoreDrawerRubberBand.stretchOf(80, extent: -10), 0);
    });

    test('scales with the panel: the same pull gives a longer panel more', () {
      final short = CoreDrawerRubberBand.stretchOf(100, extent: 200);
      final long = CoreDrawerRubberBand.stretchOf(100, extent: 600);

      expect(long, greaterThan(short));
    });

    test('follows the reach and the tension it is given', () {
      final base = CoreDrawerRubberBand.stretchOf(80, extent: 300);

      expect(
        CoreDrawerRubberBand.stretchOf(80, extent: 300, reach: 0.2),
        greaterThan(base),
      );
      expect(
        CoreDrawerRubberBand.stretchOf(80, extent: 300, tension: 1),
        greaterThan(base),
      );
      expect(
        CoreDrawerRubberBand.stretchOf(80, extent: 300, tension: 0.2),
        lessThan(base),
      );
      // A smaller reach is a smaller bound, whatever the pull.
      expect(
        CoreDrawerRubberBand.stretchOf(1000000, extent: 300, reach: 0.05),
        lessThan(300 * 0.05),
      );
    });

    test('refuses a reach or a tension that is not a resistance', () {
      expect(
        () => CoreDrawerRubberBand.stretchOf(10, extent: 300, reach: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CoreDrawerRubberBand.stretchOf(10, extent: 300, tension: 0),
        throwsA(isA<AssertionError>()),
      );
      // Above 1 the edge would run ahead of the pointer.
      expect(
        () => CoreDrawerRubberBand.stretchOf(10, extent: 300, tension: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the scale about the docked edge', () {
    test('is 1 with no stretch and grows with it', () {
      expect(CoreDrawerRubberBand.scaleOf(0, extent: 300), 1);
      expect(
        CoreDrawerRubberBand.scaleOf(15, extent: 300),
        closeTo(1.05, 1e-9),
      );
    });

    test('puts the far edge exactly [stretch] px out', () {
      for (final extent in [120.0, 300.0, 777.0]) {
        for (final stretch in [0.5, 7.0, 29.0]) {
          final scale = CoreDrawerRubberBand.scaleOf(stretch, extent: extent);
          expect(extent * scale - extent, closeTo(stretch, 1e-9));
        }
      }
    });

    test('is 1 for a panel with no extent, and never below 1', () {
      expect(CoreDrawerRubberBand.scaleOf(10, extent: 0), 1);
      expect(CoreDrawerRubberBand.scaleOf(-10, extent: 300), 1);
    });
  });

  group("pull and pose are each other's inverse", () {
    test('a stretch reads back to the pull that made it', () {
      for (final pull in [-0.5, -3.0, -12.0, -60.0, -250.0, -900.0]) {
        final pose = CoreDrawerRubberBand.poseOf(pull, extent: 300);

        expect(
          CoreDrawerRubberBand.pullOf(pose, extent: 300),
          closeTo(pull, math.max(1e-6, pull.abs() * 1e-9)),
          reason: '$pull',
        );
      }
    });

    test('a slide reads back to itself', () {
      for (final pull in [0.0, 1.0, 40.0, 299.0, 400.0]) {
        final pose = CoreDrawerRubberBand.poseOf(pull, extent: 300);

        expect(pose.slide, pull);
        expect(CoreDrawerRubberBand.pullOf(pose, extent: 300), pull);
      }
    });

    test('a stretch at the limit has no pull that makes it', () {
      const limit = CoreDrawerRubberBand.defaultReach * 300;

      expect(
        CoreDrawerRubberBand.overshootOf(limit, extent: 300),
        double.infinity,
      );
      expect(
        CoreDrawerRubberBand.overshootOf(limit + 5, extent: 300),
        double.infinity,
      );
    });

    test('nothing stretched needs no overshoot', () {
      expect(CoreDrawerRubberBand.overshootOf(0, extent: 300), 0);
      expect(CoreDrawerRubberBand.overshootOf(-3, extent: 300), 0);
      expect(CoreDrawerRubberBand.overshootOf(5, extent: 0), 0);
    });
  });

  group('the return to the dock', () {
    test('starts where the pointer let go and ends at the dock', () {
      expect(
        CoreDrawerRubberBand.settleAt(Duration.zero, from: 18),
        18,
      );
      expect(
        CoreDrawerRubberBand.settleAt(
          CoreDrawerRubberBand.defaultSettleDuration,
          from: 18,
        ),
        0,
      );
    });

    test('has nothing left after the duration, and nothing happened before '
        'the release', () {
      expect(
        CoreDrawerRubberBand.settleAt(const Duration(seconds: 5), from: 18),
        0,
      );
      expect(
        CoreDrawerRubberBand.settleAt(
          const Duration(milliseconds: -40),
          from: 18,
        ),
        18,
      );
    });

    test('only ever falls, and never crosses the dock', () {
      var previous = double.infinity;
      for (var ms = 0; ms <= 300; ms += 5) {
        final left = CoreDrawerRubberBand.settleAt(
          Duration(milliseconds: ms),
          from: 40,
        );
        expect(left, lessThanOrEqualTo(previous), reason: '$ms ms');
        expect(left, greaterThanOrEqualTo(0), reason: '$ms ms');
        previous = left;
      }
    });

    test('decelerates into the dock: the last stretch of time moves the panel '
        'less than the first', () {
      const from = 40.0;
      final first =
          from -
          CoreDrawerRubberBand.settleAt(
            const Duration(milliseconds: 60),
            from: from,
          );
      final last = CoreDrawerRubberBand.settleAt(
        const Duration(milliseconds: 240),
        from: from,
      );

      expect(last, lessThan(first));
    });

    test('has nothing to return from when nothing is displaced', () {
      expect(CoreDrawerRubberBand.settleAt(Duration.zero, from: 0), 0);
      expect(
        CoreDrawerRubberBand.settleAt(
          const Duration(milliseconds: 100),
          from: -5,
        ),
        0,
      );
    });

    test(
      'is a whole-duration move: a zero duration is already at the dock',
      () {
        expect(
          CoreDrawerRubberBand.settleAt(
            Duration.zero,
            from: 18,
            duration: Duration.zero,
          ),
          0,
        );
      },
    );

    test('is a transition-tier motion, so reduced motion reaches it', () {
      expect(
        CoreReducedMotion.isTransitionMotion(
          CoreDrawerRubberBand.defaultSettleDuration,
        ),
        isTrue,
      );
      expect(
        CoreReducedMotion.resolve(
          CoreDrawerRubberBand.defaultSettleDuration,
          reduce: true,
        ),
        Duration.zero,
      );
      expect(
        CoreDrawerRubberBand.defaultSettleDuration,
        const Duration(milliseconds: CoreDuration.moderate),
      );
    });

    test('follows the arrival easing, so a browser and a framework walk the '
        'same curve', () {
      expect(CoreDrawerRubberBand.defaultSettleEasing, CoreEasing.enter);
    });
  });

  group('a stretch is no distance toward the edge the panel hides behind', () {
    test('only a pull toward that edge counts', () {
      expect(CoreDrawerRubberBand.dismissDistanceOf(40), 40);
      expect(CoreDrawerRubberBand.dismissDistanceOf(0), 0);
      expect(CoreDrawerRubberBand.dismissDistanceOf(-40), 0);
      expect(CoreDrawerRubberBand.dismissDistanceOf(-1000000000), 0);
    });

    test('never dismisses, whatever the speed or the extent', () {
      for (final pull in [-1.0, -30.0, -250.0, -5000.0]) {
        for (final velocity in [-4000.0, -400.0, 0.0, 399.0, 400.0, 4000.0]) {
          for (final extent in [0.0, 120.0, 300.0, 900.0]) {
            expect(
              CoreDrawerContract.dismissesOnRelease(
                dragDistance: CoreDrawerRubberBand.dismissDistanceOf(pull),
                panelExtent: extent,
                threshold: CoreDrawerContract.defaultDragDismissThreshold,
                velocity: velocity,
              ),
              isFalse,
              reason: 'pull $pull at $velocity px/s on $extent',
            );
          }
        }
      }
    });

    test('is a drawer that does not stretch unless it is asked to', () {
      expect(CoreDrawerContract.defaultRubberBand, isFalse);
    });
  });

  group('the gesture table is consistent with the rules it exercises', () {
    final extent = _num(gestures['extent']);
    final threshold = _num(gestures['threshold']);

    for (final c in gestureCases) {
      test(c['name']! as String, () {
        final steps = (c['steps']! as List).map(_num).toList();
        final durationMs = _num(c['durationMs']);
        final holdMs = _num(c['holdMs'] ?? 0);

        // The pointer walks the steps in straight lines at one pace, a move
        // every 16 ms; its pull is the last step.
        final tracker = CoreDragVelocityTracker()..addSample(Duration.zero, 0);
        final segmentMs = durationMs / steps.length;
        var from = 0.0;
        var elapsedMs = 0.0;
        for (final to in steps) {
          final moves = math.max(1, (segmentMs / 16).ceil());
          for (var i = 1; i <= moves; i++) {
            elapsedMs += segmentMs / moves;
            tracker.addSample(
              Duration(microseconds: (elapsedMs * 1000).round()),
              from + (to - from) * i / moves,
            );
          }
          from = to;
        }
        final velocity = tracker.velocityAt(
          Duration(microseconds: ((elapsedMs + holdMs) * 1000).round()),
        );
        final pull = steps.last;

        final pose = CoreDrawerRubberBand.poseOf(pull, extent: extent);
        final expected = c['pose']! as Map<String, Object?>;
        expect(pose.slide, closeTo(_num(expected['slide']), kStretchTolerance));
        expect(
          pose.stretch,
          closeTo(_num(expected['stretch']), kStretchTolerance),
        );

        expect(
          CoreDrawerContract.dismissesOnRelease(
            dragDistance: CoreDrawerRubberBand.dismissDistanceOf(pull),
            panelExtent: extent,
            threshold: threshold,
            velocity: velocity,
          ),
          c['dismisses'],
          reason: 'released at $velocity px/s',
        );

        // A row that is moving toward the hiding edge when it lifts keeps a
        // wide margin from the 400 px/s a flick needs, or a loaded machine
        // decides it: a real browser delivers its events late, never early.
        if (velocity > 0) {
          expect(
            (velocity - CoreDrawerContract.defaultDismissVelocity).abs(),
            greaterThan(100),
            reason: '$velocity px/s is too close to the flick line',
          );
        }

        // What is left after a release that kept the panel is what the
        // return starts from, and the samples are that return.
        final settleRows = c['settle'] as List?;
        expect(settleRows == null, c['dismisses'], reason: 'settle rows');
        if (settleRows != null) {
          final start = math.max(pose.slide, pose.stretch);
          for (final row in settleRows.cast<List<Object?>>()) {
            expect(
              CoreDrawerRubberBand.settleAt(
                Duration(milliseconds: (row[0]! as num).toInt()),
                from: start,
              ),
              closeTo(_num(row[1]), kStretchTolerance),
              reason: 'at ${row[0]} ms',
            );
          }
        }
      });
    }
  });
}

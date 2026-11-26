// A ContextMenu can lift its source off the page while the menu is open and
// fold the menu back into it when it closes - opt-in, `liftChild`. What the two
// seats must agree on is not an animation but a handful of numbers at given
// moments: how far the lift has come a given time after the press, what size,
// shadow and dim that is, where the panel folds to and how small it has got.
// They are `CoreContextMenuLift`, `CoreContextMenuLiftTimeline` and
// `CoreContextMenuRetract`, and the shared table
// (`context_menu_lift_vectors.json`) pins them. This file replays every row of
// it on the functions and every trace on the timeline, then checks the rules
// the functions promise for any input.
//
// The table's values come from an independent reference (the easing solved by
// bisection, the rest written out from the contract's arithmetic), so a rule
// changed here and in the table together would still have to agree with a
// second implementation of it.
//
// The numbers of the look are `CoreContextMenuStyle`'s, and the functions take
// them as arguments: every row here passes the numbers the table was written
// against (and the `override` block passes a style that states others), and
// one test pins those numbers to the Style's defaults.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter and Web ContextMenu tests and the
/// Chrome probe.
const String kContextMenuLiftVectorsPath =
    'test/fixtures/context_menu_lift_vectors.json';

/// What a table value may differ from the Dart one by: the reference solves
/// the curve to 1e-12 and the solver here to 1e-10 of x. A value that is a
/// multiple of the progress (a 40 px blur) carries that error times the
/// multiple.
const double _kTolerance = 1e-6;

Duration _ms(Object? value) => Duration(milliseconds: (value! as num).toInt());

double _d(Object? value) => (value! as num).toDouble();

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

/// The cast a table states: its `cast` layers, in the order given.
List<CoreShadowLayer> _cast(Object? layers) => [
  for (final layer in _list(layers))
    (
      offsetX: _d(layer['offsetX']),
      offsetY: _d(layer['offsetY']),
      blurRadius: _d(layer['blurRadius']),
      spreadRadius: _d(layer['spreadRadius']),
      opacity: _d(layer['opacity']),
      inset: false,
    ),
];

CoreMenuBox _box(Object? edges) {
  final e = (edges! as List).cast<num>().map((v) => v.toDouble()).toList();

  return CoreMenuBox(left: e[0], top: e[1], right: e[2], bottom: e[3]);
}

void main() {
  final doc =
      jsonDecode(File(kContextMenuLiftVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final numbers = doc['numbers']! as Map<String, Object?>;
  final override = doc['override']! as Map<String, Object?>;

  // The numbers the table was written against, handed to the functions as the
  // arguments they take.
  final rise = _ms(numbers['durationMs']);
  final liftScale = _d(numbers['liftScale']);
  final dimOpacity = _d(numbers['dimOpacity']);
  final retractScale = _d(numbers['retractScale']);
  final cast = _cast(numbers['cast']);

  group('the numbers', () {
    test('the table states the numbers it was written against', () {
      // The gesture is the contract's...
      expect(
        _ms(numbers['holdMs']),
        CoreContextMenuContract.defaultLongPressDuration,
      );
      expect(
        _ms(numbers['delayMs']),
        CoreContextMenuContract.defaultLiftDelay,
      );
      expect(
        numbers['liftsWithoutHold'],
        CoreContextMenuContract.defaultLiftsWithoutHold,
      );
      // ...and the look is the Style's.
      expect(
        _ms(numbers['durationMs']),
        CoreContextMenuStyle.defaultLiftDuration,
      );
      expect(_d(numbers['liftScale']), CoreContextMenuStyle.defaultLiftScale);
      expect(
        _d(numbers['dimOpacity']),
        CoreContextMenuStyle.defaultLiftDimOpacity,
      );
      expect(
        _d(numbers['retractScale']),
        CoreContextMenuStyle.defaultRetractScale,
      );
      expect(
        CoreBorderRadius.all(_d(numbers['radius'])),
        CoreContextMenuStyle.defaultLiftRadius,
      );
      final layers = _list(numbers['cast']);
      expect(layers.length, CoreContextMenuStyle.defaultLiftCast.length);
      for (var i = 0; i < layers.length; i++) {
        final layer = CoreContextMenuStyle.defaultLiftCast[i];
        expect(_d(layers[i]['offsetX']), layer.offsetX);
        expect(_d(layers[i]['offsetY']), layer.offsetY);
        expect(_d(layers[i]['blurRadius']), layer.blurRadius);
        expect(_d(layers[i]['spreadRadius']), layer.spreadRadius);
        expect(_d(layers[i]['opacity']), layer.opacity);
      }
    });

    test(
      'the contract keeps the shipped statics, equal to the Style defaults',
      () {
        // The six deprecated aliases on the contract are the Style's own
        // numbers, so a reader still on them gets the value the lift draws
        // with; they cannot drift from the Style's for the window the
        // deprecation policy gives them.
        expect(
          CoreContextMenuContract.defaultLiftScale,
          CoreContextMenuStyle.defaultLiftScale,
        );
        expect(
          CoreContextMenuContract.defaultLiftDuration,
          CoreContextMenuStyle.defaultLiftDuration,
        );
        expect(
          CoreContextMenuContract.defaultLiftDimOpacity,
          CoreContextMenuStyle.defaultLiftDimOpacity,
        );
        expect(
          CoreContextMenuContract.defaultLiftCast,
          CoreContextMenuStyle.defaultLiftCast,
        );
        expect(
          const CoreBorderRadius.all(CoreContextMenuContract.defaultLiftRadius),
          CoreContextMenuStyle.defaultLiftRadius,
        );
        expect(
          CoreContextMenuContract.defaultRetractScale,
          CoreContextMenuStyle.defaultRetractScale,
        );
      },
    );

    test('the easing the table was written against is the token', () {
      final easing = doc['easing']! as Map<String, Object?>;
      List<double> points(CoreCubicBezier c) => [c.x1, c.y1, c.x2, c.y2];
      expect(
        (easing['enter']! as List).cast<num>(),
        points(CoreContextMenuLift.easing),
      );
      expect(
        (easing['exit']! as List).cast<num>(),
        points(CoreContextMenuRetract.easing),
      );
      expect(CoreContextMenuLift.easing, CoreEasing.enter);
      expect(CoreContextMenuRetract.easing, CoreEasing.exit);
    });

    test('the default lift is fully there before the hold ends', () {
      // The point of starting it at the press: by the time the menu appears
      // the child has finished rising, so the menu reads as the lift's end.
      expect(
        CoreContextMenuContract.defaultLiftDelay +
            CoreContextMenuStyle.defaultLiftDuration,
        lessThan(CoreContextMenuContract.defaultLongPressDuration),
      );
      expect(
        CoreContextMenuLift.progress(
          elapsed: CoreContextMenuContract.defaultLongPressDuration,
          duration: CoreContextMenuStyle.defaultLiftDuration,
        ),
        1,
      );
    });

    test('the delay and the duration are transition-tier tokens', () {
      expect(
        CoreContextMenuContract.defaultLiftDelay.inMilliseconds,
        CoreDuration.fast,
      );
      expect(
        CoreContextMenuStyle.defaultLiftDuration.inMilliseconds,
        CoreDuration.moderate,
      );
      // Reduced motion shortens the duration (a transition), not the delay (a
      // hold threshold, like the hold itself).
      expect(
        CoreReducedMotion.isTransitionMotion(
          CoreContextMenuStyle.defaultLiftDuration,
        ),
        isTrue,
      );
    });

    test("the dim is lighter than a modal scrim, the cast is the panel's", () {
      expect(
        CoreContextMenuStyle.defaultLiftDimOpacity,
        lessThan(CoreOpacity.scrim),
      );
      expect(CoreContextMenuStyle.defaultLiftCast, CoreShadow.lg);
      expect(
        CoreContextMenuStyle.defaultLiftRadius,
        const CoreBorderRadius.all(CoreRadiusRole.surface),
      );
    });
  });

  group('CoreContextMenuLift.progress against the table', () {
    test('the table is not empty', () {
      expect(_list(doc['progress']), isNotEmpty);
    });

    for (final row in _list(doc['progress'])) {
      final released = row['releasedAtMs'];
      final returned = row['returnMs'];
      test(
        '${row['name']}: ${row['elapsedMs']} ms'
        '${released == null ? '' : ' (released at $released)'}',
        () {
          expect(
            CoreContextMenuLift.progress(
              elapsed: _ms(row['elapsedMs']),
              delay: _ms(row['delayMs']),
              duration: _ms(row['durationMs']),
              releasedAt: released == null ? null : _ms(released),
              returnDuration: returned == null ? null : _ms(returned),
            ),
            closeTo(_d(row['expected']), _kTolerance),
          );
        },
      );
    }
  });

  group('CoreContextMenuLift.settle against the table', () {
    for (final row in _list(doc['settle'])) {
      test(
        'from ${row['fromProgress']}, ${row['elapsedMs']} of '
        '${row['durationMs']} ms',
        () {
          expect(
            CoreContextMenuLift.settle(
              from: _d(row['fromProgress']),
              elapsed: _ms(row['elapsedMs']),
              duration: _ms(row['durationMs']),
            ),
            closeTo(_d(row['expected']), _kTolerance),
          );
        },
      );
    }
  });

  group('what a progress looks like, against the table', () {
    for (final row in _list(doc['visuals'])) {
      final progress = _d(row['progress']);
      test('at progress $progress', () {
        expect(
          CoreContextMenuLift.scale(progress, liftScale: liftScale),
          closeTo(_d(row['scale']), 1e-12),
        );
        expect(
          CoreContextMenuLift.dim(progress, opacity: dimOpacity),
          closeTo(_d(row['dim']), 1e-12),
        );
        final scaled = CoreContextMenuLift.cast(progress, layers: cast);
        final expected = _list(row['cast']);
        expect(scaled.length, expected.length);
        for (var i = 0; i < scaled.length; i++) {
          expect(scaled[i].offsetX, closeTo(_d(expected[i]['offsetX']), 1e-12));
          expect(scaled[i].offsetY, closeTo(_d(expected[i]['offsetY']), 1e-12));
          expect(
            scaled[i].blurRadius,
            closeTo(_d(expected[i]['blurRadius']), 1e-12),
          );
          expect(
            scaled[i].spreadRadius,
            closeTo(_d(expected[i]['spreadRadius']), 1e-12),
          );
          expect(scaled[i].opacity, closeTo(_d(expected[i]['opacity']), 1e-12));
          expect(scaled[i].inset, isFalse);
        }
      });
    }

    test('at full lift the cast is the style stated, unchanged', () {
      expect(CoreContextMenuLift.cast(1, layers: cast), cast);
      expect(
        CoreContextMenuLift.cast(
          1,
          layers: CoreContextMenuStyle.defaultLiftCast,
        ),
        CoreContextMenuStyle.defaultLiftCast,
      );
    });

    test('at rest there is no lift: no growth, no dim, no cast to see', () {
      expect(CoreContextMenuLift.scale(0, liftScale: liftScale), 1);
      expect(CoreContextMenuLift.dim(0, opacity: dimOpacity), 0);
      for (final layer in CoreContextMenuLift.cast(0, layers: cast)) {
        expect(layer.opacity, 0);
        expect(layer.blurRadius, 0);
        expect(layer.offsetY, 0);
      }
    });

    test('an inset layer stays inset as it scales', () {
      final scaled = CoreContextMenuLift.cast(0.5, layers: CoreShadow.inset);
      expect(scaled.single.inset, isTrue);
    });
  });

  group('rules of the lift, for any input', () {
    test('it never leaves 0..1 and never goes down while rising', () {
      var previous = 0.0;
      for (var ms = 0; ms <= 700; ms++) {
        final value = CoreContextMenuLift.progress(
          elapsed: Duration(milliseconds: ms),
          duration: rise,
        );
        expect(value, inInclusiveRange(0, 1));
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
    });

    test(
      'released at any moment it is continuous there and then only falls',
      () {
        for (final releasedMs in [160, 200, 300, 400, 449, 460, 600]) {
          final at = Duration(milliseconds: releasedMs);
          final before = CoreContextMenuLift.progress(
            elapsed: at - const Duration(microseconds: 1),
            duration: rise,
            releasedAt: at,
          );
          final after = CoreContextMenuLift.progress(
            elapsed: at,
            duration: rise,
            releasedAt: at,
          );
          expect(after, closeTo(before, 1e-4), reason: 'jump at $releasedMs');
          var previous = after;
          for (var ms = releasedMs; ms <= releasedMs + 400; ms += 5) {
            final value = CoreContextMenuLift.progress(
              elapsed: Duration(milliseconds: ms),
              duration: rise,
              releasedAt: at,
            );
            expect(value, lessThanOrEqualTo(previous + 1e-12));
            expect(value, inInclusiveRange(0, 1));
            previous = value;
          }
          // Back at rest a duration after the release, and it stays there.
          expect(previous, closeTo(0, 1e-6));
        }
      },
    );

    test('the way back is a fraction of what was reached', () {
      // Released early the lift comes back as quietly as it went up: half the
      // height is half the fall at every moment.
      for (final ms in [350, 400, 500]) {
        final tall = CoreContextMenuLift.settle(
          from: 1,
          elapsed: Duration(milliseconds: ms - 300),
          duration: const Duration(milliseconds: 300),
        );
        final half = CoreContextMenuLift.settle(
          from: 0.5,
          elapsed: Duration(milliseconds: ms - 300),
          duration: const Duration(milliseconds: 300),
        );
        expect(half, closeTo(tall / 2, 1e-12));
      }
    });

    test('a zero duration is a jump both ways', () {
      expect(
        CoreContextMenuLift.progress(
          elapsed: const Duration(milliseconds: 150),
          duration: Duration.zero,
        ),
        0,
      );
      expect(
        CoreContextMenuLift.progress(
          elapsed: const Duration(milliseconds: 151),
          duration: Duration.zero,
        ),
        1,
      );
      // Released at 200, it is gone at 200: the person let go and nothing is
      // left to fall.
      expect(
        CoreContextMenuLift.progress(
          elapsed: const Duration(milliseconds: 200),
          duration: Duration.zero,
          releasedAt: const Duration(milliseconds: 200),
        ),
        0,
      );
    });

    test('an opening with no hold waits for nothing', () {
      expect(CoreContextMenuLift.delayFor(held: false), Duration.zero);
      expect(
        CoreContextMenuLift.delayFor(held: true),
        CoreContextMenuContract.defaultLiftDelay,
      );
      expect(
        CoreContextMenuLift.progress(
          elapsed: const Duration(milliseconds: 30),
          duration: rise,
          delay: CoreContextMenuLift.delayFor(held: false),
        ),
        greaterThan(0),
      );
    });

    test("whether a click lifts is the contract's one constant", () {
      expect(CoreContextMenuLift.lifts(held: true), isTrue);
      expect(
        CoreContextMenuLift.lifts(held: false),
        CoreContextMenuContract.defaultLiftsWithoutHold,
      );
    });
  });

  /// Replays [trace] on a timeline that rises over [duration], and reads each
  /// sample with the look the numbers state.
  void replayTrace(
    Map<String, Object?> trace, {
    required Duration duration,
    required double scaleOf,
    required double dimOf,
    required List<CoreShadowLayer> castOf,
  }) {
    final timeline = CoreContextMenuLiftTimeline(duration: duration);
    final calls = _list(trace['timeline']);
    var next = 0;
    for (final sample in _list(trace['samples'])) {
      final at = _ms(sample['at']);
      // A call takes effect at its own moment, before that moment is read.
      while (next < calls.length && _ms(calls[next]['at']) <= at) {
        final call = calls[next++];
        final when = _ms(call['at']);
        switch (call['call']) {
          case 'begin':
            timeline.begin(when, held: call['held']! as bool);
          case 'release':
            timeline.release(when);
          case 'commit':
            timeline.commit(when);
          case 'close':
            timeline.close(when, duration: _ms(call['durationMs']));
          default:
            fail('unknown call $call');
        }
      }
      final reason = '${trace['name']} at ${sample['at']} ms';
      final progress = timeline.progress(at);
      expect(
        progress,
        closeTo(_d(sample['progress']), _kTolerance),
        reason: reason,
      );
      expect(
        CoreContextMenuLift.scale(progress, liftScale: scaleOf),
        closeTo(_d(sample['scale']), _kTolerance),
        reason: reason,
      );
      expect(
        CoreContextMenuLift.dim(progress, opacity: dimOf),
        closeTo(_d(sample['dim']), _kTolerance),
        reason: reason,
      );
      final scaled = CoreContextMenuLift.cast(progress, layers: castOf);
      final expected = _list(sample['cast']);
      expect(scaled.length, expected.length, reason: reason);
      for (var i = 0; i < scaled.length; i++) {
        expect(
          scaled[i].offsetY,
          closeTo(_d(expected[i]['offsetY']), _kTolerance),
          reason: reason,
        );
        expect(
          scaled[i].blurRadius,
          closeTo(_d(expected[i]['blurRadius']), _kTolerance),
          reason: reason,
        );
        expect(
          scaled[i].opacity,
          closeTo(_d(expected[i]['opacity']), _kTolerance),
          reason: reason,
        );
      }
    }
  }

  group('the timeline, every trace of the table', () {
    final traces = _list(doc['traces']);

    test('the table is not empty', () {
      expect(traces, isNotEmpty);
    });

    for (final trace in traces) {
      test(trace['name']! as String, () {
        replayTrace(
          trace,
          duration: rise,
          scaleOf: liftScale,
          dimOf: dimOpacity,
          castOf: cast,
        );
      });
    }
  });

  group('a style that states other numbers, every trace of the table', () {
    final other = override['numbers']! as Map<String, Object?>;
    final traces = _list(override['traces']);

    test('states other numbers than the defaults, in every field', () {
      expect(_d(other['liftScale']), isNot(liftScale));
      expect(_d(other['dimOpacity']), isNot(dimOpacity));
      expect(_d(other['retractScale']), isNot(retractScale));
      expect(_d(other['radius']), isNot(_d(numbers['radius'])));
      expect(_cast(other['cast']), isNot(cast));
      for (final trace in traces) {
        expect(
          _ms(trace['durationMs']),
          isNot(rise),
          reason: '${trace['name']}',
        );
      }
    });

    for (final trace in traces) {
      test(trace['name']! as String, () {
        replayTrace(
          trace,
          duration: _ms(trace['durationMs']),
          scaleOf: _d(other['liftScale']),
          dimOf: _d(other['dimOpacity']),
          castOf: _cast(other['cast']),
        );
      });
    }
  });

  group('the rise a hold leaves, against the table', () {
    final rows = _list(doc['riseDuration']);

    test('the table is not empty', () {
      expect(rows, isNotEmpty);
    });

    for (final row in rows) {
      test('${row['name']}', () {
        final hold = row['holdMs'];
        expect(
          CoreContextMenuLift.riseDuration(
            _ms(row['requestedMs']),
            held: row['held']! as bool,
            hold: hold == null ? _ms(numbers['holdMs']) : _ms(hold),
          ),
          _ms(row['expectedMs']),
        );
      });
    }
  });

  group('rules of the rise, for any duration a style states', () {
    const hold = CoreContextMenuContract.defaultLongPressDuration;
    final delay = CoreContextMenuLift.delayFor(held: true);

    test(
      'a held touch is fully lifted when the hold ends, whatever is asked',
      () {
        for (var ms = -100; ms <= 4000; ms += 7) {
          final asked = Duration(milliseconds: ms);
          final run = CoreContextMenuLift.riseDuration(asked, held: true);
          expect(run, greaterThanOrEqualTo(Duration.zero), reason: '$ms');
          expect(
            run,
            lessThanOrEqualTo(asked < Duration.zero ? Duration.zero : asked),
            reason: '$ms ms asked: never longer than the style says',
          );
          expect(
            delay + run,
            lessThanOrEqualTo(hold),
            reason: '$ms ms asked: the rise ends before the hold does',
          );
          expect(
            CoreContextMenuLift.progress(elapsed: hold, duration: run),
            1,
            reason: '$ms ms asked: the child is whole when the menu opens',
          );
          // Asking for less than the hold leaves is honoured exactly.
          if (asked >= Duration.zero && delay + asked <= hold) {
            expect(run, asked, reason: '$ms ms asked fits, so it is as asked');
          }
        }
      },
    );

    test('an opening with no hold has nothing to finish before', () {
      for (var ms = -100; ms <= 4000; ms += 7) {
        final asked = Duration(milliseconds: ms);
        expect(
          CoreContextMenuLift.riseDuration(asked, held: false),
          asked < Duration.zero ? Duration.zero : asked,
          reason: '$ms',
        );
      }
    });

    test(
      'the timeline holds a held touch to the room and a click to nothing',
      () {
        const asked = Duration(milliseconds: 800);
        final touch = CoreContextMenuLiftTimeline(duration: asked)
          ..begin(Duration.zero, held: true);
        expect(touch.duration, asked, reason: 'what the style asked is kept');
        expect(touch.rise, hold - delay);
        expect(touch.progress(hold), 1, reason: 'whole when the menu opens');
        expect(
          touch.progress(hold - const Duration(milliseconds: 1)),
          lessThan(1),
        );

        final click = CoreContextMenuLiftTimeline(duration: asked)
          ..begin(Duration.zero, held: false);
        expect(click.rise, asked);
        expect(click.progress(hold), lessThan(1), reason: 'it rises as asked');
        expect(click.progress(asked), 1);
      },
    );

    test('the way back from a release takes the rise it was held to', () {
      final timeline = CoreContextMenuLiftTimeline(
        duration: const Duration(milliseconds: 800),
      )..begin(Duration.zero, held: true);
      const releasedAt = Duration(milliseconds: 400);
      final from = timeline.progress(releasedAt);
      timeline.release(releasedAt);
      expect(from, inExclusiveRange(0, 1));
      expect(timeline.isRest(releasedAt + (hold - delay)), isTrue);
      expect(
        timeline.isRest(
          releasedAt + (hold - delay) - const Duration(milliseconds: 1),
        ),
        isFalse,
      );
    });

    test('a timeline that has not begun has no rise', () {
      expect(
        CoreContextMenuLiftTimeline(duration: const Duration(seconds: 1)).rise,
        Duration.zero,
      );
    });
  });

  group(
    'what a style states is held to the range the picture is defined on',
    () {
      test(
        'a lift scale under 1 leaves the child its size, never shrinks it',
        () {
          for (final value in [0.0, 0.5, 0.999, 1.0, -3.0]) {
            for (final progress in [0.0, 0.25, 1.0]) {
              expect(
                CoreContextMenuLift.scale(progress, liftScale: value),
                1,
                reason: 'liftScale $value at $progress',
              );
            }
          }
          expect(CoreContextMenuLift.scale(1, liftScale: 1.5), 1.5);
          expect(CoreContextMenuLift.scale(0.5, liftScale: 1.5), 1.25);
        },
      );

      test(
        'a lift scale that is not a finite number is no growth, not a crash',
        () {
          for (final value in [
            double.nan,
            double.infinity,
            double.negativeInfinity,
          ]) {
            expect(
              CoreContextMenuLift.scale(1, liftScale: value),
              1,
              reason: '$value',
            );
          }
        },
      );

      test('a dim is a share: held to 0..1', () {
        expect(CoreContextMenuLift.dim(1, opacity: -0.2), 0);
        expect(CoreContextMenuLift.dim(1, opacity: 0), 0);
        expect(CoreContextMenuLift.dim(1, opacity: 0.35), 0.35);
        expect(CoreContextMenuLift.dim(1, opacity: 1), 1);
        expect(CoreContextMenuLift.dim(1, opacity: 5), 1);
        expect(CoreContextMenuLift.dim(0.5, opacity: 5), 0.5);
        expect(CoreContextMenuLift.dim(1, opacity: double.nan), 0);
        expect(CoreContextMenuLift.dim(1, opacity: double.infinity), 1);
        expect(CoreContextMenuLift.dim(1, opacity: double.negativeInfinity), 0);
      });

      test('a fold ends between gone and not shrunk: held to 0..1', () {
        expect(CoreContextMenuRetract.endScaleOf(-1), 0);
        expect(CoreContextMenuRetract.endScaleOf(0), 0);
        expect(CoreContextMenuRetract.endScaleOf(0.3), 0.3);
        expect(CoreContextMenuRetract.endScaleOf(1), 1);
        expect(CoreContextMenuRetract.endScaleOf(2), 1);
        expect(CoreContextMenuRetract.endScaleOf(double.nan), 1);
        expect(CoreContextMenuRetract.endScaleOf(double.infinity), 1);
        expect(CoreContextMenuRetract.endScaleOf(double.negativeInfinity), 0);
      });

      test('the frame of a fold draws with the held number', () {
        final panel = CoreMenuBox.fromLTWH(100, 100, 240, 200);
        final source = CoreMenuBox.fromLTWH(0, 0, 300, 60);
        double endOf(double value) => CoreContextMenuRetract.frame(
          fraction: 1,
          panel: panel,
          source: source,
          endScale: value,
        ).scale;

        expect(endOf(2), 1, reason: 'a fold never grows the panel');
        expect(endOf(-1), 0, reason: 'nor mirrors it');
        expect(endOf(double.nan), 1);
        expect(endOf(0.5), 0.5);
      });

      test('an empty cast lifts the child without a shadow', () {
        expect(CoreContextMenuLift.cast(1, layers: const []), isEmpty);
      });
    },
  );

  group("the timeline's rules", () {
    Duration ms(int v) => Duration(milliseconds: v);

    test('before anything begins there is nothing to draw', () {
      final timeline = CoreContextMenuLiftTimeline(duration: rise);
      expect(timeline.isBegun, isFalse);
      expect(timeline.progress(ms(1000)), 0);
      expect(timeline.isRest(ms(1000)), isTrue);
      expect(timeline.closeFraction(ms(1000)), isNull);
    });

    test('a release after the hold paid off is nothing', () {
      final timeline = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: true)
        ..commit(ms(500))
        ..release(ms(600));
      expect(timeline.isReleased, isFalse);
      expect(timeline.progress(ms(900)), 1);
      expect(timeline.isRest(ms(900)), isFalse);
    });

    test('a commit after a release is nothing: the lift keeps coming back', () {
      final timeline = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: true)
        ..release(ms(300))
        ..commit(ms(500));
      expect(timeline.isCommitted, isFalse);
      expect(timeline.progress(ms(700)), 0);
    });

    test('an opening with no hold is committed from its first moment', () {
      final timeline = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: false);
      expect(timeline.isCommitted, isTrue);
      timeline.release(ms(100));
      expect(timeline.isReleased, isFalse);
      expect(timeline.progress(ms(400)), 1);
    });

    test('closing settles from where the lift is, over the close duration', () {
      final timeline = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: false)
        ..close(ms(100), duration: ms(100));
      final from = CoreContextMenuLift.progress(
        elapsed: ms(100),
        duration: rise,
        delay: Duration.zero,
      );
      expect(timeline.isClosing, isTrue);
      expect(timeline.progress(ms(100)), closeTo(from, 1e-12));
      expect(timeline.progress(ms(150)), lessThan(from));
      expect(timeline.progress(ms(200)), 0);
      expect(timeline.isRest(ms(199)), isFalse);
      expect(timeline.isRest(ms(200)), isTrue);
    });

    test('closing twice, or after a release, changes nothing', () {
      final closing = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: false)
        ..close(ms(400), duration: ms(100))
        ..close(ms(450), duration: ms(500));
      expect(closing.closeFraction(ms(450)), closeTo(0.5, 1e-12));

      final released = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: true)
        ..release(ms(300))
        ..close(ms(310), duration: ms(100));
      expect(released.isClosing, isFalse);
    });

    test('the close fraction is linear time through the close', () {
      final timeline = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: false)
        ..close(ms(1000), duration: ms(100));
      expect(timeline.closeFraction(ms(1000)), 0);
      expect(timeline.closeFraction(ms(1025)), closeTo(0.25, 1e-12));
      expect(timeline.closeFraction(ms(1100)), 1);
      expect(timeline.closeFraction(ms(2000)), 1);
      // A close with no time to take is over at once.
      final instant = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: false)
        ..close(ms(10), duration: Duration.zero);
      expect(instant.closeFraction(ms(10)), 1);
      expect(instant.progress(ms(10)), 0);
      expect(instant.isRest(ms(10)), isTrue);
    });

    test('a released lift is at rest only when it is all the way back', () {
      final timeline = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: true)
        ..release(ms(300));
      expect(timeline.isRest(ms(300)), isFalse);
      expect(timeline.isRest(ms(599)), isFalse);
      expect(timeline.isRest(ms(600)), isTrue);
      // Released before it began: nothing was ever drawn.
      final early = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: true)
        ..release(ms(100));
      expect(early.isRest(ms(100)), isTrue);
    });

    test('beginning again starts over', () {
      final timeline = CoreContextMenuLiftTimeline(duration: rise)
        ..begin(ms(0), held: true)
        ..release(ms(300))
        ..begin(ms(1000), held: true);
      expect(timeline.isReleased, isFalse);
      expect(timeline.progress(ms(1000)), 0);
      expect(timeline.progress(ms(1100)), 0);
      expect(timeline.progress(ms(1400)), greaterThan(0));
    });

    test('a duration given to the timeline is the one it rises over', () {
      final jump = CoreContextMenuLiftTimeline(duration: Duration.zero)
        ..begin(ms(0), held: true);
      expect(jump.progress(ms(150)), 0);
      expect(jump.progress(ms(151)), 1);
      jump.release(ms(200));
      expect(jump.progress(ms(200)), 0);
    });
  });

  group('CoreContextMenuRetract against the table', () {
    for (final row in _list(doc['retract'])) {
      final panel = _box(row['panel']);
      final source = _box(row['source']);
      final pivot = (row['pivot']! as List).cast<num>();

      test('${row['name']}: where it folds to', () {
        final found = CoreContextMenuRetract.pivot(
          panel: panel,
          source: source,
        );
        expect(found.x, closeTo(pivot[0].toDouble(), 1e-12));
        expect(found.y, closeTo(pivot[1].toDouble(), 1e-12));
      });

      for (final frame in _list(row['frames'])) {
        test('${row['name']}: at ${frame['fraction']} of the close', () {
          final drawn = CoreContextMenuRetract.frame(
            fraction: _d(frame['fraction']),
            panel: panel,
            source: source,
            endScale: retractScale,
          );
          expect(drawn.scale, closeTo(_d(frame['scale']), _kTolerance));
          expect(drawn.opacity, closeTo(_d(frame['opacity']), _kTolerance));
          expect(drawn.pivotX, closeTo(pivot[0].toDouble(), 1e-12));
          expect(drawn.pivotY, closeTo(pivot[1].toDouble(), 1e-12));
          final rect = (frame['rect']! as List).cast<num>();
          final placed = drawn.applyTo(panel);
          expect(placed.left, closeTo(rect[0].toDouble(), _kTolerance));
          expect(placed.top, closeTo(rect[1].toDouble(), _kTolerance));
          expect(placed.right, closeTo(rect[2].toDouble(), _kTolerance));
          expect(placed.bottom, closeTo(rect[3].toDouble(), _kTolerance));
        });
      }
    }

    test('the curve of scale and opacity alone', () {
      final panel = _box([0, 0, 100, 100]);
      final source = _box([0, 0, 10, 10]);
      for (final point in _list(doc['retractCurve'])) {
        final drawn = CoreContextMenuRetract.frame(
          fraction: _d(point['fraction']),
          panel: panel,
          source: source,
          endScale: retractScale,
        );
        expect(drawn.scale, closeTo(_d(point['scale']), _kTolerance));
        expect(drawn.opacity, closeTo(_d(point['opacity']), _kTolerance));
      }
    });
  });

  group('CoreContextMenuRetract under a style that states another fold', () {
    final other = override['numbers']! as Map<String, Object?>;
    final endScale = _d(other['retractScale']);
    final panel = _box([0, 0, 100, 100]);
    final source = _box([0, 0, 10, 10]);

    for (final point in _list(override['retractCurve'])) {
      test('at ${point['fraction']} of the close', () {
        final drawn = CoreContextMenuRetract.frame(
          fraction: _d(point['fraction']),
          panel: panel,
          source: source,
          endScale: endScale,
        );
        expect(drawn.scale, closeTo(_d(point['scale']), _kTolerance));
        expect(drawn.opacity, closeTo(_d(point['opacity']), _kTolerance));
      });
    }
  });

  group('rules of the fold, for any input', () {
    test('the pivot is always a point of the source', () {
      final sources = [
        _box([0, 0, 300, 60]),
        _box([250, 80, 450, 140]),
        _box([10, 10, 10, 10]),
      ];
      for (final source in sources) {
        for (var x = -200.0; x <= 700; x += 97) {
          for (var y = -200.0; y <= 700; y += 89) {
            final panel = CoreMenuBox.fromLTWH(x, y, 240, 160);
            final pivot = CoreContextMenuRetract.pivot(
              panel: panel,
              source: source,
            );
            expect(pivot.x, inInclusiveRange(source.left, source.right));
            expect(pivot.y, inInclusiveRange(source.top, source.bottom));
          }
        }
      }
    });

    test('a panel whose middle is over the source folds about that middle', () {
      final panel = CoreMenuBox.fromLTWH(100, 50, 200, 150);
      final source = CoreMenuBox.fromLTWH(0, 0, 400, 300);
      final pivot = CoreContextMenuRetract.pivot(panel: panel, source: source);
      expect(pivot.x, 200);
      expect(pivot.y, 125);
      final frame = CoreContextMenuRetract.frame(
        fraction: 1,
        panel: panel,
        source: source,
        endScale: retractScale,
      );
      final folded = frame.applyTo(panel);
      expect((folded.left + folded.right) / 2, closeTo(200, 1e-9));
      expect((folded.top + folded.bottom) / 2, closeTo(125, 1e-9));
    });

    test('it starts as the panel is and ends small and gone', () {
      final panel = CoreMenuBox.fromLTWH(100, 100, 240, 200);
      final source = CoreMenuBox.fromLTWH(0, 0, 300, 60);
      final start = CoreContextMenuRetract.frame(
        fraction: 0,
        panel: panel,
        source: source,
        endScale: retractScale,
      );
      expect(start.scale, 1);
      expect(start.opacity, 1);
      expect(start.applyTo(panel), panel);
      final end = CoreContextMenuRetract.frame(
        fraction: 1,
        panel: panel,
        source: source,
        endScale: retractScale,
      );
      expect(end.scale, closeTo(retractScale, 1e-12));
      expect(end.opacity, 0);
    });

    test('scale and opacity only go down as the close goes on', () {
      final panel = CoreMenuBox.fromLTWH(100, 100, 240, 200);
      final source = CoreMenuBox.fromLTWH(0, 0, 300, 60);
      var scale = 2.0;
      var opacity = 2.0;
      for (var i = 0; i <= 100; i++) {
        final frame = CoreContextMenuRetract.frame(
          fraction: i / 100,
          panel: panel,
          source: source,
          endScale: retractScale,
        );
        expect(frame.scale, lessThanOrEqualTo(scale));
        expect(frame.opacity, lessThanOrEqualTo(opacity));
        expect(frame.scale, inInclusiveRange(retractScale, 1));
        expect(frame.opacity, inInclusiveRange(0, 1));
        scale = frame.scale;
        opacity = frame.opacity;
      }
    });

    test('the fold is time-clamped: past either end it holds the end', () {
      final panel = CoreMenuBox.fromLTWH(100, 100, 240, 200);
      final source = CoreMenuBox.fromLTWH(0, 0, 300, 60);
      expect(
        CoreContextMenuRetract.frame(
          fraction: -1,
          panel: panel,
          source: source,
          endScale: retractScale,
        ).scale,
        1,
      );
      expect(
        CoreContextMenuRetract.frame(
          fraction: 2,
          panel: panel,
          source: source,
          endScale: retractScale,
        ).opacity,
        0,
      );
    });

    test('the frame is a value', () {
      const a = CoreContextMenuRetractFrame(
        scale: 0.5,
        opacity: 0.5,
        pivotX: 1,
        pivotY: 2,
      );
      const b = CoreContextMenuRetractFrame(
        scale: 0.5,
        opacity: 0.5,
        pivotX: 1,
        pivotY: 2,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          const CoreContextMenuRetractFrame(
            scale: 0.5,
            opacity: 0.5,
            pivotX: 1,
            pivotY: 3,
          ),
        ),
      );
    });
  });
}

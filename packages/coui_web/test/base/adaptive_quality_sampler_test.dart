// What the Web decides about adaptive quality without a browser: which gaps
// between frames are samples, when the page is asked for frames at all, what a
// hidden tab or a reduce-transparency preference does to the measurement.
//
// `WebQualitySampler` is the DOM-free part of the Web seat, so a VM runs it
// against a clock the test moves by hand. The listeners and the
// `requestAnimationFrame` loop around it are the Chrome probe's
// (`tool/parity/test/web/adaptive_quality_probe_test.dart`) — nothing here
// says they work.
//
// The governor's own judgement is `coui_core`'s, and the table in
// `adaptive_quality_vectors.json` pins it for every package. Replaying the
// table's interval traces through the sampler is what shows the Web feeds the
// governor the numbers the table assumes: an interval is the gap between two
// frame timestamps, on the page's own clock.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/quality_sampler.dart';
import 'package:test/test.dart';

const String _kVectorsPath =
    '../coui_core/test/fixtures/adaptive_quality_vectors.json';

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

List<Map<String, Object?>> _intervalTraces() {
  final table =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;

  return [
    for (final trace in _list(table['traces']))
      if (trace['metric'] == 'interval') trace,
  ];
}

/// The page's clock, in whole microseconds, so that an interval is exact and a
/// trace row's `ratio × budget` lands where the table put it.
class _Page {
  _Page(this.sampler);

  final WebQualitySampler sampler;
  int micros = 0;

  double get ms => micros / Duration.microsecondsPerMillisecond;

  /// A frame [intervalMicros] after the last one, the page in motion.
  void frame(int intervalMicros, {bool moving = true}) {
    micros += intervalMicros;
    if (moving) sampler.onActivity(ms);
    sampler.onFrame(ms);
  }

  /// [count] frames, one budget apart.
  void frames(int count, [int? intervalMicros]) {
    final interval = intervalMicros ?? sampler.governor!.budgetMicros;
    for (var i = 0; i < count; i++) {
      frame(interval);
    }
  }

  /// Time passing with nothing on the page moving and no frame asked for.
  void idle(int micros) => this.micros += micros;
}

CoreAdaptiveQuality _at60({
  CoreQualityTier? initial,
  CoreQualityTier? lowest,
  bool allowStepUp = true,
}) => CoreAdaptiveQuality(
  targetFrameRate: 60,
  initialQuality: initial,
  lowest: lowest,
  allowStepUp: allowStepUp,
);

WebQualitySampler _sampler(
  CoreAdaptiveQuality stated, [
  void Function(CoreQualityChange change)? onChange,
]) => WebQualitySampler(stated: stated, onChange: onChange ?? (_) {});

void main() {
  group('the sampler replays the shared table on frame timestamps', () {
    for (final trace in _intervalTraces()) {
      test(trace['name']! as String, () {
        final hz = (trace['refreshHz']! as num).toDouble();
        final initial = trace['initial'];
        final changes = <Map<String, Object?>>[];
        var frame = 0;
        final sampler = _sampler(
          CoreAdaptiveQuality(
            targetFrameRate: hz,
            initialQuality: initial == null
                ? null
                : CoreQualityTier.values.byName(initial as String),
            allowStepUp: trace['allowStepUp'] != false,
          ),
          (change) => changes.add({
            'frame': frame,
            'from': change.from.name,
            'to': change.to.name,
            'reason': change.reason.name,
          }),
        );
        final budget = sampler.governor!.budgetMicros;
        expect(budget, CoreFrameBudget.microsFor(hz));

        final page = _Page(sampler)
          // The first frame of a stretch has no interval to measure: it is the
          // anchor every later gap is taken from.
          ..sampler.onActivity(0)
          ..sampler.onFrame(0);
        for (final step in _list(trace['steps'])) {
          expect(
            step.containsKey('event'),
            isFalse,
            reason: 'no interval trace states an event',
          );
          final count = (step['frames']! as num).toInt();
          final pattern = (step['pattern'] as List?)?.cast<num>();
          for (var i = 0; i < count; i++) {
            final ratio = pattern == null
                ? (step['ratio']! as num).toDouble()
                : pattern[i % pattern.length].toDouble();
            frame++;
            page.frame((ratio * budget).round());
          }
        }

        expect(changes, [
          for (final e in _list(trace['expect']))
            {
              'frame': e['frame'],
              'from': e['from'],
              'to': e['to'],
              'reason': e['reason'],
            },
        ]);
        expect(
          sampler.tier,
          CoreQualityTier.values.byName(trace['final']! as String),
        );
      });
    }

    test('the table has interval traces to replay', () {
      // A table that lost them would make the group above pass by being
      // empty.
      expect(_intervalTraces().length, greaterThanOrEqualTo(8));
    });
  });

  group('what the sampler runs', () {
    test('a forced tier runs nothing and asks for no frame', () {
      final sampler = _sampler(
        const CoreAdaptiveQuality(forced: CoreQualityTier.solid),
      );
      expect(sampler.tier, CoreQualityTier.solid);
      expect(sampler.governor, isNull);
      sampler.onActivity(0);
      expect(sampler.wantsFrames, isFalse);
    });

    test('one rung to be on is nothing to decide', () {
      final sampler = _sampler(_at60(lowest: CoreQualityTier.full));
      expect(sampler.governor, isNull);
      expect(sampler.wantsFrames, isFalse);
    });

    test('an initial tier is where it starts', () {
      final sampler = _sampler(_at60(initial: CoreQualityTier.noRefraction));
      expect(sampler.tier, CoreQualityTier.noRefraction);
      expect(sampler.governor, isNotNull);
    });

    test('and its frames are the intervals — the metric the table calls '
        '`interval`', () {
      final sampler = _sampler(_at60());
      expect(sampler.governor!.metric, CoreFrameMetric.interval);
    });
  });

  group('the page is asked for frames only while it moves', () {
    test('not before anything has moved', () {
      expect(_sampler(_at60()).wantsFrames, isFalse);
    });

    test('from a sign of motion until the grace has passed', () {
      final sampler = _sampler(_at60());
      final graceMs = sampler.stated.tuning.sampleGraceSeconds * 1000;
      sampler.onActivity(1000);
      expect(sampler.wantsFrames, isTrue);

      // Still inside the grace: the loop runs on.
      sampler
        ..onFrame(1000)
        ..onFrame(1000 + graceMs - 1);
      expect(sampler.wantsFrames, isTrue);

      // The first frame past it is the one that notices, and stops.
      sampler.onFrame(1000 + graceMs + 17);
      expect(sampler.wantsFrames, isFalse);
    });

    test('a later sign of motion reopens it', () {
      final sampler = _sampler(_at60())
        ..onActivity(0)
        ..onFrame(0)
        ..onFrame(5000);
      expect(sampler.wantsFrames, isFalse);

      sampler.onActivity(9000);
      expect(sampler.wantsFrames, isTrue);
    });

    test('a sign of motion extends the grace rather than restarting it', () {
      final sampler = _sampler(_at60())
        ..onActivity(0)
        ..onActivity(1500)
        ..onActivity(100) // out of order: never shortens it
        ..onFrame(1500)
        ..onFrame(3400); // inside 1500 + 2000
      expect(sampler.wantsFrames, isTrue);
    });

    test('frames with no motion are not samples', () {
      final changes = <CoreQualityChange>[];
      final sampler = _sampler(_at60(), changes.add);
      final page = _Page(sampler);
      // A dropped frame every other frame would degrade a page that moved;
      // none of it was asked for, so none of it is read.
      for (var i = 0; i < 1000; i++) {
        page.frame(33333, moving: false);
      }
      expect(changes, isEmpty);
      expect(sampler.tier, CoreQualityTier.full);
      expect(sampler.governor!.phase, CoreQualityPhase.warmup);
    });
  });

  group('a stretch of idleness is not a long frame', () {
    // The governor skips, then warms up on, a number of frames it derives from
    // the budget. Feeding exactly one fewer than that leaves it in the warm-up
    // and one more takes it out, which is how a test sees whether a given gap
    // was counted as a frame.
    int framesToWarm(WebQualitySampler sampler) {
      final counts = sampler.governor!.frameCounts;

      return counts.skip + counts.warmup;
    }

    test('the first frame after the gate reopened is an anchor, not a '
        'sample', () {
      final sampler = _sampler(_at60());
      final page = _Page(sampler)
        ..sampler.onActivity(0)
        ..sampler.onFrame(0);
      final needed = framesToWarm(sampler);

      // Ten seconds of nothing: the loop was never asked for a frame. The
      // next frame arrives long after the grace; it is noticed and dropped.
      page
        ..frames(100)
        ..idle(10 * Duration.microsecondsPerSecond)
        ..frame(16667, moving: false);
      expect(sampler.wantsFrames, isFalse);

      // Motion again. The next frame has nothing before it to be measured
      // from.
      page
        ..frame(16667)
        ..frames(needed - 100 - 1);
      expect(
        sampler.governor!.phase,
        CoreQualityPhase.warmup,
        reason: 'the gap or its two anchors were counted as frames',
      );
      page.frames(1);
      expect(sampler.governor!.phase, CoreQualityPhase.runtime);
    });

    test('a hidden tab does not leave a gap in the measurement', () {
      final sampler = _sampler(_at60());
      final page = _Page(sampler)
        ..sampler.onActivity(0)
        ..sampler.onFrame(0);
      final needed = framesToWarm(sampler);
      page.frames(needed + 1);
      expect(sampler.governor!.phase, CoreQualityPhase.runtime);

      sampler.onVisibilityChanged(hidden: true, nowMs: page.ms);
      expect(sampler.wantsFrames, isFalse);
      page.idle(60 * Duration.microsecondsPerSecond);
      sampler.onVisibilityChanged(hidden: false, nowMs: page.ms);

      // Coming back starts the warm-up over: what was measured before says
      // nothing about a device that was away.
      expect(sampler.governor!.phase, CoreQualityPhase.warmup);
      expect(sampler.wantsFrames, isTrue);
      page
        ..frame(16667) // the anchor
        ..frames(needed - 1);
      expect(sampler.governor!.phase, CoreQualityPhase.warmup);
      page.frames(1);
      expect(sampler.governor!.phase, CoreQualityPhase.runtime);
    });
  });

  group('the display rate is read off the first frames', () {
    test('unless the app states it', () {
      expect(_sampler(_at60()).estimating, isFalse);
      expect(
        _sampler(const CoreAdaptiveQuality()).estimating,
        isTrue,
        reason: 'no target stated: the first intervals say what the rate is',
      );
    });

    test('sixty intervals at 120 Hz make the budget half of 60 Hz’s', () {
      final sampler = _sampler(const CoreAdaptiveQuality());
      expect(
        sampler.governor!.budgetMicros,
        CoreFrameBudget.microsFor(CoreFrameBudget.defaultRefreshRate),
        reason: 'until it knows, the page is judged against 60 Hz',
      );
      final page = _Page(sampler)
        ..sampler.onActivity(0)
        ..sampler.onFrame(0)
        ..frames(CoreFrameBudget.estimateIntervals - 1, 8333);
      expect(sampler.estimating, isTrue);
      page.frames(1, 8333);

      expect(sampler.estimating, isFalse);
      expect(sampler.governor!.budgetMicros, CoreFrameBudget.microsFor(120));
    });

    test('and those intervals are not samples', () {
      final sampler = _sampler(const CoreAdaptiveQuality());
      final page = _Page(sampler)
        ..sampler.onActivity(0)
        ..sampler.onFrame(0)
        ..frames(CoreFrameBudget.estimateIntervals, 8333);
      final counts = sampler.governor!.frameCounts;
      final needed = counts.skip + counts.warmup;

      page.frames(needed - 1);
      expect(sampler.governor!.phase, CoreQualityPhase.warmup);
      page.frames(1);
      expect(sampler.governor!.phase, CoreQualityPhase.runtime);
    });

    test('a 30 fps page is judged against 60 Hz, not mistaken for a 30 Hz '
        'display', () {
      final sampler = _sampler(const CoreAdaptiveQuality());
      _Page(sampler)
        ..sampler.onActivity(0)
        ..sampler.onFrame(0)
        ..frames(CoreFrameBudget.estimateIntervals, 33333);

      expect(sampler.governor!.budgetMicros, CoreFrameBudget.microsFor(60));
    });
  });

  group('accessibility outranks the measurement', () {
    test('a reduce-transparency preference stops it, and ending it starts '
        'the warm-up over', () {
      final changes = <CoreQualityChange>[];
      final sampler = _sampler(_at60(), changes.add);
      final page = _Page(sampler)
        ..sampler.onActivity(0)
        ..sampler.onFrame(0);
      final counts = sampler.governor!.frameCounts;
      page.frames(counts.skip + counts.warmup + 1);
      expect(sampler.governor!.phase, CoreQualityPhase.runtime);

      sampler.onReducedTransparency(reduced: true);
      expect(sampler.wantsFrames, isFalse);
      expect(sampler.governor!.measurementHeld, isTrue);

      // Frames that still arrive say nothing about the glass: the surfaces
      // are already opaque. Slow ones do not degrade anything.
      sampler.onActivity(page.ms);
      for (var i = 0; i < 2000; i++) {
        page.frame(50000);
      }
      expect(changes, isEmpty);

      sampler.onReducedTransparency(reduced: false);
      expect(sampler.governor!.phase, CoreQualityPhase.warmup);
      expect(sampler.tier, CoreQualityTier.full);
      expect(sampler.wantsFrames, isTrue);

      // And it measures again: a page that cannot hold a frame is given up
      // on once the tail of the change and the new warm-up have passed.
      final after = sampler.governor!.frameCounts;
      page.frames(after.settle + after.skip + after.warmup, 60000);
      expect(
        [for (final change in changes) change.to],
        [CoreQualityTier.solid],
      );
    });

    test('saying the same thing twice opens one hold, not two', () {
      final sampler = _sampler(_at60())..onReducedTransparency(reduced: false);
      expect(sampler.governor!.measurementHeld, isFalse);

      sampler
        ..onReducedTransparency(reduced: true)
        ..onReducedTransparency(reduced: true);
      expect(sampler.governor!.measurementHeld, isTrue);
      sampler.onReducedTransparency(reduced: false);

      // One hold was opened, so one release is all it takes: only the tail of
      // the change is left, and it runs out.
      _Page(sampler)
        ..sampler.onActivity(0)
        ..sampler.onFrame(0)
        ..frames(sampler.governor!.frameCounts.settle);
      expect(sampler.governor!.measurementHeld, isFalse);
    });

    test('an app’s own hold stops it for as long as it is held, and a '
        'moment more', () {
      final sampler = _sampler(_at60());
      expect(sampler.governor!.measurementHeld, isFalse);
      final hold = sampler.hold();
      expect(sampler.governor!.measurementHeld, isTrue);
      hold.release();
      // The tail of the work that was held is not read either.
      expect(sampler.governor!.measurementHeld, isTrue);

      _Page(sampler)
        ..sampler.onActivity(0)
        ..sampler.onFrame(0)
        ..frames(sampler.governor!.frameCounts.settle);
      expect(sampler.governor!.measurementHeld, isFalse);
    });

    test('with nothing to run, a hold holds nothing', () {
      final sampler = _sampler(
        const CoreAdaptiveQuality(forced: CoreQualityTier.full),
      );
      final hold = sampler.hold();
      expect(hold.released, isTrue, reason: 'there is nothing to release');
      hold.release();
      expect(hold.released, isTrue);
    });
  });

  group('what the sampler reports', () {
    test('the tier changes before the callback hears of it', () {
      CoreQualityTier? seen;
      late final WebQualitySampler sampler;
      sampler = _sampler(
        _at60(initial: CoreQualityTier.noRefraction),
        (change) => seen = sampler.tier,
      );
      final page = _Page(sampler)
        ..sampler.onActivity(0)
        ..sampler.onFrame(0);
      // A page that cannot hold a frame: the warm-up gives up the rest.
      for (var i = 0; i < 4000 && seen == null; i++) {
        page.frame(60000);
      }

      expect(seen, CoreQualityTier.solid);
    });
  });
}

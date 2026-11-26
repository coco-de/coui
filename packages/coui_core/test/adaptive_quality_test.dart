// Adaptive quality: the ladder of tiers, the frame budget and the governor that
// moves along the ladder from measured frames, all of it pure and shared by
// the two seats. The seats supply the frames (Flutter's raster times, the
// Web's frame intervals) and apply the tier; every judgement in between is
// here, and the table in `test/fixtures/adaptive_quality_vectors.json` pins it
// for all three packages. This file replays that table on the pure types and
// holds the invariants a table row cannot: what a tier withholds, that a rung
// is one entry, that holds nest, that the counts follow the refresh rate.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const String kAdaptiveQualityVectorsPath =
    'test/fixtures/adaptive_quality_vectors.json';

Map<String, Object?> _vectors() =>
    jsonDecode(File(kAdaptiveQualityVectorsPath).readAsStringSync())
        as Map<String, Object?>;

Map<String, Object?> _budgetTable() =>
    _vectors()['budget']! as Map<String, Object?>;

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

double _hz(Object? value) => switch (value) {
  null => double.nan,
  'NaN' => double.nan,
  'Infinity' => double.infinity,
  final num n => n.toDouble(),
  _ => throw ArgumentError('hz $value'),
};

CoreQualityTier _tier(Object? name) =>
    CoreQualityTier.values.byName(name! as String);

/// One thing a trace does: feed a frame of [ratio] budgets, or an event.
class _Item {
  const _Item.frame(this.ratio) : event = null;
  const _Item.event(this.event) : ratio = null;

  final double? ratio;
  final String? event;
}

List<_Item> _expand(List<Map<String, Object?>> steps) {
  final items = <_Item>[];
  for (final step in steps) {
    final event = step['event'];
    if (event != null) {
      items.add(_Item.event(event as String));
      continue;
    }
    final frames = (step['frames']! as num).toInt();
    final pattern = (step['pattern'] as List?)?.cast<num>();
    for (var i = 0; i < frames; i++) {
      final ratio = pattern == null
          ? (step['ratio']! as num).toDouble()
          : pattern[i % pattern.length].toDouble();
      items.add(_Item.frame(ratio));
    }
  }

  return items;
}

/// What a trace makes the governor do: the frame each change was reported on,
/// and the tier it ended at.
({List<(int, CoreQualityChange)> changes, CoreQualityGovernor governor})
_replay(
  Map<String, Object?> trace,
) {
  final budget = CoreFrameBudget.microsFor(_hz(trace['refreshHz']));
  final metric = CoreFrameMetric.values.byName(trace['metric']! as String);
  var frame = 0;
  var at = 0;
  final changes = <(int, CoreQualityChange)>[];
  final governor = CoreQualityGovernor(
    rungs: [for (final name in trace['rungs']! as List) _tier(name)],
    metric: metric,
    budgetMicros: budget,
    initial: trace['initial'] == null ? null : _tier(trace['initial']),
    allowStepUp: trace['allowStepUp'] != false,
    onChange: (change) => changes.add((frame, change)),
  );
  final holds = <CoreQualityHold>[];
  for (final item in _expand(_list(trace['steps']))) {
    switch (item.event) {
      case 'hold':
        holds.add(governor.hold());
      case 'release':
        holds.removeLast().release();
      case 'reset':
        governor.reset();
      case null:
        frame++;
        final cost = (item.ratio! * budget).round();
        // A cost cannot end a frame sooner than the display shows it; an
        // interval is the time since the last frame.
        at += metric == CoreFrameMetric.cost
            ? (cost > budget ? cost : budget)
            : cost;
        governor.add(cost, at);
      default:
        throw ArgumentError('event ${item.event}');
    }
  }

  return (changes: changes, governor: governor);
}

/// A tuning small enough to run a window in a handful of frames: three at
/// 60 Hz. Everything not named is the default.
CoreQualityTuning _quickTuning({
  int recoverWindows = CoreQualityTuning.defaultRecoverWindows,
  int probationWindows = CoreQualityTuning.defaultProbationWindows,
  int maxBackoffDoublings = CoreQualityTuning.defaultMaxBackoffDoublings,
}) => CoreQualityTuning(
  skipSeconds: 0.05,
  windowSeconds: 0.05,
  cooldownSeconds: 0,
  degradeWindows: 1,
  recoverWindows: recoverWindows,
  probationWindows: probationWindows,
  maxBackoffDoublings: maxBackoffDoublings,
);

/// Feeds a governor frames at the pace the clock would run them.
class _Feeder {
  _Feeder(this.governor);

  final CoreQualityGovernor governor;
  int at = 0;

  void frames(int count, int cost) {
    for (var i = 0; i < count; i++) {
      at += cost > governor.budgetMicros ? cost : governor.budgetMicros;
      governor.add(cost, at);
    }
  }

  void skip() => frames(governor.frameCounts.skip, 1000);

  void windows(int count, int cost) =>
      frames(count * governor.frameCounts.window, cost);
}

void main() {
  group('the ladder', () {
    const ladder = CoreQualityLadder.standard;

    test('is full, then without the bend, then without the backdrop pass', () {
      expect(ladder.tiers, [
        CoreQualityTier.full,
        CoreQualityTier.noRefraction,
        CoreQualityTier.solid,
      ]);
      expect(ladder.top, CoreQualityTier.full);
    });

    test('every tier is one rung and a rung withholds a superset of the '
        'rung above it — a tier never adds an effect', () {
      for (var i = 1; i < ladder.length; i++) {
        final above = ladder.withheldAt(ladder.steps[i - 1].tier);
        final here = ladder.withheldAt(ladder.steps[i].tier);
        expect(here.containsAll(above), isTrue);
        expect(here.length, greaterThan(above.length), reason: 'no-op rung');
      }
      expect(ladder.withheldAt(CoreQualityTier.full), isEmpty);
      expect(CoreQualityTier.values.toSet(), ladder.tiers.toSet());
    });

    test('states what each tier withholds, as the shared table does', () {
      for (final row in _list(_vectors()['tiers'])) {
        final tier = _tier(row['tier']);
        expect(
          ladder.withholds(tier, CoreQualityEffect.refraction),
          row['refraction'] == false,
          reason: '$tier refraction',
        );
        expect(
          ladder.withholds(tier, CoreQualityEffect.backdropPass),
          row['backdropPass'] == false,
          reason: '$tier backdrop pass',
        );
      }
    });

    test('reaches only the rungs that stop drawing something the surfaces '
        'draw, as the shared table does', () {
      for (final row in _list(_vectors()['reach'])) {
        final drawable = {
          for (final name in row['drawable']! as List)
            CoreQualityEffect.values.byName(name as String),
        };
        expect(ladder.reachable(drawable), [
          for (final name in row['rungs']! as List) _tier(name),
        ], reason: '$drawable');
      }
    });

    test('a reduce-transparency preference is the first tier that leaves out '
        'both the bend and the pass', () {
      expect(
        ladder.effective(CoreQualityTier.full, reduceTransparency: true),
        CoreQualityTier.solid,
      );
      expect(
        ladder.effective(
          CoreQualityTier.noRefraction,
          reduceTransparency: true,
        ),
        CoreQualityTier.solid,
      );
      expect(
        ladder.effective(
          CoreQualityTier.noRefraction,
          reduceTransparency: false,
        ),
        CoreQualityTier.noRefraction,
      );
      // Not a tier the preference could ever be "lower" than.
      expect(
        ladder.effective(CoreQualityTier.solid, reduceTransparency: true),
        CoreQualityTier.solid,
      );
    });

    test('the order and what each rung drops are data: another ladder is '
        'another answer from the same code', () {
      const reordered = CoreQualityLadder([
        CoreQualityStep(CoreQualityTier.full),
        CoreQualityStep(
          CoreQualityTier.noRefraction,
          drops: {CoreQualityEffect.backdropPass},
        ),
        CoreQualityStep(
          CoreQualityTier.solid,
          drops: {CoreQualityEffect.refraction},
        ),
      ]);
      // Nothing about the first tier below the top is built into the type: it
      // withholds what its entry says, and the one beneath it adds to that.
      expect(
        reordered.withholds(
          CoreQualityTier.noRefraction,
          CoreQualityEffect.refraction,
        ),
        isFalse,
      );
      expect(
        reordered.withholds(
          CoreQualityTier.solid,
          CoreQualityEffect.refraction,
        ),
        isTrue,
      );
      expect(
        reordered.withholds(
          CoreQualityTier.solid,
          CoreQualityEffect.backdropPass,
        ),
        isTrue,
        reason: 'the union down to the rung',
      );
      // The tier a reduce-transparency preference forces is found by what it
      // removes, so it moved with the data.
      expect(
        reordered.firstWithholding(
          CoreQualityLadder.reducedTransparencyWithholds,
        ),
        CoreQualityTier.solid,
      );
      expect(reordered, isNot(ladder));
    });

    test('a tier the ladder has no rung for withholds nothing', () {
      const short = CoreQualityLadder([
        CoreQualityStep(CoreQualityTier.full),
        CoreQualityStep(
          CoreQualityTier.solid,
          drops: {CoreQualityEffect.backdropPass},
        ),
      ]);
      expect(short.indexOf(CoreQualityTier.noRefraction), -1);
      expect(short.withheldAt(CoreQualityTier.noRefraction), isEmpty);
    });

    group('settles a material', () {
      final glass = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);
      final material = glass.surface!;

      test('unchanged at the top, and the same instance', () {
        expect(
          identical(ladder.settle(CoreQualityTier.full, material), material),
          isTrue,
        );
        expect(
          identical(
            ladder.settle(CoreQualityTier.noRefraction, material),
            material,
          ),
          isTrue,
          reason: 'blur and fill stay without the bend',
        );
      });

      test('opaque, with the edge band kept, where the pass is withheld', () {
        final solid = ladder.settle(CoreQualityTier.solid, material)!;
        expect(solid, material.withoutTransparency());
        expect(solid.usesTransparency, isFalse);
        expect(solid.sheen, material.sheen);
        expect(solid.drawsOwnEdge, material.drawsOwnEdge);
      });

      test('a material that was never transparent is left alone', () {
        const flat = CoreSurfaceToken.flat();
        expect(
          identical(ladder.settle(CoreQualityTier.solid, flat), flat),
          isTrue,
        );
        expect(ladder.settle(CoreQualityTier.solid, null), isNull);
      });

      test('takes the bend away from the tier that withholds it, and only '
          'there', () {
        final bend = glass.refraction;
        expect(bend, isNotNull);
        expect(ladder.settleRefraction(CoreQualityTier.full, bend), bend);
        expect(
          ladder.settleRefraction(CoreQualityTier.noRefraction, bend),
          isNull,
        );
        expect(ladder.settleRefraction(CoreQualityTier.solid, bend), isNull);
        expect(ladder.settleRefraction(CoreQualityTier.solid, null), isNull);
      });
    });
  });

  group('the frame budget', () {
    test('is the period of the refresh rate, as the shared table says', () {
      for (final row in _list(_budgetTable()['microsFor'])) {
        expect(
          CoreFrameBudget.microsFor(_hz(row['hz'])),
          row['micros'],
          reason: '${row['hz']} Hz',
        );
      }
      expect(CoreFrameBudget.microsFor(null), 16667);
    });

    test('reads the display off the frames, as the shared table says', () {
      for (final row in _list(_budgetTable()['estimate'])) {
        final intervals = [
          for (final run in row['intervals']! as List)
            ...List.filled((run as List)[1] as int, run[0] as int),
        ];
        expect(
          CoreFrameBudget.estimateRefreshRate(intervals),
          (row['hz'] as num?)?.toDouble(),
          reason: row['name']! as String,
        );
      }
    });
  });

  group('percentile (nearest rank)', () {
    test('picks a value that happened, never between two', () {
      final hundred = List<int>.generate(100, (i) => i + 1);
      expect(CoreFrameStats.percentile(hundred, 95), 95);
      expect(CoreFrameStats.percentile(hundred, 75), 75);
      expect(CoreFrameStats.percentile(hundred, 100), 100);
      expect(CoreFrameStats.percentile(hundred, 1), 1);
      expect(CoreFrameStats.percentile([7], 95), 7);
      expect(CoreFrameStats.percentile([3, 1, 2], 50), 2);
    });

    test('does not reorder its input and refuses an empty one', () {
      final values = [3, 1, 2];
      CoreFrameStats.percentile(values, 50);
      expect(values, [3, 1, 2]);
      expect(
        () => CoreFrameStats.percentile(const [], 50),
        throwsArgumentError,
      );
    });
  });

  group('the governor replays the shared table', () {
    for (final trace in _list(_vectors()['traces'])) {
      test(trace['name']! as String, () {
        final run = _replay(trace);
        final expected = _list(trace['expect']);
        expect(
          [
            for (final (frame, change) in run.changes)
              {
                'frame': frame,
                'from': change.from.name,
                'to': change.to.name,
                'reason': change.reason.name,
              },
          ],
          [
            for (final e in expected)
              {
                'frame': e['frame'],
                'from': e['from'],
                'to': e['to'],
                'reason': e['reason'],
              },
          ],
        );
        expect(run.governor.tier, _tier(trace['final']));
      });
    }
  });

  group('the governor', () {
    CoreQualityGovernor make({
      int budget = 16667,
      CoreFrameMetric metric = CoreFrameMetric.cost,
      CoreQualityTier? initial,
      void Function(CoreQualityChange)? onChange,
      CoreQualityTuning tuning = const CoreQualityTuning(),
      bool allowStepUp = true,
    }) => CoreQualityGovernor(
      rungs: CoreQualityLadder.standard.tiers,
      metric: metric,
      budgetMicros: budget,
      initial: initial,
      onChange: onChange,
      tuning: tuning,
      allowStepUp: allowStepUp,
    );

    test('counts the same seconds in frames at any refresh rate', () {
      expect(make().frameCounts, (
        skip: 90,
        warmup: 180,
        window: 120,
        settle: 60,
      ));
      expect(
        make(budget: CoreFrameBudget.microsFor(120)).frameCounts,
        (skip: 180, warmup: 360, window: 240, settle: 120),
      );
      expect(
        make(budget: CoreFrameBudget.microsFor(30)).frameCounts,
        (skip: 45, warmup: 90, window: 60, settle: 30),
      );
    });

    test('starts in the warm-up at the top, or in the runtime at the initial '
        'tier', () {
      expect(make().phase, CoreQualityPhase.warmup);
      expect(make().tier, CoreQualityTier.full);
      final restored = make(initial: CoreQualityTier.noRefraction);
      expect(restored.phase, CoreQualityPhase.runtime);
      expect(restored.tier, CoreQualityTier.noRefraction);
    });

    test('reports what it decided on', () {
      final changes = <CoreQualityChange>[];
      final governor = make(onChange: changes.add);
      var at = 0;
      for (var i = 0; i < 270; i++) {
        at += 33000;
        governor.add(i < 90 ? 1000 : 33000, at);
      }
      expect(changes, hasLength(1));
      final change = changes.single;
      expect(change.from, CoreQualityTier.full);
      expect(change.to, CoreQualityTier.solid);
      expect(change.reason, CoreQualityReason.warmup);
      expect(change.metric, CoreFrameMetric.cost);
      expect(change.framesMeasured, 180);
      expect(change.percentileMillis, 33);
      expect(change.budgetMillis, closeTo(16.667, 1e-9));
      expect(governor.phase, CoreQualityPhase.runtime);
    });

    test('holds nest, and measuring resumes only after the last release '
        'and the settle', () {
      final changes = <CoreQualityChange>[];
      final governor = make(
        initial: CoreQualityTier.noRefraction,
        onChange: changes.add,
        tuning: const CoreQualityTuning(
          skipSeconds: 0.01,
          windowSeconds: 0.02,
          settleSeconds: 0.05,
          cooldownSeconds: 0,
        ),
      );
      final counts = governor.frameCounts;
      var at = 0;
      void feed(int frames, int cost) {
        for (var i = 0; i < frames; i++) {
          at += 33000;
          governor.add(cost, at);
        }
      }

      final first = governor.hold();
      final second = governor.hold();
      expect(governor.measurementHeld, isTrue);
      feed(1000, 90000);
      first
        ..release()
        ..release(); // twice does nothing
      expect(governor.measurementHeld, isTrue, reason: 'one hold still open');
      feed(1000, 90000);
      second.release();
      expect(second.released, isTrue);
      expect(governor.measurementHeld, isTrue, reason: 'settling');
      expect(changes, isEmpty);

      feed(counts.settle, 90000);
      expect(governor.measurementHeld, isFalse);
      expect(changes, isEmpty, reason: 'the settle frames are not judged');

      // After the skip and two windows the overload is finally judged.
      feed(counts.skip + 2 * counts.window, 90000);
      expect(changes, hasLength(1));
      expect(changes.single.reason, CoreQualityReason.overrun);
    });

    test('a failed step up doubles the wait, at most maxBackoffDoublings '
        'times', () {
      final feed = _Feeder(
        make(
          initial: CoreQualityTier.solid,
          tuning: _quickTuning(
            recoverWindows: 2,
            probationWindows: 3,
            maxBackoffDoublings: 2,
          ),
        ),
      )..skip();
      final governor = feed.governor;

      expect(governor.recoverWindowsNeeded, 2);
      feed.windows(2, 3000); // up: solid -> noRefraction
      expect(governor.tier, CoreQualityTier.noRefraction);
      feed.windows(1, 30000); // lost again inside the probation
      expect(governor.tier, CoreQualityTier.solid);
      expect(governor.recoverWindowsNeeded, 4);

      feed.windows(4, 3000);
      expect(governor.tier, CoreQualityTier.noRefraction);
      feed.windows(1, 30000);
      expect(governor.recoverWindowsNeeded, 8);

      feed
        ..windows(8, 3000)
        ..windows(1, 30000);
      expect(
        governor.recoverWindowsNeeded,
        8,
        reason: 'capped at maxBackoffDoublings doublings',
      );

      // A step up that survives the probation clears the debt.
      feed.windows(8, 3000);
      expect(governor.tier, CoreQualityTier.noRefraction);
      feed.windows(3, 3000);
      expect(governor.recoverWindowsNeeded, 2);
    });

    test('a step up lost after its probation is over is not a failed one', () {
      final feed = _Feeder(
        make(
          initial: CoreQualityTier.solid,
          tuning: _quickTuning(recoverWindows: 3, probationWindows: 2),
        ),
      )..skip();

      expect(feed.governor.tier, CoreQualityTier.solid);
      feed.windows(3, 3000);
      expect(feed.governor.tier, CoreQualityTier.noRefraction);
      feed.windows(2, 3000); // the probation, survived
      expect(feed.governor.tier, CoreQualityTier.noRefraction);
      feed.windows(1, 30000);
      expect(feed.governor.tier, CoreQualityTier.solid);
      expect(feed.governor.recoverWindowsNeeded, 3);
    });

    test('a reset forgets the debt as well as the frames', () {
      final feed = _Feeder(
        make(
          initial: CoreQualityTier.solid,
          tuning: _quickTuning(recoverWindows: 1, probationWindows: 3),
        ),
      )..skip();
      final governor = feed.governor;

      feed
        ..windows(1, 3000)
        ..windows(1, 30000);
      expect(governor.recoverWindowsNeeded, 2);
      governor.reset();
      expect(governor.recoverWindowsNeeded, 1);
      expect(governor.phase, CoreQualityPhase.warmup);
    });

    test('judges against the new budget after the display changes its rate, '
        'and drops the window it was collecting', () {
      final governor = make();
      expect(governor.frameCounts.window, 120);
      governor.setBudget(CoreFrameBudget.microsFor(120));
      expect(governor.budgetMicros, 8333);
      expect(governor.frameCounts.window, 240);
      governor.setBudget(8333); // same: nothing to do
      expect(governor.frameCounts.window, 240);
    });

    test('carries the skip it still owes over to the new budget as time', () {
      // Learning the display is 120 Hz is not having spent the half second a
      // 60 Hz governor owed: the warm-up must not start measuring on frames
      // the old budget counted. At 120 Hz the skip is 180 frames, 90 of which
      // are owed after 45 frames of the 60 Hz skip have gone.
      final governor = make();
      final feed = _Feeder(governor)..frames(45, 1000);
      governor.setBudget(CoreFrameBudget.microsFor(120));
      final counts = governor.frameCounts;
      expect(counts.skip, 180);

      // 90 frames of the new budget are the 45 that were left of the old one,
      // then the warm-up proper.
      feed.frames(90 + counts.warmup - 1, 1000);
      expect(governor.phase, CoreQualityPhase.warmup);
      feed.frames(1, 1000);
      expect(governor.phase, CoreQualityPhase.runtime);
    });

    test('and the settle after a hold, the same way', () {
      final governor = make();
      governor.hold().release();
      expect(governor.frameCounts.settle, 60);
      governor.setBudget(CoreFrameBudget.microsFor(120));

      // Still held: a settle of 120 frames, not the old 60.
      final feed = _Feeder(governor)..frames(119, 1000);
      expect(governor.measurementHeld, isTrue);
      feed.frames(1, 1000);
      expect(governor.measurementHeld, isFalse);
    });

    test('ignores a negative cost and never steps below the last rung', () {
      final governor = make(initial: CoreQualityTier.solid);
      var at = 0;
      for (var i = 0; i < 2000; i++) {
        at += 40000;
        governor.add(i.isEven ? -5 : 40000, at);
      }
      expect(governor.tier, CoreQualityTier.solid);
    });

    test('with one rung there is nowhere to go', () {
      final governor = CoreQualityGovernor(
        rungs: const [CoreQualityTier.full],
        metric: CoreFrameMetric.cost,
        budgetMicros: 16667,
      );
      var at = 0;
      for (var i = 0; i < 1000; i++) {
        at += 90000;
        governor.add(90000, at);
      }
      expect(governor.tier, CoreQualityTier.full);
    });
  });

  group('what an app states', () {
    const both = {CoreQualityEffect.refraction, CoreQualityEffect.backdropPass};

    test('states nothing: the top, no governor, off', () {
      const stated = CoreAdaptiveQuality();
      expect(stated.startTier(both), CoreQualityTier.full);
      expect(stated.allowStepUp, isTrue);
      expect(stated.forced, isNull);
    });

    test('a forced tier is held and nothing is measured', () {
      const stated = CoreAdaptiveQuality(forced: CoreQualityTier.noRefraction);
      expect(stated.startTier(both), CoreQualityTier.noRefraction);
      expect(
        stated.governor(
          drawable: both,
          metric: CoreFrameMetric.cost,
          budgetMicros: 16667,
          onChange: (_) {},
        ),
        isNull,
      );
    });

    test('forced wins over an initial tier', () {
      const stated = CoreAdaptiveQuality(
        forced: CoreQualityTier.solid,
        initialQuality: CoreQualityTier.noRefraction,
      );
      expect(stated.startTier(both), CoreQualityTier.solid);
    });

    test('an initial tier is where the governor starts, without a warm-up', () {
      const stated = CoreAdaptiveQuality(
        initialQuality: CoreQualityTier.noRefraction,
      );
      expect(stated.startTier(both), CoreQualityTier.noRefraction);
      final governor = stated.governor(
        drawable: both,
        metric: CoreFrameMetric.cost,
        budgetMicros: 16667,
        onChange: (_) {},
      )!;
      expect(governor.tier, CoreQualityTier.noRefraction);
      expect(governor.phase, CoreQualityPhase.runtime);
    });

    test('an initial tier with no rung starts at the one that looks the '
        'same', () {
      const stated = CoreAdaptiveQuality(
        initialQuality: CoreQualityTier.noRefraction,
      );
      // An engine that draws no bend: the rung is not a step.
      expect(
        stated.startTier(const {CoreQualityEffect.backdropPass}),
        CoreQualityTier.full,
      );
    });

    test('never goes below the lowest tier it names', () {
      const stated = CoreAdaptiveQuality(lowest: CoreQualityTier.noRefraction);
      expect(stated.rungs(both), [
        CoreQualityTier.full,
        CoreQualityTier.noRefraction,
      ]);
    });

    test('has no governor when there is only one rung to be on', () {
      const stated = CoreAdaptiveQuality();
      expect(
        stated.governor(
          drawable: const {},
          metric: CoreFrameMetric.cost,
          budgetMicros: 16667,
          onChange: (_) {},
        ),
        isNull,
      );
      const floored = CoreAdaptiveQuality(lowest: CoreQualityTier.full);
      expect(
        floored.governor(
          drawable: both,
          metric: CoreFrameMetric.cost,
          budgetMicros: 16667,
          onChange: (_) {},
        ),
        isNull,
      );
    });

    test('judges against the rate it targets when it states one, else the '
        "display's", () {
      expect(const CoreAdaptiveQuality().budgetMicros(120), 8333);
      expect(const CoreAdaptiveQuality().budgetMicros(null), 16667);
      expect(
        const CoreAdaptiveQuality(targetFrameRate: 60).budgetMicros(120),
        16667,
      );
    });

    test('compares by value', () {
      void noop(CoreQualityChange _) {}
      expect(
        CoreAdaptiveQuality(
          forced: CoreQualityTier.solid,
          onQualityChanged: noop,
        ),
        CoreAdaptiveQuality(
          forced: CoreQualityTier.solid,
          onQualityChanged: noop,
        ),
      );
      expect(
        const CoreAdaptiveQuality(),
        isNot(const CoreAdaptiveQuality(allowStepUp: false)),
      );
      expect(
        const CoreAdaptiveQuality(),
        isNot(const CoreAdaptiveQuality(targetFrameRate: 60)),
      );
      expect(
        const CoreAdaptiveQuality(),
        isNot(
          const CoreAdaptiveQuality(
            tuning: CoreQualityTuning(windowSeconds: 3),
          ),
        ),
      );
    });
  });
}

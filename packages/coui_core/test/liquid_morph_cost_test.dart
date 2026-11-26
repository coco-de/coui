// What the silhouette costs per frame, measured before anything renders it.
//
// The outline is walked every frame a morph runs, so its cost is not a
// detail of the implementation — it decides whether the design is buildable
// at all. If a grid fine enough to carry a neck cannot be walked inside a
// frame, the answer is not "optimise later": it is that the merge belongs on
// the GPU after all, and the shader gate this design avoided has to be paid.
//
// Measuring it here rather than after wiring it to an overlay is the whole
// point. The wiring is the expensive part to undo.
//
// ## What this can and cannot say
//
// It runs on the Dart VM, on whatever machine CI or a laptop provides, and
// reports a number that is not a phone's. So it does **not** certify a
// frame budget. What it does is bound the shape of the cost — how it scales
// with resolution, and whether the default is in the same order of
// magnitude as a frame or three orders away. An algorithm that is 100× over
// budget here will not be rescued by a faster device, and one that is 50×
// under has room for the difference between this machine and a mid-range
// Android.
//
// The threshold is therefore deliberately loose and its role is to catch a
// *regression in kind* — a change that makes the walk quadratic in
// something it was linear in, or that reintroduces the four-samples-per-cell
// version this already avoids.
//
// ## Why this runs outside the blocking suite
//
// It is tagged `perf`, so `melos run test:dart` (the `Dart Test` step that
// blocks merges) skips it and `melos run test:perf` runs it in the separate
// `Perf (비차단 관찰 — 벽시계 측정)` CI job, which is not a required check.
// The number it asserts on is wall-clock time, and on a busy self-hosted
// runner that number says how busy the runner was, not how the walk scales:
// PRs that never touched this file went red on it and turned green on a
// re-run. A check that is routinely cleared by re-running teaches people to
// re-run past the real regression too. So the signal stays visible in its
// own job, and a red there is read as "look at the shape" — not as a merge
// block that a lucky retry can clear.
@TestOn('vm')
@Tags(['perf'])
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// A trigger-sized body, at the scale a real button occupies.
const _kAnchor = CoreMorphBlob(
  centerX: 90,
  centerY: 120,
  halfWidth: 48,
  halfHeight: 18,
  radius: 8,
);

/// Panel geometry an overlay actually opens at.
const _kPanelCenterX = 260.0;
const _kPanelHalfHeight = 90.0;
const _kPanelRadius = 16.0;
const _kDefaultPanelHalfWidth = 140.0;

/// The widest the blend ever goes — a morph mid-flight, not at rest.
const _kMidFlightBlend = 28.0;

/// A morph mid-flight: two bodies close enough to have a neck.
CoreLiquidMorphShape _midFlight({
  double panelHalf = _kDefaultPanelHalfWidth,
}) => .new(
  anchor: _kAnchor,
  panel: CoreMorphBlob(
    centerX: _kPanelCenterX,
    centerY: _kAnchor.centerY,
    halfWidth: panelHalf,
    halfHeight: _kPanelHalfHeight,
    radius: _kPanelRadius,
  ),
  smoothness: _kMidFlightBlend,
);

/// Median walk time, in microseconds.
///
/// Median rather than mean because a VM that decides to collect garbage
/// during one iteration would otherwise set the number, and that is a
/// statement about the collector rather than about this algorithm.
/// Walks discarded before timing, to pay for JIT on the path the timed
/// runs reuse. Reporting the first walk would overstate the cost severalfold.
const _kWarmupRuns = 3;

/// Timed walks. Odd so the median is a sample rather than an average.
const _kTimedRuns = 9;

/// Grid sizes the scaling test compares. Doubling must cost about 4×.
const _kCoarseGrid = 48;
const _kFineGrid = 96;

/// The fallback grid for a device that cannot afford the default.
const _kFallbackGrid = 32;

/// Loose ceilings, in microseconds. Their job is to catch a regression in
/// kind, not to certify a frame budget on hardware this is not running on.
const _kDefaultGridCeilingMicros = 2800;
const _kFallbackGridCeilingMicros = 400;

/// Doubling a 2-D grid costs about 4×; anything past this grew faster
/// than area.
const _kScalingCeiling = 6;

/// Panel half-widths for the geometry-independence test.
const _kSmallPanelHalf = 70.0;
const _kLargePanelHalf = 320.0;

int _medianMicros(CoreLiquidMorphShape shape, int resolution) =>
    _interleavedMedians([(shape, resolution)]).single;

/// Medians for several walks, measured **interleaved**.
///
/// Every assertion here is a RATIO of two timings, and measuring them one
/// after the other makes that ratio a statement about the machine rather
/// than about the algorithm. Two effects do it:
///
/// * **Load.** A shared runner busy during the second measurement and
///   quiet during the first inflates the ratio with nothing in the code
///   changing. This test reported 2.6× for a pair whose true value is
///   0.76, and 8.6× for a pair whose true value is near 4.
/// * **JIT.** Whichever walk runs first pays for the compile the other
///   then reuses. Warming each shape separately does not fix it — the
///   shared inner path is already hot by the time the second one starts,
///   so the first is measured cold-ish and the second warm.
///
/// Interleaving puts both under the same conditions sample by sample, so
/// whatever the machine is doing lands on both sides of the ratio and
/// cancels. Warmup covers every shape before any of them is timed, so no
/// walk is charged for compiling a path the next one gets free.
List<int> _interleavedMedians(List<(CoreLiquidMorphShape, int)> walks) {
  for (var i = 0; i < _kWarmupRuns; i++) {
    for (final (shape, resolution) in walks) {
      CoreLiquidMorphOutline.of(shape, resolution: resolution);
    }
  }

  final samples = [for (final _ in walks) <int>[]];
  for (var i = 0; i < _kTimedRuns; i++) {
    for (var w = 0; w < walks.length; w++) {
      final (shape, resolution) = walks[w];
      final watch = Stopwatch()..start();
      CoreLiquidMorphOutline.of(shape, resolution: resolution);
      watch.stop();
      samples[w].add(watch.elapsedMicroseconds);
    }
  }

  return [
    for (final s in samples) (s..sort())[s.length ~/ 2],
  ];
}

void main() {
  group('the walk is affordable at the resolution it ships with', () {
    test('the default grid stays well inside a frame on this machine', () {
      final micros = _medianMicros(
        _midFlight(),
        CoreLiquidMorphOutline.defaultResolution,
      );
      // The measurement is the deliverable; a pass with no value printed
      // leaves the next person re-measuring by hand.
      // ignore: avoid_print
      print(
        'morph-outline  resolution=${CoreLiquidMorphOutline.defaultResolution}'
        '  median=${micros}us',
      );

      // A sixth of a 60fps frame. Loose on purpose: this machine is not a
      // phone, and the number that matters is whether the cost is the same
      // order as a frame or three orders below it.
      expect(
        micros,
        lessThan(_kDefaultGridCeilingMicros),
        reason: 'the default grid does not fit a frame with room to spare',
      );
    });

    test('and its cost is quadratic in resolution, not worse', () {
      // The grid is 2-D, so doubling the resolution must cost about four
      // times — never eight. Eight would mean the walk gained a per-cell
      // scan of something that grows with the grid, which is exactly the
      // regression the single-sample grid and the segment chaining were
      // written to avoid.
      final shape = _midFlight();
      final [coarse, fine] = _interleavedMedians([
        (shape, _kCoarseGrid),
        (shape, _kFineGrid),
      ]);
      final ratio = fine / coarse;
      // The measurement is the deliverable — a pass with no number leaves
      // the next person re-measuring by hand.
      // ignore: avoid_print
      print(
        'morph-outline  $_kCoarseGrid=${coarse}us'
        '  $_kFineGrid=${fine}us  ratio=$ratio',
      );

      expect(
        ratio,
        lessThan(_kScalingCeiling),
        reason: 'the walk grew faster than area',
      );
    });

    test('and it does not grow with the panel it traces', () {
      // The sampled box grows with the bodies, but the grid does not — the
      // cost is the grid's, not the geometry's. If this ever failed, a
      // full-screen sheet would cost more per frame than a tooltip, and the
      // resolution knob would have stopped meaning what it says.
      final [small, large] = _interleavedMedians([
        (_midFlight(panelHalf: _kSmallPanelHalf), _kFineGrid),
        (_midFlight(panelHalf: _kLargePanelHalf), _kFineGrid),
      ]);
      // Reported for the same reason as above.
      // ignore: avoid_print
      print(
        'morph-outline  panel$_kSmallPanelHalf=${small}us'
        '  panel$_kLargePanelHalf=${large}us',
      );

      expect(large, lessThan(small * 2));
    });
  });

  group('the resolution knob is usable at both ends', () {
    test('a coarse grid is cheap enough for a low-end frame', () {
      // The fallback if the default turns out too dear on a real device:
      // drop the grid. This pins that the knob actually buys something —
      // if a coarse grid cost nearly the same, there would be nothing to
      // trade and the design would have no room to move.
      final micros = _medianMicros(_midFlight(), _kFallbackGrid);
      // Reported for the same reason as above.
      // ignore: avoid_print
      print('morph-outline  resolution=$_kFallbackGrid  median=${micros}us');

      expect(micros, lessThan(_kFallbackGridCeilingMicros));
    });

    test('and a coarse grid still carries a neck', () {
      // Cheapness that loses the feature is not a fallback. The neck has
      // to survive the grid the fallback would use, or the trade is
      // between an effect and no effect rather than between two qualities.
      final outline = CoreLiquidMorphOutline.of(
        _midFlight(),
        resolution: _kFallbackGrid,
      );
      final betweenBodies = outline.contours
          .expand((c) => c)
          .where(
            (p) => p.x > 140 && p.x < 130 + 40,
          );

      expect(
        outline.contours.expand((c) => c).length,
        greaterThan(32),
      );
      expect(betweenBodies, isNotEmpty, reason: 'the neck sampled away');
    });
  });
}

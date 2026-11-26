// How fast the pointer was moving when it let go of a Web drawer, and what the
// release rule makes of it.
//
// The estimate (`CoreDragVelocityTracker`) and the rule
// (`CoreDrawerContract.dismissesOnRelease`) are Core's, pinned by the vector
// table coui_core shares with the Flutter sheet test and the Chrome drawer
// probe (`tool/parity`). This file reads that table through the Web package's
// own export and runs the chain the pointer handler runs — samples in,
// pixels per second out, signed for the edge the panel hides behind, handed
// to the rule — so a Web build that stopped exporting the tracker, or a
// change to the table that Flutter had not followed, fails here.
//
// The handler itself needs a real `web.PointerEvent`, which the VM does not
// have (see `drawer_sheet_test.dart`). What this file cannot see — that the
// handler feeds the tracker the event's own clock in the right unit, and
// re-signs the reading for the edge — is what the Chrome probe
// (`tool/parity/test/web/drawer_fling_probe_test.dart`) drives with real
// input, on every side.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

/// The vector table shared with Core, Flutter and the Chrome drawer probe
/// (cwd is `packages/coui_web` under `dart test`).
const String kDragReleaseVectorsPath =
    '../coui_core/test/fixtures/drag_release_vectors.json';

/// A display's frame, which is how often a browser reports a moving pointer.
const Duration kFrame = Duration(milliseconds: 16);

/// The sign of a position that grows when the pointer moves toward the edge
/// the panel hides behind: `+1` for right / bottom, `-1` for left / top —
/// the handler's `_dismissSign`, restated because the handler is private to
/// a component the VM cannot drive.
const Map<CoreDrawerSide, double> kDismissSign = {
  CoreDrawerSide.bottom: 1,
  CoreDrawerSide.right: 1,
  CoreDrawerSide.top: -1,
  CoreDrawerSide.left: -1,
};

/// What releasing a stroke does, run the way the Web drawer's pointer
/// handlers run it: the press and every move are samples (the lift is not),
/// the release asks the tracker as of the lift and hands the rule the reading
/// re-signed for the edge.
///
/// The stroke covers [travel] px toward the hiding edge (negative = back
/// toward the docked edge) in [duration] at a constant speed, one move per
/// [kFrame] — the last one landing exactly at [duration] — and the pointer
/// lifts [hold] later.
bool releaseDismisses({
  required CoreDrawerSide side,
  required double travel,
  required Duration duration,
  required double panelExtent,
  required double threshold,
  Duration hold = Duration.zero,
}) {
  final sign = kDismissSign[side]!;
  final tracker = CoreDragVelocityTracker();
  const start = 400.0;

  tracker.addSample(Duration.zero, start);
  final frames = (duration.inMicroseconds / kFrame.inMicroseconds).ceil();
  var position = start;
  for (var i = 1; i <= frames; i++) {
    final progress = i / frames;
    position = start + sign * travel * progress;
    tracker.addSample(duration * progress, position);
  }

  // What `_dragDelta` holds: only motion toward the hiding edge counts.
  final dragged = ((position - start) * sign).clamp(0.0, double.infinity);

  return CoreDrawerContract.dismissesOnRelease(
    dragDistance: dragged,
    panelExtent: panelExtent,
    threshold: threshold,
    velocity: tracker.velocityAt(duration + hold) * sign,
  );
}

void main() {
  final doc =
      jsonDecode(File(kDragReleaseVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final trackerCases =
      ((doc['tracker']! as Map<String, Object?>)['cases']! as List)
          .cast<Map<String, Object?>>();
  final gestures = doc['gestures']! as Map<String, Object?>;
  final gestureCases = (gestures['cases']! as List)
      .cast<Map<String, Object?>>();
  final extent = (gestures['extent']! as num).toDouble();
  final threshold = (gestures['threshold']! as num).toDouble();

  group('the tracker a Web build ships reads the shared vectors', () {
    for (final c in trackerCases) {
      test(c['name']! as String, () {
        final tracker = CoreDragVelocityTracker();
        for (final sample in (c['samples']! as List).cast<List<Object?>>()) {
          // The table is in milliseconds, as a browser stamps its events.
          tracker.addSample(
            Duration(microseconds: ((sample[0]! as num) * 1000).round()),
            (sample[1]! as num).toDouble(),
          );
        }
        // Asked as the pointer-up handler asks, when the case names a lift.
        final readAtMs = c['readAtMs'] as num?;
        final reading = readAtMs == null
            ? tracker.velocity
            : tracker.velocityAt(
                Duration(microseconds: (readAtMs * 1000).round()),
              );

        expect(reading, closeTo((c['pxPerSec']! as num).toDouble(), 1e-6));
      });
    }
  });

  group('a Web drawer release, from pointer samples to the verdict', () {
    test('the table drives a panel of the default threshold', () {
      expect(threshold, CoreDrawerContract.defaultDragDismissThreshold);
    });

    for (final side in CoreDrawerSide.values) {
      group('${side.name} drawer', () {
        for (final c in gestureCases) {
          test(c['name']! as String, () {
            final verdict = releaseDismisses(
              side: side,
              travel: (c['travel']! as num).toDouble(),
              duration: Duration(
                microseconds: ((c['durationMs']! as num) * 1000).round(),
              ),
              hold: Duration(
                microseconds: (((c['holdMs'] as num?) ?? 0) * 1000).round(),
              ),
              panelExtent: extent,
              threshold: threshold,
            );

            expect(verdict, c['dismisses']);
          });
        }
      });
    }
  });
}

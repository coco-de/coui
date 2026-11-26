// How a released drag on a Drawer is judged: how fast the pointer was moving
// (CoreDragVelocityTracker) and whether that, with the distance, dismisses the
// panel (CoreDrawerContract.dismissesOnRelease). Both are pinned by one vector
// table. Flutter's gesture recognisers measure the velocity themselves and the
// Web seat feeds this tracker, so the table is also what the Flutter sheet and
// a real-Chrome probe of the Web drawer are held to — a rule that changes on
// one platform fails the other.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter sheet test, the Web chain test and
/// the Chrome drawer probe.
const String kDragReleaseVectorsPath =
    'test/fixtures/drag_release_vectors.json';

void main() {
  final doc =
      jsonDecode(File(kDragReleaseVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final tracker = doc['tracker']! as Map<String, Object?>;
  final trackerCases = (tracker['cases']! as List).cast<Map<String, Object?>>();
  final releaseCases =
      ((doc['release']! as Map<String, Object?>)['cases']! as List)
          .cast<Map<String, Object?>>();
  final gestures = doc['gestures']! as Map<String, Object?>;
  final gestureCases = (gestures['cases']! as List)
      .cast<Map<String, Object?>>();

  test('the vector tables are not empty', () {
    expect(trackerCases, isNotEmpty);
    expect(releaseCases, isNotEmpty);
    expect(gestureCases, isNotEmpty);
  });

  test('the table is measured the way the tracker measures', () {
    expect(
      Duration(milliseconds: tracker['horizonMs']! as int),
      CoreDragVelocityTracker.defaultHorizon,
    );
    expect(
      Duration(milliseconds: tracker['stoppedGapMs']! as int),
      CoreDragVelocityTracker.defaultStoppedGap,
    );
  });

  group('CoreDragVelocityTracker against the shared vectors', () {
    for (final c in trackerCases) {
      test(c['name']! as String, () {
        final velocity = CoreDragVelocityTracker();
        for (final sample in (c['samples']! as List).cast<List<Object?>>()) {
          velocity.addSample(
            Duration(microseconds: ((sample[0]! as num) * 1000).round()),
            (sample[1]! as num).toDouble(),
          );
        }
        // A case that names a moment to read at is asked as the release asks:
        // at the lift. One that does not is read as of its newest sample.
        final readAtMs = c['readAtMs'] as num?;
        final reading = readAtMs == null
            ? velocity.velocity
            : velocity.velocityAt(
                Duration(microseconds: (readAtMs * 1000).round()),
              );

        expect(reading, closeTo((c['pxPerSec']! as num).toDouble(), 1e-6));
      });
    }
  });

  group('CoreDragVelocityTracker', () {
    test('forgets a gesture on reset', () {
      final velocity = CoreDragVelocityTracker()
        ..addSample(Duration.zero, 0)
        ..addSample(const Duration(milliseconds: 10), 12);
      expect(velocity.velocity, 1200);

      velocity.reset();
      expect(velocity.velocity, 0);
      expect(velocity.sampleCount, 0);
    });

    test('a read with nothing sampled is no direction', () {
      final velocity = CoreDragVelocityTracker();

      expect(velocity.velocityAt(const Duration(seconds: 1)), 0);
      expect(velocity.velocity, 0);
    });

    test('a read at the newest sample is the velocity', () {
      final velocity = CoreDragVelocityTracker()
        ..addSample(Duration.zero, 0)
        ..addSample(const Duration(milliseconds: 10), 12)
        ..addSample(const Duration(milliseconds: 20), 24);

      expect(
        velocity.velocityAt(const Duration(milliseconds: 20)),
        velocity.velocity,
      );
    });

    test('keeps no more than the window it can read', () {
      // A drag that goes on for minutes must not grow without bound.
      final velocity = CoreDragVelocityTracker();
      for (var ms = 0; ms <= 60000; ms += 8) {
        velocity.addSample(Duration(milliseconds: ms), ms * 0.5);
      }

      expect(velocity.sampleCount, lessThan(20));
      expect(velocity.velocity, closeTo(500, 1e-6));
    });

    test("the window is the caller's to widen", () {
      // 150 ms of steady motion: the default window reads the last 100.
      final wide = CoreDragVelocityTracker(
        horizon: const Duration(milliseconds: 300),
      );
      final narrow = CoreDragVelocityTracker();
      for (var ms = 0; ms <= 150; ms += 10) {
        // Quickens after 100 ms, so a wider window reads a lower average.
        final position = ms <= 100 ? ms * 1.0 : 100 + (ms - 100) * 5.0;
        wide.addSample(Duration(milliseconds: ms), position);
        narrow.addSample(Duration(milliseconds: ms), position);
      }

      expect(narrow.velocity, greaterThan(wide.velocity));
    });

    test('a sample past the horizon is not read, pause or no pause', () {
      // A stopped gap wider than the horizon: the only thing keeping the
      // 200 ms-old sample out of the estimate is the horizon itself.
      final velocity =
          CoreDragVelocityTracker(
              horizon: const Duration(milliseconds: 50),
              stoppedGap: const Duration(milliseconds: 500),
            )
            ..addSample(Duration.zero, 0)
            ..addSample(const Duration(milliseconds: 200), 200);

      expect(velocity.velocity, 0);
    });
  });

  group('CoreDrawerContract.dismissesOnRelease against the shared vectors', () {
    for (final c in releaseCases) {
      test(c['name']! as String, () {
        final threshold = c['velocityThreshold'];
        final verdict = threshold == null
            ? CoreDrawerContract.dismissesOnRelease(
                dragDistance: (c['dragDistance']! as num).toDouble(),
                panelExtent: (c['panelExtent']! as num).toDouble(),
                threshold: (c['threshold']! as num).toDouble(),
                velocity: (c['velocity']! as num).toDouble(),
              )
            : CoreDrawerContract.dismissesOnRelease(
                dragDistance: (c['dragDistance']! as num).toDouble(),
                panelExtent: (c['panelExtent']! as num).toDouble(),
                threshold: (c['threshold']! as num).toDouble(),
                velocity: (c['velocity']! as num).toDouble(),
                velocityThreshold: (threshold as num).toDouble(),
              );

        expect(verdict, c['dismisses']);
      });
    }
  });

  group('the release rule keeps its old call shape', () {
    test('a caller that states no velocity gets the distance rule alone', () {
      // Every call written before speed existed passes no velocity; none of
      // them may start dismissing on something they never measured.
      expect(
        CoreDrawerContract.dismissesOnRelease(
          dragDistance: 40,
          panelExtent: 300,
          threshold: CoreDrawerContract.defaultDragDismissThreshold,
        ),
        isFalse,
      );
      expect(
        CoreDrawerContract.dismissesOnRelease(
          dragDistance: 150,
          panelExtent: 300,
          threshold: CoreDrawerContract.defaultDragDismissThreshold,
        ),
        isTrue,
      );
    });

    test('the default velocity is pixels per second, not per millisecond', () {
      // A browser's deltas are per millisecond; this constant is compared
      // against pixels per second: 400 px/s is 0.4 px/ms.
      expect(CoreDrawerContract.defaultDismissVelocity, 400);
    });
  });

  group('the gesture table is consistent with the rule it exercises', () {
    final extent = (gestures['extent']! as num).toDouble();
    final threshold = (gestures['threshold']! as num).toDouble();

    for (final c in gestureCases) {
      test(c['name']! as String, () {
        final travel = (c['travel']! as num).toDouble();
        final durationMs = (c['durationMs']! as num).toDouble();
        final holdMs = (c['holdMs'] as num?)?.toDouble() ?? 0;
        // A hold longer than the stopped gap leaves nothing moving at the
        // lift; otherwise the stroke's constant speed: px/ms * 1000 = px/s.
        final held =
            holdMs > CoreDragVelocityTracker.defaultStoppedGap.inMilliseconds;
        final speed = held ? 0.0 : travel / durationMs * 1000;

        expect(
          CoreDrawerContract.dismissesOnRelease(
            dragDistance: travel,
            panelExtent: extent,
            threshold: threshold,
            velocity: speed,
          ),
          c['dismisses'],
        );
        // The rows must stay far from the line, or a loaded machine decides
        // them: a real browser delivers its events late, never early.
        if (travel > 0 && !held) {
          final margin = (speed - CoreDrawerContract.defaultDismissVelocity)
              .abs();
          expect(
            margin,
            greaterThan(CoreDrawerContract.defaultDismissVelocity * 0.5),
          );
        }
      });
    }
  });
}

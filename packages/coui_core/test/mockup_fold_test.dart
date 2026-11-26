// The fold rules both platforms read for `MockupFoldable`: which screen is
// lit at an angle, what the app on it is told, and where every part of the
// device is drawn. The poses are a table (`test/fixtures/
// mockup_fold_vectors.json`) derived corner by corner with plain
// trigonometry, independently of the matrices under test, and the Flutter and
// Web transports read the same table.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const String _kVectorsPath = 'test/fixtures/mockup_fold_vectors.json';

/// A projected corner may differ from the table by rounding only: the table
/// keeps six decimals.
const double _kTolerance = 1e-5;

Map<String, dynamic> _readVectors() =>
    jsonDecode(File(_kVectorsPath).readAsStringSync()) as Map<String, dynamic>;

CoreMockupFoldPart _part(CoreMockupFoldPose pose, String name) =>
    switch (name) {
      'innerRight' => pose.innerRight,
      'innerLeft' => pose.innerLeft,
      'cover' => pose.cover,
      'edgeLeft' => pose.edgeLeft,
      'edgeRight' => pose.edgeRight,
      _ => throw ArgumentError.value(name, 'name', 'not a part'),
    };

void main() {
  final doc = _readVectors();
  final geometry = doc['geometry'] as Map<String, dynamic>;
  final width = (geometry['width'] as num).toDouble();
  final height = (geometry['height'] as num).toDouble();
  final thickness = (geometry['thickness'] as num).toDouble();
  final perspective = (geometry['perspective'] as num).toDouble();
  final vectors = (doc['vectors'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  CoreMockupFoldPose poseAt(double angle) => CoreMockupFoldPose.compute(
    angle: angle,
    width: width,
    height: height,
    thickness: thickness,
    perspective: perspective,
  );

  /// The box each part's corners are the corners of.
  ({double width, double height}) boxOf(String name) => switch (name) {
    'cover' => (width: width / 2, height: height),
    'edgeLeft' || 'edgeRight' => (width: thickness, height: height),
    _ => (width: width, height: height),
  };

  group('CoreMockupFold — the rules read from the angle', () {
    test('the table is not empty and covers both ends', () {
      final angles = [for (final v in vectors) (v['angle'] as num).toDouble()];
      expect(angles, containsAll([CoreMockupFold.closed, CoreMockupFold.flat]));
      expect(angles, contains(CoreMockupFold.halfOpen));
    });

    for (final vector in vectors) {
      final angle = (vector['angle'] as num).toDouble();

      test('at $angle° — screen, fold state and screen light', () {
        expect(
          CoreMockupFold.activeScreen(angle).name,
          vector['activeScreen'],
        );
        expect(CoreMockupFold.innerIsFlat(angle), vector['isFlat']);
        expect(CoreMockupFold.foldState(angle).name, vector['foldState']);
        expect(
          1 - CoreMockupFold.innerScreenLight(angle),
          closeTo((vector['innerScreenDim'] as num).toDouble(), _kTolerance),
        );
        expect(
          1 - CoreMockupFold.coverScreenLight(angle),
          closeTo((vector['coverScreenDim'] as num).toDouble(), _kTolerance),
        );
      });
    }

    test('an angle outside the range reads as the nearer end', () {
      expect(CoreMockupFold.clampAngle(-40), CoreMockupFold.closed);
      expect(CoreMockupFold.clampAngle(400), CoreMockupFold.flat);
      expect(poseAt(-40), poseAt(CoreMockupFold.closed));
      expect(poseAt(400), poseAt(CoreMockupFold.flat));
    });

    test('a screen is never lit while the other carries the content', () {
      for (var angle = 0.0; angle <= 180; angle += 1) {
        final onCover =
            CoreMockupFold.activeScreen(angle) == CoreMockupFoldScreen.cover;
        // The content moves at the angle where both screens are dark.
        if (onCover) {
          expect(CoreMockupFold.innerScreenLight(angle), 0, reason: '$angle°');
        } else {
          expect(CoreMockupFold.coverScreenLight(angle), 0, reason: '$angle°');
        }
      }
    });
  });

  group('CoreMockupFoldPose — where each part is drawn', () {
    for (final vector in vectors) {
      final angle = (vector['angle'] as num).toDouble();
      final parts = vector['parts'] as Map<String, dynamic>;

      test('at $angle° — every part lands where the table says', () {
        final pose = poseAt(angle);
        final failures = <String>[];

        for (final entry in parts.entries) {
          final expected = entry.value as Map<String, dynamic>;
          final part = _part(pose, entry.key);
          final box = boxOf(entry.key);
          if (part.visible != expected['visible']) {
            failures.add(
              '${entry.key}: visible ${part.visible}, '
              'table ${expected['visible']}',
            );
          }
          final corners = [
            CoreMockupFoldPose.project(part.matrix, 0, 0),
            CoreMockupFoldPose.project(part.matrix, box.width, 0),
            CoreMockupFoldPose.project(part.matrix, 0, box.height),
            CoreMockupFoldPose.project(part.matrix, box.width, box.height),
          ];
          final table = (expected['corners'] as List<dynamic>)
              .cast<List<dynamic>>();
          for (var i = 0; i < corners.length; i++) {
            final x = (table[i][0] as num).toDouble();
            final y = (table[i][1] as num).toDouble();
            if ((corners[i].x - x).abs() > _kTolerance ||
                (corners[i].y - y).abs() > _kTolerance) {
              failures.add(
                '${entry.key} corner $i: (${corners[i].x}, ${corners[i].y}), '
                'table ($x, $y)',
              );
            }
          }
        }

        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }

    test('open flat, both halves lie where the open body lies', () {
      final pose = poseAt(CoreMockupFold.flat);
      for (final part in [pose.innerLeft, pose.innerRight]) {
        final origin = CoreMockupFoldPose.project(part.matrix, 0, 0);
        final far = CoreMockupFoldPose.project(part.matrix, width, height);
        expect(origin.x, closeTo(0, _kTolerance));
        expect(origin.y, closeTo(0, _kTolerance));
        expect(far.x, closeTo(width, _kTolerance));
        expect(far.y, closeTo(height, _kTolerance));
        expect(part.visible, isTrue);
        expect(part.shade, closeTo(0, _kTolerance));
      }
      expect(pose.isFlat, isTrue);
      expect(pose.cover.visible, isFalse);
    });

    test('shut, the cover stands in the middle of the stage, facing out', () {
      final pose = poseAt(CoreMockupFold.closed);
      final left = CoreMockupFoldPose.project(pose.cover.matrix, 0, 0).x;
      final right = CoreMockupFoldPose.project(
        pose.cover.matrix,
        width / 2,
        0,
      ).x;

      expect(pose.cover.visible, isTrue);
      expect(pose.innerLeft.visible, isFalse);
      // Reads left to right: the hinge end is on the left.
      expect(left, lessThan(right));
      expect((left + right) / 2, closeTo(width / 2, _kTolerance));
      expect(pose.cover.shade, closeTo(0, _kTolerance));
    });

    test('what is drawn stays centred on the stage at every angle', () {
      for (var angle = 0.0; angle <= 180; angle += 3) {
        final pose = poseAt(angle);
        final reach = [
          CoreMockupFoldPose.project(pose.innerRight.matrix, width / 2, 0).x,
          CoreMockupFoldPose.project(pose.innerRight.matrix, width, 0).x,
          CoreMockupFoldPose.project(pose.edgeRight.matrix, thickness, 0).x,
          CoreMockupFoldPose.project(pose.innerLeft.matrix, 0, 0).x,
          CoreMockupFoldPose.project(pose.edgeLeft.matrix, 0, 0).x,
          CoreMockupFoldPose.project(pose.cover.matrix, 0, 0).x,
          CoreMockupFoldPose.project(pose.cover.matrix, width / 2, 0).x,
        ]..sort();

        expect(
          (reach.first + reach.last) / 2,
          closeTo(width / 2, _kTolerance),
          reason: '$angle°',
        );
      }
    });

    test('a part-open device is narrower than an open one', () {
      final pose = poseAt(CoreMockupFold.halfOpen);
      final left = CoreMockupFoldPose.project(pose.innerLeft.matrix, 0, 0).x;
      final right = CoreMockupFoldPose.project(
        pose.innerRight.matrix,
        width,
        0,
      ).x;

      expect(right - left, lessThan(width));
      expect(pose.innerLeft.visible, isTrue);
      expect(pose.innerRight.visible, isTrue);
      // Both halves are turned, so both carry some shade.
      expect(pose.innerLeft.shade, greaterThan(0));
      expect(pose.innerRight.shade, greaterThan(0));
    });

    test('the inner face of the left half and the cover never show '
        'together', () {
      for (var angle = 0.0; angle <= 180; angle += 1) {
        final pose = poseAt(angle);
        expect(
          pose.innerLeft.visible && pose.cover.visible,
          isFalse,
          reason: '$angle°',
        );
      }
    });

    test('an edge ends where the corner of the face behind it cuts it', () {
      CoreMockupFoldCorner corner(String key) {
        final pair = (geometry[key] as List<dynamic>).cast<num>();

        return (x: pair[0].toDouble(), y: pair[1].toDouble());
      }

      final inner = corner('innerCorner');
      final cover = corner('coverCorner');
      var compared = 0;

      for (final vector in vectors) {
        final angle = (vector['angle'] as num).toDouble();
        final pose = poseAt(angle);
        final cuts = vector['edgeCuts'] as Map<String, dynamic>;
        final actual = {
          'right': pose.rightEdgeCut(top: inner, bottom: inner),
          'left': pose.leftEdgeCut(
            innerTop: inner,
            innerBottom: inner,
            coverTop: cover,
            coverBottom: cover,
          ),
        };

        for (final side in actual.keys) {
          final expected = cuts[side] as Map<String, dynamic>?;
          // The table states a cut only where the edge is drawn.
          if (expected == null) continue;
          final cut = actual[side]!;
          expect(
            cut.outlineAtEnd,
            expected['outlineAtEnd'],
            reason: '$angle° $side',
          );
          for (final (end, got) in [('top', cut.top), ('bottom', cut.bottom)]) {
            final want = (expected[end] as List<dynamic>).cast<num>();
            expect(
              got.x,
              closeTo(want[0].toDouble(), _kTolerance * want[0].abs() + 1e-5),
              reason: '$angle° $side $end across',
            );
            expect(got.y, want[1].toDouble(), reason: '$angle° $side $end');
            compared++;
          }
        }
      }

      // A table with no cut in it would pass by comparing nothing.
      expect(compared, greaterThan(20));
    });

    test('the left edge is cut by the face its slab does not show', () {
      const inner = (x: 16.0, y: 16.0);
      const cover = (x: 24.0, y: 20.0);
      CoreMockupFoldEdgeCut cutAt(double angle) => poseAt(angle).leftEdgeCut(
        innerTop: inner,
        innerBottom: inner,
        coverTop: cover,
        coverBottom: cover,
      );

      // Nearly shut the cover faces out, so the outline is the inner face's.
      expect(poseAt(20).cover.visible, isTrue);
      expect(cutAt(20).outlineAtEnd, isTrue);
      expect(cutAt(20).top.y, inner.y);
      // Held open the inner face shows, so the outline is the cover's.
      expect(poseAt(120).cover.visible, isFalse);
      expect(cutAt(120).outlineAtEnd, isFalse);
      expect(cutAt(120).top.y, cover.y);
    });

    test('a square corner cuts nothing, and the cut scales with the '
        'device', () {
      const square = (x: 0.0, y: 0.0);
      const round = (x: 16.0, y: 16.0);
      final pose = poseAt(CoreMockupFold.halfOpen);

      expect(pose.rightEdgeCut(top: square, bottom: round).top, square);
      expect(
        pose.rightEdgeCut(top: square, bottom: round).bottom.x,
        isPositive,
      );
      // Each end is cut by its own corner, on both faces of the left slab.
      for (final angle in [20.0, CoreMockupFold.halfOpen]) {
        final left = poseAt(angle).leftEdgeCut(
          innerTop: square,
          innerBottom: round,
          coverTop: square,
          coverBottom: round,
        );
        expect(left.top, square, reason: '$angle°');
        expect(left.bottom.x, isPositive, reason: '$angle°');
      }

      const scale = 1.5;
      final scaled = CoreMockupFoldPose.compute(
        angle: CoreMockupFold.halfOpen,
        width: width * scale,
        height: height * scale,
        thickness: thickness * scale,
        perspective: perspective,
      );
      final base = pose.rightEdgeCut(top: round, bottom: round).top;
      final grown = scaled
          .rightEdgeCut(
            top: (x: round.x * scale, y: round.y * scale),
            bottom: (x: round.x * scale, y: round.y * scale),
          )
          .top;

      expect(grown.x, closeTo(base.x * scale, _kTolerance * base.x));
      expect(grown.y, round.y * scale);
    });

    test('the pose scales with the device', () {
      const scale = 1.5;
      final base = poseAt(CoreMockupFold.halfOpen);
      final scaled = CoreMockupFoldPose.compute(
        angle: CoreMockupFold.halfOpen,
        width: width * scale,
        height: height * scale,
        thickness: thickness * scale,
        perspective: perspective,
      );
      final a = CoreMockupFoldPose.project(base.innerLeft.matrix, 0, 0);
      final b = CoreMockupFoldPose.project(scaled.innerLeft.matrix, 0, 0);

      expect(b.x, closeTo(a.x * scale, _kTolerance));
      expect(b.y, closeTo(a.y * scale, _kTolerance));
    });
  });
}

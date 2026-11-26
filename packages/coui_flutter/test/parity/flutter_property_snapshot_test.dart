// The absence-vs-measured split in `buildFlutterPropertySnapshotJson`.
//
// `null` in a snapshot field means the chrome walk found no node to
// attribute that field to. It does NOT mean "measured, and the answer is
// nothing" — Web says that second fact with a concrete value
// (`rgba(0,0,0,0)`, `0px`), so encoding it as `null` here made the two
// platforms look divergent while both painted the same nothing.
//
// These tests exist because the tempting simplification — collapsing
// `null` into transparent at the comparator instead — would report
// "verified" exactly when the walk breaks, turning the failure this probe
// exists to catch into the failure it hides.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flutter_property_snapshot.dart';

void main() {
  group('buildFlutterPropertySnapshotJson — absence vs measured nothing', () {
    test('a chrome node stating no fill reports transparent, not null', () {
      final json = buildFlutterPropertySnapshotJson(
        key: 'k',
        probeRole: 'root',
        decoration: const BoxDecoration(),
      );

      expect(json['backgroundColor'], isNotNull);
      expect(json['borderRadiusPx'], isNotNull);
    });

    test('no chrome node at all leaves those fields null', () {
      final json = buildFlutterPropertySnapshotJson(
        key: 'k',
        probeRole: 'root',
      );

      expect(json['backgroundColor'], isNull);
      expect(json['borderRadiusPx'], isNull);
    });

    test('a circle reports no corner radius — there are no square corners', () {
      final json = buildFlutterPropertySnapshotJson(
        key: 'k',
        probeRole: 'root',
        decoration: const BoxDecoration(shape: BoxShape.circle),
      );

      expect(json['borderRadiusPx'], isNull);
      // The fill is still a measured fact even when the corners are not.
      expect(json['backgroundColor'], isNotNull);
    });

    test('a stated fill and radius still come through unchanged', () {
      final json = buildFlutterPropertySnapshotJson(
        key: 'k',
        probeRole: 'root',
        decoration: BoxDecoration(
          color: const Color(0xFF102030),
          borderRadius: BorderRadius.circular(8),
        ),
      );

      expect(json['backgroundColor'], isNotNull);
      expect(json['borderRadiusPx'], isNotNull);
    });
  });
}

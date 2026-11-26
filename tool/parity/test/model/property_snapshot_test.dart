// This file's entire purpose is checking specific numeric conversions
// against specific expected numeric outputs — naming each one would add
// noise, not clarity. Matches the existing convention across this repo's
// test suite (e.g. `packages/coui_flutter/test/pixel_snap_test.dart`).
import 'package:test/test.dart';

import '../../src/model/property_snapshot.dart';

void main() {
  group('roundPx', () {
    test('rounds to 2 decimal places', () {
      expect(roundPx(4.567), 4.57);
      expect(roundPx(4), 4);
    });
  });

  group('roundAlpha', () {
    test('rounds to 3 decimal places', () {
      expect(roundAlpha(0.123456), 0.123);
      expect(roundAlpha(1), 1.0);
    });
  });

  group('NormalizedColor', () {
    test('rounds alpha at construction, not just at comparison time', () {
      final color = NormalizedColor(r: 1, g: 2, b: 0, a: 0.123456);
      expect(color.a, 0.123);
    });

    test('round-trips through toJson/fromJson', () {
      final color = NormalizedColor(r: 1, g: 2, b: 0, a: 0.5);
      expect(NormalizedColor.fromJson(color.toJson()), color);
    });
  });

  group('FourSidePx', () {
    test('round-trips through toJson/fromJson', () {
      const sides = FourSidePx(1, 2, 3, 4);
      expect(FourSidePx.fromJson(sides.toJson()), sides);
    });
  });

  group('PropertySnapshot', () {
    test('round-trips a fully-populated snapshot through JSON', () {
      final snapshot = PropertySnapshot(
        key: 'card-default-light-defaultStyle',
        platform: 'web',
        probeRole: 'root',
        fontFamily: 'Pretendard',
        fontWeight: 600,
        fontSizePx: 16,
        lineHeightPx: 24,
        letterSpacingPx: 0.5,
        color: NormalizedColor(r: 29, g: 29, b: 31, a: 1),
        backgroundColor: NormalizedColor(r: 255, g: 255, b: 255, a: 1),
        borderColor: NormalizedColor(r: 0, g: 0, b: 0, a: 1),
        borderWidthPx: 1,
        borderRadiusPx: const FourSidePx(8, 8, 8, 8),
        paddingPx: const FourSidePx(16, 12, 16, 12),
        outlineWidthPx: 2,
        outlineOffsetPx: 2,
        boxShadow: [
          BoxShadowLayer(
            offsetX: 0,
            offsetY: 4,
            blur: 6,
            spread: 2,
            color: NormalizedColor(r: 0, g: 0, b: 0, a: 0.1),
          ),
        ],
        opacity: 1,
      );

      final decoded = PropertySnapshot.fromJson(snapshot.toJson());
      expect(decoded, snapshot);
    });

    test('round-trips a minimally-populated snapshot (all optional null)', () {
      const snapshot = PropertySnapshot(
        key: 'k',
        platform: 'flutter',
        probeRole: 'root',
      );
      final decoded = PropertySnapshot.fromJson(snapshot.toJson());
      expect(decoded, snapshot);
    });

    test('== distinguishes snapshots with different boxShadow layers', () {
      PropertySnapshot withShadowOffsetY(double offsetY) => .new(
        key: 'k',
        platform: 'web',
        probeRole: 'root',
        boxShadow: [
          BoxShadowLayer(
            offsetX: 0,
            offsetY: offsetY,
            blur: 0,
            spread: 0,
            color: NormalizedColor(r: 0, g: 0, b: 0, a: 1),
          ),
        ],
      );
      final near = withShadowOffsetY(4);
      final far = withShadowOffsetY(8);

      expect(near == far, isFalse);
      // Two separately-constructed instances with the same values must
      // compare equal by value, not just be reference-identical.
      expect(near == withShadowOffsetY(4), isTrue);
    });
  });
}

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pixelSnap()', () {
    test('no-op when the product lands on a whole physical pixel', () {
      expect(pixelSnap(10.0, 2.0), equals(10.0));
      expect(pixelSnap(12.0, 1.0), equals(12.0));
    });

    test('rounds to the nearest physical pixel', () {
      // 10.3 × 2.0 = 20.6 → 21 → 21 / 2.0 = 10.5
      expect(pixelSnap(10.3, 2.0), equals(10.5));
      // 10.2 × 1.5 = 15.3 → 15 → 15 / 1.5 = 10.0
      expect(pixelSnap(10.2, 1.5), equals(10.0));
    });

    test('returns the value unchanged for a non-positive ratio', () {
      expect(pixelSnap(10.3, 0), equals(10.3));
      expect(pixelSnap(10.3, -2), equals(10.3));
    });
  });

  group('PixelSnap', () {
    testWidgets('snapOf snaps under a PixelSnap ancestor', (tester) async {
      double? snapped;
      await tester.pumpWidget(
        PixelSnap(
          devicePixelRatio: 2.0,
          child: Builder(
            builder: (context) {
              snapped = PixelSnap.snapOf(context, 10.3);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(snapped, equals(10.5));
    });

    testWidgets('snapOf returns the value unchanged with no ancestor', (
      tester,
    ) async {
      double? snapped;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            snapped = PixelSnap.snapOf(context, 10.3);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(snapped, equals(10.3));
    });
  });
}

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// A thumb's edges — not its centre — stop at the track ends, so a
// pointer x maps over `trackWidth - thumbSize`. 50% is the one value
// where that model and a centre-anchored one agree, which is why these
// pin the ends: a centre-anchored mapping passes a midpoint test.

const _kTrackWidth = 300.0;
// Read from the Core default so a change to the thumb moves these taps with
// it — a stale literal lands the tap off the half-thumb line.
const _kThumbSize = CoreRangeStyle.defaultThumbSize;
const _kMin = 0.0;
const _kMax = 100.0;
const _kInitialMin = 40.0;
const _kInitialMax = 60.0;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kTrackWidth,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

void main() {
  group('Range pointer mapping', () {
    testWidgets('a tap half a thumb in from the left reads as min', (
      tester,
    ) async {
      double? changedMin;
      await tester.pumpWidget(
        _buildApp(
          Range(
            onChanged: (min, _) => changedMin = min,
            minValue: _kInitialMin,
            maxValue: _kInitialMax,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final topLeft = tester.getTopLeft(find.byType(Range));
      final centre = tester.getCenter(find.byType(Range));
      await tester.tapAt(Offset(topLeft.dx + _kThumbSize / 2, centre.dy));
      final __ = await tester.pumpAndSettle();

      expect(changedMin, _kMin);
    });

    testWidgets('a tap half a thumb in from the right reads as max', (
      tester,
    ) async {
      double? changedMax;
      await tester.pumpWidget(
        _buildApp(
          Range(
            onChanged: (_, max) => changedMax = max,
            minValue: _kInitialMin,
            maxValue: _kInitialMax,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final topRight = tester.getTopRight(find.byType(Range));
      final centre = tester.getCenter(find.byType(Range));
      await tester.tapAt(Offset(topRight.dx - _kThumbSize / 2, centre.dy));
      final __ = await tester.pumpAndSettle();

      expect(changedMax, _kMax);
    });
  });
}

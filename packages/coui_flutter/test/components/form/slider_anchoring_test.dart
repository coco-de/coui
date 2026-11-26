import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// The thumb's edges — not its centre — stop at the track ends, so a
// pointer x maps over `trackWidth - thumbSize`. 50% is the one value
// where that model and a centre-anchored one agree, which is why these
// pin the ends: a centre-anchored mapping passes a midpoint test.

const _kTrackWidth = 300.0;
const _kThumbSize = CoreSliderStyle.defaultThumbSize;
const _kMin = 0.0;
const _kMax = 100.0;
const _kMidValue = 50.0;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kTrackWidth,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

void main() {
  group('Slider pointer mapping', () {
    testWidgets('a tap half a thumb in from the left reads as min', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(
        _buildApp(Slider(onChanged: (v) => changed = v, value: _kMidValue)),
      );
      final _ = await tester.pumpAndSettle();

      // Where the thumb's centre sits when the thumb is parked at min.
      final topLeft = tester.getTopLeft(find.byType(Slider));
      final centre = tester.getCenter(find.byType(Slider));
      await tester.tapAt(
        Offset(topLeft.dx + _kThumbSize / 2, centre.dy),
      );
      final __ = await tester.pumpAndSettle();

      expect(changed, _kMin);
    });

    testWidgets('a tap half a thumb in from the right reads as max', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(
        _buildApp(Slider(onChanged: (v) => changed = v, value: _kMidValue)),
      );
      final _ = await tester.pumpAndSettle();

      final topRight = tester.getTopRight(find.byType(Slider));
      final centre = tester.getCenter(find.byType(Slider));
      await tester.tapAt(
        Offset(topRight.dx - _kThumbSize / 2, centre.dy),
      );
      final __ = await tester.pumpAndSettle();

      expect(changed, _kMax);
    });

    testWidgets('the track centre still reads as the midpoint', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(
        _buildApp(Slider(onChanged: (v) => changed = v, value: _kMin)),
      );
      final _ = await tester.pumpAndSettle();

      await tester.tapAt(tester.getCenter(find.byType(Slider)));
      final __ = await tester.pumpAndSettle();

      expect(changed, _kMidValue);
    });
  });
}

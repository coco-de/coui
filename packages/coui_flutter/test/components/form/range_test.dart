import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kMinValue = 20.0;
const _kMaxValue = 80.0;
const _kPreviewWidth = 300.0;
const _kDragOffset = 40.0;
const _kGap = 4.0;
const _kThumbSize = 24.0;
const _kTrackHeight = 8.0;
const _kNewTrackHeight = 12.0;

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Center(
      child: SizedBox(width: _kPreviewWidth, child: child),
    ),
  ),
);

void main() {
  group('Range', () {
    testWidgets('renders without leading/trailing', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Range(minValue: _kMinValue, maxValue: _kMaxValue)),
      );
      expect(find.byType(Range), findsOneWidget);
    });

    testWidgets('renders leading and trailing slots', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Range(
            minValue: _kMinValue,
            maxValue: _kMaxValue,
            leading: Text('0'),
            trailing: Text('100'),
          ),
        ),
      );
      expect(find.text('0'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('implements CoreRangeContract', (tester) async {
      const range = Range(minValue: _kMinValue, maxValue: _kMaxValue);
      expect(range, isA<CoreRangeContract<Widget>>());
    });

    testWidgets('dragging fires onChanged', (tester) async {
      double? lastMin;
      double? lastMax;
      await tester.pumpWidget(
        _buildApp(
          Range(
            onChanged: (min, max) {
              lastMin = min;
              lastMax = max;
            },
            minValue: _kMinValue,
            maxValue: _kMaxValue,
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Range)),
      );
      await gesture.moveBy(const Offset(_kDragOffset, 0));
      await gesture.up();
      await tester.pump();

      expect(lastMin != null || lastMax != null, isTrue);
    });
  });

  group('CoreRangeStyle', () {
    test('merge overrides non-null fields', () {
      const base = CoreRangeStyle(minMaxGapStyle: CoreGapStyle(size: _kGap));
      const override = CoreRangeStyle(thumbSize: _kThumbSize);
      final merged = base.merge(override);
      expect(merged.minMaxGapStyle?.size, equals(_kGap));
      expect(merged.thumbSize, equals(_kThumbSize));
    });

    test('copyWith replaces fields', () {
      const style = CoreRangeStyle(trackHeight: _kTrackHeight);
      final copy = style.copyWith(trackHeight: _kNewTrackHeight);
      expect(copy.trackHeight, equals(_kNewTrackHeight));
    });
  });
}

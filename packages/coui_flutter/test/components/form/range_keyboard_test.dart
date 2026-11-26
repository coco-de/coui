import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

const _kInitialMin = 20.0;
const _kInitialMax = 80.0;
const _kArrowStep = 1.0;
const _kNearLeftEdgeRatio = 0.05;
const _kNearRightEdgeRatio = 0.95;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

/// Wraps [Range] so `onChanged` actually feeds back into the widget —
/// `Range` is a controlled component (its `minValue`/`maxValue` come
/// from the parent), so a keyboard adjustment only has something to
/// build on if the previous change was applied, exactly like a real
/// consumer's `setState`.
class _ControlledRange extends material.StatefulWidget {
  const _ControlledRange({
    required this.onChanged,
    required this.initialMin,
    required this.initialMax,
  });

  final double initialMin;
  final double initialMax;
  final void Function(double min, double max) onChanged;

  @override
  material.State<_ControlledRange> createState() => _ControlledRangeState();
}

class _ControlledRangeState extends material.State<_ControlledRange> {
  late double _min = widget.initialMin;
  late double _max = widget.initialMax;

  @override
  Widget build(BuildContext context) {
    return Range(
      onChanged: (min, max) {
        setState(() {
          _min = min;
          _max = max;
        });
        widget.onChanged(min, max);
      },
      minValue: _min,
      maxValue: _max,
    );
  }
}

void main() {
  group('Range keyboard', () {
    testWidgets(
      'dragging near the min thumb focuses it — arrow keys then adjust '
      'only minValue',
      (tester) async {
        double? min;
        double? max;
        await tester.pumpWidget(
          _buildApp(
            _ControlledRange(
              onChanged: (a, b) {
                min = a;
                max = b;
              },
              initialMin: _kInitialMin,
              initialMax: _kInitialMax,
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        // Tap near the left edge — closer to the min thumb (20%) than
        // the max thumb (80%) — picks the min handle and focuses it.
        final topLeft = tester.getTopLeft(find.byType(Range));
        final size = tester.getSize(find.byType(Range));
        await tester.tapAt(
          topLeft + Offset(size.width * _kNearLeftEdgeRatio, size.height / 2),
        );
        final __ = await tester.pumpAndSettle();
        expect(min, isNotNull);
        final minAfterTap = min!;
        final maxAfterTap = max!;

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        final ___ = await tester.pumpAndSettle();

        expect(min, minAfterTap + _kArrowStep);
        expect(max, maxAfterTap);
      },
    );

    testWidgets(
      'dragging near the max thumb focuses it — arrow keys then adjust '
      'only maxValue',
      (tester) async {
        double? min;
        double? max;
        await tester.pumpWidget(
          _buildApp(
            _ControlledRange(
              onChanged: (a, b) {
                min = a;
                max = b;
              },
              initialMin: _kInitialMin,
              initialMax: _kInitialMax,
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final topLeft = tester.getTopLeft(find.byType(Range));
        final size = tester.getSize(find.byType(Range));
        await tester.tapAt(
          topLeft + Offset(size.width * _kNearRightEdgeRatio, size.height / 2),
        );
        final __ = await tester.pumpAndSettle();
        expect(max, isNotNull);
        final minAfterTap = min!;
        final maxAfterTap = max!;

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        final ___ = await tester.pumpAndSettle();

        expect(max, maxAfterTap - _kArrowStep);
        expect(min, minAfterTap);
      },
    );

    testWidgets('Home/End on the min thumb clamp to [min, maxValue]', (
      tester,
    ) async {
      double? min;
      double? max;
      await tester.pumpWidget(
        _buildApp(
          _ControlledRange(
            onChanged: (a, b) {
              min = a;
              max = b;
            },
            initialMin: _kInitialMin,
            initialMax: _kInitialMax,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final topLeft = tester.getTopLeft(find.byType(Range));
      final size = tester.getSize(find.byType(Range));
      await tester.tapAt(
        topLeft + Offset(size.width * _kNearLeftEdgeRatio, size.height / 2),
      );
      final __ = await tester.pumpAndSettle();
      final maxAfterTap = max!;

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      final ___ = await tester.pumpAndSettle();
      expect(min, 0);
      expect(max, maxAfterTap);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      final ____ = await tester.pumpAndSettle();
      // End on the min thumb jumps to its upper bound: the max thumb's
      // current value, not the slider's global max (mutual clamp).
      expect(min, maxAfterTap);
    });
  });
}

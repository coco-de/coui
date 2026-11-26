import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kHalfValue = 0.5;
const _kZeroValue = 0.0;
const _kCustomMin = 0.0;
const _kCustomMax = 100.0;
const _kCustomValue = 50.0;
const _kFiveDivisions = 5;
const _kSizedBoxWidth = 300.0;
const _kTrackHeight = 6.0;
const _kThumbSize = 16.0;

Widget _buildApp(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kSizedBoxWidth,
      child: Theme(
        data: const ThemeData(),
        child: child,
      ),
    ),
  ),
);

void main() {
  group('Slider widget', () {
    testWidgets('renders with default value', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Slider(value: _kHalfValue)),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = material.Key('test-slider');

      await tester.pumpWidget(
        _buildApp(
          const Slider(key: testKey, value: _kHalfValue),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('disabled slider does not fire onChanged', (tester) async {
      var changeCount = 0;

      await tester.pumpWidget(
        _buildApp(
          Slider(
            onChanged: (_) {
              changeCount += 1;
            },
            enabled: false,
            value: _kZeroValue,
          ),
        ),
      );

      await tester.tap(find.byType(Slider));
      final _ = await tester.pumpAndSettle();

      expect(changeCount, equals(0));
    });

    testWidgets('renders with custom min and max', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Slider(
            max: _kCustomMax,
            min: _kCustomMin,
            value: _kCustomValue,
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('renders with divisions', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Slider(
            divisions: _kFiveDivisions,
            value: _kHalfValue,
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('renders with custom style', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Slider(
            value: _kHalfValue,
            sliderStyle: CoreSliderStyle(
              trackHeight: _kTrackHeight,
              thumbSize: _kThumbSize,
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });
  });
}

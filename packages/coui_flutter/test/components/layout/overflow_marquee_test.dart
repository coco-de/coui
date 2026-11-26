import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kTestDuration = Duration(seconds: 5);
const _kFadePortionValue = 30.0;

void main() {
  group('OverflowMarquee', () {
    testWidgets('renders with child', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OverflowMarquee(
            child: material.Text('marquee content'),
          ),
        ),
      );

      expect(find.text('marquee content'), findsOneWidget);
    });

    testWidgets('renders with horizontal direction param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OverflowMarquee(
            direction: CoreAxis.horizontal,
            child: material.Text('horizontal marquee'),
          ),
        ),
      );

      expect(find.text('horizontal marquee'), findsOneWidget);
    });

    testWidgets('renders with vertical direction param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OverflowMarquee(
            direction: CoreAxis.vertical,
            child: material.Text('vertical marquee'),
          ),
        ),
      );

      expect(find.text('vertical marquee'), findsOneWidget);
    });

    testWidgets('renders with custom duration param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OverflowMarquee(
            overflowMarqueeStyle: CoreOverflowMarqueeStyle(
              duration: _kTestDuration,
            ),
            child: material.Text('timed marquee'),
          ),
        ),
      );

      expect(find.text('timed marquee'), findsOneWidget);
    });

    testWidgets('renders with fadePortion param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OverflowMarquee(
            overflowMarqueeStyle: CoreOverflowMarqueeStyle(
              fadePortion: _kFadePortionValue,
            ),
            child: material.Text('faded marquee'),
          ),
        ),
      );

      expect(find.text('faded marquee'), findsOneWidget);
    });

    testWidgets('renders OverflowMarquee widget in tree', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OverflowMarquee(
            child: material.Text('widget tree test'),
          ),
        ),
      );

      expect(find.byType(OverflowMarquee), findsOneWidget);
    });
  });
}

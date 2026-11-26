import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kTestBreakpoint = 300.0;
const _kTestMinSize = 100.0;
const _kTestMaxSize = 800.0;
const _kTestPadding = CoreEdgeInsets.symmetric(horizontal: 16);
// Note: not const because CoreStagedStageBreakpoint assert checks .length at runtime.
final _kTestBreakpoints = [400.0, 600.0, 900.0];
const _kTestWidth = 500.0;
const _kDefaultBreakpoint576 = 576.0;
const _kDefaultBreakpoint768 = 768.0;
const _kWidthBelow350 = 350.0;
const _kWidthBetween500 = 500.0;
const _kWidthBeyond1000 = 1000.0;

void main() {
  group('CoreConstantStageBreakpoint', () {
    test('constructor stores breakpoint value', () {
      const bp = CoreConstantStageBreakpoint(_kTestBreakpoint);

      expect(bp.breakpoint, equals(_kTestBreakpoint));
    });

    test('minSize defaults to 0', () {
      const bp = CoreConstantStageBreakpoint(_kTestBreakpoint);

      expect(bp.minSize, equals(0));
    });

    test('maxSize defaults to infinity', () {
      const bp = CoreConstantStageBreakpoint(_kTestBreakpoint);

      expect(bp.maxSize, equals(double.infinity));
    });

    test('constructor stores custom minSize and maxSize', () {
      const bp = CoreConstantStageBreakpoint(
        _kTestBreakpoint,
        maxSize: _kTestMaxSize,
        minSize: _kTestMinSize,
      );

      expect(bp.minSize, equals(_kTestMinSize));
      expect(bp.maxSize, equals(_kTestMaxSize));
    });

    test('getMinWidth returns floor multiple of breakpoint', () {
      const bp = CoreConstantStageBreakpoint(_kTestBreakpoint);
      // 500 / 300 = 1.666, floor = 1, so minWidth = 300
      final result = bp.getMinWidth(_kTestWidth);

      expect(result, equals(_kTestBreakpoint));
    });

    test('getMaxWidth returns ceiling multiple of breakpoint', () {
      const bp = CoreConstantStageBreakpoint(_kTestBreakpoint);
      // 500 / 300 = 1.666, ceil = 2, so maxWidth = 600
      final result = bp.getMaxWidth(_kTestWidth);

      expect(result, equals(_kTestBreakpoint * 2));
    });

    test('getMinWidth when width is exact multiple', () {
      const bp = CoreConstantStageBreakpoint(_kTestBreakpoint);
      // 600 / 300 = 2.0, floor = 2, minWidth = 600
      final result = bp.getMinWidth(_kTestBreakpoint * 2);

      expect(result, equals(_kTestBreakpoint * 2));
    });

    test('getMaxWidth when width is exact multiple', () {
      const bp = CoreConstantStageBreakpoint(_kTestBreakpoint);
      // 600 / 300 = 2.0, ceil = 2, maxWidth = 600
      final result = bp.getMaxWidth(_kTestBreakpoint * 2);

      expect(result, equals(_kTestBreakpoint * 2));
    });
  });

  group('CoreStagedStageBreakpoint', () {
    test('defaultBreakpoints constructor creates staged breakpoint', () {
      const bp = CoreStagedStageBreakpoint.defaultBreakpoints();

      expect(bp.breakpoints, isNotEmpty);
      expect(bp.breakpoints.length, greaterThan(1));
    });

    test('defaultBreakpoints contains expected values', () {
      const bp = CoreStagedStageBreakpoint.defaultBreakpoints();

      expect(bp.breakpoints, contains(_kDefaultBreakpoint576));
      expect(bp.breakpoints, contains(_kDefaultBreakpoint768));
    });

    test('constructor stores provided breakpoints', () {
      final bp = CoreStagedStageBreakpoint(_kTestBreakpoints);

      expect(bp.breakpoints, equals(_kTestBreakpoints));
    });

    test('minSize returns first breakpoint', () {
      final bp = CoreStagedStageBreakpoint(_kTestBreakpoints);

      expect(bp.minSize, equals(_kTestBreakpoints.first));
    });

    test('maxSize returns last breakpoint', () {
      final bp = CoreStagedStageBreakpoint(_kTestBreakpoints);

      expect(bp.maxSize, equals(_kTestBreakpoints.last));
    });

    test('getMinWidth below first breakpoint returns first breakpoint', () {
      final bp = CoreStagedStageBreakpoint(_kTestBreakpoints);
      // width 350 is below first breakpoint (400), so minWidth = 400
      // Actually: iterates i=1 (600), 350 < 600 returns breakpoints[0] = 400
      final result = bp.getMinWidth(_kWidthBelow350);

      expect(result, equals(_kTestBreakpoints[0]));
    });

    test('getMinWidth between breakpoints returns lower breakpoint', () {
      final bp = CoreStagedStageBreakpoint(_kTestBreakpoints);
      // width 500 is between 400 and 600
      // i=1: 500 < 600 returns breakpoints[0] = 400
      final result = bp.getMinWidth(_kWidthBetween500);

      expect(result, equals(_kTestBreakpoints[0]));
    });

    test('getMaxWidth below first breakpoint returns first breakpoint', () {
      final bp = CoreStagedStageBreakpoint(_kTestBreakpoints);
      // width 350 < 400, so maxWidth = 400
      final result = bp.getMaxWidth(_kWidthBelow350);

      expect(result, equals(_kTestBreakpoints[0]));
    });

    test('getMaxWidth beyond last breakpoint returns maxSize', () {
      final bp = CoreStagedStageBreakpoint(_kTestBreakpoints);
      // width 1000 > 900 (last), returns maxSize = 900
      final result = bp.getMaxWidth(_kWidthBeyond1000);

      expect(result, equals(bp.maxSize));
    });

    test(
      'CoreStageBreakpoint.defaultBreakpoints is CoreStagedStageBreakpoint',
      () {
        final bp = CoreStageBreakpoint.defaultBreakpoints;

        expect(bp, isA<CoreStagedStageBreakpoint>());
      },
    );
  });

  group('StageContainer', () {
    testWidgets('renders with builder', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          StageContainer(
            builder: (context, padding) {
              return material.Padding(
                padding: padding.toValue(),
                child: const material.Text('Stage Content'),
              );
            },
          ),
        ),
      );

      expect(find.byType(StageContainer), findsOneWidget);
      expect(find.text('Stage Content'), findsOneWidget);
    });

    testWidgets('renders with custom breakpoint', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          StageContainer(
            breakpoint: const CoreConstantStageBreakpoint(_kTestBreakpoint),
            builder: (context, padding) {
              return const material.Text('Custom Breakpoint');
            },
          ),
        ),
      );

      expect(find.byType(StageContainer), findsOneWidget);
      expect(find.text('Custom Breakpoint'), findsOneWidget);
    });

    testWidgets('renders with custom padding', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          StageContainer(
            padding: _kTestPadding,
            builder: (context, padding) {
              return const material.Text('Custom Padding');
            },
          ),
        ),
      );

      expect(find.byType(StageContainer), findsOneWidget);
      expect(find.text('Custom Padding'), findsOneWidget);
    });

    testWidgets('builder receives EdgeInsets parameter', (tester) async {
      CoreEdgeInsets? receivedPadding;
      final _ = await tester.pumpWidget(
        _buildApp(
          StageContainer(
            builder: (context, padding) {
              receivedPadding = padding;
              return const material.SizedBox();
            },
          ),
        ),
      );

      expect(receivedPadding, isNotNull);
    });
  });
}
